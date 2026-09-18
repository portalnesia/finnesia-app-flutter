/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/keypad.dart';

import '../support/harness.dart';

Keypad keypad({
  ValueChanged<String>? onDigit,
  VoidCallback? onBackspace,
  bool enabled = true,
}) =>
    Keypad(
      onDigit: onDigit ?? (_) {},
      onBackspace: onBackspace ?? () {},
      backspaceLabel: 'Hapus angka',
      enabled: enabled,
    );

Finder key(String label) => find.widgetWithText(OutlinedButton, label);

void main() {
  group('the keypad', () {
    testWidgets('has every digit, and a double zero for round amounts', (
      tester,
    ) async {
      await tester.pumpWidget(harness(keypad()));

      for (final label in [
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '00'
      ]) {
        expect(key(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('gives the digit of the key that was tapped', (tester) async {
      final digits = <String>[];
      await tester.pumpWidget(harness(keypad(onDigit: digits.add)));

      await tester.tap(key('5'));
      await tester.tap(key('00'));
      await tester.tap(key('0'));

      expect(digits, ['5', '00', '0']);
    });

    testWidgets('takes a digit back, and says so to a screen reader', (
      tester,
    ) async {
      var back = 0;
      await tester.pumpWidget(harness(keypad(onBackspace: () => back++)));

      await tester.tap(find.bySemanticsLabel('Hapus angka'));

      expect(back, 1);
    });

    testWidgets('does nothing while disabled', (tester) async {
      final digits = <String>[];
      var back = 0;
      await tester.pumpWidget(
        harness(
          keypad(
            onDigit: digits.add,
            onBackspace: () => back++,
            enabled: false,
          ),
        ),
      );

      await tester.tap(key('5'), warnIfMissed: false);
      await tester.tap(find.bySemanticsLabel('Hapus angka'),
          warnIfMissed: false);

      expect(digits, isEmpty);
      expect(back, 0);
    });

    testWidgets('has keys big enough to hit, with room between them', (
      tester,
    ) async {
      await tester.pumpWidget(harness(keypad()));

      final one = tester.getRect(key('1'));
      final two = tester.getRect(key('2'));
      final four = tester.getRect(key('4'));
      expect(one.height, greaterThanOrEqualTo(PnTouch.primary));
      expect(one.width, greaterThanOrEqualTo(PnTouch.min));
      expect(two.left - one.right, greaterThanOrEqualTo(8));
      expect(four.top - one.bottom, greaterThanOrEqualTo(8));
    });

    for (final width in checkedWidths) {
      for (final scale in checkedTextScales) {
        for (final brightness in Brightness.values) {
          testWidgets(
            'fits ${width.toInt()} dp at text ${scale}x in the ${brightness.name} theme',
            (tester) async {
              await tester.useSize(width);
              await tester.pumpWidget(
                harness(
                  Center(child: SizedBox(width: width - 32, child: keypad())),
                  brightness: brightness,
                  textScale: scale,
                ),
              );

              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });
}
