/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// A4-default receipt renderer for an installed Windows printer queue.
///
/// The same normalized receipt fields and translated labels feed this PDF and the legacy ESC/POS
/// formatter. The Windows queue submits the document through the selected printer driver's path.
library;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/js_compat.dart';
import 'package:pn_pos/src/pos_escpos_format.dart';
import 'package:pn_pos/src/pos_receipt.dart';
import 'package:pn_pos/src/pos_tender.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pos/printer/receipt.dart' show receiptBrandingText;

const _titleStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);

const _detailStyle = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);

pw.ThemeData? _fontThemeCache;
Future<pw.ThemeData>? _fontThemeFuture;

Future<pw.ThemeData> _receiptFontTheme() async {
  final cached = _fontThemeCache;
  if (cached != null) return cached;

  final loading = _fontThemeFuture ??= _loadReceiptFontTheme();
  try {
    final theme = await loading;
    _fontThemeCache = theme;
    return theme;
  } finally {
    if (identical(_fontThemeFuture, loading)) _fontThemeFuture = null;
  }
}

Future<pw.ThemeData> _loadReceiptFontTheme() async {
  final regularFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
  );
  return pw.ThemeData.withFont(base: regularFont, bold: boldFont);
}

/// Builds an A4-default PDF while allowing a Windows print queue to supply its page format.
Future<Uint8List> renderReceiptPdf({
  required ReceiptSale sale,
  required String fallbackProductName,
  required ReceiptEscPosLabels labels,
  String? footerText,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) async {
  final document = pw.Document(theme: await _receiptFontTheme());
  final lines = posReceiptLines(
    invoiceItems: sale.invoiceItems,
    fallbackName: fallbackProductName,
  );
  final payments = sale.payments ?? const <PaymentLine>[];

  document.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        ..._receiptHeader(sale, payments, labels),
        pw.SizedBox(height: 12),
        pw.Divider(),
        ..._receiptItems(lines, labels),
        pw.Divider(),
        ..._receiptTotals(sale, payments, labels),
        ...buildReceiptFooterWidgets(
          sale: sale,
          footerText: footerText,
          labels: labels,
        ),
      ],
    ),
  );

  return document.save();
}

List<pw.Widget> _receiptHeader(
  ReceiptSale sale,
  List<PaymentLine> payments,
  ReceiptEscPosLabels labels,
) {
  final widgets = <pw.Widget>[
    pw.Center(child: pw.Text(labels.title, style: _titleStyle)),
  ];
  final outletName = sale.outletName;
  if (outletName != null && outletName.isNotEmpty) {
    widgets.add(pw.Center(child: pw.Text(outletName)));
  }

  widgets.addAll([
    pw.Center(child: pw.Text(sale.number)),
    pw.Text(
      formatDateTime(firstNonEmpty([sale.createdAt, sale.transactionDate])),
    ),
  ]);

  final cashierName = sale.cashierName;
  if (cashierName != null && cashierName.isNotEmpty) {
    widgets.add(pw.Text('${labels.cashier}: $cashierName'));
  }
  final tableNumber = sale.tableNumber;
  if (tableNumber != null && tableNumber.isNotEmpty) {
    widgets.add(pw.Text('${labels.tableNumber}: $tableNumber'));
  }
  final queueNumber = sale.queueNumber;
  if (queueNumber != null && queueNumber.isNotEmpty) {
    widgets.add(pw.Text('${labels.queueNumber}: $queueNumber'));
  }

  if (payments.length == 1) {
    final method = payments.first.method;
    widgets.add(
      pw.Text('${labels.paymentMethodLabel}: ${labels.tenderMethod(method)}'),
    );
  }

  return widgets;
}

List<pw.Widget> _receiptItems(
  List<ReceiptLine> lines,
  ReceiptEscPosLabels labels,
) {
  if (lines.isEmpty) return [pw.Text(labels.noItems)];

  return [
    for (final line in lines) ...[
      _amountRow(line.name, formatCurrency(line.total)),
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(
          '${jsNumber(line.quantity)} x ${formatCurrency(line.price)}',
          style: _detailStyle,
        ),
      ),
      if (line.discount > 0)
        _amountRow(labels.discount, '-${formatCurrency(line.discount)}'),
    ],
  ];
}

List<pw.Widget> _receiptTotals(
  ReceiptSale sale,
  List<PaymentLine> payments,
  ReceiptEscPosLabels labels,
) {
  final widgets = <pw.Widget>[
    _amountRow(labels.subtotal, formatCurrency(sale.subtotal)),
  ];
  if (sale.discountAmount > 0) {
    widgets.add(
      _amountRow(labels.discount, '-${formatCurrency(sale.discountAmount)}'),
    );
  }
  if (sale.taxAmount > 0) {
    widgets.add(_amountRow(labels.tax, formatCurrency(sale.taxAmount)));
  }
  widgets.add(
    _amountRow(
      labels.paymentTotal,
      formatCurrency(sale.grandTotal),
      bold: true,
    ),
  );

  final hasCash = hasCashTender(payments.map((payment) => payment.method));
  if (payments.length == 1 && hasCash) {
    widgets.add(
      _amountRow(labels.cashTendered, formatCurrency(sale.tenderedAmount)),
    );
    widgets.add(
      _amountRow(labels.change, formatCurrency(sale.changeAmount), bold: true),
    );
  } else if (payments.length != 1) {
    for (final payment in payments) {
      widgets.add(
        _amountRow(
          labels.paidByMethod(payment.method),
          formatCurrency(payment.amount),
        ),
      );
    }
    if (hasCash) {
      widgets.add(
        _amountRow(
          labels.change,
          formatCurrency(sale.changeAmount),
          bold: true,
        ),
      );
    }
  }

  return widgets;
}

List<pw.Widget> buildReceiptFooterWidgets({
  required ReceiptSale sale,
  required String? footerText,
  required ReceiptEscPosLabels labels,
}) {
  final widgets = <pw.Widget>[];
  if (sale.status == POSSaleStatus.voided.wire) {
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.Center(
          child: pw.Text(
            labels.voided,
            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
      ),
    );
  }

  final lines = footerText?.split('\n') ?? const <String>[];
  for (final line in lines) {
    if (line.isNotEmpty) {
      widgets.add(pw.Center(child: pw.Text(line, style: _detailStyle)));
    }
  }
  if (lines.any((line) => line.isNotEmpty)) {
    widgets.add(pw.SizedBox(height: 8));
  }
  for (final line in receiptBrandingText.split('\n')) {
    widgets.add(pw.Center(child: pw.Text(line, style: _detailStyle)));
  }
  return widgets;
}

pw.Widget _amountRow(String label, String amount, {bool bold = false}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: bold
                  ? const pw.TextStyle(fontWeight: pw.FontWeight.bold)
                  : null,
            ),
          ),
          pw.Text(
            amount,
            style: bold
                ? const pw.TextStyle(fontWeight: pw.FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
