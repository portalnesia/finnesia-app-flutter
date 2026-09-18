/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_receipt.dart';
import 'package:pn_types/src/category.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/apps/web/src/lib/pos-receipt.test.ts`.
// Inputs and expectations are copied unchanged; only the syntax changed
// (describe/it -> group/test, toBe -> equals). 6 cases, plus 1 added below.

/// Mirrors the source test's `item(over)` builder: every field the receipt reads, with the
/// oracle's own defaults (quantity 1, price 10.000, no discount).
///
/// The source test casts with `as SalesInvoiceItem` because the real type has twenty-odd
/// fields the receipt never touches. The Dart `InvoiceItem` record declares only the seven
/// that are read, so no cast is needed and a caller cannot pass a field this module ignores.
InvoiceItem invoiceItem({
  String id = 'itm_1',
  String? productName,
  String? description,
  num quantity = 1,
  num price = 10000,
  num lineSubtotal = 10000,
  num lineTotal = 10000,
  Category? category,
}) =>
    (
      id: id,
      productName: productName,
      description: description,
      quantity: quantity,
      price: price,
      lineSubtotal: lineSubtotal,
      lineTotal: lineTotal,
      category: category,
    );

void main() {
  group('posReceiptLines', () {
    test('reads the lines off the invoice, where the server actually puts them',
        () {
      final lines = posReceiptLines(
        invoiceItems: [
          invoiceItem(productName: 'Kopi Susu'),
        ],
        fallbackName: 'Barang',
      );
      expect(lines, hasLength(1));
      expect(lines[0].name, equals('Kopi Susu'));
    });

    test('never shows an id to the customer when the product is gone', () {
      // The item still carries its product_id; the point is that nothing in the name
      // derivation reaches for it.
      final lines = posReceiptLines(
        invoiceItems: [invoiceItem()],
        fallbackName: 'Barang',
      );
      expect(lines[0].name, equals('Barang'));
      expect(lines[0].name, isNot(contains('01M1')));
    });

    test('prefers a typed description over the fallback', () {
      final lines = posReceiptLines(
        invoiceItems: [invoiceItem(description: 'Titipan warung')],
        fallbackName: 'Barang',
      );
      expect(lines[0].name, equals('Titipan warung'));
    });

    test(
        'reports the discount the customer actually got, however it was entered',
        () {
      final byAmount = posReceiptLines(
        invoiceItems: [
          invoiceItem(quantity: 2, price: 10000, lineSubtotal: 17000),
        ],
        fallbackName: 'Barang',
      );
      expect(byAmount[0].discount, equals(3000));

      final byPercent = posReceiptLines(
        invoiceItems: [
          invoiceItem(quantity: 2, price: 10000, lineSubtotal: 18000),
        ],
        fallbackName: 'Barang',
      );
      expect(byPercent[0].discount, equals(2000));
    });

    test(
        'never reports a negative discount when tax pushes the line above its base',
        () {
      final lines = posReceiptLines(
        invoiceItems: [
          invoiceItem(quantity: 1, price: 10000, lineSubtotal: 11000),
        ],
        fallbackName: 'Barang',
      );
      expect(lines[0].discount, equals(0));
    });

    // A sale fetched from the list endpoint carries no invoice relation; the receipt must
    // render empty rather than throw on the way to the printer.
    test('survives a sale with no invoice loaded', () {
      expect(
          posReceiptLines(invoiceItems: null, fallbackName: 'Barang'), isEmpty);
      expect(posReceiptLines(invoiceItems: const [], fallbackName: 'Barang'),
          isEmpty);
    });

    // BUKAN dari oracle. The source's chain is `item.product?.name || item.description ||
    // fallbackName`, and JavaScript's `||` treats `''` as absent. Dart's `??` only treats
    // `null` as absent, so a literal port would let an empty product name win and print a
    // **blank line** on the customer's receipt instead of the fallback.
    //
    // Verified against the running source: `product.name = ''` gives `'Barang'` there, and
    // so does `description = ''`. The empty-string case is reachable — a product whose name
    // was cleared in the catalogue, or a description field submitted empty by a form.
    test('treats an empty name as absent, the way JavaScript does', () {
      expect(
        posReceiptLines(
          invoiceItems: [invoiceItem(productName: '')],
          fallbackName: 'Barang',
        )[0]
            .name,
        equals('Barang'),
      );
      expect(
        posReceiptLines(
          invoiceItems: [invoiceItem(description: '')],
          fallbackName: 'Barang',
        )[0]
            .name,
        equals('Barang'),
      );
      // A description still wins over the fallback when it has content, and the product
      // name still wins over the description — the chain's order is unchanged.
      expect(
        posReceiptLines(
          invoiceItems: [
            invoiceItem(productName: 'Kopi', description: 'Titipan'),
          ],
          fallbackName: 'Barang',
        )[0]
            .name,
        equals('Kopi'),
      );
      expect(
        posReceiptLines(
          invoiceItems: [invoiceItem(description: '   ')],
          fallbackName: 'Barang',
        )[0]
            .name,
        equals('   '),
      );
    });
  });
}
