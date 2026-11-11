/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/escpos.dart';
import 'package:pn_pos/src/escpos_pdf_layout.dart';
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

const _thermalPageFormat = PdfPageFormat(
  80 * PdfPageFormat.mm,
  300 * PdfPageFormat.mm,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initializePosNumberFormat();
    await initializePosDateTime();
    useFixedLocalZone(Duration.zero);
  });

  group('Windows ordinary-printer PDF receipt', () {
    test(
      'keeps the centered tenant footer and branding gap from Bluetooth',
      () {
        for (final sale in [_sale(), _pendingSale()]) {
          final lines = parseEscPosPdfLayout(
            formatReceiptEscPos(
              sale,
              'Unknown item',
              _labels,
              'Terima kasih\nSampai jumpa',
              true,
              32,
            ),
          );
          final footerStart = lines.indexWhere(
            (line) => line.text == 'Terima kasih',
          );

          expect(footerStart, greaterThanOrEqualTo(0));
          expect(lines[footerStart].alignment, EscPosAlign.center);
          expect(lines[footerStart].bold, isFalse);
          expect(lines[footerStart + 1].text, 'Sampai jumpa');
          expect(lines[footerStart + 2].text, '');
          expect(lines[footerStart + 3].text, 'Finnesia POS');
          expect(lines[footerStart + 3].alignment, EscPosAlign.center);
        }
      },
    );

    test('renders a normal sale into a valid PDF document', () async {
      final bytes = await renderReceiptPdf(
        escPosBytes: formatReceiptEscPos(
          _sale(),
          'Unknown item',
          _labels,
          'Terima kasih\nSampai jumpa',
          true,
          32,
        ),
        columns: 32,
        pageFormat: _thermalPageFormat,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(String.fromCharCodes(bytes), contains('NotoSansMono-Regular'));
      expect(String.fromCharCodes(bytes), contains('NotoSansMono-Bold'));
      expect(bytes.length, greaterThan(1000));
    });

    test(
      'renders empty and voided sales without requiring printer hardware',
      () async {
        final bytes = await renderReceiptPdf(
          escPosBytes: formatReceiptEscPos(
            _sale(items: const [], status: POSSaleStatus.voided.wire),
            'Unknown item',
            _labels,
            null,
            true,
            32,
          ),
          columns: 32,
          pageFormat: PdfPageFormat.a4,
        );

        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(500));
      },
    );
  });
}
