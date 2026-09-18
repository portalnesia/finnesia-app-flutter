/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/app_theme.dart';

/// The widths every primitive is checked at (`plan/ui/README.md` §3.1): a phone, a small
/// tablet in portrait, a 10-inch in portrait, a small landscape, a 10-inch in landscape.
const checkedWidths = [360.0, 600.0, 800.0, 1024.0, 1280.0];

/// The text scales every primitive is checked at.
const checkedTextScales = [1.0, 1.3];

/// [child] inside the app theme, as it is at runtime. No localizations: `pn_ui` widgets take
/// their text as parameters (`.claude/rules/style.md` §7.1).
Widget harness(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) =>
    MaterialApp(
      theme: pnTheme(Brightness.light),
      darkTheme: pnTheme(Brightness.dark),
      themeMode:
          brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
      builder: (context, home) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: home!,
      ),
      home: Scaffold(body: child),
    );

extension SurfaceSize on WidgetTester {
  /// Draws at [width] by [height] logical pixels, whatever the device pixel ratio.
  Future<void> useSize(double width, [double height = 800]) async {
    view.physicalSize = Size(width, height);
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
  }
}
