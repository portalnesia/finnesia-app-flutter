/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/endpoints/tenant.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/print_settings.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/printer/receipt.dart';
import 'package:pos/sale/invoice_item.dart';

/// Prints the customer receipt of [sale] to the paired printer.
///
/// A sale that came without its invoice or its payments is read again from the single-sale
/// endpoint, which loads them: printed as it is, it would be a receipt of nothing bought. That
/// read failing is the caller's (`ApiError`, `TransportException`): guessing at the goods would
/// hand a customer a wrong receipt.
///
/// The name of the outlet and the footer are the shop's, and optional: neither can be read
/// without the network, and neither is a reason to send the customer away with no receipt.
///
/// Throws [PrinterException] like `printDocument`.
Future<void> printReceipt(
  POSSale sale, {
  required ApiClient client,
  required PrinterPort printer,
  required StorePort store,
  required L10n l10n,
}) async {
  final complete = sale.invoice != null && sale.payments != null
      ? sale
      : await PosApi.salesGet(client, (id: sale.id));
  final (settings, outletName) = await (
    readPrintSettings(client),
    _readOutletName(client, sale.outletId),
  ).wait;
  await printDocument(
    receiptBytes(
      complete,
      l10n: l10n,
      outletName: outletName,
      footerText: settings?.receiptFooterText,
    ),
    printer: printer,
    store: store,
  );
}

Future<String?> _readOutletName(ApiClient client, String outletId) async {
  try {
    return (await TenantApi.outletsGet(client, (id: outletId))).name;
  } on ApiError {
    return null;
  } on TransportException {
    return null;
  }
}

/// The last six characters of a `client_ref`, which is what ties a temporary receipt to its sale.
///
/// A ULID is 26 characters and its **first** ten are the millisecond it was minted at, so a slip
/// carrying the head of the ref would show two sales rung up in the same second as the same code.
/// The tail is the random part, and six characters of Crockford base32 is 30 bits — far more than
/// a shift's worth of sales needs to stay apart, and short enough to read off a slip.
String shortRef(String clientRef) => clientRef.length <= 6
    ? clientRef
    : clientRef.substring(clientRef.length - 6);

/// Prints the **temporary** receipt of a sale that has not reached the server.
///
/// The same formatter as the recorded one (`formatReceiptEscPos`, ported byte for byte), given
/// what the tablet knows. Two things differ, and both are deliberate
/// (`plan/offline-queue/README.md` D-Q3):
///
/// - **No transaction number.** Only the server issues one, and a locally invented "last + 1"
///   would collide with a real sale's, since the server's numbers are sequential and shared by
///   every tablet. Two receipts bearing the same number cannot be told apart afterwards.
/// - **A "not sent" marker and the short ref instead**, so the slip says what it is and can be
///   matched to the sale once the sale has a number.
///
/// The goods come from the entry's own copy, written at the moment of payment: there is no server
/// record to read them from, which is exactly why the copy exists.
///
/// Nothing here reaches the network — that is the point of it.
Future<void> printPendingReceipt(
  PendingSale entry, {
  required PrinterPort printer,
  required StorePort store,
  required L10n l10n,
}) => printDocument(
  receiptBytesFor((
    // The marker where the number goes, and the ref underneath it.
    number: l10n.posReceiptTemporary,
    createdAt: entry.paidAt,
    transactionDate: entry.paidAt,
    outletName: entry.receipt.outletName,
    cashierName: entry.receipt.cashierName,
    // The basket's own, not the payload's: the payload carries ids.
    tableNumber: entry.payload.tableNumber,
    queueNumber: entry.payload.queueNumber,
    subtotal: entry.receipt.subtotal,
    discountAmount: entry.receipt.discountAmount,
    taxAmount: entry.receipt.taxAmount,
    grandTotal: entry.receipt.grandTotal,
    tenderedAmount: entry.receipt.tenderedAmount,
    changeAmount: entry.receipt.changeAmount,
    // Not a recorded sale, so no status line claims one. The marker above says the rest.
    status: '',
    invoiceItems: entry.receipt.items.map(toInvoiceItem).toList(),
    payments: [
      for (final p in entry.payload.payments)
        (method: p.method.wire, amount: p.amount),
    ],
  ), l10n: l10n),
  printer: printer,
  store: store,
);
