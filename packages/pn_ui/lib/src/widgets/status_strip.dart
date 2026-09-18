/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_ui/src/theme/app_theme.dart';

/// One fact in a [StatusStrip], and what happens when it is tapped.
///
/// A record and not two positional parameters, so a caller building a list of these reads as
/// data rather than as a row of unlabelled arguments. `onTap` is null for most items (who is
/// signed in, which outlet): most facts are just facts, and only one so far — the offline
/// queue's count — is also a way into a screen.
typedef StatusStripItem = ({String label, VoidCallback? onTap});

/// One line of plain facts across the top of a screen: who is signed in, which outlet, which
/// shift.
///
/// A fixed 40 dp, so it never grows into the catalog under it, and it scrolls sideways when the
/// facts are wider than the screen rather than wrapping. [items] are given by the caller,
/// already in the cashier's language.
class StatusStrip extends StatelessWidget {
  const StatusStrip({super.key, required this.items});

  final List<StatusStripItem> items;

  static const height = 40.0;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final pn = context.pn;

    return SizedBox(
      height: height,
      child: ColoredBox(
        color: pn.surfaceMuted,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  VerticalDivider(
                    width: 25,
                    thickness: 1,
                    indent: 10,
                    endIndent: 10,
                    color: pn.border,
                  ),
                // `InkWell(onTap: null)` either way, rather than a bare `Text` for the untappable
                // ones: a fact that becomes tappable later does not need its render tree
                // restructured, and a disabled `InkWell` already draws and behaves exactly like
                // plain text.
                InkWell(
                  onTap: items[i].onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      items[i].label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
