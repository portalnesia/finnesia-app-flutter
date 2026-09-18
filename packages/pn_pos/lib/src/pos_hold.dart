/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'pos_cart.dart';
import 'pos_hold_store.dart';

part 'pos_hold.freezed.dart';

/// A basket the cashier parked, waiting to be paid for.
///
/// Ported from `HeldOrder` in
/// `finnesia-monorepo/packages/shared/src/pos/pos-hold.ts`.
///
/// `freezed` rather than hand-written: ten fields, compared in tests, copied when the
/// basket is updated (`copyWith` is exactly what `updateHeldOrder` does), and serialized by
/// the SQLite store in `apps/pos`. That is all three of the questions
/// `.claude/rules/patterns.md` §2a.5 asks before reaching for codegen.
@freezed
abstract class HeldOrder with _$HeldOrder {
  const factory HeldOrder({
    required String id,
    required String label,
    required String outletId,
    String? customerId,
    String? customerMemo,
    String? tableNumber,
    String? queueNumber,
    required num headerDiscount,
    required List<CartLine> lines,

    /// ISO-8601, and the sort key. A `String` rather than a `DateTime` because that is what
    /// the source stores and what `localeCompare` orders on — see [listHeldOrders] for why
    /// the comparison is done as text.
    required String heldAt,
  }) = _HeldOrder;
}

/// A held order before it has an id and a timestamp.
///
/// The source types this as `Omit<HeldOrder, 'id' | 'heldAt'>`. TypeScript's `Omit` has no
/// Dart equivalent, so it is a type of its own. That is the honest translation: `id` and
/// `heldAt` are assigned by [holdOrder], and a caller cannot supply them by accident.
@freezed
abstract class HeldOrderDraft with _$HeldOrderDraft {
  const factory HeldOrderDraft({
    required String label,
    required String outletId,
    String? customerId,
    String? customerMemo,
    String? tableNumber,
    String? queueNumber,
    required num headerDiscount,
    required List<CartLine> lines,
  }) = _HeldOrderDraft;
}

/// Source's `Math.random().toString(36).slice(2, 8)` — six base-36 characters.
///
/// Only has to make an id unique within one till's queue, which the timestamp alone cannot
/// do: two baskets parked in the same millisecond would collide. The source reached for
/// `Date.now()` alone and had to add this suffix for the same reason.
final _random = math.Random();

String _newId() {
  final suffix = _random.nextInt(2176782336).toRadixString(36).padLeft(6, '0');
  return 'hold_${DateTime.now().millisecondsSinceEpoch}_${suffix.substring(0, 6)}';
}

/// Every basket held at [outletId], most recently held first.
///
/// Held orders belong to the store they were rung up at. Resuming a basket at another
/// outlet would post it against the wrong stock and the wrong drawer.
///
/// ## Ordering, and the one place this port had to work harder than the source
///
/// The source sorts with `b.heldAt.localeCompare(a.heldAt)`. That relies on
/// `Array.prototype.sort` being **stable**, which JavaScript has guaranteed since ES2019:
/// baskets with identical timestamps keep their insertion order.
///
/// **Dart's `List.sort` is not stable.** Verified by running it — with forty equal keys the
/// order came back scrambled. So the sort here carries the original index as a tie-breaker,
/// which reproduces exactly what a stable sort does, instead of depending on unspecified
/// behaviour.
///
/// That tie-break is reachable in production, not theoretical: `heldAt` has millisecond
/// precision, and a cashier tapping two baskets into the queue quickly lands both in the
/// same millisecond. Without it the list order would flicker between reads.
///
/// `localeCompare` was verified to agree with plain codepoint comparison on ISO-8601
/// timestamps (zero mismatches over every pair of a sample set), so `compareTo` is a
/// faithful replacement and no locale handling is needed.
Future<List<HeldOrder>> listHeldOrders(
    HoldOrderStore store, String outletId) async {
  final all = await store.readAll();
  final matching = all.where((o) => o.outletId == outletId).toList();

  // Decorate with the index so equal timestamps fall back to insertion order, then sort
  // descending by heldAt.
  final indexed = [
    for (var i = 0; i < matching.length; i++) (index: i, order: matching[i]),
  ];
  indexed.sort((a, b) {
    final byTime = b.order.heldAt.compareTo(a.order.heldAt);
    return byTime != 0 ? byTime : a.index.compareTo(b.index);
  });
  return [for (final e in indexed) e.order];
}

