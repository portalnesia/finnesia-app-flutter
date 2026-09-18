/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:ui';

/// WCAG 2 contrast ratio between two colours, from 1 (identical) to 21 (black on white).
///
/// It does not matter which one is the text. `Color.computeLuminance` is the relative
/// luminance WCAG defines, so the formula is not written out here.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// One foreground-on-background pair the app really draws, and the bar it has to clear.
///
/// [minimum] is per pair because the bar is not one number: text needs 4.5, and the boundary
/// of an input or a focus ring needs 3 (WCAG 1.4.3 and 1.4.11).
class ContrastCheck {
  const ContrastCheck(
    this.name,
    this.foreground,
    this.background, {
    required this.minimum,
  });

  final String name;
  final Color foreground;
  final Color background;
  final double minimum;

  double get ratio => contrastRatio(foreground, background);

  bool get passes => ratio >= minimum;

  @override
  String toString() =>
      '$name: ${ratio.toStringAsFixed(2)}:1 (needs $minimum:1)';
}

/// The checks that do not clear their bar. Empty means all of them do.
List<ContrastCheck> failingChecks(Iterable<ContrastCheck> checks) => [
      for (final check in checks)
        if (!check.passes) check,
    ];
