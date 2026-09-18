/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/painting.dart';

import 'contrast.dart';

/// `hsl(h s% l%)`, so a value reads the way a designer writes it.
Color _hsl(double h, double s, double l) =>
    HSLColor.fromAHSL(1, h, s / 100, l / 100).toColor();

/// [colour] laid over [over] at [alpha], the way the web app's `bg-<token>/10` does it.
///
/// A container slot is a **tint of** its colour, not the colour: Material puts ordinary ink on
/// top of it, and a full-strength fill would leave that ink nowhere to stand.
Color _tint(Color colour, Color over, double alpha) =>
    Color.alphaBlend(colour.withValues(alpha: alpha), over);

/// Every colour the app draws, per theme.
///
/// Taken from the web app's tokens (owner decision, 2026-09-29), so a tablet and a browser show
/// the same brand. The two are not identical: a token is kept only where it clears the contrast
/// bar this app measures it against, and every difference is written down next to the value.
/// [requiredChecks] measures every pair it draws.
final class PnPalette {
  const PnPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.border,
    required this.outline,
    required this.accent,
    required this.onAccent,
    required this.brandInk,
    required this.error,
    required this.onError,
    required this.errorText,
    required this.focus,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.primaryContainer,
    required this.onPrimaryContainer,
  });

  /// The screen behind everything.
  final Color background;

  /// Cards, sheets and dialogs.
  final Color surface;

  /// A panel that sits on a surface without being a card: the cart column, a selected row.
  final Color surfaceMuted;

  /// Text and icons.
  final Color ink;

  /// Secondary text.
  final Color inkMuted;

  /// A hairline between rows. Decorative: it is never the only thing that shows where a
  /// control is, so it is not held to 3:1.
  final Color border;

  /// The edge of an input or an unselected control, which **is** what shows where it is,
  /// and so has to clear 3:1 (WCAG 1.4.11).
  final Color outline;

  /// Finnesia amber. The one accent, and a **surface** colour: as words it is 2.04:1 on the
  /// light page, which is what [brandInk] is for.
  final Color accent;

  /// Text on [accent]. Dark, never white: white on this amber is about 2.1:1.
  final Color onAccent;

  /// The amber as words, icons and links on a light page (`--brand-ink` on the web). In the dark
  /// theme it is [accent] itself, because the amber is already bright enough to read there.
  final Color brandInk;

  /// The fill of a destructive button.
  final Color error;
  final Color onError;

  /// Error text and icons on a surface, such as a negative variance. Not [error]: a fill
  /// and a piece of text are held to different bars against different backgrounds.
  final Color errorText;

  /// The ring around whatever has keyboard focus.
  final Color focus;

  /// The brand's **second** colour. The web app uses it for a state that is real but not yet in
  /// effect, and this app has one: a Shorebird patch that has downloaded and applies on the next
  /// restart. One second colour, not a third accent: it never fills a button that takes money.
  final Color secondary;
  final Color onSecondary;

  /// [secondary] as a panel, which is what Material's `secondaryContainer` slot is for: a
  /// `SegmentedButton`'s selected segment and the Shorebird update banner both read it.
  final Color secondaryContainer;
  final Color onSecondaryContainer;

  /// The amber as a panel: the native-update banner. A tint, so a `TextButton` on it still has
  /// somewhere to stand.
  final Color primaryContainer;
  final Color onPrimaryContainer;

  // Neither theme uses pure white or pure black for the page or the text: on a tablet held all
  // day that is harsh, and it leaves nothing lighter or darker to build depth from. The neutrals
  // are **warm** (hue 24-38), matching the web app's tokens, so the greys sit with the amber
  // rather than fighting it. Every pair is measured by `requiredChecks`.
  static final light = PnPalette(
    background: _hsl(38, 30, 97.5),
    surface: _hsl(0, 0, 100),
    surfaceMuted: _hsl(36, 20, 94),
    ink: _hsl(24, 14, 10),
    inkMuted: _hsl(28, 9, 40),
    border: _hsl(30, 14, 87),
    // The web app has no token for this: it uses `--border` for an input's edge, which is
    // 1.27:1 and fails the 3:1 an input edge needs (WCAG 1.4.11). Same warm hue, dark enough
    // to be seen.
    outline: _hsl(30, 9, 46),
    accent: _hsl(36, 100, 50),
    onAccent: _hsl(24, 14, 10),
    brandInk: _hsl(28, 100, 30),
    // A destructive fill with white text, and the same red as text on a light surface.
    error: _hsl(0, 62, 42),
    onError: _hsl(0, 0, 98),
    errorText: _hsl(0, 62, 42),
    // The ring is ink: an amber ring would be 2.14:1 on a light page, and invisible on an
    // amber button in any theme.
    focus: _hsl(24, 14, 10),
    secondary: _hsl(276, 100, 50),
    onSecondary: _hsl(0, 0, 100),
    // `bg-secondary/10` over the surface, the web app's own tint. At 10% the purple is still
    // legible as words on its own tint (4.65:1), which a deeper tint would break.
    secondaryContainer: _tint(_hsl(276, 100, 50), _hsl(0, 0, 100), 0.10),
    onSecondaryContainer: _hsl(24, 14, 10),
    primaryContainer: _hsl(38, 72, 90),
    onPrimaryContainer: _hsl(24, 14, 10),
  );

  // A charcoal, not black: with a black page a dialog's barrier had nothing left to darken.
  static final dark = PnPalette(
    background: _hsl(24, 12, 8),
    // The web app's card is 12%, and at 12% a dialog's barrier measured 1.23:1 against it,
    // below the 1.25 this app holds a dialog to. One step lighter, nothing else moved: the
    // same hue and saturation the web app uses.
    surface: _hsl(24, 10, 13),
    surfaceMuted: _hsl(24, 8, 18),
    ink: _hsl(38, 20, 93),
    inkMuted: _hsl(30, 12, 70),
    border: _hsl(24, 8, 23),
    outline: _hsl(30, 8, 45),
    // 52%, not 50%: the web app's dark amber. The extra lightness is what keeps the fill itself
    // visible on a charcoal page.
    accent: _hsl(36, 100, 52),
    onAccent: _hsl(24, 30, 10),
    // Already bright enough to be words here, so it is the accent itself.
    brandInk: _hsl(36, 100, 52),
    error: _hsl(0, 72, 74),
    onError: _hsl(24, 30, 10),
    // The bright red works in both roles on a dark page, so one value serves as fill and as text.
    errorText: _hsl(0, 72, 74),
    // Ink in both themes; see `light`.
    focus: _hsl(38, 20, 93),
    secondary: _hsl(276, 80, 72),
    onSecondary: _hsl(276, 60, 12),
    // A dark surface swallows a tint, so the dark theme needs more of it for the panel to read
    // as one: the web app raises its own secondary overlays in the dark theme for that reason.
    secondaryContainer: _tint(_hsl(276, 80, 72), _hsl(24, 10, 13), 0.25),
    onSecondaryContainer: _hsl(38, 20, 93),
    primaryContainer: _hsl(36, 28, 18),
    onPrimaryContainer: _hsl(38, 20, 93),
  );
}

