/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_cart_gate.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/packages/shared/src/pos/pos-cart-gate.test.ts`.
// Inputs and expectations are copied unchanged; only the syntax changed
// (describe/it -> group/test, toBe -> equals). 15 cases.
//
// One case here has no counterpart in the source test, marked "BUKAN dari oracle" below:
// the source relies on JavaScript truthiness for the ownership ids, and Dart does not
// behave the same way. See that test for the reasoning.

/// The ownership block's shared input, mirroring the source's `base` object.
///
/// A plain function rather than a shared const map: Dart's named parameters make the
/// "spread then override" pattern unnecessary, and each test reads better stating only
/// what it is actually varying.
({bool requireShift, String? shiftId, String outletId, bool? shiftResumed})
    _base() => (
          requireShift: true,
          shiftId: 'shift_1',
          outletId: 'out_1',
          shiftResumed: true,
        );

void main() {
  // When may the POS cart render instead of the shift gate?
  //
  // This exists because of a blank-screen regression: the cart rendered the gate whenever
  // there was no open shift, and the gate returned null when the company had
  // `require_shift` switched off. Null gate + null cart = a black screen with only the
  // header. The cart must be reachable with an outlet alone when shifts are off.
  group('canEnterCart', () {
    test('needs a shift when the company requires one', () {
      expect(
        canEnterCart(
          requireShift: true,
          shiftId: null,
          outletId: 'out_1',
        ),
        isFalse,
      );
    });

    // An open shift alone must NOT open the cart: the cashier has to see the info screen
    // and consciously continue it first. A shift left open overnight otherwise looked
    // exactly like a fresh one.
    test('waits for an explicit continue when a shift is already open', () {
      expect(
        canEnterCart(
          requireShift: true,
          shiftId: 'shift_1',
          outletId: 'out_1',
        ),
        isFalse,
      );
    });

    test('accepts an open shift once the cashier has continued it', () {
      expect(
        canEnterCart(
          requireShift: true,
          shiftId: 'shift_1',
          outletId: 'out_1',
          shiftResumed: true,
        ),
        isTrue,
      );
    });

    test('accepts an outlet alone when shifts are switched off', () {
      // Regression: this must not be false. Returning false here blanked the screen.
      expect(
        canEnterCart(
          requireShift: false,
          shiftId: null,
          outletId: 'out_1',
        ),
        isTrue,
      );
    });

    test('still needs an outlet when shifts are switched off', () {
      // Without an outlet there is nowhere to attribute the sale, so the picker stays.
      expect(
        canEnterCart(
          requireShift: false,
          shiftId: null,
          outletId: '',
        ),
        isFalse,
      );
    });

    test('never enters the cart with neither shift nor outlet', () {
      expect(
        canEnterCart(
          requireShift: true,
          shiftId: null,
          outletId: '',
        ),
        isFalse,
      );
      expect(
        canEnterCart(
          requireShift: false,
          shiftId: null,
          outletId: '',
        ),
        isFalse,
      );
    });

    test('ignores a blank-but-present shift id', () {
      expect(
        canEnterCart(
          requireShift: true,
          shiftId: '   ',
          outletId: 'out_1',
        ),
        isFalse,
      );
    });

    // A shift holds one cashier's custody of the drawer. Another cashier at the same
    // outlet must not be handed the cart for it — the server refuses an explicit
    // shift_id that is not theirs, so rendering the cart would only produce a till full
    // of failed sales.
    group('ownership', () {
      test('refuses a shift held by a different cashier', () {
        final b = _base();
        expect(
          canEnterCart(
            requireShift: b.requireShift,
            shiftId: b.shiftId,
            outletId: b.outletId,
            shiftResumed: b.shiftResumed,
            shiftOwnerId: 'user_2',
            currentUserId: 'user_1',
          ),
          isFalse,
        );
      });

      test('accepts a shift held by the caller', () {
        final b = _base();
        expect(
          canEnterCart(
            requireShift: b.requireShift,
            shiftId: b.shiftId,
            outletId: b.outletId,
            shiftResumed: b.shiftResumed,
            shiftOwnerId: 'user_1',
            currentUserId: 'user_1',
          ),
          isTrue,
        );
      });

      // An unauthenticated render, or a payload from an older API, must not lock the till
      // by accident: ownership only refuses when both ids are actually known.
      test('does not block when the owner is unknown', () {
        final b = _base();
        expect(
          canEnterCart(
            requireShift: b.requireShift,
            shiftId: b.shiftId,
            outletId: b.outletId,
            shiftResumed: b.shiftResumed,
            currentUserId: 'user_1',
          ),
          isTrue,
        );
        expect(
          canEnterCart(
            requireShift: b.requireShift,
            shiftId: b.shiftId,
            outletId: b.outletId,
            shiftResumed: b.shiftResumed,
            shiftOwnerId: 'user_2',
          ),
          isTrue,
        );
      });

      // With shifts switched off the shift is bookkeeping, not a session anyone owns.
      test('ignores ownership when shifts are switched off', () {
        final b = _base();
        expect(
          canEnterCart(
            requireShift: false,
            shiftId: b.shiftId,
            outletId: b.outletId,
            shiftResumed: b.shiftResumed,
            shiftOwnerId: 'user_2',
            currentUserId: 'user_1',
          ),
          isTrue,
        );
      });

      // BUKAN dari oracle. The source writes `input.shiftOwnerId && input.currentUserId`,
      // and in JavaScript an empty string is falsy — so an id that arrived as `''` is
      // treated as unknown and does not lock the till. Dart has no truthiness: a naive
      // port with `!= null` would treat `''` as a real id, and since `'' != 'user_1'` the
      // till would lock. That is the exact failure the source comment warns about ("must
      // not lock the till by accident"), so the port has to keep JS's answer and this
      // test pins it.
      test('treats an empty-string id as unknown, not as a mismatch', () {
        final b = _base();
        expect(
          canEnterCart(
            requireShift: b.requireShift,
            shiftId: b.shiftId,
            outletId: b.outletId,
            shiftResumed: b.shiftResumed,
            shiftOwnerId: '',
            currentUserId: 'user_1',
          ),
          isTrue,
        );
        expect(
          canEnterCart(
            requireShift: b.requireShift,
            shiftId: b.shiftId,
            outletId: b.outletId,
            shiftResumed: b.shiftResumed,
            shiftOwnerId: 'user_2',
            currentUserId: '',
          ),
          isTrue,
        );
      });
    });
  });

  // The header's drawer button keys off the same "ready" notion as the cart. A shift that
  // merely exists is not enough: while the info screen is up, offering a cash movement
  // into a drawer the cashier has not acknowledged is wrong.
  group('isShiftReady', () {
    test('is false with no shift at all', () {
      expect(isShiftReady(requireShift: true, shiftId: null), isFalse);
      expect(isShiftReady(requireShift: true, shiftId: '   '), isFalse);
    });

    test('is false while an open shift is still awaiting the continue choice',
        () {
      expect(isShiftReady(requireShift: true, shiftId: 'shift_1'), isFalse);
      expect(
        isShiftReady(
            requireShift: true, shiftId: 'shift_1', shiftResumed: false),
        isFalse,
      );
    });

    test('is true once the cashier has continued the open shift', () {
      expect(
        isShiftReady(
            requireShift: true, shiftId: 'shift_1', shiftResumed: true),
        isTrue,
      );
    });

    test(
        'is true for an auto-opened shift when the company does not require shifts',
        () {
      // Shifts switched off: the shift is bookkeeping, not a session to acknowledge.
      expect(isShiftReady(requireShift: false, shiftId: 'shift_1'), isTrue);
    });
  });
}
