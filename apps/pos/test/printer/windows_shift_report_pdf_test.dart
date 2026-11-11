/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_escpos_format.dart';
import 'package:pos/printer/windows_shift_report_pdf.dart';

String _tenderMethod(String method) => method;

const _labels = ShiftReportEscPosLabels(
  title: 'Shift report',
  cashier: 'Cashier',
  openedAt: 'Opened',
  printedAt: 'Printed',
  totalSales: 'Total sales',
  paymentsByMethod: 'Payments by method',
  total: 'Total',
  deposit: 'Cash deposit',
  openingCash: 'Opening cash',
  cashSales: 'Cash sales',
  cashOut: 'Cash out / drop',
  totalDeposit: 'Total deposit',
  nonCashPayments: 'Non-cash payments',
  tenderMethod: _tenderMethod,
  noTenders: 'No non-cash tenders',
  productsSoldTitle: 'Products sold',
  productsSoldTotal: 'Products total',
  finnesiaBranding: 'Finnesia POS',
);

final _summary = (
  number: 'SHIFT-0032',
  cashierName: 'Ayu',
  openedAt: '2026-11-11T01:00:00Z',
  totalSales: 84000,
  openingCash: 20000,
  salesByMethod: <String, num>{'CASH': 54000, 'CARD': 30000},
  cashOut: 5000,
  cashDrop: 4000,
  nonCashTenders: <NonCashTenderLine>[
    (
      saleNumber: 'POS-0007',
      method: 'CARD',
      reference: 'AUTH-91',
      amount: 30000,
    ),
  ],
  productSales: <ProductSalesLine>[
    (productName: 'Kopi Susu', quantity: 2, unitPrice: 25000, total: 50000),
  ],
);

const _thermalPageFormat = PdfPageFormat(
  80 * PdfPageFormat.mm,
  300 * PdfPageFormat.mm,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    initializePosNumberFormat();
    await initializePosDateTime();
    useFixedLocalZone(Duration.zero);
  });

  test(
    'renders a valid PDF with embedded fixed-width Noto Sans Mono fonts',
    () async {
      final bytes = await renderShiftReportPdf(
        escPosBytes: formatShiftReportEscPos(
          _summary,
          '2026-11-11T02:00:00Z',
          _labels,
          false,
          'Terima kasih',
          true,
          32,
        ),
        columns: 32,
        pageFormat: _thermalPageFormat,
      );
      final raw = String.fromCharCodes(bytes);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(raw, contains('NotoSansMono-Regular'));
      expect(raw, contains('NotoSansMono-Bold'));
      expect(bytes.length, greaterThan(1000));
    },
  );

  test('product section can be enabled or disabled', () async {
    final withoutProductsBytes = formatShiftReportEscPos(
      _summary,
      '2026-11-11T02:00:00Z',
      _labels,
      false,
      null,
      true,
      32,
    );
    final withProductsBytes = formatShiftReportEscPos(
      _summary,
      '2026-11-11T02:00:00Z',
      _labels,
      true,
      null,
      true,
      32,
    );
    final withoutProducts = await renderShiftReportPdf(
      escPosBytes: withoutProductsBytes,
      columns: 32,
      pageFormat: _thermalPageFormat,
    );
    final withProducts = await renderShiftReportPdf(
      escPosBytes: withProductsBytes,
      columns: 32,
      pageFormat: _thermalPageFormat,
    );
    expect(String.fromCharCodes(withoutProducts.take(5)), '%PDF-');
    expect(String.fromCharCodes(withProducts.take(5)), '%PDF-');
    expect(withoutProducts.length, greaterThan(1000));
    expect(withProducts.length, greaterThan(withoutProducts.length));
  });
}
