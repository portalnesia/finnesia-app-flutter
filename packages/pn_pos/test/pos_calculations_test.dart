/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_pos/src/pos_calculations.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/product.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/packages/shared/src/pos/pos-calculations.test.ts`
// on origin/dev-putu.
CartMathLine _line({
  required num quantity,
  required num price,
  num? discountPercent,
  num? discountAmount,
  num? taxRate,
  bool isTaxInclusive = false,
}) =>
    CartMathLine(
      quantity: quantity,
      price: price,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      taxRate: taxRate,
      isTaxInclusive: isTaxInclusive,
    );

CartTotals _totalsWithSettings(
  List<CartLine> lines, {
  required POSPreferences preferences,
}) =>
    totalsOfLines(lines, preferences: preferences);

Product _taxedProduct() => Product.fromJson(
      jsonDecode('''
        {"id":"p1","name":"Kopi","unit_id":"u1","sell_price":10000,
         "tax_id":"tax_1","tax":{"id":"tax_1","name":"PPN","rate":11}}''')
          as Map<String, dynamic>,
    );

void main() {
  group('pos calculations', () {
    test('calcLineTotal with discount and tax', () {
      expect(
        calcLineTotal(
          const CartMathLine(quantity: 2, price: 10000, discountPercent: 10),
        ),
        equals(18000),
      );
      expect(
        calcLineTotal(
          const CartMathLine(
            quantity: 1,
            price: 10000,
            discountAmount: 500,
            taxRate: 10,
          ),
        ),
        equals(10450),
      );
    });

    test('calcCartTotals matches service math', () {
      final totals = calcCartTotals(const [
        CartMathLine(quantity: 2, price: 10000),
        CartMathLine(quantity: 1, price: 5000, discountPercent: 20),
      ]);
      expect(totals.subtotal, equals(25000));
      expect(totals.discount, equals(1000));
      expect(totals.grandTotal, equals(24000));
    });

    test('calcChange and isTenderSufficient', () {
      expect(calcChange(50000, 30000), equals(20000));
      expect(calcChange(20000, 30000), equals(0));
      expect(isTenderSufficient(30000, 30000), isTrue);
      expect(isTenderSufficient(29999, 30000), isFalse);
    });

    test('zero qty and empty cart', () {
      expect(calcCartTotals(const []).grandTotal, equals(0));
      expect(calcLineTotal(const CartMathLine(quantity: 0, price: 10000)),
          equals(0));
    });

    test('adds an exclusive tax on top of the line', () {
      final totals = calcCartTotals([
        _line(quantity: 1, price: 10000, taxRate: 11),
      ]);
      expect(totals.tax, 1100);
      expect(totals.grandTotal, 11100);
    });

    test('carves an inclusive tax out of the price the cashier entered', () {
      final totals = calcCartTotals([
        _line(
          quantity: 1,
          price: 10000,
          taxRate: 11,
          isTaxInclusive: true,
        ),
      ]);
      final lineTax = 10000 - 10000 / 1.11;
      expect(totals.tax, lineTax);
      expect(totals.subtotal, 10000 - lineTax);
      expect(totals.grandTotal, 10000);
    });

    test('resolves the same inclusive line through line and cart totals', () {
      final line = _line(
        quantity: 1,
        price: 10000,
        discountPercent: 10,
        taxRate: 11,
        isTaxInclusive: true,
      );
      final net = 9000;
      final lineTax = net - net / 1.11;
      final totals = calcCartTotals([line]);
      expect(totals.tax, lineTax);
      expect(calcLineTotal(line), totals.grandTotal);
    });

    test('leaves the tax at zero without a tax rate', () {
      expect(
        calcCartTotals(const [CartMathLine(quantity: 2, price: 10000)]).tax,
        0,
      );
      expect(
        calcCartTotals(const [CartMathLine(quantity: 2, price: 10000)])
            .grandTotal,
        20000,
      );
    });

    test('lets the percentage win when a line carries both discounts', () {
      final totals = calcCartTotals([
        _line(
          quantity: 1,
          price: 10000,
          discountPercent: 10,
          discountAmount: 500,
        ),
      ]);
      expect(totals.discount, 1000);
      expect(totals.grandTotal, 9000);
    });

    test('never lets the grand total go negative', () {
      final totals = calcCartTotals([
        const CartMathLine(
          quantity: 1,
          price: 1000,
          discountAmount: 5000,
        ),
      ]);
      expect(totals.grandTotal, 0);
    });
  });

  group('taxed product cart totals', () {
    test('uses product tax only while tax is enabled', () {
      final line = CartLine(id: 'line_1', product: _taxedProduct(), qty: 1);

      final exclusive = _totalsWithSettings(
        [line],
        preferences:
            const POSPreferences(requireShift: false, taxEnabled: true),
      );
      expect(exclusive.subtotal, 10000);
      expect(exclusive.tax, 1100);
      expect(exclusive.grandTotal, 11100);

      final inclusive = _totalsWithSettings(
        [line],
        preferences: const POSPreferences(
          requireShift: false,
          taxEnabled: true,
          priceIncludesTax: true,
        ),
      );
      expect(inclusive.tax, 10000 - 10000 / 1.11);
      expect(inclusive.grandTotal, 10000);

      final disabled = _totalsWithSettings(
        [line],
        preferences: const POSPreferences(requireShift: false),
      );
      expect(disabled.tax, 0);
      expect(disabled.grandTotal, 10000);
    });
  });
}
