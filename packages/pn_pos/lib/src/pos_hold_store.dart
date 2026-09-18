/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'pos_hold.dart';

/// Where the held-order queue is kept.
///
/// The source of this module reads `window.localStorage` directly. That is not portable and
/// not what this app wants: a parked basket is a sale in progress, and
/// `.claude/rules/project.md` §5 requires it in SQLite rather than in something the system
/// can clear. So storage sits behind this port and the real implementation lives in
/// `apps/pos` (`.claude/rules/architecture.md` §3.2).
///
/// ## Why the methods are `async`
///
/// `localStorage` is synchronous, so the source's functions are too. `sqflite` is not. A
/// synchronous port could only ever be implemented by the fake, which would make the
/// interface describe something no real implementation can satisfy — a port that lies. The
/// cost is that every caller awaits; the benefit is that the interface is implementable.
///
/// ## Why it deals in whole lists, not rows
///
/// `readAll`/`writeAll` mirror the source's two functions exactly, and they are what the
/// logic needs: every operation here is "read everything, filter/append in memory, write
/// everything back". Adding `getById`/`insert`/`delete` would let a caller express an update
/// as three round trips instead of one, and would put the read-modify-write sequence
/// somewhere other than where the invariant is enforced.
///
/// This is **not** an N+1 shape: the queue is read once per user action, and every mutation
/// is a single write of the whole list. `.claude/rules/optimization.md` §1.
abstract interface class HoldOrderStore {
  /// Every held order, across all outlets.
  ///
  /// Implementations must return an empty list rather than throwing when the underlying
  /// storage is unreadable — a private window, cleared data, or a corrupted row must not
  /// take the till down mid-shift. The fake reproduces that failure so the path is covered.
  Future<List<HeldOrder>> readAll();

  /// Replaces the whole queue.
  ///
  /// Implementations must swallow write failures. Storage full or blocked leaves the cart
  /// in front of the cashier unaffected; only the parking queue is, and throwing here would
  /// interrupt a sale in progress.
  Future<void> writeAll(List<HeldOrder> orders);
}
