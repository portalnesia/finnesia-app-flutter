/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/palette.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/till_bar.dart';

// The bar that carries the way out to the Menu. It is a widget of its own and not part of the
// status strip, so what it must do is small and worth pinning: be reachable by tap, be big
// enough to hit, and read as a control to a screen reader.

Widget wrap(Widget child) => MaterialApp(
      theme: pnTheme(Brightness.light),
      home: Scaffold(body: child),
    );

void main() {
  group('the till bar', () {
    testWidgets('opens the menu when tapped', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        wrap(TillBar(label: 'Menu', onOpen: () => opened++)),
      );

      await tester.tap(find.text('Menu'));
      await tester.pump();

      expect(opened, 1);
    });

    testWidgets('is at least the minimum touch size', (tester) async {
      await tester.pumpWidget(wrap(TillBar(label: 'Menu', onOpen: () {})));

      // A mis-tap here is not money, but it is the only way out of the screen.
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(PnTouch.min),
      );
    });

    testWidgets('shows the word beside the icon', (tester) async {
      await tester.pumpWidget(wrap(TillBar(label: 'Menu', onOpen: () {})));

      // Both halves earn their place: the icon is the affordance a cashier recognises without
      // reading, and the word says where it goes. The source does the same (`till-bar.tsx`).
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
    });

    testWidgets(
        'is the grey of the page behind the products, not the white of a card',
        (tester) async {
      await tester.pumpWidget(wrap(TillBar(label: 'Menu', onOpen: () {})));

      final bar = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(TillBar),
              matching: find.byType(Material),
            )
            .first,
      );

      // It is chrome, not content: white is for what the cashier reads and types into.
      expect(bar.color, PnPalette.light.background);
    });

    testWidgets('carries a second action at the far end, on the same row', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        wrap(
          TillBar(
            label: 'Menu',
            onOpen: () {},
            trailingLabel: 'Detail shift',
            trailingIcon: Icons.receipt_long_outlined,
            onTrailing: () => opened++,
          ),
        ),
      );

      await tester.tap(find.text('Detail shift'));
      await tester.pump();

      expect(opened, 1);
      // Same row as the Menu, and to the right of it.
      expect(
        tester.getCenter(find.text('Detail shift')).dy,
        tester.getCenter(find.text('Menu')).dy,
      );
      expect(
        tester.getCenter(find.text('Detail shift')).dx,
        greaterThan(tester.getCenter(find.text('Menu')).dx),
      );
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Detail shift')).height,
        greaterThanOrEqualTo(PnTouch.min),
      );
    });

    testWidgets(
        'is icons only in portrait, each still named for a screen reader', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var opened = 0;
      var detail = 0;
      await tester.pumpWidget(
        wrap(
          TillBar(
            label: 'Menu',
            onOpen: () => opened++,
            trailingLabel: 'Detail shift',
            trailingIcon: Icons.receipt_long_outlined,
            onTrailing: () => detail++,
          ),
        ),
      );

      expect(find.text('Menu'), findsNothing);
      expect(find.text('Detail shift'), findsNothing);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);

      await tester.tap(find.byTooltip('Menu'));
      await tester.tap(find.byTooltip('Detail shift'));

      expect(opened, 1);
      expect(detail, 1);
      for (final name in ['Menu', 'Detail shift']) {
        final size = tester.getSize(find.byTooltip(name));
        expect(size.shortestSide, greaterThanOrEqualTo(PnTouch.min));
      }
    });

    testWidgets('has no second action unless it is given one', (tester) async {
      await tester.pumpWidget(wrap(TillBar(label: 'Menu', onOpen: () {})));

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('is drawn in ink, not in the accent', (tester) async {
      await tester.pumpWidget(wrap(TillBar(label: 'Menu', onOpen: () {})));

      // The accent is the one primary action per screen (R-29), and on the till that is Pay.
      // A navigation control wearing it competes with the button that takes money, and it is what
      // made the bar read as a web header rather than as part of the app. The theme puts the
      // accent in `colorScheme.primary`, which is what `TextButton` takes by default.
      final paragraph = tester.renderObject<RenderParagraph>(find.text('Menu'));
      final ink = tester.element(find.byType(TillBar)).pn.ink;
      expect(paragraph.text.style?.color, ink);

      // The icon goes with the word: two colours in one button would read as two controls.
      final icon = tester.widget<Icon>(find.byIcon(Icons.menu));
      expect(icon.color, isNull);
    });

    testWidgets('takes its label from the caller, never from a translation',
        (tester) async {
      await tester.pumpWidget(
        wrap(TillBar(label: 'Anything the caller says', onOpen: () {})),
      );

      // `pn_ui` has no `AppLocalizations` and must not grow one (`style.md` §7.1): a reusable
      // widget that reads its own text cannot be reused.
      expect(find.text('Anything the caller says'), findsOneWidget);
    });
  });
}
