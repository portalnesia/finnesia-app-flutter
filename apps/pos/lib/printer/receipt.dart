/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:typed_data';

import 'package:pn_pos/src/pos_escpos_format.dart'
    show ReceiptEscPosLabels, ReceiptSale, formatReceiptEscPos;
import 'package:pn_types/src/pos.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/sale/invoice_item.dart';
import 'package:pos/screens/common/tender_label.dart';

/// The customer receipt of [sale], as the bytes for the printer.
///
/// The layout is `formatReceiptEscPos`'s, ported from the web app and checked byte for byte
/// against it. This hands it what it cannot fetch for itself: the words, in the cashier's language
/// (`style.md` §7: the formatter takes its labels from the caller), and the figures.
///
/// [sale] must carry its invoice and its payments, which only the single-sale endpoint loads: a
/// sale without them prints "no item details", which is a receipt that says nothing of what was
/// bought. [outletName] and [footerText] are the shop's, and the formatter prints no line for
/// either unless told.
Uint8List receiptBytes(
  POSSale sale, {
  required L10n l10n,
  String? outletName,
  String? footerText,
}) => receiptBytesFor(
  receiptData(sale, outletName: outletName),
  l10n: l10n,
  footerText: footerText,
);

/// The normalized receipt fields shared by the ESC/POS and Windows PDF renderers.
ReceiptSale receiptData(POSSale sale, {String? outletName}) => (
  number: sale.number,
  createdAt: sale.createdAt,
  transactionDate: sale.transactionDate,
  outletName: outletName,
  cashierName: sale.cashier?.name,
  tableNumber: sale.tableNumber,
  queueNumber: sale.queueNumber,
  subtotal: sale.subtotal,
  discountAmount: sale.discountAmount,
  taxAmount: sale.taxAmount,
  grandTotal: sale.grandTotal,
  tenderedAmount: sale.tenderedAmount,
  changeAmount: sale.changeAmount,
  // The wire value, so a status this build does not know still prints as itself.
  status: sale.status?.wire ?? '',
  invoiceItems: sale.invoice?.items.map(toInvoiceItem).toList(),
  payments: [
    for (final p in sale.payments ?? const <POSSalePayment>[])
      (method: p.method, amount: p.amount),
  ],
);

/// The same ESC/POS bytes, for a caller that has receipt fields but not a [POSSale].
///
/// The **temporary** receipt of a queued sale is that caller: it has no server record at all, and
/// it prints from the copy the till wrote at the moment of payment (`plan/offline-queue/README.md`
/// D-Q3). Sharing this function keeps the recorded and temporary receipt layouts together.
Uint8List receiptBytesFor(
  ReceiptSale sale, {
  required L10n l10n,
  String? footerText,
}) => formatReceiptEscPos(
  sale,
  l10n.saleDetailUnknownProduct,
  receiptLabels(l10n),
  footerText,
);

/// Translated labels shared by ESC/POS and PDF receipt renderers.
ReceiptEscPosLabels receiptLabels(L10n l10n) => ReceiptEscPosLabels(
  title: l10n.receiptTitle,
  cashier: l10n.posCashier,
  tableNumber: l10n.posTableNumber,
  queueNumber: l10n.posQueueNumber,
  discount: l10n.posDiscount,
  subtotal: l10n.posSubtotal,
  tax: l10n.posTax,
  paymentMethodLabel: l10n.receiptPaymentMethod,
  paymentTotal: l10n.posTotal,
  cashTendered: l10n.posCashTendered,
  change: l10n.posChangeDue,
  voided: l10n.receiptVoided,
  noItems: l10n.receiptNoItems,
  tenderMethod: (wire) => tenderMethodLabel(l10n, wire),
  paidByMethod: (wire) => l10n.receiptPaidBy(tenderMethodLabel(l10n, wire)),
  // Only printed when the formatter is given showBranding, which this app does not enable.
  finnesiaBranding: '',
);
