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
    });
  }

  // `finnesia-monorepo/packages/ui/src/index.css` since "one shared theme" (680feddf,
  // 2026-11-16): the navy palette every app of the platform shares. Each Flutter token is
  // written down with the CSS variable it is taken from, so a value that drifts from the web is
  // a failing line with both names on it. Tokens the web has no variable for (`outline`) and the
  // ones this app deliberately sets apart (`focus`) are not in this table.
  group('follows the web tokens', () {
    Color hsl(double h, double s, double l) =>
        HSLColor.fromAHSL(1, h, s / 100, l / 100).toColor();

    final web = <String, (Color, Color, Color, Color)>{
      // token: (flutter light, web light, flutter dark, web dark)
      'background <- --background': (
        PnPalette.light.background,
        hsl(38, 30, 97.5),
        PnPalette.dark.background,
        hsl(222, 40, 10),
      ),
      'surface <- --card': (
        PnPalette.light.surface,
        hsl(0, 0, 100),
        PnPalette.dark.surface,
        hsl(217, 33, 14),
      ),
      'surfaceMuted <- --muted': (
        PnPalette.light.surfaceMuted,
        hsl(36, 20, 94),
        PnPalette.dark.surfaceMuted,
        hsl(217, 33, 18),
      ),
      'ink <- --foreground': (
        PnPalette.light.ink,
        hsl(215, 28, 17),
        PnPalette.dark.ink,
        hsl(210, 40, 96),
      ),
      'inkMuted <- --muted-foreground': (
        PnPalette.light.inkMuted,
        hsl(215, 14, 34),
        PnPalette.dark.inkMuted,
        hsl(215, 20, 65),
      ),
      'border <- --border': (
        PnPalette.light.border,
        hsl(37, 29, 91),
        PnPalette.dark.border,
        hsl(217, 33, 24),
      ),
      'accent <- --primary': (
        PnPalette.light.accent,
        hsl(36, 100, 50),
        PnPalette.dark.accent,
        hsl(36, 100, 52),
      ),
      'onAccent <- --primary-foreground': (
        PnPalette.light.onAccent,
        hsl(24, 14, 10),
        PnPalette.dark.onAccent,
        hsl(24, 30, 10),
      ),
      'brandInk <- --brand-ink': (
        PnPalette.light.brandInk,
        hsl(28, 100, 30),
        PnPalette.dark.brandInk,
        hsl(36, 100, 52),
      ),
      'error <- --destructive': (
        PnPalette.light.error,
        hsl(0, 62, 42),
        PnPalette.dark.error,
        hsl(0, 72, 74),
      ),
      'errorText <- --destructive': (
        PnPalette.light.errorText,
        hsl(0, 62, 42),
        PnPalette.dark.errorText,
        hsl(0, 72, 74),
      ),
      'onError <- --destructive-foreground': (
        PnPalette.light.onError,
        hsl(0, 0, 98),
        PnPalette.dark.onError,
        hsl(24, 30, 10),
      ),
      'secondary <- --secondary': (
        PnPalette.light.secondary,
        hsl(276, 100, 50),
        PnPalette.dark.secondary,
        hsl(276, 80, 72),
      ),
      'onSecondary <- --secondary-foreground': (
        PnPalette.light.onSecondary,
        hsl(0, 0, 100),
        PnPalette.dark.onSecondary,
        hsl(276, 60, 12),
      ),
      'onSecondaryContainer <- --foreground': (
        PnPalette.light.onSecondaryContainer,
        hsl(215, 28, 17),
        PnPalette.dark.onSecondaryContainer,
        hsl(210, 40, 96),
      ),
      'primaryContainer <- --accent': (
        PnPalette.light.primaryContainer,
        hsl(38, 72, 90),
        PnPalette.dark.primaryContainer,
        hsl(217, 35, 20),
      ),
      'onPrimaryContainer <- --accent-foreground': (
        PnPalette.light.onPrimaryContainer,
        hsl(215, 28, 17),
        PnPalette.dark.onPrimaryContainer,
        hsl(210, 40, 96),
      ),
    };

    for (final MapEntry(key: token, value: (light, webLight, dark, webDark))
        in web.entries) {
      test(token, () {
        expect(light, webLight, reason: 'light $token');
        expect(dark, webDark, reason: 'dark $token');
      });
    }

    // The web app has no token for an input's edge: it uses `--border`, which fails the 3:1 an
    // edge needs (WCAG 1.4.11). This app keeps its own, in the navy of the shared theme rather
    // than the warm grey it had, so it sits with the text and the dark surfaces (owner decision,
    // 2026-11-20).
    test('outline is the navy of the shared theme, in both themes', () {
      expect(PnPalette.light.outline, hsl(215, 14, 45));
      expect(PnPalette.dark.outline, hsl(217, 16, 52));
    });

    // A tint of the purple over the surface, the web app's `bg-secondary/10`: it follows the
    // surface it is laid over, so a dark surface that changed changes it too.
    test('the secondary container is the purple laid over the surface', () {
      expect(
        PnPalette.dark.secondaryContainer,
        Color.alphaBlend(
          PnPalette.dark.secondary.withValues(alpha: 0.25),
          PnPalette.dark.surface,
        ),
      );
    });
  });

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
    // measured 1.80:1 on it. It is the web app's `--accent`: an amber tint on the light page,
    // navy in the dark theme, where an amber tint over navy reads as brown.
    test('is not the full amber, with words that can be read on it', () {
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
