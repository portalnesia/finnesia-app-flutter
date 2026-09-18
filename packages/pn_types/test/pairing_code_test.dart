/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/pairing_code.dart';
import 'package:test/test.dart';

// The module has no monorepo counterpart. Its two facts about the backend were checked
// against the Go source rather than taken from comments: the alphabet and length
// (`posDevicePairingAlphabet`, `POSDevicePairingCodeLength`) and the case fold on lookup
// (`strings.ToUpper`).

void main() {
  group('normalizePairingCode', () {
    test('keeps an upper-case alphanumeric code as typed', () {
      expect(normalizePairingCode('AB3K7M'), 'AB3K7M');
    });

    // The backend folds case on lookup (strings.ToUpper), so a cashier whose tablet
    // keyboard is not in caps lock still pairs.
    test('upper-cases a code typed in lower case', () {
      expect(normalizePairingCode('ab3k7m'), 'AB3K7M');
      expect(normalizePairingCode('Ab3K7m'), 'AB3K7M');
    });

    test('strips the spaces and dashes a pasted code may carry', () {
      expect(normalizePairingCode('AB3 K7M'), 'AB3K7M');
      expect(normalizePairingCode('AB3-K7M'), 'AB3K7M');
      expect(normalizePairingCode('  ab3-k7m  '), 'AB3K7M');
    });

    // Normalization never drops a character it does not recognize: stripping one would
    // silently turn what was typed into a different, shorter code.
    test(
      'keeps characters instead of dropping them, so validation can judge them',
      () {
        expect(normalizePairingCode('AB3OK7'), 'AB3OK7');
        expect(normalizePairingCode('AB30K7'), 'AB30K7');
      },
    );

    test('does not truncate — validation decides the length', () {
      expect(normalizePairingCode('AB3K7M9'), 'AB3K7M9');
    });

    test('returns an empty string when there is nothing left', () {
      expect(normalizePairingCode(''), '');
      expect(normalizePairingCode('   '), '');
    });
  });

  group('isValidPairingCode', () {
    test('accepts a six-character code', () {
      expect(pairingCodeLength, 6);
      expect(isValidPairingCode('AB3K7M'), isTrue);
    });

    // The rule is six alphanumeric characters, 0-9 and A-Z, and nothing else is forbidden.
    // The backend never issues I, L, O, 0 or 1, but the client does not police that: a code
    // with one simply fails there, and a client that never rejects a real code cannot be
    // broken by the backend widening its alphabet.
    test('accepts every digit and letter in every position', () {
      for (final char in '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
        expect(
          isValidPairingCode(char * pairingCodeLength),
          isTrue,
          reason: char,
        );
      }
    });

    test('accepts I, L, O, 0 and 1 — the backend just never issues them', () {
      expect(isValidPairingCode('AB3IK7'), isTrue);
      expect(isValidPairingCode('AB3LK7'), isTrue);
      expect(isValidPairingCode('AB3OK7'), isTrue);
      expect(isValidPairingCode('AB30K7'), isTrue);
      expect(isValidPairingCode('AB31K7'), isTrue);
    });

    test('rejects fewer or more than six characters', () {
      expect(isValidPairingCode('AB3K7'), isFalse);
      expect(isValidPairingCode('AB3K7M9'), isFalse);
      expect(isValidPairingCode(''), isFalse);
    });

    test('rejects symbols', () {
      expect(isValidPairingCode('AB3@K7'), isFalse);
      expect(isValidPairingCode('AB3.K7'), isFalse);
    });

    test('rejects anything that has not been normalized', () {
      expect(isValidPairingCode('ab3k7m'), isFalse);
      expect(isValidPairingCode('AB3 K7M'), isFalse);
    });
  });

  group('applyPairingCodeInput', () {
    test('accepts the sixth character of a code being typed', () {
      expect(applyPairingCodeInput('AB3K7M', 'AB3K7'), 'AB3K7M');
    });

    // The case maxLength cannot handle: the raw string is longer than six, the code inside
    // it is not. Counting the raw string would truncate this into a wrong code.
    test('accepts a code pasted with the spacing a chat message carries', () {
      expect(applyPairingCodeInput('AB3 K7M', ''), 'AB3K7M');
      expect(applyPairingCodeInput('  ab3-k7m  ', ''), 'AB3K7M');
    });

    // The reported bug: the field took any number of characters and only complained at
    // submit. Keeping the previous value is what makes the extra keystroke do nothing.
    test(
      'refuses a seventh character instead of letting it into the field',
      () {
        expect(applyPairingCodeInput('AB3K7M9', 'AB3K7M'), 'AB3K7M');
      },
    );

    // Truncating would hand the cashier a six-character code they never typed, and a
    // different code is a different outlet's device. Refusing keeps the paste honest.
    test('refuses a paste that is too long even when the field is empty', () {
      expect(applyPairingCodeInput('AB3K7M9', ''), '');
    });

    test(
      'refuses an insertion that would push a full field past six, rather than eating its last character',
      () {
        expect(applyPairingCodeInput('AB3XK7M', 'AB3K7M'), 'AB3K7M');
      },
    );

    test('always allows deleting and clearing', () {
      expect(applyPairingCodeInput('AB3K7', 'AB3K7M'), 'AB3K7');
      expect(applyPairingCodeInput('', 'AB3K7M'), '');
    });

    // Same contract as normalizePairingCode: nothing is dropped, so a symbol in the field
    // stays visible and isValidPairingCode is what rejects it.
    test('keeps a character that is not alphanumeric, so it stays visible', () {
      expect(applyPairingCodeInput('AB3@K7', ''), 'AB3@K7');
    });

    test('counts every character toward the six, whatever it is', () {
      expect(applyPairingCodeInput('AB3@K7M', ''), '');
    });

    // Only the scanner can put such a value in the field (a QR that is not a pairing code).
    // Refusing its backspaces too would leave the field stuck with no way back.
    test(
      'stays deletable when a mis-scanned QR left more than six characters',
      () {
        expect(applyPairingCodeInput('AB3K7M9', 'AB3K7M99'), 'AB3K7M9');
      },
    );
  });

  // Not in the TypeScript oracle. Found by running this module against the source over
  // 811 strings (see `plan/api-client/findings.md`): JavaScript's toUpperCase applies FULL
  // case mappings ('ß' becomes 'SS'), Dart's and Go's strings.ToUpper apply SIMPLE ones and
  // leave 'ß' alone. The backend is Go, so Dart agrees with it and the TypeScript client
  // does not. These pin that: the input is compared against what the backend would do, not
  // against what JavaScript happens to do.
  //
  // All of these passed the first time they ran — the behaviour already followed from using
  // Dart's own toUpperCase — so there was no RED to observe.
  group('characters where JavaScript and the backend disagree', () {
    final sharpS = String.fromCharCode(0xdf); // ß
    final ligatureFi = String.fromCharCode(0xfb01); // ﬁ

    test('keeps a sharp s as it is, instead of expanding it to SS', () {
      expect(normalizePairingCode(sharpS), sharpS);
      expect(normalizePairingCode(ligatureFi), ligatureFi);
    });

    // The failure the module exists to prevent: rewriting what the cashier typed into a
    // different, plausible-looking code. JavaScript turns three sharp s into SSSSSS, which
    // is a well-formed code; the value here stays visibly wrong and is rejected.
    test('does not turn a run of sharp s into a valid code', () {
      expect(isValidPairingCode(normalizePairingCode(sharpS * 3)), isFalse);
    });

    test('counts a sharp s as one character toward the six', () {
      expect(applyPairingCodeInput(sharpS * 5, ''), sharpS * 5);
    });
  });

  // Also not in the oracle, and these DO agree with JavaScript (differential, 811 strings):
  // `\s` covers the Unicode spaces a phone keyboard or a chat app can produce, and only the
  // ASCII hyphen counts as a dash.
  group('Unicode spaces and dashes', () {
    final nbsp = String.fromCharCode(0xa0);
    final ideographicSpace = String.fromCharCode(0x3000);
    final lineSeparator = String.fromCharCode(0x2028);
    final enDash = String.fromCharCode(0x2013);
    final minusSign = String.fromCharCode(0x2212);

    test(
      'strips a no-break space, an ideographic space and a line separator',
      () {
        expect(normalizePairingCode('AB3${nbsp}K7M'), 'AB3K7M');
        expect(normalizePairingCode('${ideographicSpace}AB3K7M'), 'AB3K7M');
        expect(normalizePairingCode('AB3K7M$lineSeparator'), 'AB3K7M');
      },
    );

    // A code pasted with an en dash is not silently repaired: the dash stays, and
    // validation reports it.
    test('keeps dashes that are not the ASCII hyphen', () {
      expect(normalizePairingCode('AB3${enDash}K7M'), 'AB3${enDash}K7M');
      expect(normalizePairingCode('AB3${minusSign}K7M'), 'AB3${minusSign}K7M');
      expect(
        isValidPairingCode(normalizePairingCode('AB3${enDash}K7')),
        isFalse,
      );
    });
  });
}
