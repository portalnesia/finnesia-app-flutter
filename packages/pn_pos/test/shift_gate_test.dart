/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/shift_gate.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:test/test.dart';

// The module has no monorepo counterpart. The cases after `// New` cover what an earlier
// suite never asserted.

const openShift = POSShift(
  id: 'shift_1',
  number: 'SH-001',
  cashierId: 'usr_1',
  outletId: 'out_1',
  openedAt: '2026-09-18T08:00:00Z',
  openingCash: 500000,
  totalSales: 0,
  totalTransactions: 0,
);

/// Everything the till needs to be sellable, so each test changes one thing.
ShiftGateState gate({
  bool isLoading = false,
  POSShift? activeShift = openShift,
  bool requireShift = true,
  String outletId = 'out_1',
  String? currentUserId = 'usr_1',
  String? resumedShiftId = 'shift_1',
}) =>
    resolveShiftGate(
      isLoading: isLoading,
      activeShift: activeShift,
      requireShift: requireShift,
      outletId: outletId,
      currentUserId: currentUserId,
      resumedShiftId: resumedShiftId,
    );

void main() {
  group('resolveShiftGate', () {
    test('waits while the shift is still being read', () {
      // Loading wins over everything: deciding before the answer arrives is how a till
      // flashes "buka shift" at a cashier who already has one open.
      expect(gate(isLoading: true), ShiftGateState.loading);
    });

    test('opens the cart when the open shift is mine and resumed', () {
      expect(gate(), ShiftGateState.cart);
    });

    test('asks before working in my own open shift', () {
      // A shift left open overnight looks exactly like a fresh one, so the cashier has to
      // see it (number, when it was opened, by whom) before selling into it.
      expect(gate(resumedShiftId: null), ShiftGateState.alreadyOpen);
    });

    test('ignores a resume that belongs to a different shift', () {
      // A stale resume from a shift that has since been closed must not open this one.
      expect(gate(resumedShiftId: 'shift_other'), ShiftGateState.alreadyOpen);
    });

    test(
        'reports a shift held by another cashier instead of offering to continue it',
        () {
      // Another cashier's drawer is not mine to sell in; the server refuses it too.
      expect(gate(currentUserId: 'usr_2'), ShiftGateState.heldByOther);
    });

    test('treats an unknown cashier as someone else', () {
      // Without a user id the ownership check cannot pass, and guessing "mine" would put
      // a cashier to work in a drawer that is not theirs.
      expect(gate(currentUserId: null), ShiftGateState.heldByOther);
    });

    test('treats a shift with no cashier as someone else', () {
      expect(
        gate(activeShift: openShift.copyWith(cashierId: '')),
        ShiftGateState.heldByOther,
      );
    });

    test('asks for a shift when none is open and shifts are required', () {
      expect(gate(activeShift: null), ShiftGateState.shiftRequired);
    });

    test('opens the cart with no shift when the company does not require one',
        () {
      // The server auto-opens a bookkeeping shift at checkout, so there is nothing for
      // the cashier to acknowledge.
      expect(
        gate(requireShift: false, activeShift: null),
        ShiftGateState.cart,
      );
    });

    test(
        'opens the cart in an open shift when the company does not require one',
        () {
      expect(
        gate(
          requireShift: false,
          resumedShiftId: null,
          currentUserId: 'usr_2',
        ),
        ShiftGateState.cart,
      );
    });

    test('refuses to sell without an outlet', () {
      // A sale has to belong to a store. On the tablet the outlet comes from pairing, so
      // an empty one means the session is not usable yet: the till must not report itself
      // sellable on a guess. Which non-cart state it lands in does not matter; that it is
      // never `cart` does.
      expect(gate(outletId: ''), isNot(ShiftGateState.cart));
    });

    // New: the JavaScript truthiness the oracle never asserted (`patterns.md` §1.1).

    test('treats an empty user id as unknown, the way `!!""` does', () {
      // `!!input.currentUserId` is false for `''`, and `shift.cashier_id === ''` would
      // otherwise be true for a shift whose cashier is also empty: two unknowns matching
      // each other would hand the drawer to nobody in particular.
      expect(
        gate(
          currentUserId: '',
          activeShift: openShift.copyWith(cashierId: ''),
        ),
        ShiftGateState.heldByOther,
      );
    });

    test('lets loading win even when there is no outlet and no shift', () {
      expect(
        gate(isLoading: true, outletId: '', activeShift: null),
        ShiftGateState.loading,
      );
    });
  });
}
