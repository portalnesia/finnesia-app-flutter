/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Emits the JSON cases that the differential check compares against the TypeScript source.
///
/// Not a test — it is run by hand when re-verifying the port against `finnesia-monorepo`:
///
/// ```bash
/// # 1. Dart side
/// cd packages/pn_pos && dart run tool/escpos_format_cases.dart > /tmp/dart.json
/// # 2. TypeScript side — the matching generator lives next to the source it drives
/// cd finnesia-monorepo/apps/web && bun run src/lib/__probe-escpos-format.ts > /tmp/ts.json
/// # 3. Compare
/// python tool/compare_cases.py /tmp/dart.json /tmp/ts.json
/// ```
///
/// It lives in `tool/` rather than `test/` on purpose: `.claude/rules/testing.md` §3 forbids
/// a second test file per module, and this is not a test — it is the fixture generator for
/// a one-off cross-repo comparison. The cases below mirror the ones in
/// `test/pos_escpos_format_test.dart`, so the two stay in step.
library;

import 'dart:convert';

import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_escpos_format.dart';
import 'package:pn_pos/src/pos_receipt.dart';

String _method(String m) => 'Metode $m';

final _receiptLabels = ReceiptEscPosLabels(
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
  tenderMethod: _method,
  paidByMethod: (m) => 'Bayar (Metode $m)',
  finnesiaBranding: 'finnesia.com',
);

const _categoryLabels = CategoryTicketEscPosLabels(
  noItems: 'Kosong',
  tableNumber: 'No. Meja',
  queueNumber: 'No. Antrian',
);

final _shiftLabels = ShiftReportEscPosLabels(
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
  tenderMethod: _method,
  noTenders: 'Tidak ada',
  productsSoldTitle: 'Rincian Produk',
  productsSoldTotal: 'Total Rincian Produk',
  finnesiaBranding: 'finnesia.com',
);

InvoiceItem _item({
  String? productName = 'Kopi Susu',
  String? description,
  num quantity = 1,
  num price = 10000,
  num lineSubtotal = 10000,
  num lineTotal = 10000,
}) =>
    (
      id: 'itm_1',
      productName: productName,
      description: description,
      quantity: quantity,
      price: price,
      lineSubtotal: lineSubtotal,
      lineTotal: lineTotal,
      category: null,
    );

