/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'pos_pending_sale.dart';
import 'pos_pending_sale_store.dart';

/// In-memory [PendingSaleStore] for tests.
///
/// Lives in `lib/`, not `test/`, for the reason in `.claude/rules/native-ports.md` §2.3: a fake
/// in `test/` cannot be used by another package's tests, and a fake redefined per test file
/// drifts. `apps/pos` needs this too — it has to test the drain loop and the close-shift guard
/// without a database.
///
/// ## The failure switches **throw**, unlike [FakeHoldOrderStore]'s
///
/// That is the whole difference between the two ports, and it is why this is a separate fake
/// rather than a second mode on that one. A parked basket whose storage fails may be lost; a
/// queued sale whose storage fails may **not**, so the caller has to be told. A fake that
/// returned an empty list here would make every test of the caller's error path pass while
/// testing nothing.
///
/// ## What it records
///
/// Every call is counted and the last write is kept, because the drain loop's contract is partly
/// about **how much** storage work it does: one read per pass, and one write per outcome, not one
/// per sale behind it (`optimization.md` §5, README §5.3).
class FakePendingSaleStore implements PendingSaleStore {
  FakePendingSaleStore({this.companyId = 'comp_1', List<PendingSale>? seed})
      : _entries = [...?seed];

  @override
  final String companyId;

  List<PendingSale> _entries;

  /// When true, every read throws instead of answering.
  ///
  /// Not "returns empty": the contract is that an unreadable queue is **not** an empty queue, and
  /// the fake has to reproduce the answer the caller actually meets, or the caller's error path is
  /// never executed by a test.
  bool failRead = false;

  /// When true, every write throws: enqueue, remove, mark, retry, attempt.
  ///
  /// One switch for all of them rather than one per method: they share a single failure mode (the
  /// disk), and a caller that handles one of them has handled them all. [failRemove] exists
  /// separately for the drain loop, where the difference matters.
  bool failWrite = false;

  /// When true, only [remove] fails, and the other writes still work.
  ///
  /// The drain loop needs this case on its own: a sale that was posted but could not be removed
  /// must be reported differently from one that was never posted, and a fake that failed both
  /// would let a test pass for the wrong reason.
  bool failRemove = false;

  /// How many times each method was called.
  int readCount = 0;
  int enqueueCount = 0;
  int writeCount = 0;

  /// What was written last, for assertions that care about the payload.
  List<PendingSale>? lastWritten;

  /// Entries in insertion order, as the real store returns them (`position`).
  List<PendingSale> get entries => [..._entries];

  @override
  Future<List<PendingSale>> readAll() async {
    readCount++;
    if (failRead) {
      throw PendingSaleStoreException('read failed (fake)', cause: 'failRead');
    }
    // Filtered by company, like the real store's `WHERE company_id = ?`. The fake holds every
    // tenant's rows for the same reason the table does: a test that seeds another tenant's sale
    // must be able to prove it is invisible, not merely absent.
    return [
      for (final e in _entries)
        if (e.companyId == companyId) e,
    ];
  }

  @override
  Future<void> enqueue(PendingSale sale) async {
    enqueueCount++;
    _guardWrite();
    if (sale.companyId != companyId) {
      // The real store's `company_id` column would accept the row and no read would ever return
      // it — a sale silently outside its own queue. Failing loudly here is what keeps that from
      // being reachable at all.
      throw ArgumentError.value(
        sale.companyId,
        'sale.companyId',
        'belongs to another company than this store ($companyId)',
      );
    }
    // Idempotent on `client_ref`, and the stored entry wins: it is the one that knows when the
    // money was taken. The real store relies on a `UNIQUE` column for this; here it is the lookup.
    if (_entries.any((e) => e.clientRef == sale.clientRef)) return;
    _entries = [..._entries, sale];
    lastWritten = entries;
  }

  @override
  Future<int> count({
    String? outletId,
    PendingSaleStatus? status = PendingSaleStatus.pending,
  }) async {
    // Counts through [readAll] so the read counter and the failure switch behave the same for
    // both, exactly as the real store's one query does.
    final all = await readAll();
    return all
        .where((e) => outletId == null || e.outletId == outletId)
        .where((e) => status == null || e.status == status)
        .length;
  }

  @override
  Future<void> markFailed(String clientRef, String error) => _update(
      clientRef,
      (e) => e.copyWith(
            status: PendingSaleStatus.failed,
            error: error,
          ));

  @override
  Future<void> retry(String clientRef) => _update(
        clientRef,
        (e) => e.copyWith(status: PendingSaleStatus.pending, error: null),
      );

  @override
  Future<void> recordAttempt(String clientRef, {String? reason}) => _update(
        clientRef,
        (e) => e.copyWith(
          attempts: e.attempts + 1,
          // A null reason leaves the previous one in place: a later network failure must not erase
          // the explanation the server gave (`pos_pending_sale_store.dart`).
          error: reason ?? e.error,
        ),
      );

  @override
  Future<void> remove(String clientRef) async {
    writeCount++;
    if (failWrite || failRemove) {
      throw PendingSaleStoreException('remove failed (fake)',
          cause: 'failRemove');
    }
    // A `DELETE` that matched nothing did what was asked, so this is not an error.
    _entries = [
      for (final e in _entries)
        if (e.clientRef != clientRef) e,
    ];
    lastWritten = entries;
  }

  Future<void> _update(
    String clientRef,
    PendingSale Function(PendingSale) change,
  ) async {
    writeCount++;
    _guardWrite();
    // An unknown ref is an ordinary state, not a failure: another pass or the cashier may have
    // removed the row while this one was retrying.
    if (!_entries.any((e) => e.clientRef == clientRef)) return;
    _entries = [
      for (final e in _entries)
        if (e.clientRef == clientRef) change(e) else e,
    ];
    lastWritten = entries;
  }

  void _guardWrite() {
    if (failWrite) {
      throw PendingSaleStoreException('write failed (fake)',
          cause: 'failWrite');
    }
  }
}
