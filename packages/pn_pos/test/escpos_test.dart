/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:pn_pos/src/escpos.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/apps/web/src/lib/escpos.test.ts`.
// Inputs and expectations are copied unchanged; only the syntax changed
// (describe/it -> group/test, toEqual -> equals). 12 cases, plus 2 added below.
//
// The source builds `number[]` and wraps it in a `Uint8Array` only at the very end
// (`buildCommands`). This port returns `Uint8List` from every builder, which is what
// `.claude/rules/native-ports.md` §2.1 requires — the transport carries bytes, not ints.
// The observable byte sequence is identical, including the modulo-256 wrapping that
// `Uint8Array.from` performs; verified by running both.
void main() {
  group('escpos command builder', () {
    test('cmdInit resets the printer', () {
      expect(cmdInit(), equals(Uint8List.fromList([0x1b, 0x40])));
    });

    test('cmdAlign maps left/center/right to 0/1/2', () {
      expect(cmdAlign(EscPosAlign.left),
          equals(Uint8List.fromList([0x1b, 0x61, 0])));
      expect(cmdAlign(EscPosAlign.center),
          equals(Uint8List.fromList([0x1b, 0x61, 1])));
      expect(cmdAlign(EscPosAlign.right),
          equals(Uint8List.fromList([0x1b, 0x61, 2])));
    });

    test('cmdBold toggles on/off', () {
      expect(cmdBold(true), equals(Uint8List.fromList([0x1b, 0x45, 1])));
      expect(cmdBold(false), equals(Uint8List.fromList([0x1b, 0x45, 0])));
    });

    test(
        'cmdFontSize encodes width/height multipliers and clamps out-of-range values',
        () {
      expect(cmdFontSize(1, 1), equals(Uint8List.fromList([0x1d, 0x21, 0x00])));
      expect(cmdFontSize(2, 2), equals(Uint8List.fromList([0x1d, 0x21, 0x11])));
      // clamped to [1,8]
      expect(
          cmdFontSize(0, 20), equals(Uint8List.fromList([0x1d, 0x21, 0x07])));
    });

    test('cmdFeed advances by the given number of lines', () {
      expect(cmdFeed(3), equals(Uint8List.fromList([0x1b, 0x64, 3])));
      expect(cmdFeed(), equals(Uint8List.fromList([0x1b, 0x64, 1])));
    });

    test('cmdCut emits a partial-cut sequence', () {
      expect(cmdCut(), equals(Uint8List.fromList([0x1d, 0x56, 1])));
    });

    test('cmdText encodes UTF-8 bytes with a trailing newline', () {
      expect(cmdText('AB'), equals(Uint8List.fromList([0x41, 0x42, 0x0a])));
    });

    test('cmdDivider repeats "-" to the given width', () {
      final bytes = cmdDivider(10);
      expect(utf8.decode(bytes), equals('----------\n'));
    });

    test('cmdLineColumns pads the middle so both sides land on one line', () {
      final bytes = cmdLineColumns('Total', 'Rp 1.000', 20);
      final line = utf8.decode(bytes).replaceAll('\n', '');
      expect(line.length, equals(20));
      expect(line.startsWith('Total'), isTrue);
      expect(line.endsWith('Rp 1.000'), isTrue);
    });

    test('cmdLineColumns truncates the label instead of overflowing the width',
        () {
      final bytes = cmdLineColumns(
          'A very long product name that will not fit', 'Rp 1.000', 20);
      final line = utf8.decode(bytes).replaceAll('\n', '');
      expect(line.length, lessThanOrEqualTo(20));
      expect(line.endsWith('Rp 1.000'), isTrue);
    });

    test('buildCommands flattens nested op arrays into one Uint8Array', () {
      final result = buildCommands([cmdInit(), cmdText('X')]);
      expect(result, isA<Uint8List>());
      expect(result.toList(), equals([0x1b, 0x40, 0x58, 0x0a]));
    });

    test('buildCommands returns an empty array for no ops', () {
      expect(buildCommands([]), equals(Uint8List(0)));
    });

    // BUKAN dari oracle, dan ini bug yang nyata kalau tidak ditangani.
    //
    // The source clamps with `Math.min(8, Math.max(1, Math.round(n)))`, and
    // `Math.round(NaN)` is NaN — `Math.max(1, NaN)` is NaN, `Math.min(8, NaN)` is NaN, and
    // `(NaN - 1) << 4` is 0, so the source quietly emits a normal-size command. **Dart's
    // `num.round()` throws `UnsupportedError` on NaN and on infinity.** A direct port
    // would therefore crash the till on a NaN size instead of printing at normal size —
    // a print failure in the middle of a sale, from a value nobody validated.
    //
    // Verified by running both: JS gives `[29,33,0]` for `cmdFontSize(NaN, NaN)`.
    test('cmdFontSize survives NaN and infinity the way the source does', () {
      expect(cmdFontSize(double.nan, double.nan),
          equals(Uint8List.fromList([0x1d, 0x21, 0x00])));
      expect(cmdFontSize(double.infinity, double.infinity),
          equals(Uint8List.fromList([0x1d, 0x21, 0x77])));
      expect(cmdFontSize(double.negativeInfinity, double.negativeInfinity),
          equals(Uint8List.fromList([0x1d, 0x21, 0x00])));
    });

    // BUKAN dari oracle. `cmdFeed` has no clamp in the source, and the byte is wrapped by
    // `Uint8Array.from` modulo 256 — so `cmdFeed(300)` emits byte 44, not an error.
    // `Uint8List` wraps identically (verified), so this pins that the wrapping is
    // preserved rather than "fixed" into a clamp, which would diverge from the web app.
    test('cmdFeed wraps out-of-range line counts modulo 256, like the source',
        () {
      expect(cmdFeed(300), equals(Uint8List.fromList([0x1b, 0x64, 44])));
      expect(cmdFeed(-1), equals(Uint8List.fromList([0x1b, 0x64, 255])));
    });
  });
}
