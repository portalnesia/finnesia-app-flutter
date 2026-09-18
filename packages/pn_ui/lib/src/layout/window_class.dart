/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/widgets.dart';

/// How much room a screen has, in the three steps where the till's content changes shape.
///
/// [compact] cannot hold the catalog and the cart side by side (the cart becomes a sheet);
/// [regular] holds them with a 380 dp cart; [wide] gives the cart 440 dp and packs the grid.
/// Three and not two: one break point would leave an 8-inch tablet in landscape with whichever
/// extreme was nearer (`plan/ui/README.md` §3.1).
enum WindowClass { compact, regular, wide }

/// The class for a window [width] in logical pixels.
WindowClass windowClassOf(double width) {
  if (width < 840) return WindowClass.compact;
  if (width < 1200) return WindowClass.regular;
  return WindowClass.wide;
}

extension WindowClassOfContext on BuildContext {
  /// From the width of the window, not its orientation: split-screen and fixed-size windows do
  /// not follow the orientation.
  WindowClass get windowClass => windowClassOf(MediaQuery.sizeOf(this).width);
}
