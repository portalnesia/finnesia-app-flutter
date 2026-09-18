/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'pos_hold.dart';
import 'pos_hold_store.dart';

/// In-memory [HoldOrderStore] for tests.
///
/// Lives in `lib/`, not `test/`, for the reason in `.claude/rules/native-ports.md` §2.3: a
/// fake in `test/` cannot be used by another package's tests, and a fake redefined per test
/// file drifts. `apps/pos` needs this too — it has to test the cart's hold button without a
/// database.
///
/// Both failure switches are here because a fake that only ever succeeds hides bugs. The
/// two paths below are the ones the source's `try`/`catch` blocks exist for, and a port
/// without tests on them means those blocks were never executed.
class FakeHoldOrderStore implements HoldOrderStore {
  FakeHoldOrderStore([List<HeldOrder>? seed]) : _orders = [...?seed];

  List<HeldOrder> _orders;

  /// When true, [readAll] returns an empty list instead of throwing.
  ///
  /// Not "throws" — the *contract* is that an unreadable store looks empty, because the
  /// caller cannot do anything about it and a till must keep working. The source's
  /// `catch { return [] }` is the same decision, so the fake reproduces the answer the
  /// caller actually sees.
  bool failRead = false;

  /// When true, [writeAll] silently does nothing.
  ///
  /// Silent rather than throwing, for the same reason: the source's `catch` block is empty
  /// on purpose, and a cashier must not meet a storage error while taking money.
  bool failWrite = false;

  /// How many times each method was called.
  ///
  /// Recorded so tests can assert call counts — the read-modify-write sequence is the part
  /// of this module that could regress into doing more storage work than it needs.
  /// `.claude/rules/optimization.md` §5.
  int readCount = 0;
  int writeCount = 0;

  /// What was written last, for assertions that care about the payload.
  List<HeldOrder>? lastWritten;

  @override
  Future<List<HeldOrder>> readAll() async {
    readCount++;
    if (failRead) return [];
    return [..._orders];
  }

  @override
  Future<void> writeAll(List<HeldOrder> orders) async {
    writeCount++;
    if (failWrite) return;
    lastWritten = [...orders];
    _orders = [...orders];
  }
}
