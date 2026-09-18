/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_escpos_format.dart';
import 'package:pn_pos/src/pos_print_category.dart';
import 'package:pn_pos/src/pos_receipt.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/apps/web/src/lib/pos-escpos-format.test.ts`.
// Inputs and expectations are copied unchanged; only the syntax changed
// (describe/it -> group/test, toEqual -> equals). 38 cases, plus 6 added below.
//
// Verified against the running source rather than only against the oracle: a probe ran
// every added case through the TypeScript formatter and its byte output was compared with
// this port's, byte for byte. The oracle is the only source for this module — it covers all
// three formatters (`cross-repo.md` §5.1).

String _decode(Uint8List bytes) => utf8.decode(bytes);

String _methodLabel(String method) => 'Metode $method';
String _paidByMethodLabel(String method) => 'Bayar (Metode $method)';

const receiptLabels = ReceiptEscPosLabels(
  title: 'STRUK',
  cashier: 'Kasir',
  tableNumber: 'No. Meja',
  queueNumber: 'No. Antrian',
  discount: 'Diskon',
  subtotal: 'Subtotal',
  tax: 'Pajak',
  paymentMethodLabel: 'Metode',
  paymentTotal: 'Total',
  cashTendered: 'Bayar',
  change: 'Kembali',
  voided: 'DIBATALKAN',
  noItems: 'Tidak ada barang',
  tenderMethod: _methodLabel,
  paidByMethod: _paidByMethodLabel,
  finnesiaBranding: 'finnesia.com',
);

/// Mirrors the source test's `item(over)` builder. The source casts with
/// `as SalesInvoiceItem` because the real type has twenty-odd fields the formatter never
/// touches; the Dart [InvoiceItem] record declares only the seven that are read.
InvoiceItem invoiceItem({
  String id = 'itm_1',
  String? productName = 'Kopi Susu',
  String? description,
  num quantity = 1,
  num price = 10000,
  num lineSubtotal = 10000,
  num lineTotal = 10000,
}) =>
    (
      id: id,
      productName: productName,
      description: description,
      quantity: quantity,
      price: price,
      lineSubtotal: lineSubtotal,
      lineTotal: lineTotal,
      category: null,
    );

PaymentLine payment(String method, num amount) =>
    (method: method, amount: amount);

ReceiptSale receiptSale({
  String number = 'PS/001',
  String? createdAt = '2026-09-09T10:00:00Z',
  String? transactionDate = '2026-09-09',
  String? outletName,
  String? cashierName,
  String? tableNumber,
  String? queueNumber,
  num subtotal = 10000,
  num discountAmount = 0,
  num taxAmount = 0,
  num grandTotal = 10000,
  num tenderedAmount = 10000,
  num changeAmount = 0,
  String status = 'POSTED',
  List<InvoiceItem>? invoiceItems,
  List<PaymentLine>? payments,
}) =>
    (
      number: number,
      createdAt: createdAt,
      transactionDate: transactionDate,
      outletName: outletName,
      cashierName: cashierName,
      tableNumber: tableNumber,
      queueNumber: queueNumber,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      tenderedAmount: tenderedAmount,
      changeAmount: changeAmount,
      status: status,
      invoiceItems: invoiceItems ?? [invoiceItem()],
      payments: payments,
    );

