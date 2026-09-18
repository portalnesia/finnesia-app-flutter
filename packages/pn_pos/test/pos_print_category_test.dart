/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_print_category.dart';
import 'package:pn_types/src/category.dart';
import 'package:pn_types/src/product.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/apps/web/src/lib/pos-print-category.test.ts`.
// Inputs and expectations are copied unchanged; only the syntax changed
// (describe/it -> group/test, toEqual -> equals). 9 cases.

const makanan = Category(id: 'cat_makanan', name: 'Makanan');
final nasiGoreng = Category(
  id: 'cat_nasgor',
  name: 'Nasi Goreng',
  parentId: 'cat_makanan',
  parent: makanan,
);
const minuman = Category(id: 'cat_minuman', name: 'Minuman');

Product product(String id, String name, [Category? category]) => Product(
      id: id,
      name: name,
      unitId: 'u1',
      category: category,
    );

void main() {
  group('topLevelCategory', () {
    test('returns null for no category', () {
      expect(topLevelCategory(null), isNull);
    });

    test('returns the category itself when it has no parent', () {
      expect(
        topLevelCategory(makanan),
        equals((key: 'cat_makanan', name: 'Makanan')),
      );
    });

    test('rolls a sub-category up to its parent', () {
      expect(
        topLevelCategory(nasiGoreng),
        equals((key: 'cat_makanan', name: 'Makanan')),
      );
    });
  });

  group('cartLinesWithCategory', () {
    test('maps a live cart line to its top-level category', () {
      final lines = [
        CartLine(
            id: 'l1',
            product: product('p1', 'Nasi Goreng Spesial', nasiGoreng),
            qty: 2),
      ];
      expect(
        cartLinesWithCategory(lines, 'Tanpa Kategori'),
        equals([
          (
            id: 'l1',
            name: 'Nasi Goreng Spesial',
            quantity: 2,
            categoryKey: 'cat_makanan',
            categoryName: 'Makanan',
          ),
        ]),
      );
    });

    test(
        'falls back to the uncategorized label when the product has no category',
        () {
      final lines = [
        CartLine(id: 'l1', product: product('p1', 'Es Batu'), qty: 1)
      ];
      final line = cartLinesWithCategory(lines, 'Tanpa Kategori')[0];
      expect(line.categoryKey, equals('__none__'));
      expect(line.categoryName, equals('Tanpa Kategori'));
    });
  });

  group('receiptLinesWithCategory', () {
    test('maps a posted sale line to its top-level category', () {
      final lines = receiptLinesWithCategory(
        invoiceItems: [
          (
            id: 'it1',
            productName: 'Es Teh',
            description: null,
            quantity: 3,
            price: 10000,
            lineSubtotal: 30000,
            lineTotal: 30000,
            category: minuman,
          ),
        ],
        fallbackName: 'Produk',
        uncategorizedLabel: 'Tanpa Kategori',
      );
      expect(
        lines,
        equals([
          (
            id: 'it1',
            name: 'Es Teh',
            quantity: 3,
            categoryKey: 'cat_minuman',
            categoryName: 'Minuman',
          ),
        ]),
      );
    });

    test('has nothing to print when the sale has no invoice items', () {
      expect(
        receiptLinesWithCategory(
          invoiceItems: null,
          fallbackName: 'Produk',
          uncategorizedLabel: 'Tanpa Kategori',
        ),
        isEmpty,
      );
    });
  });

  group('groupByCategory', () {
    test('groups in first-seen order, not alphabetically', () {
      final groups = groupByCategory(const [
        (
          id: 'l1',
          name: 'Es Teh',
          quantity: 1,
          categoryKey: 'cat_minuman',
          categoryName: 'Minuman'
        ),
        (
          id: 'l2',
          name: 'Nasi Goreng',
          quantity: 1,
          categoryKey: 'cat_makanan',
          categoryName: 'Makanan'
        ),
        (
          id: 'l3',
          name: 'Es Jeruk',
          quantity: 1,
          categoryKey: 'cat_minuman',
          categoryName: 'Minuman'
        ),
      ]);
      expect(
          groups.map((g) => g.name).toList(), equals(['Minuman', 'Makanan']));
      expect(groups[0].lines, hasLength(2));
      expect(groups[1].lines, hasLength(1));
    });

    test('returns nothing for an empty ticket', () {
      expect(groupByCategory(const []), isEmpty);
    });
  });
}
