/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pn_types/src/product.dart';
import 'package:pos/till/cart_controller.dart';

// Written new: the cart is a list in the page's state and every mutation is a call to a pure
// function of `pn_pos`, so there is no source object to port. What is ported is the arithmetic
// (`pos_cart`, `pos_calculations`, already tested there); what is tested here is that the
// controller uses it, plus two things the page never had: undo a removal, and tell listeners.

Product product(String id, {num price = 10000}) =>
    Product(id: id, name: 'Produk $id', unitId: 'unit_1', sellPrice: price);

void main() {
  group('putting things in', () {
    test('a product becomes one line of one', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'));

      expect(cart.lines, hasLength(1));
      expect(cart.lines.single.qty, 1);
    });

    test('the same product again is one more, not another line', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'))
        ..add(product('a'));

      expect(cart.lines, hasLength(1));
      expect(cart.lines.single.qty, 2);
    });

    test('counts the pieces, not the lines', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'))
        ..add(product('a'))
        ..add(product('b'));

      expect(cart.itemCount, 3);
    });

    test('a quantity is never below one', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'));

      cart.setQty(cart.lines.single.id, 0);

      expect(cart.lines.single.qty, 1);
    });

    test('a quantity can be set', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'));

      cart.setQty(cart.lines.single.id, 7);

      expect(cart.lines.single.qty, 7);
    });
  });

  group('what it adds up to', () {
    test('is the price times the quantity, line by line', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a', price: 10000))
        ..add(product('a', price: 10000))
        ..add(product('b', price: 2500));

      expect(cart.totals.subtotal, 22500);
      expect(cart.totals.grandTotal, 22500);
    });

    test('is nothing for an empty cart', () {
      expect(CartController(analytics: FakeAnalytics()).totals.grandTotal, 0);
    });

    test('counts a product with no price as free rather than failing', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(const Product(id: 'x', name: 'Tanpa harga', unitId: 'unit_1'));

      expect(cart.totals.grandTotal, 0);
    });
  });

  group('taking things out', () {
    test('a removed line is gone', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'))
        ..add(product('b'));

      cart.remove(cart.lines.first.id);

      expect(cart.lines.map((l) => l.product.id), ['b']);
    });

    test('and can be brought back where it was', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'))
        ..add(product('b'))
        ..add(product('c'));
      final middle = cart.lines[1];
      cart.remove(middle.id);

      cart.undoRemove();

      expect(cart.lines.map((l) => l.product.id), ['a', 'b', 'c']);
      expect(cart.lines[1].qty, middle.qty);
    });

    test('keeps the quantity it had', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'));
      cart.setQty(cart.lines.single.id, 5);
      cart.remove(cart.lines.single.id);

      cart.undoRemove();

      expect(cart.lines.single.qty, 5);
    });

    test('still comes back after other lines were changed meanwhile', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'))
        ..add(product('b'))
        ..add(product('c'));
      cart.remove(cart.lines[2].id);
      cart.remove(cart.lines[1].id);
      // Only the last removal is remembered, and the cart is shorter than where it sat.
      cart.remove(cart.lines[0].id);

      cart.undoRemove();

      expect(cart.lines.map((l) => l.product.id), ['a']);
    });

    test('merges into the line the product got in the meantime', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'));
      cart.setQty(cart.lines.single.id, 3);
      cart.remove(cart.lines.single.id);
      // Scanned again before the undo: a second row for one product would print twice.
      cart.add(product('a'));

      cart.undoRemove();

      expect(cart.lines, hasLength(1));
      expect(cart.lines.single.qty, 4);
    });

    test('has nothing to bring back at first, or a second time', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'));

      cart.undoRemove();
      expect(cart.lines, hasLength(1));

      cart.remove(cart.lines.single.id);
      cart.undoRemove();
      cart.undoRemove();
      expect(cart.lines, hasLength(1));
    });

    test('says whether there is something to bring back', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'));
      expect(cart.canUndoRemove, isFalse);

      cart.remove(cart.lines.single.id);
      expect(cart.canUndoRemove, isTrue);

      cart.undoRemove();
      expect(cart.canUndoRemove, isFalse);
    });

    test('only the last removal is remembered', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'))
        ..add(product('b'));
      cart.remove(cart.lines[0].id);
      cart.remove(cart.lines[0].id);

      cart.undoRemove();

      expect(cart.lines.map((l) => l.product.id), ['b']);
    });

    test('clearing empties it, and there is no undo for it', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'))
        ..add(product('b'));

      cart.clear();
      cart.undoRemove();

      expect(cart.lines, isEmpty);
      expect(cart.canUndoRemove, isFalse);
    });

    test('a removal that never happened is not remembered', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'));

      cart.remove('no such line');

      expect(cart.canUndoRemove, isFalse);
    });
  });

  group('telling the screen', () {
    test('every change is announced, and a no-op is not', () {
      final cart = CartController(analytics: FakeAnalytics());
      var announced = 0;
      cart.addListener(() => announced++);

      cart.add(product('a'));
      expect(announced, 1);
      cart.setQty(cart.lines.single.id, 2);
      expect(announced, 2);
      cart.remove(cart.lines.single.id);
      expect(announced, 3);
      cart.undoRemove();
      expect(announced, 4);
      cart.undoRemove();
      expect(announced, 4);
      cart.remove('no such line');
      expect(announced, 4);
      cart.clear();
      expect(announced, 5);
      cart.clear();
      expect(announced, 5);
    });

    test('the lines it hands out cannot be changed from outside', () {
      final cart = CartController(analytics: FakeAnalytics())
        ..add(product('a'));

      expect(() => cart.lines.clear(), throwsUnsupportedError);
    });
  });

  group('taking a whole basket', () {
    // What a resumed held basket is: lines that were rung up earlier, possibly before a restart.
    final held = [
      CartLine(id: 'line_1', product: product('a'), qty: 2),
      CartLine(
        id: 'line_2',
        product: product('b'),
        qty: 1,
        discountPercent: 10,
      ),
    ];

    test(
      'replaces what is there, with the quantities and discounts it had',
      () {
        final cart = CartController(analytics: FakeAnalytics())
          ..add(product('z'));

        cart.replaceAll(held);

        expect(cart.lines.map((l) => (l.product.id, l.qty)), [
          ('a', 2),
          ('b', 1),
        ]);
        expect(cart.lines.last.discountPercent, 10);
      },
    );

    test('gives the lines ids of its own: the ones it came with were made by a '
        'counter that starts again after a restart, and would collide', () {
      final cart = CartController(analytics: FakeAnalytics())..replaceAll(held);

      final ids = cart.lines.map((l) => l.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, isNot(contains('line_1')));
      expect(ids, isNot(contains('line_2')));
      // And what is rung up next does not collide with them either.
      cart.add(product('c'));
      final all = cart.lines.map((l) => l.id).toList();
      expect(all.toSet(), hasLength(all.length));
    });

    test(
      'tells the listeners, and forgets the removal it could have undone',
      () {
        final cart = CartController(analytics: FakeAnalytics())
          ..add(product('z'));
        cart.remove(cart.lines.single.id);
        var told = 0;
        cart.addListener(() => told++);

        cart.replaceAll(held);

        expect(told, 1);
        expect(cart.canUndoRemove, isFalse);
      },
    );
  });

  group('analytics', () {
    test(
      'logs item_added_to_cart for every add, even the same product twice',
      () {
        final analytics = FakeAnalytics();
        CartController(analytics: analytics)
          ..add(product('a'))
          ..add(product('a'));

        expect(analytics.logged.map((e) => e.$1), [
          'item_added_to_cart',
          'item_added_to_cart',
        ]);
      },
    );

    test('logs item_removed_from_cart', () {
      final analytics = FakeAnalytics();
      final cart = CartController(analytics: analytics)..add(product('a'));

      cart.remove(cart.lines.single.id);

      expect(analytics.logged.map((e) => e.$1), [
        'item_added_to_cart',
        'item_removed_from_cart',
      ]);
    });

    test('logs nothing for a removal that never happened', () {
      final analytics = FakeAnalytics();
      final cart = CartController(analytics: analytics);

      cart.remove('no such line');

      expect(analytics.logged, isEmpty);
    });

    test('logs cart_cleared, but not for an already-empty cart', () {
      final analytics = FakeAnalytics();
      final cart = CartController(analytics: analytics)..add(product('a'));

      cart.clear();
      cart.clear();

      expect(
        analytics.logged.where((e) => e.$1 == 'cart_cleared'),
        hasLength(1),
      );
    });
  });
}
