/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_shift.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/ledger_row.dart';
import 'package:pos/l10n/app_localizations.dart';

/// A shift is open at this outlet, and it is the cashier's own.
///
/// It is shown before the till rather than walked through, because a shift left open overnight
/// used to look exactly like a fresh one, and the cashier kept selling into yesterday's
/// reconciliation. Continuing is a decision, and this is where it is made.
///
/// There is no cashier row: this only shows for the cashier who holds the shift, so it would
/// always print the name of the person reading it.
///
/// There is no close button yet. Closing a drawer is its own screen (C9), and a button that leads
/// nowhere is a dead control.
class AlreadyOpenPanel extends StatelessWidget {
  const AlreadyOpenPanel({
    super.key,
    required this.shift,
    required this.onContinue,
  });

  final POSShift shift;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final notice = openShiftNotice(
      number: shift.number,
      openedAt: shift.openedAt,
    );

    return _Panel(
      title: l10n.shiftOpenTitle,
      description: notice.stale ? l10n.shiftOpenStaleDesc : l10n.shiftOpenDesc,
      facts: [
        LedgerRow(label: l10n.shiftNumberLabel, value: shift.number),
        LedgerRow(
          label: l10n.shiftOpenedAtLabel,
          value: formatDateTime(shift.openedAt),
        ),
        LedgerRow(
          label: l10n.shiftOpeningCashLabel,
          value: formatCurrency(shift.openingCash),
        ),
      ],
      action: SizedBox(
        height: PnTouch.primary,
        child: FilledButton(
          onPressed: onContinue,
          child: Text(l10n.shiftContinue(shift.number)),
        ),
      ),
    );
  }
}

/// A shift is open at this outlet, and it is someone else's.
///
/// No button at all, not a disabled one: the only ways out are that cashier closing it, or an
/// override (C9), and neither is something this screen can do yet.
class HeldByOtherPanel extends StatelessWidget {
  const HeldByOtherPanel({super.key, required this.shift});

  final POSShift shift;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final name = shift.cashier?.name;
    // An empty name would print "opened by  and is still open".
    final holder = name == null || name.isEmpty
        ? l10n.shiftUnknownCashier
        : name;

    return _Panel(
      title: l10n.shiftHeldTitle,
      description: l10n.shiftHeldDesc(shift.number, holder),
      facts: [
        LedgerRow(label: l10n.shiftNumberLabel, value: shift.number),
        LedgerRow(
          label: l10n.shiftOpenedAtLabel,
          value: formatDateTime(shift.openedAt),
        ),
        LedgerRow(label: l10n.shiftCashierLabel, value: holder),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.description,
    required this.facts,
    this.action,
  });

  final String title;
  final String description;
  final List<Widget> facts;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: theme.headlineMedium),
        ),
        const SizedBox(height: 8),
        Text(description, style: theme.bodyMedium),
        const SizedBox(height: 24),
        ...facts,
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    );
  }
}
