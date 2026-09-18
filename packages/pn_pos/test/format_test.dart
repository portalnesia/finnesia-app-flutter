/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/format.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/packages/shared/src/utils/format.test.ts`.
// Inputs and expectations are copied unchanged; only the syntax changed
// (describe/it -> group/test, toBe -> equals). 6 cases, plus 2 added below.
//
// The JS source formats with `toLocaleString('id-ID')` and Dart with
// `NumberFormat.decimalPattern('id_ID')`. Those were verified to agree on every value
// tested — thousands separators, decimal comma, the 3-fraction-digit default, and the
// NaN/Infinity rendering. See `format.dart` for the one place they do not.
void main() {
  setUpAll(initializePosNumberFormat);

  group('formatCurrency', () {
    test('formats a positive number in IDR with thousand separators', () {
      expect(formatCurrency(1234567), equals('Rp 1.234.567'));
    });

    test('formats zero as "Rp 0"', () {
      expect(formatCurrency(0), equals('Rp 0'));
    });

    test('formats null/undefined as a dash', () {
      expect(formatCurrency(null), equals('-'));
    });

    // BUKAN dari oracle, dan sengaja TIDAK memperbaiki apa pun. The source's guard is
    // `value === null || value === undefined`, so NaN falls through to
    // `toLocaleString` and renders as the literal text `Rp NaN`. Dart's `intl` produces
    // the identical string, so this is **shared behaviour, not a port divergence**.
    //
    // Pinned because it is surprising and reachable: the cart maths can produce NaN from a
    // bad price or quantity (see the NaN clamp in `pos_cart.dart`), and `Rp NaN` on a
    // receipt is a bug someone will eventually want fixed. Fixing it means fixing the
    // source first — `.claude/rules/cross-repo.md` §4: *"Kalau oracle-nya sendiri tampak
    // salah, jangan perbaiki hanya di Dart."* This test records the agreed behaviour so
    // that change is a deliberate, visible one rather than a silent drift.
    test('renders NaN the same way the source does, as agreed behaviour', () {
      expect(formatCurrency(double.nan), equals('Rp NaN'));
      expect(formatSigned(double.nan), equals('Rp NaN'));
    });
  });

  group('formatSigned', () {
    test('prepends a minus for negative balances', () {
      expect(formatSigned(-250000), equals('-Rp 250.000'));
    });

    test('renders positive without a leading plus', () {
      expect(formatSigned(5000), equals('Rp 5.000'));
    });

    test('renders null as a dash', () {
      expect(formatSigned(null), equals('-'));
    });

    // BUKAN dari oracle. `formatSigned` puts the sign *before* the `Rp`, and it derives
    // that sign from `value < 0` rather than from the formatted string. Negative zero is
    // where those two approaches disagree, and the source's choice matters:
    //
    //   formatSigned(-0)   -> "Rp 0"     (the guard is `< 0`, which is false for -0)
    //   formatCurrency(-0) -> "Rp -0"    (no guard at all; the locale prints the sign)
    //
    // Both were read off the running source, not assumed. The asymmetry is real and is
    // preserved: `formatCurrency` has no sign logic to get wrong, and `formatSigned`'s
    // `Math.abs` is what keeps the minus out. Dart's `<` agrees with JavaScript's on -0, so
    // no divergence — but a "simplification" that derives the sign from the formatted text
    // would turn `formatSigned(-0)` into `-Rp 0`, a shortfall that isn't there.
    test('handles negative zero the way the source does', () {
      expect(formatSigned(-0.0), equals('Rp 0'));
      expect(formatCurrency(-0.0), equals('Rp -0'));
    });
  });
}
