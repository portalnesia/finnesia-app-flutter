/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_pos/src/pos_hold_fake.dart';
import 'package:pn_pos/src/pos_transaction_detail.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pn_types/src/product.dart';
import 'package:pos/till/cart_controller.dart';
import 'package:pos/till/hold_controller.dart';
import 'package:pos/till/transaction_detail_controller.dart';

// Written new. The behaviour lives in nine `useState`/`useCallback` calls in a page, around the
// pure functions of `pos-hold.ts` (ported to `pn_pos`, and tested there). What is ported is the
// behaviour: a basket parked without a server call, a resumed basket updating its own slot when it
// is held again, the basket on screen parked and not discarded when another is resumed, and a paid
// basket dropped. What is tested here is the controller that joins them to the cart.
//
// Added over the source: the basket is only cleared once it is **known to be stored**. The port
// swallows a failed write (a parked basket must not interrupt a sale), so the only way to know is
// to read it back, and clearing a cart into a store that dropped it loses the sale.

Product product(String id, {num price = 10000}) =>
    Product(id: id, name: 'Produk $id', unitId: 'unit_1', sellPrice: price);

final noon = DateTime.utc(2026, 9, 21, 5, 30); // 12.30 in WIB

typedef Rig = ({
  FakeApiTransport transport,
  HoldController hold,
  CartController cart,
  TransactionDetailController detail,
  FakeHoldOrderStore store,
  FakeAnalytics analytics,
});

Rig rig({List<HeldOrder>? seed, DateTime? now}) {
  final store = FakeHoldOrderStore(seed);
  final analytics = FakeAnalytics();
  // A separate fake: the cart's own events (`item_added_to_cart`, ...) are not what this
  // controller's analytics tests assert on.
  final cart = CartController(analytics: FakeAnalytics());
  final transport = FakeApiTransport();
  final detail = TransactionDetailController(
    client: ApiClient(transport: transport, language: () => 'id'),
    outletId: 'out_1',
  );
  final hold = HoldController(
    store: store,
    outletId: 'out_1',
    cart: cart,
    detail: detail,
    analytics: analytics,
    now: () => now ?? noon,
  );
  addTearDown(() {
    hold.dispose();
    detail.dispose();
    cart.dispose();
  });
  return (
    transport: transport,
    hold: hold,
    cart: cart,
    detail: detail,
    store: store,
    analytics: analytics,
  );
}

HeldOrder heldOrder(
  String id, {
  String outletId = 'out_1',
  String heldAt = '2026-09-21T03:00:00.000Z',
  String label = 'Meja',
  List<Product>? goods,
}) => HeldOrder(
  id: id,
  label: label,
  outletId: outletId,
  headerDiscount: 0,
  lines: [
    for (final p in goods ?? [product('a')])
      CartLine(id: 'line_$id', product: p, qty: 1),
  ],
  heldAt: heldAt,
);

