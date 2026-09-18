/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'pos_pending_sale.dart';

/// Where the offline queue is kept.
///
/// The source of this module reads `window.localStorage` directly, and stores one JSON blob per
/// company under `pn_pos_pending_sales_<companyId>`
/// (`finnesia-monorepo/apps/web/src/lib/pos-offline-queue.ts`). That is not portable, and
/// `.claude/rules/project.md` §5 requires SQLite for anything holding money. So storage sits
/// behind this port and the real implementation lives in `apps/pos`
/// (`.claude/rules/architecture.md` §3.2).
///
/// ## The contract is the **opposite** of [HoldOrderStore]
///
/// A parked basket may be lost — the cashier re-rings it. A **queued sale may not**: the money
/// has already been taken and the goods have left the shop. So every method here **throws**
/// [PendingSaleStoreException] when the storage fails, and nothing is ever silently empty.
///
/// The web app does the opposite (`catch { return [] }`), and that is why the three oracle cases
/// that pin its behaviour are not ported. A queue that reads as empty when it is unreadable would
/// let the cashier close the shift and reset the tablet on top of sales nobody can see
/// (`plan/offline-queue/README.md` §4.1, `cross-repo.md` §4).
///
/// ## Why it deals in rows, not whole lists
///
/// [HoldOrderStore] reads and writes the whole list, mirroring the two functions the source has
/// and because every held-order operation really is "read everything, filter in memory, write
/// everything back". This one is not, and copying that shape would be wrong twice over:
///
/// - The queue is a **table**, read by status and outlet (the drain loop and the close-shift
///   guard), and a whole-list write would rewrite every row to change one.
/// - `enqueue` must be **idempotent on `client_ref`**, which a whole-list write cannot express:
///   it would silently overwrite the entry that recorded the money being taken.
///
/// Every method is `async` for the same reason [HoldOrderStore]'s are: `sqflite` is, and a
/// synchronous port could only be implemented by the fake — a port that lies.
///
/// ## Why the company is fixed at construction, not passed per call
///
/// The source passes `companyId` to every function, because it needs the string to build the
/// `localStorage` key. Here it is the store's identity, and that is a deliberate difference with
/// a safety reason attached:
///
/// **A wrong `companyId` at a call site reads as an empty queue.** Empty is indistinguishable from
/// "everything has been sent", which is the exact failure this port exists to prevent — so the
/// interface removes the opportunity. One store, one tenant; a device re-paired to another tenant
/// gets a new store, and a sale belonging to the other tenant is rejected loudly by [enqueue]
/// rather than written where nothing will read it.
///
/// The company is still a **column** on every row: the table holds every tenant's rows, the reads
/// filter on it, and a re-pair cannot make one tenant's sale appear in another's queue.
abstract interface class PendingSaleStore {
  /// The tenant whose queue this is.
  String get companyId;

  /// Every entry for this store's company, oldest first — the order they were rung up in, which
  /// is the order they are sent in.
  ///
  /// Throws [PendingSaleStoreException] when the storage cannot be read. **Never** an empty list
  /// to mean "unreadable": see the class doc.
  Future<List<PendingSale>> readAll();

  /// Adds [sale], or does nothing when an entry with the same `client_ref` is already there.
  ///
  /// **Idempotent on `client_ref`**, and the entry already stored wins. The real case is a caller
  /// that retried after a timeout while the first write had in fact landed: a second row would be
  /// a second sale for money taken once, and overwriting would replace the record that knows when
  /// it was taken.
  ///
  /// Throws [ArgumentError] when [PendingSale.companyId] is not this store's — that is a bug in
  /// the caller, and it would otherwise write a row no read would ever return.
  ///
  /// Throws [PendingSaleStoreException] when the write fails, so the caller can keep the cart in
  /// front of the cashier and say the sale was not processed.
  Future<void> enqueue(PendingSale sale);

  /// How many entries match.
  ///
  /// [outletId] narrows it to one outlet. [status] defaults to `pending` — the sales still waiting
  /// to be sent — and `null` means "any status", which is what the close-shift guard asks: it
  /// refuses while there is a `pending` **or** `failed` sale at that outlet
  /// (`plan/offline-queue/README.md` §6).
  ///
  /// Throws [PendingSaleStoreException] when the storage cannot be read.
  Future<int> count({
    String? outletId,
    PendingSaleStatus? status = PendingSaleStatus.pending,
  });

  /// Marks an entry as failed, with the server's own sentence for [error].
  ///
  /// The entry stays in the queue: the goods have already left the shop, so the cashier decides
  /// whether to retry it or discard it knowing the drawer will be short.
  ///
  /// An unknown [clientRef] is not an error — the row may have been removed by another pass or
  /// discarded by the cashier while this one was retrying.
  ///
  /// Throws [PendingSaleStoreException] when the write fails.
  Future<void> markFailed(String clientRef, String error);

  /// Puts a failed entry back in the pending queue, clearing its reason.
  ///
  /// An unknown [clientRef] is not an error, as [markFailed].
  ///
  /// Throws [PendingSaleStoreException] when the write fails.
  Future<void> retry(String clientRef);

  /// Removes an entry for good, once it has been sent or the cashier discarded it.
  ///
  /// An unknown [clientRef] is not an error: "the row is gone" is an ordinary state, and a
  /// `DELETE` that matched nothing did what was asked.
  ///
  /// Throws [PendingSaleStoreException] when the write fails. **Not swallowed**: a silent
  /// failure would tell the drain loop the sale is gone while it is still on disk, and the next
  /// pass would post it a second time.
  Future<void> remove(String clientRef);

  /// Counts one more send that failed without a definite answer, and records the server's
  /// reason when there is one.
  ///
  /// Shown in the panel, so a sale that keeps failing is visible rather than silently retrying
  /// forever. [reason] is the server's own sentence for a sale it **blocked** — a 402, or a 403
  /// `outlet_inactive` — which stays `pending` and never reaches [markFailed]. Without it the
  /// panel would show "Menunggu" for a sale nobody can explain.
  ///
  /// [reason] is **optional**, and the two cases differ on purpose:
  ///
  /// - `reason != null` → it replaces whatever `error` held (the newest answer is the true one).
  /// - `reason == null` → `error` is **left alone**. A later attempt that failed on the network
  ///   or a 5xx must not erase the last explanation the server gave; the cashier can act on that
  ///   one and on nothing else.
  ///
  /// Either way `attempts` goes up by one. An unknown [clientRef] is not an error, as
  /// [markFailed].
  ///
  /// Throws [PendingSaleStoreException] when the write fails.
  Future<void> recordAttempt(String clientRef, {String? reason});
}

/// The queue's storage failed: the disk is full, the file is locked, the plugin errored.
///
/// **Not** "the entry is absent" (that is an empty list, or a no-op) and **not** "the row is
/// malformed" (that is the store's to decide, and it is also a failure worth throwing over: a row
/// this app cannot read is a sale it cannot send, and pretending it is not there is how money goes
/// missing).
///
/// A typed exception rather than a bare one so the caller can tell a failing disk from a rejected
/// sale, and because `style.md` §5 requires recoverable errors to have a type the caller must
/// handle. [message] is for a developer reading a bug report — **never** a payload, a token, or a
/// customer's name (`security.md` §1).
class PendingSaleStoreException implements Exception {
  PendingSaleStoreException(this.message, {this.cause});

  final String message;

  /// Whatever the storage threw, for a debugger. Never printed.
  final Object? cause;

  @override
  String toString() => 'PendingSaleStoreException: $message';
}
