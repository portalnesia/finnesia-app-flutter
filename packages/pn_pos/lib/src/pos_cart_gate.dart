/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Whether a shift is ready to be worked in, as opposed to merely existing.
///
/// An OPEN shift is not enough on its own: while the info screen is up (the cashier has
/// not yet chosen "continue this shift"), the shift must not be treated as usable. The
/// header's drawer button stays hidden until the choice is made — otherwise the header
/// offers a cash movement into a drawer the cashier has not acknowledged.
///
/// A shift must exist for this to be true. Shifts switched off is the exception on the
/// resume check only: the auto-opened shift is bookkeeping, not a session to acknowledge.
///
/// Ported from `isShiftReady` in
/// `finnesia-monorepo/packages/shared/src/pos/pos-cart-gate.ts`.
bool isShiftReady({
  required bool requireShift,
  required String? shiftId,
  bool? shiftResumed,
}) {
  if (!_hasValue(shiftId)) return false;
  if (!requireShift) return true;
  return shiftResumed == true;
}

/// Whether the POS cart may render instead of the shift gate.
///
/// Kept as a pure function so the rule is testable without a component tree. The rule
/// itself matters because of a blank-screen bug: the cart used to render the gate
/// whenever no open shift existed, and the gate returned null when the company had shifts
/// switched off — so the screen went black with only the header visible.
///
/// An outlet is always required: a sale has to belong to a store. A shift is only required
/// when the company says so — unlike [isShiftReady], shifts switched off needs no shift at
/// all, because the cart is the only thing that can open one.
///
/// Ownership is checked only while shifts are required. An outlet's drawer is one
/// cashier's custody at a time, so a shift another cashier holds is not this cashier's to
/// sell in. With shifts switched off the shift is pure bookkeeping and anyone at the
/// outlet may use it.
///
/// Ported from `canEnterCart` in
/// `finnesia-monorepo/packages/shared/src/pos/pos-cart-gate.ts`.
bool canEnterCart({
  required bool requireShift,
  required String? shiftId,
  required String outletId,
  bool? shiftResumed,

  /// Cashier who holds the open shift, when one is open.
  String? shiftOwnerId,

  /// Cashier using this till right now.
  String? currentUserId,
}) {
  if (!_hasValue(outletId)) return false;
  if (!requireShift) return true;
  if (!isShiftReady(
    requireShift: requireShift,
    shiftId: shiftId,
    shiftResumed: shiftResumed,
  )) {
    return false;
  }
  // Only when both ids are known: an unauthenticated render, or a payload from an older
  // API, must not lock the till by accident.
  if (_isKnownId(shiftOwnerId) &&
      _isKnownId(currentUserId) &&
      shiftOwnerId != currentUserId) {
    return false;
  }
  return true;
}

/// True when a required id is actually present.
///
/// Trims, matching the source's explicit `!!id && id.trim() !== ''` for `shiftId` and
/// `outletId`. A field left as spaces is an empty field, not a real one.
bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

/// True when an optional id is known, replicating JavaScript truthiness.
///
/// **Deliberately not trimmed, and that asymmetry is the source's, not a mistake here.**
/// The source writes the ownership guard as `input.shiftOwnerId && input.currentUserId`,
/// and JavaScript treats `''` as falsy but `'   '` as truthy. [canEnterCart]'s own
/// `shiftId`/`outletId` checks trim explicitly; this one does not.
///
/// The consequence is worth stating because it is the opposite of what a reader expects:
/// a whitespace-only owner id counts as a real id and **does** lock the till. Preserved
/// rather than "fixed" because the oracle defines the behaviour, and changing it here
/// would make the Dart side disagree with the web app on when a till is sellable.
bool _isKnownId(String? id) => id != null && id.isNotEmpty;
