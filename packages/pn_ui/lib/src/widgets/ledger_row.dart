/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/widgets/money_text.dart';

/// A line of a ledger: a label on the left, an amount in tabular figures on the right, a
/// hairline under.
///
/// The one motif of the app (`plan/ui/README.md` §3.3). Stacked, the amounts line up at one right
/// edge, and that column of aligned figures is the whole decoration.
///
/// [label], [detail] and [value] are all given by the caller: the amount is already formatted
/// (see [MoneyText]) and no text is looked up here.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.emphasized = false,
  });

  final String label;

  /// The amount, already formatted.
  final String value;

  /// A second, quieter line under the label: the quantity and unit price of a cart line.
  final String? detail;

  /// The total of a group: bigger and bolder than the rows above it.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final main = emphasized
        ? theme.titleLarge!.copyWith(fontWeight: FontWeight.w700)
        : theme.bodyLarge!;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: pn.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        // One thing to a screen reader: "Subtotal, Rp 50.000", not two unrelated texts.
        child: MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3 to 2: a long product name wraps in its share, and the amount keeps its own.
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: main,
                    ),
                    if (detail != null)
                      Text(
                        detail!,
                        style: theme.bodyMedium!.copyWith(color: pn.inkMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: MoneyText(value, style: main)),
            ],
          ),
        ),
      ),
    );
  }
}
