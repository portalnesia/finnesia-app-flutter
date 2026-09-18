/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/shift_report.dart';

// The closing report, as the words and figures that end up on paper. The byte layout is the
// formatter's, ported and checked byte for byte against the web app in `pn_pos`; what is checked
// here is that this app hands it the right words and the right numbers.

const _summary = ShiftSummaryResponse(
  shiftId: 's1',
  number: 'SH-0001',
  status: ShiftStatus.open,
  outletId: 'out_1',
  cashierId: 'user_1',
  cashierName: 'Budi',
  openedAt: '2026-09-20T01:00:00Z',
  totalTransactions: 3,
  totalSales: 200000,
  openingCash: 150000,
  expectedCash: 275000,
  cashIn: 20000,
  cashOut: 5000,
  cashDrop: 10000,
  salesByMethod: {'CASH': 120000, 'QRIS': 80000},
  nonCashTenders: [
    NonCashTenderLine(
      method: 'QRIS',
      reference: 'REF-9',
      amount: 80000,
      saleNumber: 'POS-1',
    ),
  ],
  productSales: [
    ProductSalesLine(
      productId: 'p1',
      productName: 'Kopi Susu',
      quantity: 2,
      unitPrice: 25000,
      total: 50000,
    ),
  ],
);

String _paper(
  ShiftSummaryResponse summary, {
  String locale = 'id',
  bool showProductSales = false,
  String? footerText,
}) => String.fromCharCodes(
  shiftReportBytes(
    summary,
    l10n: lookupL10n(Locale(locale)),
    printedAt: DateTime.utc(2026, 9, 20, 9),
    showProductSales: showProductSales,
    footerText: footerText,
  ),
);

void main() {
  setUpAll(() async {
    initializePosNumberFormat();
    await initializePosDateTime();
    useFixedLocalZone(Duration.zero);
  });

  group('what the report says', () {
    test('names the shift and the cashier, in the cashier\'s language', () {
      final id = _paper(_summary);
      expect(id, contains('LAPORAN TUTUP SHIFT'));
      expect(id, contains('SH-0001'));
      expect(id, contains('Budi'));

      final en = _paper(_summary, locale: 'en');
      expect(en, isNot(contains('LAPORAN TUTUP SHIFT')));
      expect(en, contains('SH-0001'));
    });

    test('carries the figures of the drawer, each in its own place', () {
      final paper = _paper(_summary);

      expect(paper, contains(formatCurrency(200000))); // total sales
      expect(paper, contains(formatCurrency(150000))); // opening cash
      // Cash out and the drop are printed as one line, as the web prints them.
      expect(paper, contains('-${formatCurrency(15000)}'));
      // 150.000 + 120.000 cash sales - 5.000 - 10.000: what should be in the drawer to hand over.
      expect(paper, contains(formatCurrency(255000)));
    });

    test('lists a non-cash payment with its sale and its reference', () {
      final paper = _paper(_summary);

      expect(paper, contains('POS-1'));
      expect(paper, contains('REF-9'));
    });

    test('says so when nothing was paid by other means', () {
      final paper = _paper(
        _summary.copyWith(
          salesByMethod: {'CASH': 120000},
          nonCashTenders: const [],
        ),
      );

      expect(paper, contains('Tidak ada pembayaran non tunai'));
    });
  });

  group('what the tenant chooses', () {
    test('the product breakdown is left out unless the settings ask', () {
      expect(_paper(_summary), isNot(contains('Kopi Susu')));
      expect(_paper(_summary, showProductSales: true), contains('Kopi Susu'));
    });

    test('the footer text is printed when there is one', () {
      expect(_paper(_summary), isNot(contains('Terima kasih')));
      expect(
        _paper(_summary, footerText: 'Terima kasih'),
        contains('Terima kasih'),
      );
    });
  });
}
