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
import 'package:pn_pos/src/pos_receipt.dart';
import 'package:pn_pos/src/pos_tender.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/ledger_row.dart';
import 'package:pn_ui/src/widgets/state_view.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/print_receipt.dart';
import 'package:pos/sale/invoice_item.dart';
import 'package:pos/screens/common/print_flow.dart';
import 'package:pos/screens/common/tender_label.dart';
import 'package:pos/screens/till/pos_sheet.dart';
import 'package:pos/state/loadable.dart';

/// S11: one recorded sale, as a sheet over the list it was tapped in.
///
/// A sheet and not a page (`pos-sale-detail-page.tsx` is one): the shift's list keeps its place
/// and its scroll position, and closing the sheet is the whole way back.
///
/// Read-only except for printing (Q10): the official receipt can be sent again from here, the
/// same formatter and the same button as the screen that first said the sale went through
/// (`print_receipt.dart`, `done_screen.dart`). This is what replaces a queued sale's temporary
/// slip once it has a real number (`plan/offline-queue/README.md` D-Q3). Voiding is the web
/// app's, and is not built here.
Future<void> showSaleDetailSheet(
  BuildContext context, {
  required String saleId,
}) => showPosSheet<void>(
  context,
  heightFactor: 0.9,
  builder: (context) => SaleDetailSheet(saleId: saleId),
);

class SaleDetailSheet extends StatefulWidget {
  const SaleDetailSheet({super.key, required this.saleId});

  final String saleId;

  @override
  State<SaleDetailSheet> createState() => _SaleDetailSheetState();
}

class _SaleDetailSheetState extends State<SaleDetailSheet> {
  Loadable<POSSale>? _sale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sale != null) return;
    final client = AppScope.of(context).client;
    // Not awaited: the sheet reports its own state, and a bug it rethrows stays loud.
    _sale = Loadable(() => PosApi.salesGet(client, (id: widget.saleId)))
      ..load();
  }

  @override
  void dispose() {
    _sale?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final sale = _sale!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PosSheetHeader(title: l10n.saleDetailTitle),
        Expanded(
          child: ListenableBuilder(
            listenable: sale,
            builder: (context, _) => switch (sale.state) {
              Loading() => StateView.loading(label: l10n.commonLoading),
              Failed(:final error) => StateView(
                title: failedReadText(error, l10n.saleDetailLoadFailed),
                actionLabel: l10n.commonRetry,
                onAction: sale.load,
              ),
              Ready(:final data) => _SaleBody(sale: data),
            },
          ),
        ),
      ],
    );
  }
}

class _SaleBody extends StatelessWidget {
  const _SaleBody({required this.sale});

  final POSSale sale;

  Future<void> _print(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = L10n.of(context);
    return runPrint(
      context,
      successMessage: l10n.receiptSent,
      loadFailedMessage: l10n.receiptLoadFailed,
      analyticsEvent: 'receipt_printed',
      print: () => printReceipt(
        sale,
        client: services.client,
        printer: services.printer,
        store: services.store,
        l10n: l10n,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pn = context.pn;
    final theme = Theme.of(context).textTheme;
    final cashier = sale.cashier?.name;
    final table = sale.tableNumber;
    final queue = sale.queueNumber;
    final notes = sale.notes;
    final lines = posReceiptLines(
      invoiceItems: sale.invoice?.items.map(toInvoiceItem).toList(),
      fallbackName: l10n.saleDetailUnknownProduct,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(sale.number, style: theme.titleLarge),
        const SizedBox(height: 4),
        Text(
          formatDateTime(firstNonEmpty([sale.createdAt, sale.transactionDate])),
          style: theme.bodyMedium!.copyWith(color: pn.inkMuted),
        ),
        // In words, not only in colour: a voided sale that looks like a valid one is the mistake
        // this line is here to prevent.
        if (sale.status == POSSaleStatus.voided) ...[
          const SizedBox(height: 8),
          Text(
            l10n.saleDetailVoided,
            style: theme.titleSmall!.copyWith(color: pn.errorText),
          ),
        ],
        const SizedBox(height: 8),
        if (cashier != null && cashier.isNotEmpty)
          LedgerRow(label: l10n.saleDetailCashier, value: cashier),
        if (table != null && table.isNotEmpty)
          LedgerRow(label: l10n.posTableNumber, value: table),
        if (queue != null && queue.isNotEmpty)
          LedgerRow(label: l10n.posQueueNumber, value: queue),
        const SizedBox(height: 16),
        if (lines.isEmpty)
          Text(l10n.saleDetailNoItems, style: theme.bodyLarge)
        else
          for (final line in lines)
            LedgerRow(
              label: line.name,
              detail: _lineDetail(l10n, line),
              value: formatCurrency(line.total),
            ),
        const SizedBox(height: 16),
        LedgerRow(
          label: l10n.tillSubtotal,
          value: formatCurrency(sale.subtotal),
        ),
        if (sale.discountAmount > 0)
          LedgerRow(
            label: l10n.tillDiscount,
            value: '-${formatCurrency(sale.discountAmount)}',
          ),
        if (sale.taxAmount > 0)
          LedgerRow(
            label: l10n.saleDetailTax,
            value: formatCurrency(sale.taxAmount),
          ),
        LedgerRow(
          label: l10n.tillTotal,
          value: formatCurrency(sale.grandTotal),
          emphasized: true,
        ),
        ..._payments(context, l10n),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.saleDetailNotes, style: theme.labelLarge),
          const SizedBox(height: 4),
          Text(notes, style: theme.bodyLarge),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: PnTouch.min,
          child: OutlinedButton(
            onPressed: () => _print(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.print_outlined),
                const SizedBox(width: 8),
                Flexible(child: Text(l10n.receiptPrint)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// What was paid with, and what came back.
  ///
  /// `tendered_amount` and `change_amount` total **every** method, not cash specifically, so
  /// "received" is only shown for a sale paid with one method and that method cash: on a split
  /// sale, or a transfer, it would read as if the customer had handed over cash they did not
  /// (`pos-receipt.tsx`). The change is shown whenever cash was one of the methods, because only
  /// the drawer gives change.
  List<Widget> _payments(BuildContext context, L10n l10n) {
    final payments = sale.payments;
    if (payments == null || payments.isEmpty) return const [];

    final hasCash = hasCashTender(payments.map((p) => p.method));
    final isSingleCash = payments.length == 1 && hasCash;
    return [
      const SizedBox(height: 16),
      Text(
        l10n.saleDetailPayments,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      for (final payment in payments)
        LedgerRow(
          label: tenderMethodLabel(l10n, payment.method),
          detail: payment.reference,
          value: formatCurrency(payment.amount),
        ),
      if (isSingleCash)
        LedgerRow(
          label: l10n.saleDetailTendered,
          value: formatCurrency(sale.tenderedAmount),
        ),
      if (hasCash)
        LedgerRow(
          label: l10n.posChangeDue,
          value: formatCurrency(sale.changeAmount),
        ),
    ];
  }
}

/// `quantity x price`, and the discount the customer got on the line when there is one.
String _lineDetail(L10n l10n, ReceiptLine line) {
  final base = '${jsNumber(line.quantity)} x ${formatCurrency(line.price)}';
  if (line.discount <= 0) return base;
  return '$base\n${l10n.tillDiscount} -${formatCurrency(line.discount)}';
}
