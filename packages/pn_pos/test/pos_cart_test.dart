/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_types/src/product.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/packages/shared/src/pos/pos-cart.test.ts`.
// Inputs and expectations are copied unchanged; only the syntax changed
// (describe/it -> group/test, toBe -> equals, toBeUndefined -> isNull).
//
// 25 cases, not the 22 the counting command in `.claude/rules/cross-repo.md` §3
// reports. That command matches `it(` and `it.each(` as *lines*, so it counts the
// parameterized block once and misses the three extra rows it expands into
// (4 rows, 1 line). Inputs and expectations are unaffected; only the tally is.
Product product({
  String id = 'prd_1',
  String name = 'Kopi',
  String? sku,
  String? barcode,
  String unitId = 'unt_1',
  num? sellPrice = 10000,
}) =>
    Product(
      id: id,
      name: name,
      sku: sku,
      barcode: barcode,
      unitId: unitId,
      sellPrice: sellPrice,
    );

void main() {
  group('addToCart', () {
    test('adds a new product as its own line', () {
      final lines = addToCart([], product(id: 'prd_1'));
      expect(lines, hasLength(1));
      expect(lines[0].qty, equals(1));
    });

    test('increments the existing line instead of stacking duplicates', () {
      final lines =
          addToCart(addToCart([], product(id: 'prd_1')), product(id: 'prd_1'));
      expect(lines, hasLength(1));
      expect(lines[0].qty, equals(2));
    });

    // The old cart keyed lines on String(Date.now()), so two different products scanned
    // inside the same millisecond — which a barcode gun does routinely — collided as
    // React keys and rendered as one row.
    test(
        'gives every line a distinct id even when added in the same millisecond',
        () {
      var lines = <CartLine>[];
      for (var i = 0; i < 50; i++) {
        lines = addToCart(lines, product(id: 'prd_$i'));
      }
      expect(lines.map((l) => l.id).toSet(), hasLength(50));
    });

    test('does not mutate the array it was given', () {
      final before = addToCart([], product(id: 'prd_1'));
      addToCart(before, product(id: 'prd_2'));
      expect(before, hasLength(1));
    });
  });

  group('setLineQty', () {
    List<CartLine> base() => addToCart([], product(id: 'prd_1'));

    test('sets a normal quantity', () {
      final lines = base();
      expect(setLineQty(lines, lines[0].id, 5)[0].qty, equals(5));
    });

    // A bare <input type="number"> hands back 0, a negative, or NaN. All three used to
    // reach the payload: NaN made the grand total NaN and the pay button unusable, and a
    // zero-quantity line was posted to the server as a real sale line.
    for (final (input, expected) in const <(num, num)>[
      (0, 1),
      (-3, 1),
      (double.nan, 1),
      (double.infinity, 1),
    ]) {
      test('clamps $input to $expected', () {
        final lines = base();
        expect(setLineQty(lines, lines[0].id, input)[0].qty, equals(expected));
      });
    }

    test('leaves other lines alone', () {
      final lines = addToCart(base(), product(id: 'prd_2'));
      final next = setLineQty(lines, lines[0].id, 7);
      expect(next[1].qty, equals(1));
    });

    test('ignores an id that is not in the cart', () {
      expect(setLineQty(base(), 'nope', 9)[0].qty, equals(1));
    });
  });

  group('removeLine', () {
    test('removes only the named line', () {
      final lines =
          addToCart(addToCart([], product(id: 'prd_1')), product(id: 'prd_2'));
      final next = removeLine(lines, lines[0].id);
      expect(next, hasLength(1));
      expect(next[0].product.id, equals('prd_2'));
    });
  });

  group('findProductByCode', () {
    final catalog = [
      product(id: 'prd_1', sku: 'KOPI-01', barcode: '8991234567890'),
      product(id: 'prd_2', sku: 'TEH-01', barcode: '8990000000001'),
    ];

    test('matches a barcode exactly', () {
      expect(findProductByCode(catalog, '8991234567890')?.id, equals('prd_1'));
    });

    test('matches an sku exactly', () {
      expect(findProductByCode(catalog, 'TEH-01')?.id, equals('prd_2'));
    });

    // A gun that appends whitespace or a scanner set to upper case must still hit.
    test('ignores surrounding whitespace and case', () {
      expect(findProductByCode(catalog, '  kopi-01 ')?.id, equals('prd_1'));
    });

    test('does not match on a partial code', () {
      expect(findProductByCode(catalog, '899123'), isNull);
    });

    test('does not match a product whose sku is empty against an empty scan',
        () {
      expect(
        findProductByCode([product(id: 'prd_3', sku: '', barcode: null)], ''),
        isNull,
      );
    });
  });

  group('setLineDiscount', () {
    List<CartLine> base() => addToCart([], product(id: 'prd_1'));

    test('sets a percentage', () {
      final lines = base();
      expect(
        setLineDiscount(lines, lines[0].id, const CartDiscountPercent(10))[0]
            .discountPercent,
        equals(10),
      );
    });

    // The server applies discount_amount when present and only then falls back to the
    // percentage, so a line carrying both quietly loses the percentage.
    test('replaces a percentage with an amount rather than keeping both', () {
      final lines = base();
      final withPct =
          setLineDiscount(lines, lines[0].id, const CartDiscountPercent(10));
      final withAmt =
          setLineDiscount(withPct, lines[0].id, const CartDiscountAmount(5000));
      expect(withAmt[0].discountAmount, equals(5000));
      expect(withAmt[0].discountPercent, isNull);
    });

    test('clamps a percentage into 0..100', () {
      final lines = base();
      expect(
        setLineDiscount(lines, lines[0].id, const CartDiscountPercent(150))[0]
            .discountPercent,
        equals(100),
      );
      expect(
        setLineDiscount(lines, lines[0].id, const CartDiscountPercent(-5))[0]
            .discountPercent,
        isNull,
      );
    });

    test('never accepts a negative or NaN amount', () {
      final lines = base();
      expect(
        setLineDiscount(lines, lines[0].id, const CartDiscountAmount(-1000))[0]
            .discountAmount,
        isNull,
      );
      expect(
        setLineDiscount(
                lines, lines[0].id, const CartDiscountAmount(double.nan))[0]
            .discountAmount,
        isNull,
      );
    });

    test('clears a discount when set back to zero', () {
      final lines = base();
      final withAmt =
          setLineDiscount(lines, lines[0].id, const CartDiscountAmount(5000));
      expect(
        setLineDiscount(withAmt, lines[0].id, const CartDiscountAmount(0))[0]
            .discountAmount,
        isNull,
      );
    });
  });

  group('clampHeaderDiscount', () {
    test('passes a normal discount through', () {
      expect(clampHeaderDiscount(5000, 20000), equals(5000));
    });

    // A total below zero is a sale that pays the customer; the server rejects it.
    test('never exceeds the bill', () {
      expect(clampHeaderDiscount(50000, 20000), equals(20000));
    });

    test('never goes negative', () {
      expect(clampHeaderDiscount(-100, 20000), equals(0));
      expect(clampHeaderDiscount(double.nan, 20000), equals(0));
      expect(clampHeaderDiscount(5000, -1), equals(0));
    });
  });
}
