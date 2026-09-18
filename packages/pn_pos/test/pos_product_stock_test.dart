/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_product_stock.dart';
import 'package:pn_types/src/product.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/packages/shared/src/pos/pos-product-stock.test.ts`.
// Inputs and expectations are copied unchanged; only the syntax changed
// (describe/it -> group/test, toEqual -> equals). 5 cases, plus 1 added below.
//
// The source branches on `stock !== undefined`, which JavaScript keeps distinct from
// `null`. Dart has only one "absent", so the oracle's `undefined` cases are written as
// `null` here. See `pos_product_stock.dart` for why that loses nothing.
void main() {
  group('resolveProductStockBadge', () {
    test('tracks INVENTORY with a real count', () {
      expect(
        resolveProductStockBadge(ProductType.inventory, 12),
        equals((tracked: true, quantity: 12)),
      );
    });

    test('treats an INVENTORY product absent from the stock map as zero', () {
      expect(
        resolveProductStockBadge(ProductType.inventory, null),
        equals((tracked: true, quantity: 0)),
      );
    });

    test('tracks BUNDLE when the server computed an available quantity', () {
      expect(
        resolveProductStockBadge(ProductType.bundle, 3),
        equals((tracked: true, quantity: 3)),
      );
    });

    test(
        'does not show a false "out of stock" for a bundle with no '
        'inventory-tracked leaves', () {
      expect(
        resolveProductStockBadge(ProductType.bundle, null),
        equals((tracked: false, quantity: null)),
      );
    });

    test('never shows a badge for a service (NON_INVENTORY)', () {
      expect(
        resolveProductStockBadge(ProductType.nonInventory, null),
        equals((tracked: false, quantity: null)),
      );
      expect(
        resolveProductStockBadge(ProductType.nonInventory, 5),
        equals((tracked: false, quantity: null)),
      );
    });

    // BUKAN dari oracle. The source has no `BUNDLE` + `0` case, and it is the one input
    // that separates the two "no number" meanings the badge has to keep apart: a bundle
    // the server *computed* as 0 is a real "cannot be assembled right now", while a bundle
    // with no estimate is "no badge at all". Both are falsy in JavaScript, so a port that
    // flattened `quantity` to a non-nullable `num` would silently show "out of stock" for
    // every bundle with no inventory-tracked component — the exact false alarm the source
    // comment calls out. This pins the distinction.
    test('keeps a bundle at zero distinct from a bundle with no estimate', () {
      expect(
        resolveProductStockBadge(ProductType.bundle, 0),
        equals((tracked: true, quantity: 0)),
      );
    });
  });
}
