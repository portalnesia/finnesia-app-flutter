/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pos/l10n/app_localizations.dart';

/// The tablet sizes every screen is checked at: both orientations of a 10-inch tablet, and a
/// small one, since a layout that only fits the size it was drawn at is not a layout.
const tabletSizes = {
  'landscape': Size(1280, 800),
  'portrait': Size(800, 1280),
  'small portrait': Size(600, 960),
};

/// [child] inside the app's theme and localizations, as it is at runtime.
///
/// The formatters are initialised here, because `bootstrap` does it for the real app and a
/// screen mounted by this harness has no bootstrap above it. Without this every screen that
/// draws a price or a date throws, and the failure looks like a screen bug rather than a
/// missing setup step. A test that boots the whole `PosApp` does not need it: it goes through
/// `bootstrap`.
///
/// `initializePosDateTime` returns a future, and awaiting it here would make `harness` async
/// for every caller. It is started and not awaited: it is only I/O-free table loading, and a
/// test that needs a date reads it after a pump.
Widget harness(
  Widget child, {
  Locale locale = const Locale('id'),
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) {
  initializePosNumberFormat();
  initializePosDateTime();
  return MaterialApp(
    theme: pnTheme(Brightness.light),
    darkTheme: pnTheme(Brightness.dark),
    themeMode: brightness == Brightness.light
        ? ThemeMode.light
        : ThemeMode.dark,
    locale: locale,
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    builder: (context, home) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: home!,
    ),
    home: child,
  );
}

extension SurfaceSize on WidgetTester {
  /// Draws at [size] in logical pixels, whatever the device pixel ratio.
  Future<void> useSize(Size size) async {
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
  }
}