/// Every pair the app draws, with the bar it has to clear: 4.5:1 for text and 3:1 for the
/// edge of a control or a focus ring (WCAG 1.4.3, 1.4.11).
///
/// The amber accent on a plain background is deliberately **not** here. It is never used
/// alone to show something: a button carries dark text on it ([onAccent]), words are
/// [brandInk], and a focus ring is [focus], which is ink because amber would not reach 3:1
/// on white.
List<ContrastCheck> requiredChecks(PnPalette p) {
  const text = 4.5;
  const edge = 3.0;
  return [
    ContrastCheck('ink on background', p.ink, p.background, minimum: text),
    ContrastCheck('ink on surface', p.ink, p.surface, minimum: text),
    ContrastCheck('ink on surfaceMuted', p.ink, p.surfaceMuted, minimum: text),
    ContrastCheck('inkMuted on background', p.inkMuted, p.background,
        minimum: text),
    ContrastCheck('inkMuted on surface', p.inkMuted, p.surface, minimum: text),
    ContrastCheck('inkMuted on surfaceMuted', p.inkMuted, p.surfaceMuted,
        minimum: text),
    ContrastCheck('onAccent on accent', p.onAccent, p.accent, minimum: text),
    ContrastCheck('onError on error', p.onError, p.error, minimum: text),
    ContrastCheck('errorText on background', p.errorText, p.background,
        minimum: text),
    ContrastCheck('errorText on surface', p.errorText, p.surface,
        minimum: text),
    ContrastCheck('errorText on surfaceMuted', p.errorText, p.surfaceMuted,
        minimum: text),
    ContrastCheck('outline on background', p.outline, p.background,
        minimum: edge),
    ContrastCheck('outline on surface', p.outline, p.surface, minimum: edge),
    ContrastCheck('focus on background', p.focus, p.background, minimum: edge),
    ContrastCheck('focus on surface', p.focus, p.surface, minimum: edge),
    ContrastCheck('focus on surfaceMuted', p.focus, p.surfaceMuted,
        minimum: edge),
    // The amber as words, which is a different job from the amber as a fill.
    ContrastCheck('brandInk on background', p.brandInk, p.background,
        minimum: text),
    ContrastCheck('brandInk on surface', p.brandInk, p.surface, minimum: text),
    ContrastCheck('brandInk on surfaceMuted', p.brandInk, p.surfaceMuted,
        minimum: text),
    ContrastCheck(
        'brandInk on primaryContainer', p.brandInk, p.primaryContainer,
        minimum: text),
    ContrastCheck('onSecondary on secondary', p.onSecondary, p.secondary,
        minimum: text),
    ContrastCheck('onSecondaryContainer on secondaryContainer',
        p.onSecondaryContainer, p.secondaryContainer,
        minimum: text),
    ContrastCheck('onPrimaryContainer on primaryContainer',
        p.onPrimaryContainer, p.primaryContainer,
        minimum: text),
  ];
}
