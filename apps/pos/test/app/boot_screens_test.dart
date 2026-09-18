/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/app/boot_screens.dart';
import 'package:pos/app/finnesia_logo.dart';

import '../support/app_harness.dart';

void main() {
  group('the boot screen', () {
    testWidgets('shows the logo and says it is loading', (tester) async {
      await tester.pumpWidget(harness(const BootScreen()));

      expect(find.byType(FinnesiaLogo), findsOneWidget);
      expect(find.bySemanticsLabel('Memuat…'), findsOneWidget);
    });

    testWidgets('says it in the language the cashier picked', (tester) async {
      await tester.pumpWidget(
        harness(const BootScreen(), locale: const Locale('en')),
      );

      expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
    });
  });

  group('the boot-failed screen', () {
    testWidgets('says what happened in a sentence, and offers a retry', (
      tester,
    ) async {
      await tester.pumpWidget(harness(BootFailedScreen(onRetry: () {})));

      expect(
        find.text(
          'Data perangkat belum bisa dibuka. Pairing tablet ini tidak dihapus. Coba lagi.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Coba lagi'), findsOneWidget);
      expect(find.byType(FinnesiaLogo), findsOneWidget);
    });

    testWidgets('speaks English when the cashier picked English', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(BootFailedScreen(onRetry: () {}), locale: const Locale('en')),
      );

      expect(
        find.text(
          "The device data could not be opened. This tablet's pairing has not been removed. Try again.",
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
    });

    testWidgets('calls back when the retry is tapped', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        harness(BootFailedScreen(onRetry: () => retries++)),
      );

      await tester.tap(find.byType(FilledButton));

      expect(retries, 1);
    });

    testWidgets('has a retry big enough to hit', (tester) async {
      await tester.pumpWidget(harness(BootFailedScreen(onRetry: () {})));

      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(PnTouch.primary),
      );
    });
  });

  group('both screens', () {
    for (final MapEntry(key: name, value: size) in tabletSizes.entries) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'fit a $name tablet in the ${brightness.name} theme at large text',
          (tester) async {
            await tester.useSize(size);

            for (final screen in <Widget>[
              const BootScreen(),
              BootFailedScreen(onRetry: () {}),
            ]) {
              await tester.pumpWidget(
                harness(screen, brightness: brightness, textScale: 2),
              );

              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }
  });
}
