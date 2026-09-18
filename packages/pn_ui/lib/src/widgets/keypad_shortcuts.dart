/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

/// Lets the physical keyboard drive an amount the way [Keypad] does: digits from the number row
/// and the numpad, Backspace, and Enter to submit.
///
/// It takes focus when it appears, so a cashier with a keyboard can type without tapping first.
class KeypadShortcuts extends StatelessWidget {
  const KeypadShortcuts({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.child,
    this.onSubmit,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onSubmit;
  final Widget child;

  // The number row and the numpad both type digits.
  static final _digits = {
    LogicalKeyboardKey.digit0: '0',
    LogicalKeyboardKey.digit1: '1',
    LogicalKeyboardKey.digit2: '2',
    LogicalKeyboardKey.digit3: '3',
    LogicalKeyboardKey.digit4: '4',
    LogicalKeyboardKey.digit5: '5',
    LogicalKeyboardKey.digit6: '6',
    LogicalKeyboardKey.digit7: '7',
    LogicalKeyboardKey.digit8: '8',
    LogicalKeyboardKey.digit9: '9',
    LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.numpad9: '9',
  };

  static final _enter = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (_isTyping() || _isShortcut()) return KeyEventResult.ignored;

    final key = event.logicalKey;
    // Held Backspace keeps deleting; a held digit or Enter must not repeat, or one press of 7
    // on a slow tablet is 7777.
    if (key == LogicalKeyboardKey.backspace) {
      onBackspace();
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final digit = _digits[key];
    if (digit != null) {
      onDigit(digit);
      return KeyEventResult.handled;
    }
    if (_enter.contains(key) && onSubmit != null) {
      onSubmit!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // A text field on the same screen (a memo) owns its keys: digits there are text.
  bool _isTyping() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context != null &&
        (context.widget is EditableText ||
            context.findAncestorWidgetOfExactType<EditableText>() != null);
  }

  // Ctrl+1 and its kind belong to whatever shortcut the platform or the app gives them.
  bool _isShortcut() {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed;
  }

  @override
  Widget build(BuildContext context) =>
      Focus(autofocus: true, onKeyEvent: _onKey, child: child);
}
