/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/widgets/keypad_shortcuts.dart';

import '../support/harness.dart';

// The physical keyboard of a tablet in a dock, or a keypad on a USB numpad, drives the same
// callbacks as the on-screen keypad. (Verification V4 in `plan/ui/findings.md`: this is where
// it is proved that key events reach a widget under `flutter test`.)

class Rig {
  final digits = <String>[];
  var backspaces = 0;
  var submits = 0;

  Widget app({Widget child = const SizedBox(), bool submit = true}) => harness(
        KeypadShortcuts(
          onDigit: digits.add,
          onBackspace: () => backspaces++,
          onSubmit: submit ? () => submits++ : null,
          child: child,
        ),
      );
}

void main() {
  group('the physical keyboard', () {
    testWidgets('types digits with the number row, without a tap first', (
      tester,
    ) async {
      final rig = Rig();
      await tester.pumpWidget(rig.app());

      for (final key in [
        LogicalKeyboardKey.digit0,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit9,
      ]) {
        await tester.sendKeyEvent(key);
      }

      expect(rig.digits, ['0', '5', '9']);
    });

    testWidgets('types digits with the numpad', (tester) async {
      final rig = Rig();
      await tester.pumpWidget(rig.app());

      await tester.sendKeyEvent(LogicalKeyboardKey.numpad1);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad0);

      expect(rig.digits, ['1', '0']);
    });

    testWidgets('takes a digit back, and keeps taking them back while held', (
      tester,
    ) async {
      final rig = Rig();
      await tester.pumpWidget(rig.app());

      await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.backspace);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.backspace);

      expect(rig.backspaces, 2);
    });

    testWidgets('does not type a digit again while its key is held', (
      tester,
    ) async {
      final rig = Rig();
      await tester.pumpWidget(rig.app());

      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit7);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.digit7);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.digit7);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit7);

      expect(rig.digits, ['7']);
    });

    testWidgets('submits on Enter, and on the numpad Enter', (tester) async {
      final rig = Rig();
      await tester.pumpWidget(rig.app());

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);

      expect(rig.submits, 2);
    });

    testWidgets('ignores Enter when nothing is to be submitted', (
      tester,
    ) async {
      final rig = Rig();
      await tester.pumpWidget(rig.app(submit: false));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(rig.submits, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ignores every other key', (tester) async {
      final rig = Rig();
      await tester.pumpWidget(rig.app());

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      expect(rig.digits, isEmpty);
      expect(rig.backspaces, 0);
      expect(rig.submits, 0);
    });

    testWidgets('leaves a shortcut alone: Ctrl and a digit is not a digit', (
      tester,
    ) async {
      final rig = Rig();
      await tester.pumpWidget(rig.app());

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(rig.digits, isEmpty);
    });

    testWidgets('leaves a text field its own digits', (tester) async {
      // A memo field on the same screen: what is typed there is text, not an amount. It is
      // focused the way a cashier does it, by a tap.
      final rig = Rig();
      await tester.pumpWidget(rig.app(child: const TextField()));
      await tester.tap(find.byType(TextField));
      await tester.pump();
      // The precondition, so this cannot pass by the field never having had focus.
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        focused.widget is EditableText ||
            focused.findAncestorWidgetOfExactType<EditableText>() != null,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);

      expect(rig.digits, isEmpty);
      expect(rig.backspaces, 0);
    });
  });
}
