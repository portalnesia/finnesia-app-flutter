/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/js_compat.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/widgets/ledger_row.dart';
import 'package:pn_ui/src/widgets/state_view.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/common/entry_row.dart';
import 'package:pos/screens/common/paged_list.dart';
import 'package:pos/screens/common/tender_label.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/paged_loadable.dart';

/// The drawer's figures: who has it, every term the expected cash is made of, and what was taken
/// per payment method.
///
/// `expected_cash` is what the drawer is counted against, so it is the emphasised row and the one
/// that has to be legible from arm's length. The terms above it are listed because a cashier who
/// has to explain a variance can only do that by looking at what made the figure.
class FiguresPane extends StatelessWidget {
  const FiguresPane({super.key, required this.summary});

  final Loadable<ShiftSummaryResponse> summary;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return ListenableBuilder(
      listenable: summary,
      builder: (context, _) => switch (summary.state) {
        Loading() => StateView.loading(label: l10n.commonLoading),
        Failed(:final error) => StateView(
          title: failedReadText(error, l10n.shiftDetailLoadFailed),
          actionLabel: l10n.commonRetry,
          onAction: summary.load,
        ),
        Ready(:final data) => _figures(context, l10n, data),
      },
    );
  }

  Widget _figures(BuildContext context, L10n l10n, ShiftSummaryResponse s) {
    final theme = Theme.of(context).textTheme;
    final cashier = s.cashierName;
    final outlet = s.outletName;
    final closedAt = s.closedAt;
    final counted = s.countedCash;
    final variance = s.cashVariance;
    final notes = s.notes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        LedgerRow(label: l10n.shiftNumberLabel, value: s.number),
        LedgerRow(
          label: l10n.shiftOpenedAtLabel,
          value: formatDateTime(s.openedAt),
        ),
        if (closedAt != null && closedAt.isNotEmpty)
          LedgerRow(
            label: l10n.shiftDetailClosedAtLabel,
            value: formatDateTime(closedAt),
          ),
        if (cashier != null && cashier.isNotEmpty)
          LedgerRow(label: l10n.shiftCashierLabel, value: cashier),
        if (outlet != null && outlet.isNotEmpty)
          LedgerRow(label: l10n.menuOutletLabel, value: outlet),
        _Heading(l10n.shiftDetailFiguresTitle),
        LedgerRow(
          label: l10n.shiftDetailTransactions,
          value: '${s.totalTransactions}',
        ),
        LedgerRow(
          label: l10n.shiftDetailTotalSales,
          value: formatCurrency(s.totalSales),
        ),
        LedgerRow(
          label: l10n.shiftDetailOpeningCash,
          value: formatCurrency(s.openingCash),
        ),
        LedgerRow(
          label: l10n.shiftDetailCashIn,
          value: formatCurrency(s.cashIn),
        ),
        // One row for both, as the printed report has it (`formatShiftReportEscPos`): a drop is
        // cash leaving the drawer for the safe, and the cashier counting the drawer treats it
        // the same as cash out.
        LedgerRow(
          label: l10n.shiftDetailCashOutAndDrop,
          value: formatCurrency(s.cashOut + s.cashDrop),
        ),
        LedgerRow(
          label: l10n.shiftDetailExpectedCash,
          value: formatCurrency(s.expectedCash),
          emphasized: true,
        ),
        if (counted != null)
          LedgerRow(
            label: l10n.shiftDetailCountedCash,
            value: formatCurrency(counted),
          ),
        // In words, not only in a sign or a colour, and exactly as it fell: rounding or hiding a
        // small difference is how a till loses money quietly.
        if (variance != null)
          LedgerRow(
            label: l10n.shiftDetailVarianceLabel,
            value: varianceText(l10n, variance),
          ),
        _Heading(l10n.shiftDetailByMethodTitle),
        if (s.salesByMethod.isEmpty)
          Text(l10n.shiftDetailNoSales, style: theme.bodyLarge)
        else
          for (final entry in s.salesByMethod.entries)
            LedgerRow(
              label: tenderMethodLabel(l10n, entry.key),
              value: formatCurrency(entry.value),
            ),
        if (notes != null && notes.isNotEmpty) ...[
          _Heading(l10n.shiftDetailNotes),
          Text(notes, style: theme.bodyLarge),
        ],
      ],
    );
  }
}

