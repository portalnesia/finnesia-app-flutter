/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pos/screens/common/amount_entry.dart';

import '../../support/app_harness.dart';

// One amount, typed on the on-screen keypad or a physical keyboard, that three screens share: the
// opening cash, the counted cash, and a cash movement. The amount lives with the screen; this
// only says what a key does to it.

class _Host extends StatelessWidget {
  const _Host({this.start = 0, this.enabled = true, this.onChanged});

  final int start;
  final bool enabled;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      child: AmountEntry(
        label: 'Uang',
        initial: start,
        backspaceLabel: 'Hapus angka',
        enabled: enabled,
        onChanged: onChanged ?? (_) {},
      ),
    ),
  );
}

Future<void> pump(
  WidgetTester tester, {
  int start = 0,
  bool enabled = true,
  ValueChanged<int>? onChanged,
}) async {
  await tester.useSize(const Size(600, 960));
  await tester.pumpWidget(
    harness(_Host(start: start, enabled: enabled, onChanged: onChanged)),
  );
  // The shortcuts take focus on the first frame after they appear.
  await tester.pumpAndSettle();
}

Finder key(String label) => find.widgetWithText(OutlinedButton, label);

void main() {
  group('typing on the keypad', () {
    testWidgets('shows the amount as money, and starts at zero', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text(formatCurrency(0)), findsOneWidget);
    });

    testWidgets('a digit is added at the end', (tester) async {
      await pump(tester);

      await tester.tap(key('5'));
      await tester.pump();
      await tester.tap(key('2'));
      await tester.pump();

      expect(find.text(formatCurrency(52)), findsOneWidget);
    });

    testWidgets('the double zero writes two zeros, and nothing at zero', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(key('00'));
      await tester.pump();
      expect(find.text(formatCurrency(0)), findsOneWidget);

      await tester.tap(key('5'));
      await tester.pump();
      await tester.tap(key('00'));
      await tester.pump();
      expect(find.text(formatCurrency(500)), findsOneWidget);
    });

    testWidgets('delete drops the last digit, and does nothing at zero', (
      tester,
    ) async {
      await pump(tester, start: 1250);

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(find.text(formatCurrency(125)), findsOneWidget);

      // A finger always leaves a frame between two taps; two `tap`s without one are one tap.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pump();
      }
      expect(find.text(formatCurrency(0)), findsOneWidget);
    });

    testWidgets('stops at twelve digits, past which it is a slip of the '
        'thumb', (tester) async {
      await pump(tester, start: 999999999999);

      await tester.tap(key('5'));
      await tester.pump();

      expect(find.text(formatCurrency(999999999999)), findsOneWidget);
    });
  });

  group('reporting it', () {
    testWidgets('tells the screen every amount it comes to, in order', (
      tester,
    ) async {
      final told = <int>[];
      await pump(tester, onChanged: told.add);

      for (final digit in ['1', '2', '00']) {
        await tester.tap(key(digit));
      }
      await tester.pump();
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(told, [1, 12, 1200, 120]);
    });
  });

  group('typing on a physical keyboard', () {
    testWidgets('digits and delete work the same', (tester) async {
      await pump(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad2);
      await tester.pump();
      expect(find.text(formatCurrency(42)), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(find.text(formatCurrency(4)), findsOneWidget);
    });
  });

  group('when it is switched off', () {
    testWidgets('the keypad does nothing', (tester) async {
      await pump(tester, start: 100, enabled: false);

      await tester.tap(key('5'), warnIfMissed: false);
      await tester.pump();

      expect(find.text(formatCurrency(100)), findsOneWidget);
    });

    testWidgets('neither does a physical keyboard: an amount being sent must '
        'not change under it', (tester) async {
      await pump(tester, start: 100, enabled: false);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(find.text(formatCurrency(100)), findsOneWidget);
    });
  });
}