/// Parks a basket and returns it, with its new id and timestamp.
///
/// A held order never reaches the server: it is not a sale until it is paid for, and posting
/// an unpaid basket would create a document nobody asked for. Keeping it on the device also
/// means the queue survives a restart, which is the whole point — the customer who went back
/// for their wallet should not cost the shop the basket.
///
/// [now] is injectable because `heldAt` is the sort key: leaving it to `DateTime.now()` would
/// make every ordering test depend on how fast the machine is. `.claude/rules/native-ports.md`
/// §5.
Future<HeldOrder> holdOrder(
  HoldOrderStore store,
  HeldOrderDraft draft, {
  DateTime? now,
}) async {
  final held = HeldOrder(
    id: _newId(),
    label: draft.label,
    outletId: draft.outletId,
    customerId: draft.customerId,
    customerMemo: draft.customerMemo,
    tableNumber: draft.tableNumber,
    queueNumber: draft.queueNumber,
    headerDiscount: draft.headerDiscount,
    lines: draft.lines,
    heldAt: (now ?? DateTime.now()).toUtc().toIso8601String(),
  );
  await store.writeAll([...await store.readAll(), held]);
  return held;
}

/// Removes one basket. Unknown ids are ignored.
Future<void> dropHeldOrder(HoldOrderStore store, String id) async {
  await store
      .writeAll((await store.readAll()).where((o) => o.id != id).toList());
}

/// Forgets every basket held at [outletId].
///
/// Closing a shift ends the drawer/session a held basket was rung up under — resurfacing it
/// once a new shift opens would let the cashier "resume" a sale against a shift that no
/// longer exists. Scoped to the outlet, not a global wipe: another outlet's held baskets
/// (open in another tab/till) are untouched.
Future<void> clearHeldOrders(HoldOrderStore store, String outletId) async {
  await store.writeAll(
    (await store.readAll()).where((o) => o.outletId != outletId).toList(),
  );
}

/// Updates a basket in place, keeping its id. Returns `null` if it no longer exists.
///
/// Resuming a basket to edit it and holding it again must update the same basket, not spawn
/// a second one with a re-typed label — the cashier already named it once. `heldAt` is
/// bumped so the just-touched basket resurfaces at the top of the list, same as a fresh hold
/// does.
///
/// The `null` return (storage untouched) is for the case where the basket was dropped from
/// under it — e.g. "Buang" clicked on it while it was open in the till — so the caller can
/// fall back to creating a fresh one instead of silently losing the edit.
///
/// `null` rather than an exception because the source returns `null` and because "the basket
/// is gone" is an ordinary state a caller must handle, not a failure. It is the same shape as
/// `findProductByCode` returning `null` in `pos_cart.dart`.
Future<HeldOrder?> updateHeldOrder(
  HoldOrderStore store,
  String id,
  HeldOrderDraft draft, {
  DateTime? now,
}) async {
  final all = await store.readAll();
  final idx = all.indexWhere((o) => o.id == id);
  if (idx == -1) return null;
  final updated = HeldOrder(
    id: id,
    label: draft.label,
    outletId: draft.outletId,
    customerId: draft.customerId,
    customerMemo: draft.customerMemo,
    tableNumber: draft.tableNumber,
    queueNumber: draft.queueNumber,
    headerDiscount: draft.headerDiscount,
    lines: draft.lines,
    heldAt: (now ?? DateTime.now()).toUtc().toIso8601String(),
  );
  final next = [...all];
  next[idx] = updated;
  await store.writeAll(next);
  return updated;
}
