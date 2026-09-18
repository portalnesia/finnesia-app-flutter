/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_ui/src/widgets/keypad.dart';
import 'package:pn_ui/src/widgets/keypad_shortcuts.dart';
import 'package:pn_ui/src/widgets/money_text.dart';

/// An amount of rupiah, typed on the on-screen keypad or a physical keyboard, so the tablet's own
/// keyboard never has to open over the figures the cashier is reading.
///
/// It holds the amount itself, starting from [initial], and reports every change through
/// [onChanged]. Held here and not by the screen because a key is applied to what the amount is
/// *now*: two keys that arrive before the screen has rebuilt would otherwise both be applied to the
/// old amount, and a digit would be lost.
class AmountEntry extends StatefulWidget {
  const AmountEntry({
    super.key,
    required this.label,
    required this.onChanged,
    required this.backspaceLabel,
    this.initial = 0,
    this.enabled = true,
  });

  final String label;
  final int initial;
  final ValueChanged<int> onChanged;

  /// What a screen reader says for the delete key, which has no text on it.
  final String backspaceLabel;

  final bool enabled;

  @override
  State<AmountEntry> createState() => _AmountEntryState();
}

class _AmountEntryState extends State<AmountEntry> {
  /// A rupiah amount longer than this is a slip of the thumb, and would not fit the screen.
  static const _maxDigits = 12;

  late int _value = widget.initial;

  void _set(int next) {
    setState(() => _value = next);
    widget.onChanged(next);
  }

  void _type(String digit) {
    if (!widget.enabled) return;
    // Digits as text, so the double-zero key is two zeros and a leading zero carries no value.
    final next = '${_value == 0 ? '' : _value}$digit'.replaceFirst(
      RegExp(r'^0+'),
      '',
    );
    if (next.length > _maxDigits) return;
    _set(next.isEmpty ? 0 : int.parse(next));
  }

  void _backspace() {
    if (!widget.enabled || _value == 0) return;
    _set(_value ~/ 10);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return KeypadShortcuts(
      onDigit: _type,
      onBackspace: _backspace,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: theme.labelLarge),
          const SizedBox(height: 4),
          MoneyText(formatCurrency(_value), style: theme.headlineLarge),
          const SizedBox(height: 16),
          Keypad(
            onDigit: _type,
            onBackspace: _backspace,
            backspaceLabel: widget.backspaceLabel,
            enabled: widget.enabled,
          ),
        ],
      ),
    );
  }
}
