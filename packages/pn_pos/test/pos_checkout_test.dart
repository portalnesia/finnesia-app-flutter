/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_checkout.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/product.dart';
import 'package:test/test.dart';

// The module has no monorepo counterpart. The cases after `// New` cover what an earlier
// suite never asserted.

const product = Product(
  id: 'prod_1',
  name: 'Kopi Susu',
  unitId: 'unit_1',
  sellPrice: 18000,
  type: ProductType.inventory,
);

const line = CartLine(id: 'line_1', product: product, qty: 2);

const cash = POSTenderDTO(method: POSTenderMethod.cash, amount: 36000);

/// A draft that would post successfully, so each test changes one thing.
POSCheckoutDTO build({
  String? shiftId = 'shift_1',
  String customerId = '',
  String notes = '',
  String tableNumber = '',
  String queueNumber = '',
  num discountAmount = 0,
  List<CartLine> lines = const [line],
}) =>
    buildCheckoutPayload(
      shiftId: shiftId,
      outletId: 'out_1',
      customerId: customerId,
      notes: notes,
      tableNumber: tableNumber,
      queueNumber: queueNumber,
      discountAmount: discountAmount,
      transactionDate: '2026-09-18',
      lines: lines,
      payments: const [cash],
    );

void main() {
  group('buildCheckoutPayload', () {
    test('maps each cart line to an API item at the price on the product', () {
      expect(build().items, const [
        POSCheckoutItemDTO(
          productId: 'prod_1',
          unitId: 'unit_1',
          quantity: 2,
          price: 18000,
        ),
      ]);
    });

    test('carries the line discount through, whichever kind it is', () {
      final items = build(
        lines: const [
          CartLine(id: 'line_1', product: product, qty: 1, discountPercent: 10),
          CartLine(
            id: 'line_2',
            product: product,
            qty: 1,
            discountAmount: 2000,
          ),
        ],
      ).items;

      expect(items[0].discountPercent, 10);
      expect(items[0].discountAmount, isNull);
      expect(items[1].discountAmount, 2000);
      expect(items[1].discountPercent, isNull);
    });

    test('leaves the shift out when the company runs without shifts', () {
      expect(build(shiftId: null).shiftId, isNull);
    });

    test('never sends an empty string where the API expects an id or a number',
        () {
      // An empty string is not "absent" to the server: it is a customer id that does not
      // exist, and a checkout that fails validation after the cashier pressed Pay.
      final p = build();

      expect(p.customerId, isNull);
      expect(p.discountAmount, isNull);
      expect(p.notes, isNull);
      expect(p.tableNumber, isNull);
      expect(p.queueNumber, isNull);
    });

    test('trims the optional text fields and drops the ones left blank', () {
      final p = build(
        customerId: 'cust_1',
        notes: '  take away  ',
        tableNumber: '   ',
        queueNumber: ' 12 ',
      );

      expect(p.customerId, 'cust_1');
      expect(p.notes, 'take away');
      expect(p.tableNumber, isNull);
      expect(p.queueNumber, '12');
    });

    test(
        'keeps the outlet and the date the till worked out, and passes the tenders on',
        () {
      final p = build(discountAmount: 5000);

      expect(p.outletId, 'out_1');
      expect(p.transactionDate, '2026-09-18');
      expect(p.discountAmount, 5000);
      expect(p.payments, const [cash]);
    });

    test(
        'sends an empty item list for an empty cart rather than inventing a line',
        () {
      // The server refuses a checkout with no items, and that refusal belongs to the
      // cashier as a disabled Pay button, not as a line the builder made up.
      expect(build(lines: const []).items, isEmpty);
    });

    // New: the JavaScript semantics the oracle never asserted (`patterns.md` §1.1).

    test('treats an empty shift id as no shift, the way `"" || undefined` does',
        () {
      expect(build(shiftId: '').shiftId, isNull);
    });

    test('reads a product with no price as zero, not as an error', () {
      // `line.product.sell_price ?? 0` in the source: the type says required, the till
      // has always treated it as possibly absent.
      const free = Product(id: 'p2', name: 'Bonus', unitId: 'u2');

      final item = build(
        lines: const [CartLine(id: 'l', product: free, qty: 1)],
      ).items.single;

      expect(item.price, 0);
    });

    test('drops a bill discount that is NaN, as JavaScript does (NaN is falsy)',
        () {
      expect(build(discountAmount: double.nan).discountAmount, isNull);
    });

    test(
        'does not trim the customer id, which the source only tests for emptiness',
        () {
      // `draft.customerId || undefined`: `'  '` is truthy in JavaScript and is sent as it
      // is. Preserved because the oracle defines the behaviour (`cross-repo.md` §4); the
      // picker only ever supplies a real id, so this is not reachable from the till.
      expect(build(customerId: '  ').customerId, '  ');
    });

    test('leaves the client_ref to the checkout service', () {
      // Not in the source, and not this function's to choose: `CheckoutService` makes one per
      // basket, because the server returns whatever sale it already has under a ref
      // without comparing contents.
      expect(build().clientRef, isNull);
    });

    test('writes a payload with no null keys, ready to post as it is', () {
      expect(
        build().toJson().keys,
        unorderedEquals([
          'outlet_id',
          'transaction_date',
          'items',
          'payments',
          'shift_id',
        ]),
      );
    });
  });
}