void main() {
  setUpAll(() async {
    // The label a basket gets when the cashier names none is the time, in the tablet's zone.
    await initializePosDateTime();
    useFixedLocalZone(const Duration(hours: 7));
  });

  group('holding the basket', () {
    test('parks it, with the goods and what was filled in, and clears the '
        'till for the next customer', () async {
      final r = rig();
      r.cart
        ..add(product('a'))
        ..add(product('a'))
        ..add(product('b'));
      r.detail.pickCustomer(
        const TransactionDetail(customerId: 'c1', customerName: 'Budi'),
      );
      r.detail.setMemo('  Alergi kacang ');
      r.detail.setTableNumber('4');

      final outcome = await r.hold.hold(label: '  Meja 4 ');

      expect(outcome, HoldOutcome.held);
      final held = (await r.store.readAll()).single;
      expect(held.label, 'Meja 4');
      expect(held.outletId, 'out_1');
      expect(held.lines.map((l) => (l.product.id, l.qty)), [
        ('a', 2),
        ('b', 1),
      ]);
      expect(held.customerId, 'c1');
      expect(held.customerMemo, 'Alergi kacang');
      expect(held.tableNumber, '4');
      expect(held.queueNumber, isNull); // nothing typed is not an empty string
      expect(r.cart.lines, isEmpty);
      expect(r.detail.detail.tableNumber, isEmpty);
    });

    test('with no name it is called by the time, in the tablet zone', () async {
      final r = rig();
      r.cart.add(product('a'));

      await r.hold.hold(label: '   ');

      expect((await r.store.readAll()).single.label, '12.30');
    });

    test('an empty till has nothing to hold, and stores nothing', () async {
      final r = rig();

      final outcome = await r.hold.hold(label: 'Meja 4');

      expect(outcome, HoldOutcome.nothingToHold);
      expect(r.store.writeCount, 0);
    });

    test(
      'a basket the store did not keep stays on the till: the store '
      'swallows a failed write, so the only way to know is to read it back',
      () async {
        final r = rig();
        r.cart.add(product('a'));
        r.store.failWrite = true;

        final outcome = await r.hold.hold(label: 'Meja 4');

        expect(outcome, HoldOutcome.notStored);
        expect(r.cart.lines, hasLength(1));
      },
    );
  });

  group('what is waiting', () {
    test(
      'lists the baskets of this outlet, latest first, and counts them',
      () async {
        final r = rig(
          seed: [
            heldOrder('old', heldAt: '2026-09-21T01:00:00.000Z'),
            heldOrder('elsewhere', outletId: 'out_2'),
            heldOrder('new', heldAt: '2026-09-21T02:00:00.000Z'),
          ],
        );

        await r.hold.refresh();

        expect(r.hold.waiting.map((o) => o.id), ['new', 'old']);
        expect(r.hold.count, 2);
      },
    );

    test('a store that cannot be read has nothing waiting', () async {
      final r = rig(seed: [heldOrder('a')]);
      r.store.failRead = true;

      await r.hold.refresh();

      expect(r.hold.waiting, isEmpty);
    });

    test('a basket just held is waiting, without asking again', () async {
      final r = rig();
      r.cart.add(product('a'));

      await r.hold.hold(label: 'Meja 4');

      expect(r.hold.count, 1);
      expect(r.hold.waiting.single.label, 'Meja 4');
    });

    test('tells its listeners when the list changes', () async {
      final r = rig(seed: [heldOrder('a')]);
      var told = 0;
      r.hold.addListener(() => told++);

      await r.hold.refresh();

      expect(told, 1);
    });
  });

  group('resuming a basket', () {
    HeldOrder table4() => HeldOrder(
      id: 'h4',
      label: 'Meja 4',
      outletId: 'out_1',
      customerMemo: 'Alergi kacang',
      tableNumber: '4',
      headerDiscount: 0,
      lines: [
        CartLine(
          id: 'line_1',
          product: product('a'),
          qty: 2,
          discountPercent: 10,
        ),
        CartLine(id: 'line_2', product: product('b'), qty: 1),
      ],
      heldAt: '2026-09-21T03:00:00.000Z',
    );

    test('puts its goods and details on the till', () async {
      final r = rig(seed: [table4()]);

      final outcome = await r.hold.resume(table4());

      expect(outcome, ResumeOutcome.resumed);
      expect(r.cart.lines.map((l) => (l.product.id, l.qty)), [
        ('a', 2),
        ('b', 1),
      ]);
      expect(r.cart.lines.first.discountPercent, 10);
      expect(r.detail.detail.customerMemo, 'Alergi kacang');
      expect(r.detail.detail.tableNumber, '4');
    });

    test(
      'names the customer it carried, without waiting for the name',
      () async {
        final r = rig();
        final withCustomer = table4().copyWith(customerId: 'c2');
        r.transport.respond(
          TransportResponse(
            status: 200,
            headers: const {'content-type': 'application/json'},
            body: '{"data":{"id":"c2","name":"Budi","type":"CUSTOMER"}}',
          ),
        );

        await r.hold.resume(withCustomer);
        expect(r.detail.detail.customerId, 'c2');
        await Future<void>.delayed(Duration.zero);

        expect(r.detail.detail.customerName, 'Budi');
      },
    );

    test('stays in the queue until it is paid, but is not listed as waiting '
        'while it is the one on the till', () async {
      final r = rig(seed: [table4(), heldOrder('other')]);
      await r.hold.refresh();

      await r.hold.resume(table4());

      expect((await r.store.readAll()).map((o) => o.id), contains('h4'));
      expect(r.hold.waiting.map((o) => o.id), ['other']);
      expect(r.hold.count, 1);
      expect(r.hold.resumedLabel, 'Meja 4');
    });
  });

  group('the basket on the till when another is resumed', () {
    test('is parked, not discarded: resuming must never be why a cashier loses '
        'a sale they were halfway through', () async {
      final r = rig(seed: [heldOrder('waiting')]);
      r.cart.add(product('z'));

      await r.hold.resume(heldOrder('waiting'));

      final all = await r.store.readAll();
      expect(all, hasLength(2));
      final parked = all.firstWhere((o) => o.id != 'waiting');
      expect(parked.lines.single.product.id, 'z');
      expect(parked.label, '12.30');
    });

    test('an empty till parks nothing', () async {
      final r = rig(seed: [heldOrder('waiting')]);

      await r.hold.resume(heldOrder('waiting'));

      expect(await r.store.readAll(), hasLength(1));
    });

    test('a resumed basket that is being replaced is written back to its own '
        'slot, not parked a second time', () async {
      final r = rig(
        seed: [
          heldOrder('first', label: 'Meja 1'),
          heldOrder('second'),
        ],
      );
      await r.hold.resume(heldOrder('first', label: 'Meja 1'));
      r.cart.add(product('extra'));

      await r.hold.resume(heldOrder('second'));

      final all = await r.store.readAll();
      expect(all.map((o) => o.id).toSet(), {'first', 'second'});
      final first = all.firstWhere((o) => o.id == 'first');
      expect(first.label, 'Meja 1');
      expect(first.lines.map((l) => l.product.id), containsAll(['a', 'extra']));
    });

    test('when it cannot be parked, nothing is resumed: the till is left as '
        'it was', () async {
      final r = rig(seed: [heldOrder('waiting')]);
      r.cart.add(product('z'));
      r.store.failWrite = true;

      final outcome = await r.hold.resume(heldOrder('waiting'));

      expect(outcome, ResumeOutcome.currentNotStored);
      expect(r.cart.lines.single.product.id, 'z');
    });
  });

  group('holding a resumed basket again', () {
    test(
      'updates the same slot, and keeps its name when none is typed',
      () async {
        final r = rig(seed: [heldOrder('h1', label: 'Meja 1')]);
        await r.hold.resume(heldOrder('h1', label: 'Meja 1'));
        r.cart.add(product('extra'));

        await r.hold.hold();

        final all = await r.store.readAll();
        expect(all, hasLength(1));
        expect(all.single.id, 'h1');
        expect(all.single.label, 'Meja 1');
        expect(
          all.single.lines.map((l) => l.product.id),
          containsAll(['a', 'extra']),
        );
      },
    );

    test('a name typed now replaces the old one', () async {
      final r = rig(seed: [heldOrder('h1', label: 'Meja 1')]);
      await r.hold.resume(heldOrder('h1', label: 'Meja 1'));

      await r.hold.hold(label: 'Meja 2');

      expect((await r.store.readAll()).single.label, 'Meja 2');
    });

    test(
      'a basket dropped from under it is parked as a new one, not lost',
      () async {
        final r = rig(seed: [heldOrder('h1')]);
        await r.hold.resume(heldOrder('h1'));
        r.store.failRead = false;
        await r.store.writeAll([]); // dropped elsewhere while it was open

        await r.hold.hold(label: 'Meja 9');

        final all = await r.store.readAll();
        expect(all, hasLength(1));
        expect(all.single.label, 'Meja 9');
      },
    );

    test('the till forgets the link once it is empty: a later, unrelated hold '
        'must not overwrite that basket', () async {
      final r = rig(seed: [heldOrder('h1', label: 'Meja 1')]);
      await r.hold.resume(heldOrder('h1', label: 'Meja 1'));

      r.cart.clear();
      r.cart.add(product('new'));
      await r.hold.hold(label: 'Lain');

      final all = await r.store.readAll();
      expect(all, hasLength(2));
      expect(r.hold.resumedLabel, isNull);
    });
  });

  group('dropping and paying', () {
    test('a dropped basket is gone from the queue and the list', () async {
      final r = rig(seed: [heldOrder('a'), heldOrder('b')]);
      await r.hold.refresh();

      await r.hold.drop(heldOrder('a'));

      expect((await r.store.readAll()).map((o) => o.id), ['b']);
      expect(r.hold.waiting.map((o) => o.id), ['b']);
    });

    test('dropping the one on the till forgets the link, and leaves the till '
        'as it is', () async {
      final r = rig(seed: [heldOrder('a')]);
      await r.hold.resume(heldOrder('a'));

      await r.hold.drop(heldOrder('a'));

      expect(r.hold.resumedLabel, isNull);
      expect(r.cart.lines, isNotEmpty);
    });

    test(
      'a resumed basket that was paid for is dropped from the queue',
      () async {
        final r = rig(seed: [heldOrder('a'), heldOrder('b')]);
        await r.hold.resume(heldOrder('a'));

        await r.hold.paid();

        expect((await r.store.readAll()).map((o) => o.id), ['b']);
        expect(r.hold.resumedLabel, isNull);
      },
    );

    test('paying for a fresh basket drops nothing', () async {
      final r = rig(seed: [heldOrder('a')]);
      r.cart.add(product('z'));

      await r.hold.paid();

      expect(await r.store.readAll(), hasLength(1));
    });
  });

  group('how much storage work it does', () {
    Future<(int, int)> workFor(int waiting) async {
      final r = rig(seed: [for (var i = 0; i < waiting; i++) heldOrder('w$i')]);
      r.cart.add(product('z'));
      await r.hold.hold(label: 'x');
      return (r.store.readCount, r.store.writeCount);
    }

    test('holding reads and writes the same number of times whether one basket '
        'is waiting or thirty', () async {
      final few = await workFor(1);
      final many = await workFor(30);

      expect(many, few);
      expect(few.$2, 1); // one write of the whole list
    });
  });

  group('analytics', () {
    test('logs basket_held', () async {
      final r = rig();
      r.cart.add(product('a'));

      await r.hold.hold(label: 'Meja 4');

      expect(r.analytics.logged.map((e) => e.$1), ['basket_held']);
    });

    test('logs nothing for an empty till', () async {
      final r = rig();

      await r.hold.hold(label: 'Meja 4');

      expect(r.analytics.logged, isEmpty);
    });

    test('logs nothing when the store did not keep it', () async {
      final r = rig();
      r.cart.add(product('a'));
      r.store.failWrite = true;

      await r.hold.hold(label: 'Meja 4');

      expect(r.analytics.logged, isEmpty);
    });

    test('logs basket_resumed', () async {
      final r = rig(seed: [heldOrder('a')]);

      await r.hold.resume(heldOrder('a'));

      expect(r.analytics.logged.map((e) => e.$1), ['basket_resumed']);
    });

    test('logs nothing when the basket on the till could not be parked '
        'first', () async {
      final r = rig(seed: [heldOrder('waiting')]);
      r.cart.add(product('z'));
      r.store.failWrite = true;

      await r.hold.resume(heldOrder('waiting'));

      expect(r.analytics.logged, isEmpty);
    });

    test('logs basket_discarded', () async {
      final r = rig(seed: [heldOrder('a')]);
      await r.hold.refresh();

      await r.hold.drop(heldOrder('a'));

      expect(r.analytics.logged.map((e) => e.$1), ['basket_discarded']);
    });

    test('does not log a discard for a basket that was paid for', () async {
      final r = rig(seed: [heldOrder('a')]);
      await r.hold.resume(heldOrder('a'));

      await r.hold.paid();

      expect(
        r.analytics.logged.where((e) => e.$1 == 'basket_discarded'),
        isEmpty,
      );
    });
  });
}
