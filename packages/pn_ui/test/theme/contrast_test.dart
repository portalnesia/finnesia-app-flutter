/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/contrast.dart';

// The guard is a checker, and a checker that has never failed proves nothing
// (`testing.md` §0.3). So the first tests here do not look at the palette at all: they give
// the tool pairs whose ratio is known and make it say so, including a pair that must fail.

const black = Color(0xFF000000);
const white = Color(0xFFFFFFFF);
// Finnesia amber: hsl(36 100% 50%), which is rgb(255, 153, 0).
const amber = Color(0xFFFF9900);

void main() {
  group('contrastRatio', () {
    test('is 21 for black on white, the WCAG maximum', () {
      expect(contrastRatio(black, white), closeTo(21, 0.001));
    });

    test('is 1 for a colour on itself, the minimum', () {
      expect(contrastRatio(amber, amber), closeTo(1, 0.001));
    });

    test('does not depend on which colour is the text', () {
      expect(contrastRatio(amber, white), contrastRatio(white, amber));
    });

    test('measures white on amber at about 2.1, which fails AA', () {
      // The number that made the web token unusable for text on a button
      // (`ui/findings.md` F3, which was worked out by hand and is measured here).
      expect(contrastRatio(white, amber), closeTo(2.14, 0.02));
    });

    test(
        'measures near-black on amber above 8, which is why the text on amber is dark',
        () {
      expect(contrastRatio(const Color(0xFF09090B), amber), greaterThan(8));
    });
  });

  group('failingChecks', () {
    test('names a pair that is below its minimum', () {
      // The known-bad input. If this returned nothing, an empty result from the real
      // palette would mean nothing either.
      final failing = failingChecks([
        const ContrastCheck('white on amber', white, amber, minimum: 4.5),
      ]);

      expect(failing.map((c) => c.name), ['white on amber']);
    });

    test('lets a pair at or above its minimum through', () {
      final failing = failingChecks([
        const ContrastCheck('black on white', black, white, minimum: 4.5),
        const ContrastCheck('white on amber, large text', white, amber,
            minimum: 2),
      ]);

      expect(failing, isEmpty);
    });

    test('holds each pair to its own minimum, not to one shared number', () {
      // 3:1 is the bar for a boundary or a focus ring; 4.5:1 is the bar for text.
      const pair = ContrastCheck('mid grey on white', Color(0xFF8A8A8A), white,
          minimum: 3);

      expect(contrastRatio(pair.foreground, pair.background), greaterThan(3));
      expect(failingChecks([pair]), isEmpty);
      expect(
        failingChecks([
          ContrastCheck(pair.name, pair.foreground, pair.background,
              minimum: 4.5),
        ]),
        hasLength(1),
      );
    });
  });
}
