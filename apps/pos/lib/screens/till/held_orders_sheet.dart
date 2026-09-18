/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_calculations.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/state_view.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/till/pos_sheet.dart';
import 'package:pos/till/hold_controller.dart';

/// S9: the baskets parked mid-sale.
///
/// A held basket never reaches the server: it is not a sale until it is paid for. So the list is
/// short and plain: the cashier needs the name, the size and the moment it was parked, and a way
/// to take it back or throw it away.
Future<void> showHeldOrdersSheet(
  BuildContext context, {
  required HoldController hold,
  required Future<void> Function(HeldOrder order) onResume,
}) => showPosSheet<void>(
  context,
  heightFactor: 0.9,
  builder: (context) => HeldOrdersSheet(hold: hold, onResume: onResume),
);

class HeldOrdersSheet extends StatelessWidget {
  const HeldOrdersSheet({
    super.key,
    required this.hold,
    required this.onResume,
  });

  final HoldController hold;
  final Future<void> Function(HeldOrder order) onResume;

  /// Throwing a basket away loses a sale in progress, so it asks first. The safe answer is the quiet
  /// one and the destructive one is the filled one, so it is not the easier one to hit.
  Future<void> _confirmDrop(BuildContext context, HeldOrder order) async {
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.heldDropTitle),
        content: Text(l10n.heldDropDesc(order.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.heldDrop),
          ),
        ],
      ),
    );
    if (confirmed == true) await hold.drop(order);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PosSheetHeader(title: l10n.heldTitle),
        Expanded(
          child: ListenableBuilder(
            listenable: hold,
            builder: (context, _) {
              final orders = hold.waiting;
              if (orders.isEmpty) {
                return StateView(title: l10n.heldEmpty);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: orders.length,
                itemBuilder: (context, i) => _HeldRow(
                  order: orders[i],
                  onResume: () => onResume(orders[i]),
                  onDrop: () => _confirmDrop(context, orders[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeldRow extends StatelessWidget {
  const _HeldRow({
    required this.order,
    required this.onResume,
    required this.onDrop,
  });

  final HeldOrder order;
  final VoidCallback onResume;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final pieces = order.lines.fold<num>(0, (sum, l) => sum + l.qty);
    final total = totalsOfLines(order.lines).grandTotal;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: pn.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        // The name and what it holds above, the two actions under it: side by side they compete
        // for the width, and at 360 dp with large text one of them lost by 11 px (measured).
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.label, style: theme.titleMedium),
            Text(
              '${l10n.tillItemCount(pieces.toInt())} · ${formatCurrency(total)}',
              style: theme.bodyMedium,
            ),
            Text(
              formatDateTime(order.heldAt),
              style: theme.bodyMedium!.copyWith(color: pn.inkMuted),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  SizedBox(
                    height: PnTouch.min,
                    child: TextButton(
                      onPressed: onDrop,
                      child: Text(l10n.heldDrop),
                    ),
                  ),
                  SizedBox(
                    height: PnTouch.min,
                    child: FilledButton(
                      onPressed: onResume,
                      child: Text(l10n.heldResume),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
