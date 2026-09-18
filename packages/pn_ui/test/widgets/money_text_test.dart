/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/widgets/money_text.dart';

import '../support/harness.dart';

// `MoneyText` takes a string that is already formatted: `pn_ui` may not import `pn_pos`, so the
// caller in `apps/pos` is the one that runs `formatCurrency`.

Widget boxed(Widget child, double width) =>
    Center(child: SizedBox(width: width, child: child));

void main() {
  group('a nominal', () {
    testWidgets('shows the text it was given', (tester) async {
      await tester.pumpWidget(harness(const MoneyText('Rp 87.500')));

      expect(find.text('Rp 87.500'), findsOneWidget);
    });

    testWidgets('is set in tabular figures, so a total does not jitter', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const MoneyText('Rp 87.500')));

      final style = tester.widget<Text>(find.text('Rp 87.500')).style!;
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    testWidgets('keeps them tabular in a style it is given', (tester) async {
      await tester.pumpWidget(
        harness(
          const MoneyText('Rp 87.500', style: TextStyle(fontSize: 40)),
        ),
      );

      final style = tester.widget<Text>(find.text('Rp 87.500')).style!;
      expect(style.fontSize, 40);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    testWidgets('ends at the right edge of the room it has', (tester) async {
      await tester.pumpWidget(
        harness(boxed(const MoneyText('Rp 5.000'), 400)),
      );

      final box = tester.getRect(find.byType(SizedBox).last);
      final text = tester.getRect(find.text('Rp 5.000'));
      expect(text.right, closeTo(box.right, 0.5));
    });

    testWidgets('stays on one line by shrinking, not by wrapping', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(boxed(const MoneyText('Rp 1.234.567.890'), 60)),
      );

      expect(tester.takeException(), isNull);
      final box = tester.getRect(find.byType(SizedBox).last);
      final text = tester.getRect(find.text('Rp 1.234.567.890'));
      expect(text.width, lessThanOrEqualTo(box.width + 0.5));
      // One line: no taller than a single line of the theme's body text.
      expect(text.height, lessThan(30));
    });
  });
}
