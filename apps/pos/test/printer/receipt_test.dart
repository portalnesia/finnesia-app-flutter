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
import 'package:pn_types/src/pos.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/receipt.dart';

// The customer receipt, as the words and figures that end up on paper. The byte layout is the
// formatter's, ported and checked byte for byte against the web app in `pn_pos`; what is checked
// here is that this app hands it the right words and the right numbers.

POSSale _sale({
  List<POSSalePayment>? payments,
  POSSaleStatus status = POSSaleStatus.posted,
  num discount = 0,
  num tax = 0,
  List<SalesInvoiceItem>? items,
}) => POSSale(
  id: 'sale_1',
  number: 'POS-0007',
  shiftId: 's1',
  outletId: 'out_1',
  cashierId: 'user_1',
  transactionDate: '2026-09-20',
  subtotal: 50000,
  discountAmount: discount,
  taxAmount: tax,
  grandTotal: 50000 - discount + tax,
  tenderedAmount: 100000,
  changeAmount: 50000,
  status: status,
  createdAt: '2026-09-20T03:00:00Z',
  tableNumber: '12',
  queueNumber: '45',
  cashier: const NamedRef(id: 'user_1', name: 'Budi'),
  payments:
      payments ??
      const [POSSalePayment(id: 'p1', method: 'CASH', amount: 100000)],
  invoice: SalesInvoice(
    items:
        items ??
        const [
          SalesInvoiceItem(
            id: 'i1',
            quantity: 2,
            price: 25000,
            lineSubtotal: 50000,
            lineTotal: 50000,
            product: NamedRef(id: 'p', name: 'Kopi Susu'),
          ),
        ],
  ),
);

String _paper(
  POSSale sale, {
  String locale = 'id',
  String? outletName = 'Outlet Pusat',
  String? footerText,
}) => String.fromCharCodes(
  receiptBytes(
    sale,
    l10n: lookupL10n(Locale(locale)),
    outletName: outletName,
    footerText: footerText,
  ),
);

void main() {
  setUpAll(() async {
    initializePosNumberFormat();
    await initializePosDateTime();
    useFixedLocalZone(Duration.zero);
  });

  group('what the receipt says', () {
    test('names the shop, the sale and who rang it up', () {
      final paper = _paper(_sale());

      expect(paper, contains('Struk Penjualan'));
      expect(paper, contains('Outlet Pusat'));
      expect(paper, contains('POS-0007'));
      expect(paper, contains('Kasir: Budi'));
      expect(paper, contains('No. Meja: 12'));
      expect(paper, contains('No. Antrian: 45'));
    });

    test('is in the language of the cashier', () {
      final en = _paper(_sale(), locale: 'en');

      expect(en, isNot(contains('Struk Penjualan')));
      expect(en, contains('POS-0007'));
    });

    test('lists what was sold, with quantity, price and the line total', () {
      final paper = _paper(_sale());

      expect(paper, contains('Kopi Susu'));
      expect(paper, contains('2 x ${formatCurrency(25000)}'));
      expect(paper, contains(formatCurrency(50000)));
    });

    test(
      'a sale whose goods were not loaded says so rather than printing none',
      () {
        final paper = _paper(_sale(items: const []));

        expect(paper, contains('Tidak ada rincian barang'));
      },
    );

    test('a product deleted since the sale still gets a name', () {
      final paper = _paper(
        _sale(
          items: const [
            SalesInvoiceItem(
              id: 'i1',
              quantity: 1,
              price: 10000,
              lineSubtotal: 10000,
              lineTotal: 10000,
              product: NamedRef(id: 'gone', name: ''),
            ),
          ],
        ),
      );

      expect(paper, contains('Barang tidak dikenal'));
    });
  });

  group('the payment', () {
    test('cash names the tender and the change', () {
      final paper = _paper(_sale());

      expect(paper, contains('Bayar'));
      expect(paper, contains(formatCurrency(100000)));
      expect(paper, contains('Kembalian'));
      expect(paper, contains(formatCurrency(50000)));
    });

    test('a sale paid another way does not claim cash was handed over', () {
      final paper = _paper(
        _sale(
          payments: const [
            POSSalePayment(id: 'p1', method: 'QRIS', amount: 50000),
          ],
        ),
      );

      expect(paper, contains('Metode Pembayaran'));
      expect(paper, contains('QRIS'));
      expect(paper, isNot(contains('Kembalian')));
    });

    test('a split sale lists each payment', () {
      final paper = _paper(
        _sale(
          payments: const [
            POSSalePayment(id: 'p1', method: 'CASH', amount: 30000),
            POSSalePayment(id: 'p2', method: 'QRIS', amount: 20000),
          ],
        ),
      );

      expect(paper, contains('Bayar (Tunai)'));
      expect(paper, contains('Bayar (QRIS)'));
    });
  });

  group('what changes it', () {
    test('a voided sale is marked as voided', () {
      expect(_paper(_sale()), isNot(contains('DIBATALKAN')));
      expect(
        _paper(_sale(status: POSSaleStatus.voided)),
        contains('DIBATALKAN'),
      );
    });

    test('the footer of the tenant is printed when there is one', () {
      expect(_paper(_sale()), isNot(contains('Terima kasih')));
      expect(
        _paper(_sale(), footerText: 'Terima kasih'),
        contains('Terima kasih'),
      );
    });

    test('no outlet name is no line, not a blank one', () {
      expect(
        _paper(_sale(), outletName: null),
        isNot(contains('Outlet Pusat')),
      );
    });
  });
}
