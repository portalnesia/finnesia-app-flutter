/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';

/// An amount, on one line, in tabular figures, ending at the right edge of its room.
///
/// [text] is already formatted. `pn_ui` cannot import `pn_pos`, so the caller in the app runs
/// `formatCurrency` and hands the result here.
///
/// It shrinks to fit rather than wrap: a total that broke over two lines would read as two
/// numbers. Give it a bounded width (an `Expanded`, a `SizedBox`).
class MoneyText extends StatelessWidget {
  const MoneyText(this.text, {super.key, this.style});

  final String text;

  /// Defaults to the theme's body text. Tabular figures are added to whatever is given.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge!;
    return Align(
      alignment: Alignment.centerRight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          text,
          maxLines: 1,
          style: base.copyWith(
            fontFeatures: [
              ...?base.fontFeatures,
              const FontFeature.tabularFigures(),
            ],
          ),
        ),
      ),
    );
  }
}
