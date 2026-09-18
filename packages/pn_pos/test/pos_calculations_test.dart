/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_calculations.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/packages/shared/src/pos/pos-calculations.test.ts`.
// Inputs and expectations are copied unchanged; only the syntax changed
// (describe/it -> group/test, toBe -> equals). 4 cases.
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
  });
}
