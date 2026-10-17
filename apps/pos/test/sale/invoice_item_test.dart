/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_receipt.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pos/sale/invoice_item.dart';

ReceiptLine receiptLine(SalesInvoiceItem item) => posReceiptLines(
  invoiceItems: [toInvoiceItem(item)],
  fallbackName: 'Barang',
).single;

void main() {
  group('invoice item receipt mapping', () {
    test('does not print inclusive tax as a line discount', () {
      const item = SalesInvoiceItem(
        id: 'i_tax',
        quantity: 1,
        price: 10000,
        discountPercent: 0,
        discountAmount: 0,
        taxId: 'tax_1',
        taxRate: 11,
        isTaxInclusive: true,
        lineSubtotal: 9009.009009,
        lineTax: 990.990991,
        lineTotal: 10000,
      );

      expect(receiptLine(item).discount, 0);
    });

    test('prints the entered discount and percentage wins over amount', () {
      const item = SalesInvoiceItem(
        id: 'i_discount',
        quantity: 1,
        price: 10000,
        discountPercent: 10,
        discountAmount: 500,
        taxId: 'tax_1',
        taxRate: 11,
        isTaxInclusive: true,
        lineSubtotal: 8108.108108,
        lineTax: 891.891892,
        lineTotal: 9000,
      );

      expect(receiptLine(item).discount, 1000);
      expect(receiptLine(item).total, 9000);
    });
  });
}
