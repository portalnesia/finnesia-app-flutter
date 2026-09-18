/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_ui/src/theme/tokens.dart';

/// A number pad for an amount, drawn on screen so the tablet's keyboard never has to open over
/// the till.
///
/// It only reports keys: the screen owns the amount and decides what a digit does to it. The
/// physical keyboard is [KeypadShortcuts], which reports through the same two callbacks.
///
/// The double zero is there because amounts are in rupiah: 50.000 is a 5 and a `00` and a `00`.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.backspaceLabel,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// What a screen reader says for the delete key, which has no text on it.
  final String backspaceLabel;

  final bool enabled;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    Widget digit(String label) => _key(
          context,
          onPressed: enabled ? () => onDigit(label) : null,
          child: Text(label, style: Theme.of(context).textTheme.titleLarge),
        );

    Widget row(List<Widget> keys) => Row(
          children: [
            for (var i = 0; i < keys.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(child: keys[i]),
            ],
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        const SizedBox(height: _gap),
        row([digit('4'), digit('5'), digit('6')]),
        const SizedBox(height: _gap),
        row([digit('7'), digit('8'), digit('9')]),
        const SizedBox(height: _gap),
        row([
          digit('00'),
          digit('0'),
          _key(
            context,
            onPressed: enabled ? onBackspace : null,
            child:
                Icon(Icons.backspace_outlined, semanticLabel: backspaceLabel),
          ),
        ]),
      ],
    );
  }

  Widget _key(
    BuildContext context, {
    required VoidCallback? onPressed,
    required Widget child,
  }) =>
      SizedBox(
        height: PnTouch.primary,
        child: OutlinedButton(onPressed: onPressed, child: child),
      );
}
