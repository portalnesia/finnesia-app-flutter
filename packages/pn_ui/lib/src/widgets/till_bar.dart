/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';

/// The till's one piece of chrome: the way out to the Menu.
///
/// Ported from the first control of `till-bar.tsx`, which is a bar of its own and not the status
/// strip. The two say different things: the status strip is *facts* — who is signed in, which
/// shift, which outlet (`README.md` §3.2, R3 caps it at four) — and this is a *way out of the
/// screen*. Putting a button in the strip would make it a navigation bar with a quota, which is
/// the one thing R3 says it must not become.
///
/// **Always present, including while the shift gate is up.** The source is explicit about why:
/// a cashier who cannot sell yet still has to be able to change the language or sign out. A
/// tablet whose cashier left without signing out has no other way back to the login screen.
///
/// **Icon and word, in ink.** Both halves matter and they are there for different reasons:
///
/// - The icon is the affordance a cashier recognises without reading, and the word says where it
///   goes. The source does the same (`till-bar.tsx`).
/// - The **colour** is the part that had to be fixed. `TextButton` takes its foreground from
///   `colorScheme.primary`, and this theme puts the accent there, so the button was drawn in
///   amber: the accent is the one primary action per screen (R-29), and on the till that is Pay.
///   A navigation control wearing it competes with the button that takes money, and it is what
///   made the bar read as a web header rather than as part of the app. It is ink now.
class TillBar extends StatelessWidget {
  const TillBar({
    super.key,
    required this.label,
    required this.onOpen,
    this.trailingLabel,
    this.trailingIcon,
    this.onTrailing,
  });

  /// Already in the cashier's language. `pn_ui` never reads a translation itself
  /// (`style.md` §7.1), and this widget is prop-driven for that reason.
  final String label;

  final VoidCallback onOpen;

  /// A second way out, at the far end of the row: the shift detail. Drawn only when all three
  /// are given.
  final String? trailingLabel;
  final IconData? trailingIcon;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    final pn = context.pn;
    final trailingLabel = this.trailingLabel;
    final trailingIcon = this.trailingIcon;
    final onTrailing = this.onTrailing;

    return Material(
      color: pn.background,
      child: SizedBox(
        height: PnTouch.primary,
        child: Row(
          children: [
            const SizedBox(width: 4),
            _action(context, Icons.menu, label, onOpen),
            const Spacer(),
            if (trailingLabel != null &&
                trailingIcon != null &&
                onTrailing != null) ...[
              _action(context, trailingIcon, trailingLabel, onTrailing),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }

  /// The word and the icon in landscape; the icon alone in portrait, where two words would crowd a
  /// narrow row. The word is still there as the tooltip, which is also what a screen reader reads.
  Widget _action(
    BuildContext context,
    IconData icon,
    String text,
    VoidCallback onPressed,
  ) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PnRadius.control),
    );
    // Ink, not `colorScheme.primary`: the theme puts the accent there, and the accent belongs to
    // Pay.
    final ink = context.pn.ink;

    if (MediaQuery.orientationOf(context) == Orientation.portrait) {
      return IconButton(
        onPressed: onPressed,
        tooltip: text,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.square(PnTouch.min),
          shape: shape,
        ),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: TextButton.styleFrom(
        foregroundColor: ink,
        // The whole height of the bar is the target, not just the glyph and the word.
        minimumSize: const Size(0, PnTouch.min),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: Theme.of(context).textTheme.titleSmall,
        shape: shape,
      ),
    );
  }
}