String varianceText(L10n l10n, num variance) {
  if (variance < 0) {
    return l10n.shiftDetailVarianceShort(formatCurrency(variance.abs()));
  }
  if (variance > 0) {
    return l10n.shiftDetailVarianceOver(formatCurrency(variance));
  }
  return l10n.shiftDetailVarianceNone;
}

/// The sales the closing figures are made of, scrolled a page at a time.
///
/// A report the cashier cannot drill into is a number they have to take on trust, and a long day
/// has hundreds of sales, so the list asks for the next page as the end comes near.
class SalesPane extends StatelessWidget {
  const SalesPane({super.key, required this.sales, required this.onOpen});

  final PagedLoadable<POSSale> sales;
  final ValueChanged<POSSale> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pn = context.pn;
    final theme = Theme.of(context).textTheme;
    return PagedListPane<POSSale>(
      source: sales,
      listKey: const Key('sales-list'),
      failedTitle: l10n.shiftDetailLoadFailed,
      emptyTitle: l10n.shiftDetailNoSales,
      moreFailedLabel: l10n.shiftDetailMoreFailed,
      itemBuilder: (context, sale) => EntryRow(
        title: sale.number,
        lines: [
          Text(
            formatDateTime(
              firstNonEmpty([sale.createdAt, sale.transactionDate]),
            ),
            style: theme.bodyMedium!.copyWith(color: pn.inkMuted),
          ),
          if (sale.status == POSSaleStatus.voided)
            Text(
              l10n.shiftDetailSaleVoided,
              style: theme.bodyMedium!.copyWith(color: pn.errorText),
            ),
        ],
        value: formatCurrency(sale.grandTotal),
        onTap: () => onOpen(sale),
      ),
    );
  }
}

/// The cash that moved in and out of the drawer without a sale: the entries behind the cash in,
/// cash out and drop totals.
class MovementsPane extends StatelessWidget {
  const MovementsPane({super.key, required this.movements});

  final Loadable<List<POSCashMovement>> movements;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return ListenableBuilder(
      listenable: movements,
      builder: (context, _) => switch (movements.state) {
        Loading() => StateView.loading(label: l10n.commonLoading),
        Failed(:final error) => StateView(
          title: failedReadText(error, l10n.shiftDetailLoadFailed),
          actionLabel: l10n.commonRetry,
          onAction: movements.load,
        ),
        Ready(:final data) when data.isEmpty => StateView(
          title: l10n.shiftDetailNoMovements,
        ),
        Ready(:final data) => _list(context, l10n, data),
      },
    );
  }

  Widget _list(BuildContext context, L10n l10n, List<POSCashMovement> data) {
    final pn = context.pn;
    final theme = Theme.of(context).textTheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: data.length,
      itemBuilder: (context, i) {
        final movement = data[i];
        final creator = movement.creator?.name;
        final when = formatDateTime(movement.createdAt);
        return EntryRow(
          title: switch (movement.type) {
            CashMovementType.cashIn => l10n.shiftDetailCashIn,
            CashMovementType.cashOut => l10n.shiftDetailCashOut,
            CashMovementType.drop => l10n.shiftDetailCashDrop,
          },
          lines: [
            Text(movement.reason, style: theme.bodyMedium),
            Text(
              creator != null && creator.isNotEmpty ? '$when · $creator' : when,
              style: theme.bodyMedium!.copyWith(color: pn.inkMuted),
            ),
          ],
          // Signed the way it hits the drawer, so the column reads as a running account.
          value:
              '${movement.type == CashMovementType.cashIn ? '+' : '-'}'
              '${formatCurrency(movement.amount)}',
        );
      },
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 4),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    ),
  );
}
