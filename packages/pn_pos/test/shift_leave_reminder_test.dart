/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/shift_leave_reminder.dart';
import 'package:test/test.dart';

// Ported from `shouldWarnOnLeave` in `apps/web/src/lib/pos-leave-guard.test.ts` of the source
// repo: the same six cases, in the same order, so the two sides can be read against each other.

/// The cashier at the till holds the open shift and the company requires shifts, so each test
/// changes one thing.
bool warn({
  bool requireShift = true,
  bool shiftStateKnown = true,
  String? shiftId = 'shift_1',
  String? shiftOwnerId = 'user_1',
  String? currentUserId = 'user_1',
}) =>
    shouldWarnOnLeave(
      requireShift: requireShift,
      shiftStateKnown: shiftStateKnown,
      shiftId: shiftId,
      shiftOwnerId: shiftOwnerId,
      currentUserId: currentUserId,
    );

void main() {
  group('shouldWarnOnLeave', () {
    test('warns the cashier who holds the open shift', () {
      expect(warn(), isTrue);
    });

    test('stays quiet without an open shift', () {
      expect(warn(shiftId: null), isFalse);
    });

    test('stays quiet when another cashier holds the shift', () {
      expect(warn(shiftOwnerId: 'user_2'), isFalse);
    });

    test('stays quiet when shifts are switched off', () {
      expect(warn(requireShift: false), isFalse);
    });

    test('stays quiet while the shift state is unknown', () {
      expect(warn(shiftStateKnown: false), isFalse);
    });

    test('stays quiet when the current user is unknown', () {
      expect(warn(currentUserId: null, shiftOwnerId: null), isFalse);
    });

    // New: an empty id is no shift and nobody, the way `!input.shiftId` and
    // `!!input.currentUserId` read `''` in the source.
    test('treats empty ids as missing', () {
      expect(warn(shiftId: ''), isFalse);
      expect(warn(currentUserId: '', shiftOwnerId: ''), isFalse);
    });
  });
}
