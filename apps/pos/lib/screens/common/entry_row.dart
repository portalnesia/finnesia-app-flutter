/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/money_text.dart';

/// A title, quieter lines under it, and an amount at the right edge; tappable when [onTap] is
/// given.
///
/// The ledger row's shape (`LedgerRow`), except that the lines under the title are widgets of
/// their own: a voided sale's "Dibatalkan" and a movement's reason each have to be a piece of text
/// a reader can find.
class EntryRow extends StatelessWidget {
  const EntryRow({
    super.key,
    required this.title,
    required this.lines,
    required this.value,
    this.onTap,
  });

  final String title;
  final List<Widget> lines;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: pn.border)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: onTap == null ? 0 : PnTouch.primary,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.bodyLarge),
                      ...lines,
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: MoneyText(value, style: theme.bodyLarge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