ReceiptSale _sale({
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
      invoiceItems: invoiceItems ?? [_item()],
      payments: payments,
    );

ShiftReportSummary _summary({
  String number = 'SHIFT/001',
  String? cashierName = 'Budi',
  String? openedAt = '2026-09-09T08:00:00Z',
  num totalSales = 100000,
  num openingCash = 50000,
  Map<String, num> salesByMethod = const {'CASH': 70000, 'QRIS': 30000},
  num cashOut = 5000,
  num cashDrop = 0,
  List<NonCashTenderLine> nonCashTenders = const [
    (method: 'QRIS', reference: 'REF1', amount: 30000, saleNumber: 'PS/010'),
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

const _printedAt = '2026-09-09T12:00:00Z';

void main() async {
  await initializePosDateTime();
  initializePosNumberFormat();

  final out = <String, List<int>>{};

  out['bytes_receipt_simple'] =
      formatReceiptEscPos(_sale(), 'Barang', _receiptLabels);
  out['bytes_receipt_full'] = formatReceiptEscPos(
    _sale(
      tableNumber: 'A1',
      queueNumber: '12',
      status: 'VOID',
      subtotal: 100000,
      grandTotal: 90000,
      discountAmount: 10000,
      taxAmount: 5000,
      tenderedAmount: 100000,
      changeAmount: 10000,
      outletName: 'Outlet Pusat',
      cashierName: 'Budi',
      payments: [(method: 'CASH', amount: 90000)],
      invoiceItems: [
        _item(quantity: 2, price: 50000, lineSubtotal: 90000, lineTotal: 90000),
      ],
    ),
    'Barang',
    _receiptLabels,
    'Terima kasih\nSampai jumpa',
    true,
  );
  out['bytes_receipt_split_cash'] = formatReceiptEscPos(
    _sale(
      subtotal: 100000,
      grandTotal: 90000,
      discountAmount: 10000,
      payments: [
        (method: 'CASH', amount: 50000),
        (method: 'TRANSFER', amount: 40000),
      ],
    ),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_split_nocash'] = formatReceiptEscPos(
    _sale(
      payments: [
        (method: 'TRANSFER', amount: 4000),
        (method: 'EDC', amount: 6000),
      ],
    ),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_komplimen'] = formatReceiptEscPos(
    _sale(payments: [(method: 'KOMPLIMEN', amount: 10000)]),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_empty_invoice'] = formatReceiptEscPos(
    _sale(invoiceItems: const []),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_empty_outlet'] = formatReceiptEscPos(
    _sale(outletName: ''),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_empty_cashier'] = formatReceiptEscPos(
    _sale(cashierName: ''),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_empty_dates'] = formatReceiptEscPos(
    _sale(createdAt: '', transactionDate: ''),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_bad_date'] = formatReceiptEscPos(
    _sale(createdAt: 'not-a-date'),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_empty_footer'] = formatReceiptEscPos(
    _sale(),
    'Barang',
    _receiptLabels,
    '',
  );
  out['bytes_receipt_footer_no_text'] = formatReceiptEscPos(
    _sale(),
    'Barang',
    _receiptLabels,
    null,
    true,
  );
  out['bytes_receipt_no_payments'] = formatReceiptEscPos(
    _sale(payments: const []),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_line_discount'] = formatReceiptEscPos(
    _sale(
      invoiceItems: [
        _item(quantity: 2, price: 10000, lineSubtotal: 17000, lineTotal: 17000)
      ],
    ),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_double_qty'] = formatReceiptEscPos(
    _sale(invoiceItems: [_item(quantity: 2.0)]),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_fractional_qty'] = formatReceiptEscPos(
    _sale(invoiceItems: [_item(quantity: 2.5)]),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_long_right'] = formatReceiptEscPos(
    _sale(grandTotal: 1234567890123),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_long_name'] = formatReceiptEscPos(
    _sale(
      invoiceItems: [
        _item(productName: 'Kopi Susu Spesial Gula Aren Extra Panjang Sekali'),
      ],
    ),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_non_ascii'] = formatReceiptEscPos(
    _sale(invoiceItems: [_item(productName: 'Kopi 日本語 Susu')]),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_empty_product_name'] = formatReceiptEscPos(
    _sale(invoiceItems: [_item(productName: '', description: 'Titipan')]),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_whitespace_product_name'] = formatReceiptEscPos(
    _sale(invoiceItems: [_item(productName: '   ')]),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_nan_total'] = formatReceiptEscPos(
    _sale(grandTotal: double.nan),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_nan_qty'] = formatReceiptEscPos(
    _sale(invoiceItems: [_item(quantity: double.nan)]),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_table_only'] = formatReceiptEscPos(
    _sale(tableNumber: 'A1'),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_queue_only'] = formatReceiptEscPos(
    _sale(queueNumber: '12'),
    'Barang',
    _receiptLabels,
  );
  out['bytes_receipt_branding_only'] = formatReceiptEscPos(
    _sale(),
    'Barang',
    _receiptLabels,
    null,
    true,
  );
  out['bytes_receipt_giro_payment'] = formatReceiptEscPos(
    _sale(payments: [(method: 'GIRO', amount: 10000)]),
    'Barang',
    _receiptLabels,
  );

  final catLine = (
    id: 'l1',
    name: 'Nasi Goreng',
    quantity: 2,
    categoryKey: 'cat_1',
    categoryName: 'Makanan',
  );

  // The category ticket stamps itself with the print instant, so both sides are given the
  // same one — otherwise the comparison measures how far apart the two processes started.
  final frozenNow = DateTime.utc(2026, 9, 19, 7, 4);
  out['bytes_category_full'] = formatCategoryTicketEscPos(
    'Makanan',
    [catLine],
    'Outlet Pusat',
    'PS/002',
    _categoryLabels,
    'A1',
    '12',
    frozenNow,
  );
  out['bytes_category_minimal'] = formatCategoryTicketEscPos(
    'Makanan',
    [catLine],
    null,
    null,
    _categoryLabels,
    null,
    null,
    frozenNow,
  );
  out['bytes_category_empty_strings'] = formatCategoryTicketEscPos(
    'Makanan',
    [catLine],
    '',
    '',
    _categoryLabels,
    null,
    null,
    frozenNow,
  );
  out['bytes_category_no_lines'] = formatCategoryTicketEscPos(
    'Makanan',
    const [],
    null,
    null,
    _categoryLabels,
    null,
    null,
    frozenNow,
  );
  out['bytes_category_no_price'] = formatCategoryTicketEscPos(
    'Makanan',
    [
      (
        id: 'l1',
        name: 'Ayam Bakar',
        quantity: 2,
        categoryKey: 'c',
        categoryName: 'M'
      )
    ],
    null,
    null,
    _categoryLabels,
    null,
    null,
    frozenNow,
  );
  out['bytes_category_zero_qty'] = formatCategoryTicketEscPos(
    'Makanan',
    [
      (
        id: 'l1',
        name: 'Nasi Goreng',
        quantity: 0,
        categoryKey: 'c',
        categoryName: 'M'
      )
    ],
    null,
    null,
    _categoryLabels,
    null,
    null,
    frozenNow,
  );
  out['bytes_category_empty_name'] = formatCategoryTicketEscPos(
    'Makanan',
    [(id: 'l1', name: '', quantity: 2, categoryKey: 'c', categoryName: 'M')],
    null,
    null,
    _categoryLabels,
    null,
    null,
    frozenNow,
  );
  out['bytes_category_double_qty'] = formatCategoryTicketEscPos(
    'Makanan',
    [
      (
        id: 'l1',
        name: 'Nasi Goreng',
        quantity: 2.0,
        categoryKey: 'c',
        categoryName: 'M'
      )
    ],
    null,
    null,
    _categoryLabels,
    null,
    null,
    frozenNow,
  );

  out['bytes_shift_default'] =
      formatShiftReportEscPos(_summary(), _printedAt, _shiftLabels);
  out['bytes_shift_no_cash'] = formatShiftReportEscPos(
    _summary(salesByMethod: const {'QRIS': 30000}),
    _printedAt,
    _shiftLabels,
  );
  out['bytes_shift_empty_methods'] = formatShiftReportEscPos(
    _summary(salesByMethod: const {}),
    _printedAt,
    _shiftLabels,
  );
  out['bytes_shift_reordered_methods'] = formatShiftReportEscPos(
    _summary(salesByMethod: const {'QRIS': 30000, 'CASH': 70000}),
    _printedAt,
    _shiftLabels,
  );
  out['bytes_shift_no_tenders'] = formatShiftReportEscPos(
    _summary(nonCashTenders: const []),
    _printedAt,
    _shiftLabels,
  );
  out['bytes_shift_tender_no_ref'] = formatShiftReportEscPos(
    _summary(nonCashTenders: const [
      (method: 'QRIS', reference: null, amount: 30000, saleNumber: 'PS/010'),
    ]),
    _printedAt,
    _shiftLabels,
  );
  out['bytes_shift_empty_cashier'] = formatShiftReportEscPos(
    _summary(cashierName: ''),
    _printedAt,
    _shiftLabels,
  );
  out['bytes_shift_no_cashier'] = formatShiftReportEscPos(
    _summary(cashierName: null),
    _printedAt,
    _shiftLabels,
  );
  out['bytes_shift_products_off'] = formatShiftReportEscPos(
    _summary(productSales: const [
      (productName: 'Kopi Susu', quantity: 3, unitPrice: 15000, total: 45000),
    ]),
    _printedAt,
    _shiftLabels,
  );
  out['bytes_shift_products_on'] = formatShiftReportEscPos(
    _summary(productSales: const [
      (productName: 'Kopi Susu', quantity: 3, unitPrice: 15000, total: 45000),
      (productName: 'Roti Bakar', quantity: 2, unitPrice: 10000, total: 20000),
    ]),
    _printedAt,
    _shiftLabels,
    true,
  );
  out['bytes_shift_products_empty_name'] = formatShiftReportEscPos(
    _summary(productSales: const [
      (productName: '', quantity: 1, unitPrice: 1000, total: 1000),
    ]),
    _printedAt,
    _shiftLabels,
    true,
  );
  out['bytes_shift_products_double_qty'] = formatShiftReportEscPos(
    _summary(productSales: const [
      (productName: 'Kopi Susu', quantity: 3.0, unitPrice: 15000, total: 45000),
    ]),
    _printedAt,
    _shiftLabels,
    true,
  );
  out['bytes_shift_footer'] = formatShiftReportEscPos(
    _summary(),
    _printedAt,
    _shiftLabels,
    false,
    'Terima kasih\nSampai jumpa',
  );
  out['bytes_shift_branding'] = formatShiftReportEscPos(
    _summary(),
    _printedAt,
    _shiftLabels,
    false,
    null,
    true,
  );
  out['bytes_shift_giro_tender'] = formatShiftReportEscPos(
    _summary(nonCashTenders: const [
      (method: 'GIRO', reference: 'G1', amount: 30000, saleNumber: 'PS/011'),
    ]),
    _printedAt,
    _shiftLabels,
  );

  print(jsonEncode(out));
}
