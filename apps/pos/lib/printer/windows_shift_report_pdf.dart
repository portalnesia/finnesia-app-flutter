/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */
/// A4-default shift report PDF renderer for ordinary Windows printers.
library;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/js_compat.dart';
import 'package:pn_pos/src/pos_escpos_format.dart';

const _headingStyle = pw.TextStyle(
  fontSize: 15,
  fontWeight: pw.FontWeight.bold,
);
const _sectionStyle = pw.TextStyle(
  fontSize: 11,
  fontWeight: pw.FontWeight.bold,
);
const _detailStyle = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);

pw.ThemeData? _fontThemeCache;
Future<pw.ThemeData>? _fontThemeFuture;

Future<pw.ThemeData> _fontTheme() async {
  final cached = _fontThemeCache;
  if (cached != null) return cached;

  final loading = _fontThemeFuture ??= _loadFontTheme();
  try {
    final theme = await loading;
    _fontThemeCache = theme;
    return theme;
  } finally {
    if (identical(_fontThemeFuture, loading)) _fontThemeFuture = null;
  }
}

Future<pw.ThemeData> _loadFontTheme() async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
  );
  return pw.ThemeData.withFont(base: regular, bold: bold);
}

Future<Uint8List> renderShiftReportPdf({
  required ShiftReportSummary summary,
  required String printedAt,
  required ShiftReportEscPosLabels labels,
  bool showProductSales = false,
  String? footerText,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) async {
  final document = pw.Document(theme: await _fontTheme());
  final cashSales = summary.salesByMethod['CASH'] ?? 0;
  final totalDeposit =
      summary.openingCash + cashSales - summary.cashOut - summary.cashDrop;
  final productTotal = summary.productSales.fold<num>(
    0,
    (sum, product) => sum + product.total,
  );

  document.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Center(child: pw.Text(labels.title, style: _headingStyle)),
        pw.SizedBox(height: 3),
        pw.Center(child: pw.Text(summary.number, style: _sectionStyle)),
        pw.SizedBox(height: 10),
        if ((summary.cashierName ?? '').isNotEmpty)
          pw.Text('${labels.cashier}: ${summary.cashierName}'),
        pw.Text('${labels.openedAt}: ${formatDateTime(summary.openedAt)}'),
        pw.Text('${labels.printedAt}: ${formatDateTime(printedAt)}'),
        pw.SizedBox(height: 12),
        _section(labels.totalSales),
        _amountRow(
          labels.totalSales,
          formatCurrency(summary.totalSales),
          bold: true,
        ),
        pw.Divider(),
        _section(labels.paymentsByMethod),
        for (final entry in summary.salesByMethod.entries)
          _amountRow(
            labels.tenderMethod(entry.key),
            formatCurrency(entry.value),
          ),
        _amountRow(
          labels.total,
          formatCurrency(summary.totalSales),
          bold: true,
        ),
        pw.Divider(),
        _section(labels.deposit),
        _amountRow(labels.openingCash, formatCurrency(summary.openingCash)),
        _amountRow(labels.cashSales, formatCurrency(cashSales)),
        _amountRow(
          labels.cashOut,
          '-${formatCurrency(summary.cashOut + summary.cashDrop)}',
        ),
        _amountRow(
          labels.totalDeposit,
          formatCurrency(totalDeposit),
          bold: true,
        ),
        if (showProductSales && summary.productSales.isNotEmpty) ...[
          pw.Divider(),
          _section(labels.productsSoldTitle),
          for (final product in summary.productSales) ...[
            pw.Text(product.productName),
            _amountRow(
              '${jsNumber(product.quantity)} x ${formatCurrency(product.unitPrice)}',
              formatCurrency(product.total),
            ),
          ],
          _amountRow(
            labels.productsSoldTotal,
            formatCurrency(productTotal),
            bold: true,
          ),
        ],
        pw.Divider(),
        _section(labels.nonCashPayments),
        if (summary.nonCashTenders.isEmpty)
          pw.Text(labels.noTenders)
        else
          for (final tender in summary.nonCashTenders) ...[
            pw.Text(
              '${tender.saleNumber} ${labels.tenderMethod(tender.method)}',
            ),
            _amountRow(tender.reference ?? '', formatCurrency(tender.amount)),
          ],
        if ((footerText ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 12),
          for (final line in footerText!.split('\n'))
            if (line.isNotEmpty)
              pw.Center(child: pw.Text(line, style: _detailStyle)),
        ],
      ],
    ),
  );
  return document.save();
}

pw.Widget _section(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 5, bottom: 3),
  child: pw.Text(text, style: _sectionStyle),
);

pw.Widget _amountRow(String label, String amount, {bool bold = false}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: bold
                  ? const pw.TextStyle(fontWeight: pw.FontWeight.bold)
                  : null,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            amount,
            style: bold
                ? const pw.TextStyle(fontWeight: pw.FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
