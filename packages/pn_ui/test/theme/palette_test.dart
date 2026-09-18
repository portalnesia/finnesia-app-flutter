/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/contrast.dart';
import 'package:pn_ui/src/theme/palette.dart';

// `requiredChecks` is every foreground-on-background pair the app draws. A colour added to
// the palette without a check here is a colour nobody measured, so the checks are written
// next to the palette and this test runs them on both themes.

void main() {
  for (final entry
      in {'light': PnPalette.light, 'dark': PnPalette.dark}.entries) {
    group('the ${entry.key} palette', () {
      final palette = entry.value;

      test('clears every contrast bar it has to', () {
        final failing = failingChecks(requiredChecks(palette));

        // The reason lists every failure, so one run names all of them.
        expect(failing, isEmpty, reason: failing.join('\n'));
      });

      // A screen of #FFFFFF with #000000 text, or the reverse, is harsh on a tablet held all
      // day. The palette is measured against WCAG, not copied from the web app's tokens.
      test('never uses pure white or pure black for the page or the text', () {
        const pure = [Color(0xFFFFFFFF), Color(0xFF000000)];
        for (final c in [palette.background, palette.ink]) {
          expect(pure, isNot(contains(c)));
        }
      });

      test('is checked on a real number of pairs, not on an empty list', () {
        // An empty list would make the test above pass for nothing.
        expect(requiredChecks(palette).length, greaterThan(10));
      });

      // The palette follows the web app's tokens (owner decision, 2026-09-29). Those neutrals
      // are warm: hue 24 to 38, where the greys this app used to draw were cool (hue 220-225).
      // A tinted neutral that drifted back to blue is a colour that no longer belongs to the
      // brand, and it is invisible in a contrast check.
      test('is warm, not the cool grey it used to be', () {
        final tinted = {
          'background': palette.background,
          'surface': palette.surface,
          'surfaceMuted': palette.surfaceMuted,
          'ink': palette.ink,
          'inkMuted': palette.inkMuted,
          'border': palette.border,
          'outline': palette.outline,
        };

        for (final entry in tinted.entries) {
          final hsl = HSLColor.fromColor(entry.value);
          // White has no hue to read, so it is not asked for one.
          if (hsl.saturation < 0.05) continue;
          expect(hsl.hue, inInclusiveRange(20, 45),
              reason: '${entry.key} is ${hsl.hue.round()}deg');
        }
      });
    });
  }

  group('the focus ring', () {
    test(
        'is the ink colour in both themes, because amber would vanish on an amber button',
        () {
      // Amber ring on the amber primary button in the dark theme is invisible, and in the
      // light theme it is 2.14:1 on white. Ink clears both, next to any surface.
      expect(PnPalette.light.focus, PnPalette.light.ink);
      expect(PnPalette.dark.focus, PnPalette.dark.ink);
    });
  });

  group('the accent', () {
    // The web app splits the amber (owner decision 2026-09-29, replacing K5): 50% on the light
    // page, 52% on the dark one. The 2% buys the fill its contrast back on a charcoal page.
    test('is the web app\'s amber, 50% in light and 52% in dark', () {
      expect(PnPalette.light.accent.toARGB32(), 0xFFFF9900);
      expect(PnPalette.dark.accent.toARGB32(), 0xFFFF9D0A);
    });

    test('carries dark text in both themes, never white', () {
      for (final palette in [PnPalette.light, PnPalette.dark]) {
        expect(
          contrastRatio(palette.onAccent, palette.accent),
          greaterThan(8),
        );
      }
    });
  });

  group('brand ink', () {
    // The amber is a surface colour, not a text colour: as words on the light page it is
    // 2.04:1. The web app keeps a second, darker amber for exactly this (`--brand-ink`), and a
    // `TextButton` takes its words from `colorScheme.primary`, so without this token every
    // text button on a light screen would be unreadable.
    test('is dark enough to be words on a light page', () {
      expect(
        contrastRatio(PnPalette.light.brandInk, PnPalette.light.background),
        greaterThanOrEqualTo(4.5),
      );
      expect(PnPalette.light.brandInk.toARGB32(), 0xFF994700);
    });

    test(
        'is the accent itself in the dark theme, where the accent is already bright',
        () {
      expect(PnPalette.dark.brandInk, PnPalette.dark.accent);
    });
  });

  group('the second colour', () {
    // The web app's purple, for a state that is real but not yet in effect. It also fills
    // Material's `secondaryContainer`, which a `SegmentedButton` and the Shorebird update
    // banner both read: unset, that slot fell back to `secondary`, so the banner drew ink text
    // on an ink bar and the selected segment was ink rather than the brand's second colour.
    test('is the web app\'s purple, not the neutral it used to fall back to',
        () {
      for (final palette in [PnPalette.light, PnPalette.dark]) {
        final hue = HSLColor.fromColor(palette.secondary).hue;
        expect(hue, inInclusiveRange(270, 285));
        expect(palette.secondary, isNot(palette.ink));
      }
    });

    test('keeps its own container legible, in both themes', () {
      for (final palette in [PnPalette.light, PnPalette.dark]) {
        expect(
          contrastRatio(
            palette.onSecondaryContainer,
            palette.secondaryContainer,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('is not the same colour as the container it sits in', () {
      for (final palette in [PnPalette.light, PnPalette.dark]) {
        expect(palette.secondaryContainer, isNot(palette.secondary));
      }
    });
  });

  group('the brand panel', () {
    // `primaryContainer` is what the native-update banner paints and what a `TextButton` on it
    // sits against. Unset it fell back to the full amber, and the button's words (amber) then
    // measured 1.80:1 on it.
    test('is a tint of the amber, with words that can be read on it', () {
      for (final palette in [PnPalette.light, PnPalette.dark]) {
        expect(palette.primaryContainer, isNot(palette.accent));
        expect(
          contrastRatio(
            palette.onPrimaryContainer,
            palette.primaryContainer,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  });
}
