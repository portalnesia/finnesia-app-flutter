/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_escpos_format.dart';
import 'package:pn_pos/src/pos_receipt.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pos/printer/windows_receipt_pdf.dart';

String _tenderMethod(String method) => method;

String _paidByMethod(String method) => 'Paid by $method';

const _labels = ReceiptEscPosLabels(
  title: 'Receipt',
  cashier: 'Cashier',
  tableNumber: 'Table',
  queueNumber: 'Queue',
  discount: 'Discount',
  subtotal: 'Subtotal',
  tax: 'Tax',
  paymentMethodLabel: 'Payment method',
  paymentTotal: 'Total',
  cashTendered: 'Cash tendered',
  change: 'Change',
  voided: 'VOIDED',
  noItems: 'No items',
  tenderMethod: _tenderMethod,
  paidByMethod: _paidByMethod,
  finnesiaBranding: 'Finnesia POS',
);

ReceiptSale _sale({List<InvoiceItem>? items, String? status}) => (
  number: 'POS-0007',
  createdAt: '2026-11-11T01:30:00Z',
  transactionDate: null,
  outletName: 'Outlet Pusat',
  cashierName: 'Putu',
  tableNumber: '12',
  queueNumber: '45',
  subtotal: 50000,
  discountAmount: 1000,
  taxAmount: 0,
  grandTotal: 49000,
  tenderedAmount: 50000,
  changeAmount: 1000,
  status: status ?? POSSaleStatus.posted.wire,
  invoiceItems:
      items ??
      const [
        (
          id: 'i1',
          productName: 'Kopi Susu Café',
          description: null,
          quantity: 2,
          price: 25000,
          discountPercent: null,
          discountAmount: 1000,
          lineSubtotal: 49000,
          lineTotal: 49000,
          category: null,
        ),
      ],
  payments: const [(method: 'CASH', amount: 50000)],
);

ReceiptSale _pendingSale() => (
  number: 'BELUM TERKIRIM',
  createdAt: '2026-11-11T01:30:00Z',
  transactionDate: null,
  outletName: 'Outlet Pusat',
  cashierName: 'Putu',
  tableNumber: null,
  queueNumber: null,
  subtotal: 50000,
  discountAmount: 0,
  taxAmount: 0,
  grandTotal: 50000,
  tenderedAmount: 50000,
  changeAmount: 0,
  status: '',
  invoiceItems: _sale().invoiceItems,
  payments: const [(method: 'CASH', amount: 50000)],
);

List<String> _footerText(List<pw.Widget> widgets) => [
  for (final widget in widgets)
    if (widget is pw.Center) (widget.child as pw.Text).text.toPlainText(),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializePosNumberFormat();
    await initializePosDateTime();
    useFixedLocalZone(Duration.zero);
  });

  group('Windows ordinary-printer PDF receipt', () {
    test('centers both Finnesia branding lines after tenant footer', () {
      for (final sale in [_sale(), _pendingSale()]) {
        final footer = buildReceiptFooterWidgets(
          sale: sale,
          footerText: 'Terima kasih\nSampai jumpa',
          labels: _labels,
        );

        expect(footer, everyElement(isA<pw.Center>()));
        expect(_footerText(footer), [
          'Terima kasih',
          'Sampai jumpa',
          'Finnesia.com',
          'Aplikasi Kasir Otomatis',
        ]);
      }
    });

    test('renders a normal sale into a valid PDF document', () async {
      final bytes = await renderReceiptPdf(
        sale: _sale(),
        fallbackProductName: 'Unknown item',
        labels: _labels,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(String.fromCharCodes(bytes), contains('NotoSans-Regular'));
      expect(bytes.length, greaterThan(1000));
    });

    test(
      'renders empty and voided sales without requiring printer hardware',
      () async {
        final bytes = await renderReceiptPdf(
          sale: _sale(items: const [], status: POSSaleStatus.voided.wire),
          fallbackProductName: 'Unknown item',
          labels: _labels,
          pageFormat: PdfPageFormat.a4,
        );

        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(500));
      },
    );
  });
}
