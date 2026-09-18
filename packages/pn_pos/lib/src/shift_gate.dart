/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/pos_shift.dart';

import 'pos_cart_gate.dart';

/// Which screen the till shows while it works out whether it may sell.
///
/// [cart] is the only state that sells. The rest are the reasons it cannot, and each one
/// needs a different screen: a cashier who has to open a shift is not in the same situation
/// as one standing in front of another cashier's drawer.
enum ShiftGateState { loading, cart, heldByOther, alreadyOpen, shiftRequired }

/// The shift gate's decision, as a pure function.
///
/// The tablet has no outlet to pick, because pairing locked it, so the decision is smaller
/// here than on the web and can be lifted out whole. That is what makes it testable without
/// a widget tree.
///
/// Whether the cart may render is not decided here. [canEnterCart] owns that rule, and it is
/// the same rule the server enforces: an outlet must exist, a shift must exist when the
/// company requires one, it must have been consciously resumed, and it must belong to the
/// cashier at the till. This function only adds the *reason* when the answer is no.
ShiftGateState resolveShiftGate({
  /// True while the active shift is still being read; nothing may be decided yet.
  required bool isLoading,
  required POSShift? activeShift,

  /// The company's `require_shift` preference.
  required bool requireShift,

  /// The outlet pairing locked. Empty means the session is not usable yet.
  required String outletId,
  required String? currentUserId,

  /// The shift the cashier consciously chose to continue, if any.
  required String? resumedShiftId,
}) {
  if (isLoading) return ShiftGateState.loading;

  final shift = activeShift;

  // Ownership is checked here, before the shared rule, because the two answer different
  // questions. `canEnterCart` treats a missing cashier id as "not enough information to
  // lock the till", which is right for a render that may simply be unauthenticated. On a
  // tablet the same missing id means the app cannot prove the drawer is the cashier's, and
  // the safe direction is to say so rather than sell into it.
  //
  // Only while shifts are required: with shifts switched off the open shift is bookkeeping
  // the server maintains, not a session anyone holds, so it blocks nobody.
  if (requireShift && shift != null) {
    // `!!input.currentUserId` in the source: `''` is falsy, and deliberately not trimmed.
    final knownUser = currentUserId != null && currentUserId.isNotEmpty;
    if (!knownUser || shift.cashierId != currentUserId) {
      return ShiftGateState.heldByOther;
    }
  }

  final canSell = canEnterCart(
    requireShift: requireShift,
    shiftId: shift?.id,
    outletId: outletId,
    shiftResumed: shift != null && resumedShiftId == shift.id,
    shiftOwnerId: shift?.cashierId,
    currentUserId: currentUserId,
  );
  if (canSell) return ShiftGateState.cart;

  if (shift == null) return ShiftGateState.shiftRequired;
  return ShiftGateState.alreadyOpen;
}
