/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/ledger_row.dart';
import 'package:pn_ui/src/widgets/money_text.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/print_receipt.dart';
import 'package:pos/screens/common/print_flow.dart';

/// S7: the change, after the sale is recorded — or after it has been written to the queue but
/// not yet sent.
///
/// The whole screen, and it waits to be dismissed. It used to arrive as a toast that faded on
/// its own while the cashier was counting out notes, and a wrong change figure is money out of
/// the drawer.
///
/// The receipt is offered here, as the web app does (D2). It is the quieter of the two buttons:
/// the way on to the next customer stays the main one, and printing leaves the screen exactly as it
/// was, so a receipt that will not come out costs the cashier nothing but the receipt.
class DoneScreen extends StatelessWidget {
  const DoneScreen({
    super.key,
    required this.onNewSale,
    this.sale,
    this.pending,
  }) : assert(
         sale != null || pending != null,
         'a done screen shows either a recorded sale or a queued one',
       );

  /// The sale the server recorded. Every figure here is the server's, not a local
  /// subtraction: if the two ever disagree, the drawer is short and the app must not hide it.
  ///
  /// Null on a sale that has not been sent — there is no server record yet.
  final POSSale? sale;

  /// The queued sale, when the server has not confirmed it.
  ///
  /// The figures come from the entry's own copy, which the till wrote at the moment of payment:
  /// a sale with no server record has to be printed and totalled from what the tablet knows
  /// (`plan/offline-queue/README.md` §7, D-Q3).
  final PendingSale? pending;

  final VoidCallback onNewSale;

  /// The change the cashier reads out.
  ///
  /// The server's figure when there is one, and the tablet's otherwise. Two sources because the
  /// two cases are genuinely different: for a recorded sale the server's number is the truth,
  /// and for a queued one it is the only number there is.
  num get _change => sale?.changeAmount ?? pending!.receipt.changeAmount;

  num get _grandTotal => sale?.grandTotal ?? pending!.receipt.grandTotal;

  num get _tendered => sale?.tenderedAmount ?? pending!.receipt.tenderedAmount;

  Future<void> _print(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = L10n.of(context);
    final recorded = sale;
    if (recorded == null) {
      return runPrint(
        context,
        successMessage: l10n.receiptSent,
        loadFailedMessage: l10n.receiptLoadFailed,
        analyticsEvent: 'pending_receipt_printed',
        // The temporary receipt: the same formatter, with the "not sent" marker where the
        // transaction number goes, and the short `client_ref` so the slip can be matched to the
        // sale once it does have a number (README D-Q3).
        print: () => printPendingReceipt(
          pending!,
          printer: services.printer,
          store: services.store,
          l10n: l10n,
        ),
      );
    }
    return runPrint(
      context,
      successMessage: l10n.receiptSent,
      loadFailedMessage: l10n.receiptLoadFailed,
      analyticsEvent: 'receipt_printed',
      print: () => printReceipt(
        recorded,
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
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.posPaymentSuccess,
                    style: theme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // The change is the one thing the cashier has to read, so it is the one
                  // thing that is large.
                  Text(
                    l10n.posChangeTitle,
                    style: theme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  MoneyText(
                    key: const Key('change-amount'),
                    formatCurrency(_change),
                    style: theme.displaySmall,
                  ),
                  const SizedBox(height: 24),

                  // What the figure came from, so a cashier who doubts it can check it
                  // without walking to the dashboard.
                  if (sale != null)
                    LedgerRow(label: l10n.posReceiptNumber, value: sale!.number)
                  else ...[
                    // No transaction number: only the server issues one, and inventing one
                    // would collide with a real sale's (`plan/offline-queue/README.md` D-Q3).
                    // The short ref is what ties this slip to the sale later.
                    LedgerRow(
                      label: l10n.posReceiptNumber,
                      value: l10n.posReceiptTemporary,
                    ),
                    LedgerRow(
                      label: l10n.posQueuedRef,
                      value: shortRef(pending!.clientRef),
                    ),
                  ],
                  LedgerRow(
                    label: l10n.posGrandTotal,
                    value: formatCurrency(_grandTotal),
                  ),
                  LedgerRow(
                    label: l10n.posCashTendered,
                    value: formatCurrency(_tendered),
                  ),

                  if (pending != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.posOfflineNotSaved,
                      key: const Key('done-not-sent'),
                      style: theme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    height: PnTouch.primary,
                    child: FilledButton(
                      onPressed: onNewSale,
                      child: Text(l10n.posNewSale),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
