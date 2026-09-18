/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:typed_data';

import 'package:pn_pos/src/pos_escpos_format.dart'
    show ShiftReportEscPosLabels, formatShiftReportEscPos;
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/common/tender_label.dart';

/// The closing report of a shift, as the bytes for the printer.
///
/// The layout is `formatShiftReportEscPos`'s, ported from the web app and checked byte for byte
/// against it. This hands it what it cannot fetch for itself: the words, in the cashier's language
/// (`style.md` §7: the formatter takes its labels from the caller), and the figures.
///
/// [printedAt] is the moment the button was pressed, passed in so the same summary prints the same
/// bytes. [showProductSales] and [footerText] are the tenant's settings; the formatter prints
/// nothing for either unless told.
Uint8List shiftReportBytes(
  ShiftSummaryResponse summary, {
  required L10n l10n,
  required DateTime printedAt,
  bool showProductSales = false,
  String? footerText,
}) => formatShiftReportEscPos(
  (
    number: summary.number,
    cashierName: summary.cashierName,
    openedAt: summary.openedAt,
    totalSales: summary.totalSales,
    openingCash: summary.openingCash,
    salesByMethod: summary.salesByMethod,
    cashOut: summary.cashOut,
    cashDrop: summary.cashDrop,
    nonCashTenders: [
      for (final t in summary.nonCashTenders)
        (
          method: t.method,
          reference: t.reference,
          amount: t.amount,
          saleNumber: t.saleNumber,
        ),
    ],
    productSales: [
      for (final p in summary.productSales)
        (
          productName: p.productName,
          quantity: p.quantity,
          unitPrice: p.unitPrice,
          total: p.total,
        ),
    ],
  ),
  printedAt.toIso8601String(),
  ShiftReportEscPosLabels(
    title: l10n.posShiftReportTitle,
    cashier: l10n.posCashier,
    openedAt: l10n.posOpenedAt,
    printedAt: l10n.posPrintedAt,
    totalSales: l10n.posTotalSales,
    paymentsByMethod: l10n.posPaymentsByMethod,
    total: l10n.posTotal,
    deposit: l10n.posDepositSection,
    openingCash: l10n.posOpeningCash,
    cashSales: l10n.posCashSalesLabel,
    cashOut: l10n.posCashOut,
    totalDeposit: l10n.posTotalDeposit,
    nonCashPayments: l10n.posNonCashPayments,
    tenderMethod: (wire) => tenderMethodLabel(l10n, wire),
    noTenders: l10n.posNoNonCashPayments,
    productsSoldTitle: l10n.posProductsSoldTitle,
    productsSoldTotal: l10n.posProductsSoldTotal,
    // Only printed when the formatter is given `showBranding`, which this does not do: nothing
    // in the tablet's settings turns it on.
    finnesiaBranding: '',
  ),
  showProductSales,
  footerText,
);
