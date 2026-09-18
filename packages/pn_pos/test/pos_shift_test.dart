/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/pos_shift.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/packages/shared/src/pos/pos-shift.test.ts`.
// Inputs and expectations are copied unchanged; only the syntax changed
// (describe/it -> group/test, toBe -> equals). 16 cases.
void main() {
  setUpAll(initializePosDateTime);

  ({
    num expectedCash,
    num countedCash,
    num variance,
    bool needsNote,
    bool canClose
  }) state(num expectedCash, num countedCash, [String notes = '']) =>
      shiftCloseState(
        expectedCash: expectedCash,
        countedCash: countedCash,
        notes: notes,
      );

  group('shiftCloseState', () {
    test('closes without a note when the drawer matches', () {
      final s = state(500000, 500000);
      expect(s.variance, equals(0));
      expect(s.needsNote, isFalse);
      expect(s.canClose, isTrue);
    });

    test('reports a shortfall as a negative variance', () {
      expect(state(500000, 480000).variance, equals(-20000));
    });

    test('reports a surplus as a positive variance', () {
      expect(state(500000, 520000).variance, equals(20000));
    });

    // The server refuses a close with an unexplained variance. The cashier used to meet
    // that rule as a rejected request after counting the drawer.
    test('requires a note whenever the drawer disagrees, in either direction',
        () {
      expect(state(500000, 480000).canClose, isFalse);
      expect(state(500000, 520000).canClose, isFalse);
      expect(state(500000, 480000, 'kurang bayar kembalian').canClose, isTrue);
    });

    test('does not accept whitespace as an explanation', () {
      expect(state(500000, 480000, '   ').canClose, isFalse);
    });

    // Expected cash is a sum of numeric(18,4) columns arriving as floats; a 1e-9 artefact
    // must not be shown to the cashier as a difference they have to explain.
    test('ignores floating point dust', () {
      final s = state(0.1 + 0.2, 0.3);
      expect(s.variance, equals(0));
      expect(s.canClose, isTrue);
    });

    test('still reports a one-rupiah difference', () {
      expect(state(500000, 499999).variance, equals(-1));
      expect(state(500000, 499999).needsNote, isTrue);
    });

    test('treats a missing or unparsable figure as zero rather than NaN', () {
      expect(state(double.nan, 100000).variance, equals(100000));
      expect(state(100000, double.nan).variance, equals(-100000));
    });

    // BUKAN dari oracle. The source rounds with JavaScript's `Math.round`, which rounds
    // half **toward positive infinity**; Dart's `num.round()` rounds half **away from
    // zero**. The two disagree on every negative half, and this is the input that proves
    // it: -0.015 has a half at the second decimal, so the correct answer is -0.01 (JS) and
    // the wrong one is -0.02 (Dart's round()).
    //
    // It is reachable in production, not a curiosity: expected cash is a sum of
    // numeric(18,4) columns, so a subtraction landing exactly on a negative half-cent is
    // ordinary float dust — the very case `_round2` exists to absorb. Getting it wrong
    // shows the cashier a 2-rupiah shortfall that is not there.
    test(
        'rounds a negative half the way JavaScript does, not the way Dart does',
        () {
      expect(state(0.015, 0).variance, equals(-0.01));
      expect(state(0.025, 0).variance, equals(-0.02));
      expect(state(0, 0.015).variance, equals(0.02));
    });
  });

  // An override is a close performed by someone other than the shift's holder, through
  // pos.shift.override. The server requires a reason for it even when the drawer matches
  // exactly — the note says why this cashier, and not the holder, decided the figures — so
  // the dialog must ask before the drawer is counted, not reject afterwards.
  group('shiftCloseState — override', () {
    ({
      num expectedCash,
      num countedCash,
      num variance,
      bool needsNote,
      bool canClose
    }) overrideState(num expectedCash, num countedCash, [String notes = '']) =>
        shiftCloseState(
          expectedCash: expectedCash,
          countedCash: countedCash,
          notes: notes,
          isOverride: true,
        );

    test('requires a note even when the drawer matches exactly', () {
      final s = overrideState(500000, 500000);
      expect(s.variance, equals(0));
      expect(s.needsNote, isTrue);
      expect(s.canClose, isFalse);
    });

    test('accepts the close once a note is given', () {
      expect(
          overrideState(500000, 500000, 'Kasir sudah pulang').canClose, isTrue);
    });

    test('still does not accept whitespace as an explanation', () {
      expect(overrideState(500000, 500000, '   ').canClose, isFalse);
    });

    // The holder's own close is unchanged: a matching drawer still closes without a note.
    test('leaves a holder close unaffected', () {
      expect(
        shiftCloseState(
          expectedCash: 500000,
          countedCash: 500000,
          notes: '',
        ).canClose,
        isTrue,
      );
    });
  });

  // Whether the open shift predates today, and who opened it.
  //
  // The info screen exists so a shift left open overnight cannot be mistaken for a fresh
  // one. "Today" is the tenant-local calendar day: a 00:30 WIB open must read as today
  // even though its UTC timestamp is still yesterday.
  group('openShiftNotice', () {
    final now = DateTime.parse('2026-09-13T10:00:00+07:00');
    // Explicit zone: the assertion is about the tenant's calendar day, and the test
    // runner's own TZ must not decide the answer.
    const tz = 'Asia/Jakarta';

    test('flags a shift opened on an earlier day', () {
      final n = openShiftNotice(
        number: 'PS/1',
        openedAt: '2026-09-12T09:00:00+07:00',
        cashierName: 'Budi',
        now: now,
        timezone: tz,
      );
      expect(n.stale, isTrue);
      expect(n.cashierName, equals('Budi'));
      expect(n.number, equals('PS/1'));
    });

    test('does not flag a shift opened today', () {
      final n = openShiftNotice(
        number: 'PS/2',
        openedAt: '2026-09-13T08:00:00+07:00',
        now: now,
        timezone: tz,
      );
      expect(n.stale, isFalse);
      expect(n.cashierName, isNull);
    });

    test('treats just-after-midnight local as today, not yesterday', () {
      // 2026-09-13T00:30+07:00 is 2026-09-12T17:30Z — the UTC day is still the 12th,
      // but the WIB day is the 13th and that is the day the cashier is working in.
      final n = openShiftNotice(
        number: 'PS/3',
        openedAt: '2026-09-13T00:30:00+07:00',
        now: now,
        timezone: tz,
      );
      expect(n.stale, isFalse);
    });

    test('does not flag an unparsable timestamp', () {
      expect(
        openShiftNotice(
          number: 'PS/4',
          openedAt: 'not-a-date',
          now: now,
          timezone: tz,
        ).stale,
        isFalse,
      );
      expect(
        openShiftNotice(
          number: 'PS/5',
          openedAt: '',
          now: now,
          timezone: tz,
        ).stale,
        isFalse,
      );
    });
  });
}