void main() {
  setUpAll(() async {
    await initializePosDateTime();
    initializePosNumberFormat();
  });

  group('formatReceiptEscPos', () {
    test('ends with a feed and a cut command', () {
      final arr = formatReceiptEscPos(receiptSale(), 'Barang', receiptLabels);
      // feed(5) then cut(1) — bottom tear-off margin, check the tail literally.
      expect(arr.sublist(arr.length - 6),
          equals(Uint8List.fromList([0x1b, 0x64, 5, 0x1d, 0x56, 1])));
    });

    test('starts with init plus top padding feed', () {
      final arr = formatReceiptEscPos(receiptSale(), 'Barang', receiptLabels);
      // init(ESC @) then feed(2) — top margin before the title.
      expect(arr.sublist(0, 5),
          equals(Uint8List.fromList([0x1b, 0x40, 0x1b, 0x64, 2])));
    });

    test('includes the sale number, item name and total', () {
      final text =
          _decode(formatReceiptEscPos(receiptSale(), 'Barang', receiptLabels));
      expect(text, contains('PS/001'));
      expect(text, contains('Kopi Susu'));
      expect(text, contains('Total'));
      expect(text, contains('Rp 10.000'));
    });

    test('prints no Grand Total row — Total is the single bill total', () {
      final text =
          _decode(formatReceiptEscPos(receiptSale(), 'Barang', receiptLabels));
      expect(text, isNot(contains('Grand Total')));
      expect(RegExp('Total').allMatches(text).length, equals(1));
    });

    test(
        'keeps subtotal and Total in one section, Total before the tender rows',
        () {
      final text = _decode(formatReceiptEscPos(
        receiptSale(
          subtotal: 100000,
          grandTotal: 90000,
          discountAmount: 10000,
          payments: [payment('CASH', 50000), payment('TRANSFER', 40000)],
        ),
        'Barang',
        receiptLabels,
      ));
      final subtotalIndex = text.indexOf('Subtotal');
      final totalIndex = text.indexOf('Total');
      final firstTenderIndex = text.indexOf('Bayar (Metode');
      expect(subtotalIndex, greaterThan(-1));
      expect(totalIndex, greaterThan(subtotalIndex));
      expect(firstTenderIndex, greaterThan(totalIndex));
      expect(text, contains('Diskon'));
    });

    test('leaves a blank line after Total before the tender rows', () {
      final text = _decode(formatReceiptEscPos(
        receiptSale(payments: [payment('CASH', 10000)]),
        'Barang',
        receiptLabels,
      ));
      // Raw bytes: the Total row is bold, so its line ends with bold-off
      // (ESC E 0) followed by one blank line-feed before the tender rows. The
      // Subtotal row above is not bold, so only Total matches this.
      final esc = String.fromCharCode(0x1b);
      final nul = String.fromCharCode(0);
      expect(text, contains('Total${' ' * 18}Rp 10.000\n${esc}E$nul\n'));
    });

    test('separates the footer with a blank line, not a divider', () {
      final text = _decode(formatReceiptEscPos(
        receiptSale(),
        'Barang',
        receiptLabels,
        'Terima kasih\nSampai jumpa',
      ));
      final lines = text.split('\n');
      final footerIndex = lines.indexWhere((l) => l.contains('Terima kasih'));
      expect(footerIndex, greaterThan(0));
      expect(lines[footerIndex - 1], equals(''));
    });

    test('prints the table number only when present', () {
      final withTable = _decode(formatReceiptEscPos(
        receiptSale(tableNumber: 'A1'),
        'Barang',
        receiptLabels,
      ));
      expect(withTable, contains('No. Meja: A1'));

      final withoutTable =
          _decode(formatReceiptEscPos(receiptSale(), 'Barang', receiptLabels));
      expect(withoutTable, isNot(contains('No. Meja')));
    });

    test('prints the queue number only when present', () {
      final withQueue = _decode(formatReceiptEscPos(
        receiptSale(queueNumber: '12'),
        'Barang',
        receiptLabels,
      ));
      expect(withQueue, contains('No. Antrian: 12'));

      final withoutQueue =
          _decode(formatReceiptEscPos(receiptSale(), 'Barang', receiptLabels));
      expect(withoutQueue, isNot(contains('No. Antrian')));
    });

    // Single payment method: the header names the method, the body just shows Total —
    // no per-method loop row (that only exists for a split payment now).
    test(
        'single cash payment: header names the method, body shows Total + Bayar + Kembali',
        () {
      final text = _decode(formatReceiptEscPos(
        receiptSale(payments: [payment('CASH', 10000)]),
        'Barang',
        receiptLabels,
      ));
      expect(text, contains('Metode: Metode CASH'));
      expect(text, contains('Total'));
      expect(text, contains('Bayar'));
      expect(text, contains('Kembali'));
      expect(text, isNot(contains('Bayar (Metode CASH)')));
    });

    test(
        'single non-cash payment: header names the method, body shows only Total',
        () {
      final text = _decode(formatReceiptEscPos(
        receiptSale(payments: [payment('TRANSFER', 10000)]),
        'Barang',
        receiptLabels,
      ));
      expect(text, contains('Metode: Metode TRANSFER'));
      expect(text, contains('Total'));
      expect(text, isNot(contains('Bayar')));
      expect(text, isNot(contains('Kembali')));
    });

    // A pure KOMPLIMEN sale is still a single payment, just not cash: only Total prints.
    test('single complimentary payment: no Bayar/Kembali', () {
      final text = _decode(formatReceiptEscPos(
        receiptSale(payments: [payment('KOMPLIMEN', 10000)]),
        'Barang',
        receiptLabels,
      ));
      expect(text, isNot(contains('Bayar')));
      expect(text, isNot(contains('Kembali')));
    });

    test(
        'split payment with cash: no header method line, Total once, a Bayar row per method, Kembali once',
        () {
      final text = _decode(formatReceiptEscPos(
        receiptSale(
          payments: [payment('CASH', 4000), payment('TRANSFER', 6000)],
        ),
        'Barang',
        receiptLabels,
      ));
      expect(text, isNot(contains('Metode:')));
      expect(text, contains('Bayar (Metode CASH)'));
      expect(text, contains('Bayar (Metode TRANSFER)'));
      expect(RegExp('Kembali').allMatches(text).length, equals(1));
    });

    test('split payment without cash: Bayar rows per method, no Kembali', () {
      final text = _decode(formatReceiptEscPos(
        receiptSale(
          payments: [payment('TRANSFER', 4000), payment('EDC', 6000)],
        ),
        'Barang',
        receiptLabels,
      ));
      expect(text, contains('Bayar (Metode TRANSFER)'));
      expect(text, contains('Bayar (Metode EDC)'));
      expect(text, isNot(contains('Kembali')));
    });

    test('marks a void sale', () {
      final text = _decode(formatReceiptEscPos(
          receiptSale(status: 'VOID'), 'Barang', receiptLabels));
      expect(text, contains('DIBATALKAN'));
    });

    test('falls back to the no-items label for an empty invoice', () {
      final text = _decode(formatReceiptEscPos(
        receiptSale(invoiceItems: const []),
        'Barang',
        receiptLabels,
      ));
      expect(text, contains('Tidak ada barang'));
    });

    test('prints each line of footer text after everything else', () {
      final text = _decode(formatReceiptEscPos(
        receiptSale(),
        'Barang',
        receiptLabels,
        'Terima kasih\nSampai jumpa',
      ));
      expect(text, contains('Terima kasih'));
      expect(text, contains('Sampai jumpa'));
    });

    test('prints the Finnesia branding line only when passed true', () {
      final without =
          _decode(formatReceiptEscPos(receiptSale(), 'Barang', receiptLabels));
      expect(without, isNot(contains(receiptLabels.finnesiaBranding)));

      final withBranding = _decode(formatReceiptEscPos(
        receiptSale(),
        'Barang',
        receiptLabels,
        null,
        true,
      ));
      expect(withBranding, contains(receiptLabels.finnesiaBranding));
    });

    // ---- Not in the oracle. Each pins a JavaScript semantic Dart lacks, verified by
    // ---- running the source in Node and diffing the bytes against this port.

    test('omits the outlet line when the outlet name is empty', () {
      // `if (sale.outlet?.name)`: JavaScript treats '' as falsy. Dart has no truthiness,
      // so a literal `!= null` port would print an empty line under the title.
      final text = _decode(formatReceiptEscPos(
        receiptSale(outletName: ''),
        'Barang',
        receiptLabels,
      ));
      final esc = String.fromCharCode(0x1b);
      final nul = String.fromCharCode(0);
      final lines = text.split('\n');
      // The sale number follows the title directly — there is no blank row between them.
      expect(lines[1], equals('${esc}E${nul}PS/001'));
      expect(text, isNot(contains('\n\n\n')));
    });

    test('omits the cashier line when the cashier name is empty', () {
      final text = _decode(formatReceiptEscPos(
        receiptSale(cashierName: ''),
        'Barang',
        receiptLabels,
      ));
      expect(text, isNot(contains('Kasir:')));
    });

    test(
        'falls back to transaction_date, and to the raw value when neither parses',
        () {
      // `sale.created_at || sale.transaction_date` — the JavaScript `||` chain. An empty
      // created_at must fall through, not print an empty date row.
      final fallback = _decode(formatReceiptEscPos(
        receiptSale(createdAt: '', transactionDate: '2026-09-09'),
        'Barang',
        receiptLabels,
      ));
      expect(fallback, contains('Sep 2026'));

      // Both empty: the chain evaluates to '' and the date row renders the dash.
      final bothEmpty = _decode(formatReceiptEscPos(
        receiptSale(createdAt: '', transactionDate: ''),
        'Barang',
        receiptLabels,
      ));
      expect(bothEmpty.split('\n').any((l) => l.endsWith('-')), isTrue);

      // Unparsable: formatDateTime returns the value untouched rather than throwing.
      final unparsable = _decode(formatReceiptEscPos(
        receiptSale(createdAt: 'not-a-date'),
        'Barang',
        receiptLabels,
      ));
      expect(unparsable, contains('not-a-date'));
    });

    test('prints an integral quantity without a decimal point', () {
      // The quantity comes from a `numeric(18,4)` column and `jsonDecode` hands Dart a
      // `double` where TypeScript had a plain `number`. Dart's `toString()` would render
      // `2.0` and the customer would read "2.0 x Rp 10.000" where the web app prints "2 x".
      final text = _decode(formatReceiptEscPos(
        receiptSale(invoiceItems: [invoiceItem(quantity: 2.0)]),
        'Barang',
        receiptLabels,
      ));
      expect(text, contains('2 x Rp 10.000'));
      expect(text, isNot(contains('2.0 x')));
    });
  });

  group('formatCategoryTicketEscPos', () {
    PrintableLine line({
      String id = 'l1',
      String name = 'Nasi Goreng',
      num quantity = 2,
    }) =>
        (
          id: id,
          name: name,
          quantity: quantity,
          categoryKey: 'cat_1',
          categoryName: 'Makanan',
        );

    const categoryLabels = CategoryTicketEscPosLabels(
      noItems: 'Kosong',
      tableNumber: 'No. Meja',
      queueNumber: 'No. Antrian',
    );

    test(
        'prints the category name, outlet, sale number, and each line with its quantity',
        () {
      final text = _decode(formatCategoryTicketEscPos(
        'Makanan',
        [line()],
        'Outlet Pusat',
        'PS/002',
        categoryLabels,
      ));
      expect(text, contains('Makanan'));
      expect(text, contains('Outlet Pusat'));
      expect(text, contains('PS/002'));
      expect(text, contains('Nasi Goreng'));
      expect(text, contains('x2'));
    });

    test('never prints a price — this is a kitchen ticket, not a bill', () {
      final text = _decode(formatCategoryTicketEscPos(
        'Makanan',
        [line(name: 'Ayam Bakar')],
        null,
        null,
        categoryLabels,
      ));
      expect(text, isNot(contains('Rp')));
    });

    test('falls back to the empty label with no lines', () {
      final text = _decode(formatCategoryTicketEscPos(
        'Makanan',
        const [],
        null,
        null,
        categoryLabels,
      ));
      expect(text, contains('Kosong'));
    });

    test('prints the table number only when present', () {
      final withTable = _decode(formatCategoryTicketEscPos(
        'Makanan',
        [line()],
        null,
        null,
        categoryLabels,
        'A1',
      ));
      expect(withTable, contains('No. Meja: A1'));

      final withoutTable = _decode(formatCategoryTicketEscPos(
        'Makanan',
        [line()],
        null,
        null,
        categoryLabels,
      ));
      expect(withoutTable, isNot(contains('No. Meja')));
    });

    test('prints the queue number only when present', () {
      final withQueue = _decode(formatCategoryTicketEscPos(
        'Makanan',
        [line()],
        null,
        null,
        categoryLabels,
        null,
        '12',
      ));
      expect(withQueue, contains('No. Antrian: 12'));

      final withoutQueue = _decode(formatCategoryTicketEscPos(
        'Makanan',
        [line()],
        null,
        null,
        categoryLabels,
      ));
      expect(withoutQueue, isNot(contains('No. Antrian')));
    });

    test('pads top and bottom: init + feed(2) head, feed(5) + cut tail', () {
      final arr = formatCategoryTicketEscPos(
        'Makanan',
        [line()],
        null,
        null,
        categoryLabels,
      );
      expect(arr.sublist(0, 5),
          equals(Uint8List.fromList([0x1b, 0x40, 0x1b, 0x64, 2])));
      expect(arr.sublist(arr.length - 6),
          equals(Uint8List.fromList([0x1b, 0x64, 5, 0x1d, 0x56, 1])));
    });

    // ---- Not in the oracle.

    test('omits the outlet and sale number lines when they are empty strings',
        () {
      // `if (outletName)` / `if (saleNumber)` — falsy in JavaScript, but Dart has no
      // truthiness, so a `!= null` port would print two blank lines before the divider.
      //
      // `now` is injected rather than left to the wall clock. This test used to assert on
      // `Sep 2026` while passing no clock, so it passed only during the month it was written
      // and failed on the first of the next one — the date is the print instant and has
      // nothing to do with what this test is about.
      final text = _decode(formatCategoryTicketEscPos(
        'Makanan',
        [line()],
        '',
        '',
        categoryLabels,
        null,
        null,
        DateTime.utc(2026, 9, 15, 10),
      ));
      final lines = text.split('\n');
      // The date line follows the category directly, so neither the outlet nor the sale
      // number produced a row.
      expect(lines[1], contains('Sep 2026'));
      expect(text, isNot(contains('\n\n\n')));
    });

    test('prints an integral quantity without a decimal point', () {
      final text = _decode(formatCategoryTicketEscPos(
        'Makanan',
        [line(quantity: 2.0)],
        null,
        null,
        categoryLabels,
      ));
      expect(text, contains('x2'));
      expect(text, isNot(contains('x2.0')));
    });
  });

  ShiftReportSummary summary({
    String number = 'SHIFT/001',
    String? cashierName = 'Budi',
    String? openedAt = '2026-09-09T08:00:00Z',
    num totalSales = 100000,
    num openingCash = 50000,
    Map<String, num> salesByMethod = const {'CASH': 70000, 'QRIS': 30000},
    num cashOut = 5000,
    num cashDrop = 0,
    List<NonCashTenderLine> nonCashTenders = const [
      (
        method: 'QRIS',
        reference: 'REF1',
        amount: 30000,
        saleNumber: 'PS/010',
      ),
    ],
    List<ProductSalesLine> productSales = const [],
  }) =>
      (
        number: number,
        cashierName: cashierName,
        openedAt: openedAt,
        totalSales: totalSales,
        openingCash: openingCash,
        salesByMethod: salesByMethod,
        cashOut: cashOut,
        cashDrop: cashDrop,
        nonCashTenders: nonCashTenders,
        productSales: productSales,
      );

  const shiftLabels = ShiftReportEscPosLabels(
    title: 'LAPORAN TUTUP SHIFT',
    cashier: 'Kasir',
    openedAt: 'Login',
    printedAt: 'Dicetak',
    totalSales: 'Total Belanja',
    paymentsByMethod: 'Pembayaran',
    total: 'Total',
    deposit: 'Setoran',
    openingCash: 'Setor Awal',
    cashSales: 'Pembayaran Tunai',
    cashOut: 'Tarik Uang',
    totalDeposit: 'Total Setoran',
    nonCashPayments: 'Pembayaran Non Tunai',
    tenderMethod: _methodLabel,
    noTenders: 'Tidak ada',
    productsSoldTitle: 'Rincian Produk',
    productsSoldTotal: 'Total Rincian Produk',
    finnesiaBranding: 'finnesia.com',
  );

  const printedAt = '2026-09-09T12:00:00Z';

  const kopiSusu = (
    productName: 'Kopi Susu',
    quantity: 3,
    unitPrice: 15000,
    total: 45000,
  );

  group('formatShiftReportEscPos', () {
    test('includes the shift number, cashier name, and total sales', () {
      final text =
          _decode(formatShiftReportEscPos(summary(), printedAt, shiftLabels));
      expect(text, contains('SHIFT/001'));
      expect(text, contains('Budi'));
      expect(text, contains('Rp 100.000'));
    });

    test('itemizes each non-cash tender with its sale number and reference',
        () {
      final text =
          _decode(formatShiftReportEscPos(summary(), printedAt, shiftLabels));
      expect(text, contains('PS/010'));
      expect(text, contains('REF1'));
      expect(text, contains('Metode QRIS'));
    });

    test('never lists cash among the non-cash tenders', () {
      final withCashTender = summary(nonCashTenders: const [
        (
          method: 'QRIS',
          reference: null,
          amount: 30000,
          saleNumber: 'PS/010',
        ),
      ]);
      final text = _decode(
          formatShiftReportEscPos(withCashTender, printedAt, shiftLabels));
      // "Metode CASH" would only appear if the formatter mistakenly injected cash into the
      // itemized section — the aggregate "Pembayaran" section is allowed to mention it.
      final nonCashSectionStart = text.indexOf(shiftLabels.nonCashPayments);
      expect(
          text.substring(nonCashSectionStart), isNot(contains('Metode CASH')));
    });

    test('falls back to the no-tenders label when the shift took only cash',
        () {
      final text = _decode(formatShiftReportEscPos(
        summary(nonCashTenders: const []),
        printedAt,
        shiftLabels,
      ));
      expect(text, contains('Tidak ada'));
    });

    test(
        'computes the cash deposit total from opening cash, cash sales, and cash out',
        () {
      final text =
          _decode(formatShiftReportEscPos(summary(), printedAt, shiftLabels));
      // opening_cash 50000 + cash sales 70000 - cash_out 5000 - cash_drop 0 = 115000
      expect(text, contains('Rp 115.000'));
    });

    // The per-product breakdown is opt-in (POSPreferences.show_product_sales_summary), so
    // the formatter must stay silent about it unless the caller explicitly passes true —
    // the response always carries product_sales regardless of the preference.
    test('omits the product sales section when showProductSales is not passed',
        () {
      final text = _decode(formatShiftReportEscPos(
        summary(productSales: const [kopiSusu]),
        printedAt,
        shiftLabels,
      ));
      expect(text, isNot(contains('Rincian Produk')));
      expect(text, isNot(contains('Kopi Susu')));
    });

    test(
        'omits the product sales section when showProductSales is true but there is nothing sold',
        () {
      final text = _decode(formatShiftReportEscPos(
        summary(productSales: const []),
        printedAt,
        shiftLabels,
        true,
      ));
      expect(text, isNot(contains('Rincian Produk')));
    });

    test(
        'prints each product with quantity x unit price and the line total when enabled',
        () {
      final text = _decode(formatShiftReportEscPos(
        summary(productSales: const [kopiSusu]),
        printedAt,
        shiftLabels,
        true,
      ));
      expect(text, contains('Rincian Produk'));
      expect(text, contains('Kopi Susu'));
      expect(text, contains('3 x Rp 15.000'));
      expect(text, contains('Rp 45.000'));
    });

    // Reposition (I18): must print above Pembayaran Non Tunai, not after.
    test(
        'places the product sales section before Pembayaran Non Tunai when enabled',
        () {
      final text = _decode(formatShiftReportEscPos(
        summary(productSales: const [kopiSusu]),
        printedAt,
        shiftLabels,
        true,
      ));
      final productIndex = text.indexOf(shiftLabels.productsSoldTitle);
      final nonCashIndex = text.indexOf(shiftLabels.nonCashPayments);
      expect(productIndex, greaterThan(-1));
      expect(nonCashIndex, greaterThan(-1));
      expect(productIndex, lessThan(nonCashIndex));
    });

    // Audit requirement (I18): total sums the product lines themselves, not total_sales —
    // the fixture makes them differ (line sum 65000 vs total_sales 100000) to prove it.
    test(
        'prints a total row after the product list, summed from the product lines themselves',
        () {
      final text = _decode(formatShiftReportEscPos(
        summary(productSales: const [
          kopiSusu,
          (
            productName: 'Roti Bakar',
            quantity: 2,
            unitPrice: 10000,
            total: 20000,
          ),
        ]),
        printedAt,
        shiftLabels,
        true,
      ));
      expect(text, contains(shiftLabels.productsSoldTotal));
      expect(text, contains('Rp 65.000'));
    });

    test('prints each line of footer text after everything else', () {
      final text = _decode(formatShiftReportEscPos(
        summary(),
        printedAt,
        shiftLabels,
        false,
        'Terima kasih\nSampai jumpa',
      ));
      expect(text, contains('Terima kasih'));
      expect(text, contains('Sampai jumpa'));
    });

    test('separates the footer with a blank line, not a divider', () {
      final text = _decode(formatShiftReportEscPos(
        summary(),
        printedAt,
        shiftLabels,
        false,
        'Terima kasih\nSampai jumpa',
      ));
      final lines = text.split('\n');
      final footerIndex = lines.indexWhere((l) => l.contains('Terima kasih'));
      expect(footerIndex, greaterThan(0));
      expect(lines[footerIndex - 1], equals(''));
    });

    test('prints the Finnesia branding line only when passed true', () {
      final without =
          _decode(formatShiftReportEscPos(summary(), printedAt, shiftLabels));
      expect(without, isNot(contains(shiftLabels.finnesiaBranding)));

      final withBranding = _decode(formatShiftReportEscPos(
        summary(),
        printedAt,
        shiftLabels,
        false,
        null,
        true,
      ));
      expect(withBranding, contains(shiftLabels.finnesiaBranding));
    });

    test('pads top and bottom: init + feed(2) head, feed(5) + cut tail', () {
      final arr = formatShiftReportEscPos(summary(), printedAt, shiftLabels);
      expect(arr.sublist(0, 5),
          equals(Uint8List.fromList([0x1b, 0x40, 0x1b, 0x64, 2])));
      expect(arr.sublist(arr.length - 6),
          equals(Uint8List.fromList([0x1b, 0x64, 5, 0x1d, 0x56, 1])));
    });

    // ---- Not in the oracle.

    test('prints the payment methods in insertion order, not sorted', () {
      // `Object.entries` iterates a JS object in insertion order, and Dart's Map does the
      // same — but relying on that silently would be relying on an implementation detail.
      // A sorted port would print CASH before QRIS and look entirely plausible.
      final text = _decode(formatShiftReportEscPos(
        summary(salesByMethod: const {'QRIS': 30000, 'CASH': 70000}),
        printedAt,
        shiftLabels,
      ));
      expect(
          text.indexOf('Metode QRIS'), lessThan(text.indexOf('Metode CASH')));
    });

    test('treats a shift with no cash method as zero cash sales', () {
      // `summary.sales_by_method['CASH'] ?? 0` — the `??` is load-bearing, not defensive:
      // a card-only shift has no CASH key at all, and the deposit would become NaN.
      final text = _decode(formatShiftReportEscPos(
        summary(salesByMethod: const {'QRIS': 30000}),
        printedAt,
        shiftLabels,
      ));
      // opening_cash 50000 + cash sales 0 - cash_out 5000 - cash_drop 0 = 45000
      expect(text, contains('Rp 45.000'));
      expect(text, isNot(contains('NaN')));
    });

    test('prints an integral product quantity without a decimal point', () {
      final text = _decode(formatShiftReportEscPos(
        summary(productSales: const [
          (
            productName: 'Kopi Susu',
            quantity: 3.0,
            unitPrice: 15000,
            total: 45000,
          ),
        ]),
        printedAt,
        shiftLabels,
        true,
      ));
      expect(text, contains('3 x Rp 15.000'));
      expect(text, isNot(contains('3.0 x')));
    });

    test('prints a tender with no reference as an empty left column', () {
      // `tender.reference ?? ''` — an optional reference must not render the word "null".
      final text = _decode(formatShiftReportEscPos(
        summary(nonCashTenders: const [
          (
            method: 'QRIS',
            reference: null,
            amount: 30000,
            saleNumber: 'PS/010',
          ),
        ]),
        printedAt,
        shiftLabels,
      ));
      expect(text, contains('PS/010 Metode QRIS'));
      expect(text, isNot(contains('null')));
    });
  });
}
