/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/widgets.dart';

/// The Finnesia logo, mark and wordmark side by side, 970 x 250.
///
/// Copied from `finnesia/Logo/icon-text-horizontal.png`, a folder the owner allowed for this.
const finnesiaLogoAsset = 'assets/logo/finnesia.png';

/// The Finnesia logo, for the screens that show it before a tenant's own is known (pairing,
/// boot) and for a tenant with no logo of its own.
///
/// One image for both themes. The owner chose the amber for light and dark alike, so nothing
/// here reads the brightness.
///
/// [semanticLabel] comes from the caller: a reusable widget takes its text as a parameter
/// (`.claude/rules/style.md` §7.1).
class FinnesiaLogo extends StatelessWidget {
  const FinnesiaLogo({
    super.key,
    required this.width,
    this.height,
    this.fit = BoxFit.contain,
    required this.semanticLabel,
  });

  final double width;

  /// Null keeps the height the source's own ratio gives, which is what every caller before this
  /// parameter wanted. A caller with a frame of its own (the login banner) passes it, so the
  /// fallback logo fills the same frame the tenant's logo does instead of drawing at a
  /// different scale beside it.
  final double? height;

  /// Defaults to [BoxFit.contain] so the logo is never cropped: this is the artwork the app
  /// falls back to, and a truncated wordmark reads as a bug.
  final BoxFit fit;

  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Image.asset(
    finnesiaLogoAsset,
    width: width,
    height: height,
    fit: fit,
    semanticLabel: semanticLabel,
  );
}
