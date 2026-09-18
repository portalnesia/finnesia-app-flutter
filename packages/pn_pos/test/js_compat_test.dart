/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/js_compat.dart';
import 'package:test/test.dart';

// No oracle — the source has no module like this, because the source is JavaScript and
// already HAS these semantics. Every expectation below was read off the running source
// (Node) rather than reasoned about, and the two that matter are reachable from a real
// receipt rather than theoretical.
void main() {
  group('jsRound', () {
    test('rounds half toward positive infinity, like Math.round', () {
      expect(jsRound(0.5), equals(1));
      expect(jsRound(1.5), equals(2));
      expect(jsRound(2.5), equals(3));
    });

    test('rounds negative halves toward positive infinity, not away from zero',
        () {
      // This is the whole reason the helper exists. Dart's `(-1.5).round()` is -2 and
      // `(-0.5).round()` is -1; JavaScript gives -1 and -0. Verified against Node.
      expect(jsRound(-0.5), equals(0));
      expect(jsRound(-1.5), equals(-1));
      expect(jsRound(-2.5), equals(-2));
    });

    test('agrees with num.round() on every positive half that is not exact',
        () {
      expect(jsRound(1.4), equals(1));
      expect(jsRound(1.6), equals(2));
      expect(jsRound(-1.4), equals(-1));
      expect(jsRound(-1.6), equals(-2));
    });
  });

  group('jsNumber', () {
    test('prints an integral double without a trailing .0', () {
      // Reachable: a `numeric(18,4)` quantity arrives as a double via jsonDecode, where
      // TypeScript would have had a plain `number`. Dart's toString() gives '2.0' and the
      // customer reads "2.0 x Rp 10.000" where the web app prints "2 x Rp 10.000".
      expect(jsNumber(2.0), equals('2'));
      expect(jsNumber(3.0), equals('3'));
      expect(jsNumber(0.0), equals('0'));
      expect(jsNumber(0), equals('0'));
    });

    test('prints a fractional value with its fraction', () {
      expect(jsNumber(2.5), equals('2.5'));
      expect(jsNumber(0.5), equals('0.5'));
      expect(jsNumber(-2.5), equals('-2.5'));
    });

    test('prints negative zero as 0, like String(-0)', () {
      expect(jsNumber(-0.0), equals('0'));
      expect(jsNumber(-0), equals('0'));
    });

    test('prints NaN and the infinities the way JavaScript spells them', () {
      // Verified against Node: String(NaN) === 'NaN', String(Infinity) === 'Infinity'.
      // Dart's toString() happens to agree, but this pins it so a future refactor to
      // `toString()` cannot drift without a failing test.
      expect(jsNumber(double.nan), equals('NaN'));
      expect(jsNumber(double.infinity), equals('Infinity'));
      expect(jsNumber(double.negativeInfinity), equals('-Infinity'));
    });

    test(
        'switches to exponential form at 1e21, the same threshold as JavaScript',
        () {
      // Below 1e21 both print integers; at 1e21 JavaScript switches to '1e+21' and Dart
      // already produces the same spelling, so there is no suffix to strip there.
      expect(jsNumber(1e20), equals('100000000000000000000'));
      expect(jsNumber(1e21), equals('1e+21'));
      expect(jsNumber(1.5e21), equals('1.5e+21'));
      expect(jsNumber(-1e21), equals('-1e+21'));
    });

    test('does not saturate a large integral double at the 64-bit limit', () {
      // A regression guard on a bug this helper actually shipped with: the first version
      // went through `toInt()`, which saturates, so `jsNumber(1e20)` returned
      // '9223372036854775807' — a receipt printing a different number entirely. Verified
      // against Node that JavaScript prints all twenty digits.
      expect(jsNumber(1e20), equals('100000000000000000000'));
      expect(jsNumber(1e18), equals('1000000000000000000'));
      expect(
          jsNumber(123456789012345680000.0), equals('123456789012345680000'));
    });

    test('preserves an int without going through double', () {
      expect(jsNumber(9007199254740993), equals('9007199254740993'));
    });
  });

  group('firstNonEmpty', () {
    test('returns the first non-empty value', () {
      expect(firstNonEmpty(['a', 'b']), equals('a'));
      expect(firstNonEmpty([null, 'b']), equals('b'));
    });

    test('skips the empty string, which is the difference from ??', () {
      // `a || b` treats '' as absent; Dart's `??` does not. This is what stops a blank
      // line printing on a customer receipt where the web app prints the product name.
      expect(firstNonEmpty(['', 'b']), equals('b'));
      expect(firstNonEmpty([null, '', 'c']), equals('c'));
    });

    test('does not trim, matching JavaScript truthiness', () {
      // '   ' is truthy in JavaScript and passes through unchanged. Trimming here would be
      // a behaviour change the oracle does not sanction (`cross-repo.md` §4).
      expect(firstNonEmpty(['   ', 'b']), equals('   '));
      expect(firstNonEmpty(['  x  ']), equals('  x  '));
    });

    test('returns an empty string when nothing qualifies', () {
      // The source's chain evaluates to '' when every candidate is falsy, and that is what
      // formatDateTime turns into a dash rather than throwing on.
      expect(firstNonEmpty([]), equals(''));
      expect(firstNonEmpty([null, '']), equals(''));
    });
  });

  group('orAbsent', () {
    test('keeps a value that has something in it', () {
      expect(orAbsent('a'), equals('a'));
    });

    test(
        'turns null and the empty string into absent, which is the difference from ??',
        () {
      // The source is `if (x) payload.x = x`. `customer_id: ''` is a customer that does not
      // exist, and the server refuses the checkout after the money has been taken.
      expect(orAbsent(null), isNull);
      expect(orAbsent(''), isNull);
    });

    test('does not trim, matching JavaScript truthiness', () {
      // `'   '` is truthy in JavaScript, so the source sends it and so does this.
      expect(orAbsent('   '), equals('   '));
    });

    test(
        'agrees with firstNonEmpty on a single value, once the null is folded away',
        () {
      // Two spellings of one rule, and they are not *identical*: `orAbsent` answers null where
      // `firstNonEmpty` answers `''`, because one is nullable and the other has to return a
      // String. What must hold is that they agree on **which** values are absent — otherwise one
      // call site would send a field the other drops.
      for (final value in [null, '', 'a', '   ', '  x  ']) {
        expect(
          orAbsent(value) ?? '',
          equals(firstNonEmpty([value])),
          reason: '$value',
        );
      }
    });
  });
}
