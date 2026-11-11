/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:typed_data';

import 'package:pn_pos/src/pos_escpos_format.dart'
    show ShiftReportEscPosLabels, ShiftReportSummary, formatShiftReportEscPos;
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/receipt.dart' show receiptBrandingText;
import 'package:pos/screens/common/tender_label.dart';

/// The normalized report fields shared by the ESC/POS and Windows PDF renderers.
ShiftReportSummary shiftReportData(ShiftSummaryResponse summary) => (
  number: summary.number,
  cashierName: summary.cashierName,
  openedAt: summary.openedAt,
  totalSales: summary.totalSales,
  openingCash: summary.openingCash,
  salesByMethod: summary.salesByMethod,
  cashOut: summary.cashOut,
  cashDrop: summary.cashDrop,
  nonCashTenders: [
    for (final tender in summary.nonCashTenders)
      (
        method: tender.method,
        reference: tender.reference,
        amount: tender.amount,
        saleNumber: tender.saleNumber,
      ),
  ],
  productSales: [
    for (final product in summary.productSales)
      (
        productName: product.productName,
        quantity: product.quantity,
        unitPrice: product.unitPrice,
        total: product.total,
      ),
  ],
);

/// The report's translated labels, shared by ESC/POS and PDF renderers.
ShiftReportEscPosLabels shiftReportLabels(L10n l10n) => ShiftReportEscPosLabels(
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
  finnesiaBranding: receiptBrandingText,
);

/// The closing report of a shift, as the bytes for the printer.
///
/// The layout is `formatShiftReportEscPos`'s, ported from the web app and checked byte for byte
/// against it. [printedAt] is passed in so the same summary prints the same bytes; optional product
/// sales and footer come from the tenant's settings.
Uint8List shiftReportBytes(
  ShiftSummaryResponse summary, {
  required L10n l10n,
  required DateTime printedAt,
  bool showProductSales = false,
  String? footerText,
  int columns = 32,
  bool autoCutter = false,
}) => formatShiftReportEscPos(
  shiftReportData(summary),
  printedAt.toIso8601String(),
  shiftReportLabels(l10n),
  showProductSales,
  footerText,
  true,
  columns,
  autoCutter,
);
