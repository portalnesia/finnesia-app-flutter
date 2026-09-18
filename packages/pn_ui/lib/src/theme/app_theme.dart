/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';

import 'palette.dart';
import 'tokens.dart';

/// The palette, carried on the theme for the tokens Material has no slot for (`errorText`,
/// `inkMuted`, `outline`, `focus`). Read it with `context.pn`.
class PnColors extends ThemeExtension<PnColors> {
  const PnColors(this.palette);

  final PnPalette palette;

  @override
  PnColors copyWith({PnPalette? palette}) => PnColors(palette ?? this.palette);

  // Light and dark are switched, never blended: two palettes measured on their own are not
  // guaranteed to stay legible halfway between them.
  @override
  PnColors lerp(PnColors? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension PnBuildContext on BuildContext {
  /// The palette of the theme in scope.
  PnPalette get pn {
    final colors = Theme.of(this).extension<PnColors>();
    if (colors == null) {
      throw StateError(
        'The app theme is not applied: build the MaterialApp with pnTheme(...).',
      );
    }
    return colors.palette;
  }
}

/// The app's theme for one brightness.
///
/// The typeface is the system's (owner decision K7): identity comes from size and weight, not
/// from a font file in the APK. Every text style sets figures in **tabular** width, so a total
/// does not jitter as it changes.
ThemeData pnTheme(Brightness brightness) {
  final p = brightness == Brightness.light ? PnPalette.light : PnPalette.dark;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    // The brand's second colour: the web app's purple, for a state that is real but not yet in
    // effect. Left unset, Material falls back to `primary` (the amber) and then to `onPrimary`,
    // which put ink words on an ink bar and drew a selected segment in ink.
    secondary: p.secondary,
    onSecondary: p.onSecondary,
    secondaryContainer: p.secondaryContainer,
    onSecondaryContainer: p.onSecondaryContainer,
    primaryContainer: p.primaryContainer,
    onPrimaryContainer: p.onPrimaryContainer,
    error: p.error,
    onError: p.onError,
    surface: p.surface,
    onSurface: p.ink,
    onSurfaceVariant: p.inkMuted,
    surfaceContainerHighest: p.surfaceMuted,
    outline: p.outline,
    outlineVariant: p.border,
  );

  final control = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(PnRadius.control),
  );
  final surface = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(PnRadius.surface),
  );

  // Outside the edge, so it lands on the page behind the button and not on the amber fill.
  final focusRing = BorderSide(
    color: p.focus,
    width: 2,
    strokeAlign: BorderSide.strokeAlignOutside,
  );
  WidgetStateProperty<BorderSide?> ringOnFocus([BorderSide? resting]) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused) ? focusRing : resting,
      );

  ButtonStyle button({required double height}) => ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(64, height)),
        shape: WidgetStatePropertyAll(control),
      );

  OutlineInputBorder edge(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(PnRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );

  // Material's default (black at 54%) over a charcoal page barely darkens it, so a dialog did not
  // stand out from what it covered. Stronger in the dark theme, where there is less to darken.
  final scrim = Colors.black.withValues(
    alpha: brightness == Brightness.dark ? 0.75 : 0.5,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: [PnColors(p)],
    textTheme: _tabular(
      (brightness == Brightness.light
              ? Typography.material2021().black
              : Typography.material2021().white)
          .apply(bodyColor: p.ink, displayColor: p.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: button(height: PnTouch.primary).copyWith(
        // A button that cannot be pressed must not look like one that can: a form that waits on
        // a field would leave the cashier guessing why nothing happens. `inkMuted` on
        // `surfaceMuted` still clears 4.5:1, so the words stay readable.
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.disabled) ? p.surfaceMuted : p.accent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.disabled) ? p.inkMuted : p.onAccent,
        ),
        side: ringOnFocus(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: button(height: PnTouch.min).copyWith(
        side: ringOnFocus(BorderSide(color: p.outline)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: button(height: PnTouch.min).copyWith(
        // `TextButton` takes its words from `colorScheme.primary`, which is the amber, and the
        // amber is a **surface** colour: as words on the light page it is 2.04:1. The web app
        // keeps a second, darker amber for exactly this (`--brand-ink`); `colorScheme.primary`
        // itself is left alone, because it is what every Material fill takes.
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.disabled) ? p.inkMuted : p.brandInk,
        ),
        side: ringOnFocus(),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size.square(PnTouch.min),
        ),
        side: ringOnFocus(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: edge(p.outline, 1),
      enabledBorder: edge(p.outline, 1),
      focusedBorder: edge(p.focus, 2),
      errorBorder: edge(p.errorText, 1),
      focusedErrorBorder: edge(p.errorText, 2),
    ),
    // A hairline and no shadow: a card sits on the page, it does not float over it (R-12).
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: surface.copyWith(side: BorderSide(color: p.border)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBarrierColor: scrim,
    ),
    // 560 is Material's own ceiling for a dialog. Without it an `AlertDialog` is as wide as its
    // text on one line, so a sentence under "Sign out" spanned the whole of a tablet.
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      barrierColor: scrim,
      shape: surface,
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
    ),
  );
}

// Every style gets tabular figures. `TextTheme` has no map, so each of the fifteen is named.
TextTheme _tabular(TextTheme t) {
  TextStyle? tabular(TextStyle? s) => s?.copyWith(
        fontFeatures: [
          ...?s.fontFeatures,
          const FontFeature.tabularFigures(),
        ],
      );

  return t.copyWith(
    displayLarge: tabular(t.displayLarge),
    displayMedium: tabular(t.displayMedium),
    displaySmall: tabular(t.displaySmall),
    headlineLarge: tabular(t.headlineLarge),
    headlineMedium: tabular(t.headlineMedium),
    headlineSmall: tabular(t.headlineSmall),
    titleLarge: tabular(t.titleLarge),
    titleMedium: tabular(t.titleMedium),
    titleSmall: tabular(t.titleSmall),
    bodyLarge: tabular(t.bodyLarge),
    bodyMedium: tabular(t.bodyMedium),
    bodySmall: tabular(t.bodySmall),
    labelLarge: tabular(t.labelLarge),
    labelMedium: tabular(t.labelMedium),
    labelSmall: tabular(t.labelSmall),
  );
}
