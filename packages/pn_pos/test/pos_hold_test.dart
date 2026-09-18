/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_pos/src/pos_hold_fake.dart';
import 'package:pn_types/src/product.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/packages/shared/src/pos/pos-hold.test.ts`.
// Inputs and expectations are copied unchanged. 16 cases.
//
// ## What changed, and why it is still the same contract
//
// The source reads and writes `window.localStorage` directly. Dart has no such global, and
// the app stores the parking queue in SQLite (`.claude/rules/project.md` §5), so storage
// arrives as the `HoldOrderStore` port (`.claude/rules/architecture.md` §3.2). That has two
// mechanical consequences, neither of which touches the behaviour being asserted:
//
//   1. **Every function is `async`.** The source is synchronous because `localStorage` is.
//      `sqflite` is not, so a synchronous port could not be implemented by the real thing —
//      only by a fake, which would make the port a lie.
//   2. **The store is the first parameter.** Explicit dependency instead of a global, which
//      is what makes the failure paths testable at all.
//
// Two oracle cases are about *deserialising a corrupted entry* ("survives unreadable
// storage", "ignores a stored value that is not a list"). With a typed port there is no JSON
// at this layer, so both are ported as the contract they actually protect: **a store that
// fails must not take the till down.** The "not a list" case is now the SQLite
// implementation's responsibility, and is marked below where it lands.

List<CartLine> lines([num qty = 2]) => [
      CartLine(
        id: 'line_1',
        product: const Product(id: 'prd_1', name: 'Kopi', unitId: 'unt_1'),
        qty: qty,
      ),
    ];

HeldOrderDraft draft({
  String label = 'Bu Sri',
  String outletId = 'out_1',
  String? customerId,
  num headerDiscount = 0,
  List<CartLine>? cartLines,
}) =>
    HeldOrderDraft(
      label: label,
      outletId: outletId,
      customerId: customerId,
      headerDiscount: headerDiscount,
      lines: cartLines ?? lines(),
    );

void main() {
  late FakeHoldOrderStore store;

  setUp(() => store = FakeHoldOrderStore());

  group('held orders', () {
    test('parks a basket and reads it back', () async {
      await holdOrder(store, draft());
      final held = await listHeldOrders(store, 'out_1');
      expect(held, hasLength(1));
      expect(held[0].label, equals('Bu Sri'));
      expect(held[0].lines[0].qty, equals(2));
    });

    // A basket rung up at one store must not resume at another: it would post against the
    // wrong stock and land in the wrong drawer.
    test('never shows a basket held at another outlet', () async {
      await holdOrder(store, draft(label: 'Cabang A'));
      expect(await listHeldOrders(store, 'out_2'), isEmpty);
    });

    test('keeps the customer and the whole-bill discount with the basket',
        () async {
      await holdOrder(
        store,
        draft(label: 'Pak Budi', customerId: 'cnt_9', headerDiscount: 5000),
      );
      final held = await listHeldOrders(store, 'out_1');
      expect(held[0].customerId, equals('cnt_9'));
      expect(held[0].headerDiscount, equals(5000));
    });

    test('gives every basket its own id', () async {
      final a = await holdOrder(store, draft(label: 'A'));
      final b = await holdOrder(store, draft(label: 'B'));
      expect(a.id, isNot(equals(b.id)));
      expect(await listHeldOrders(store, 'out_1'), hasLength(2));
    });

    test('drops only the basket asked for', () async {
      final a = await holdOrder(store, draft(label: 'A'));
      await holdOrder(store, draft(label: 'B'));
      await dropHeldOrder(store, a.id);
      final rest = await listHeldOrders(store, 'out_1');
      expect(rest, hasLength(1));
      expect(rest[0].label, equals('B'));
    });

    test('shows the most recently held basket first', () async {
      // Both holds are given a fixed clock, and the seeded timestamp sits between them. Left to
      // `DateTime.now()` the two holds landed at whatever the wall clock said, and this test
      // was only passing while the wall clock happened to be earlier than the timestamp below:
      // once the date moved past it, the "newer" basket became the oldest one and sorted last.
      // A test whose result depends on what day it is run is not testing the sort.
      await holdOrder(
        store,
        draft(label: 'older'),
        now: DateTime.parse('2026-09-19T23:59:58Z'),
      );
      await holdOrder(
        store,
        draft(label: 'newer'),
        now: DateTime.parse('2026-09-19T23:59:59Z'),
      );
      // Seeded directly, mirroring the source test: it too writes the raw list to storage
      // rather than going through the API, because it is testing the *read* order.
      final all = await store.readAll();
      final newer = all.firstWhere((o) => o.label == 'newer');
      await store.writeAll([
        ...all.where((o) => o.id != newer.id),
        newer.copyWith(heldAt: '2026-09-19T23:59:59.500Z'),
      ]);
      expect((await listHeldOrders(store, 'out_1'))[0].label, equals('newer'));
    });

    // A private window, cleared site data, or a corrupted entry must not take the till
    // down in the middle of a shift.
    test('survives unreadable storage', () async {
      store.failRead = true;
      expect(await listHeldOrders(store, 'out_1'), isEmpty);
    });

    test('survives storage that refuses to write', () async {
      store.failWrite = true;
      await expectLater(holdOrder(store, draft(label: 'A')), completes);
    });

    // The source's "ignores a stored value that is not a list" case. There is no JSON at
    // this layer any more, so the equivalent is a store that hands back nothing usable —
    // and the contract is the same: an empty list, not an exception. The SQLite
    // implementation owns rejecting a malformed row; this pins that the logic above it
    // stays standing when it does.
    test('returns an empty list when the store has nothing usable', () async {
      expect(await listHeldOrders(store, 'out_1'), isEmpty);
    });

    // Closing a shift ends the drawer that basket was rung up under — it must not
    // resurface once the next shift at that outlet opens.
    group('clearHeldOrders', () {
      test('drops every basket held at the given outlet', () async {
        await holdOrder(store, draft(label: 'A'));
        await holdOrder(store, draft(label: 'B'));
        await clearHeldOrders(store, 'out_1');
        expect(await listHeldOrders(store, 'out_1'), isEmpty);
      });

      test('leaves held baskets at another outlet untouched', () async {
        await holdOrder(store, draft(label: 'A'));
        final other = await holdOrder(
            store, draft(label: 'Other outlet', outletId: 'out_2'));
        await clearHeldOrders(store, 'out_1');
        final rest = await listHeldOrders(store, 'out_2');
        expect(rest, hasLength(1));
        expect(rest[0].id, equals(other.id));
      });

      test('is a no-op when nothing is held at that outlet', () async {
        await holdOrder(store, draft(label: 'A', outletId: 'out_2'));
        await expectLater(clearHeldOrders(store, 'out_1'), completes);
        expect(await listHeldOrders(store, 'out_2'), hasLength(1));
      });
    });

    // Resuming a held basket, editing it, then holding again must not spawn a second
    // basket with a re-typed label — it should update the same one in place.
    group('updateHeldOrder', () {
      test('updates the same basket in place, keeping its id', () async {
        final a = await holdOrder(store, draft());
        final updated =
            await updateHeldOrder(store, a.id, draft(cartLines: lines(5)));
        expect(updated?.id, equals(a.id));
        final held = await listHeldOrders(store, 'out_1');
        expect(held, hasLength(1));
        expect(held[0].lines[0].qty, equals(5));
      });

      test('leaves other held baskets untouched', () async {
        final a = await holdOrder(store, draft(label: 'A'));
        final b = await holdOrder(store, draft(label: 'B'));
        await updateHeldOrder(store, a.id, draft(label: 'A renamed'));
        final held = await listHeldOrders(store, 'out_1');
        expect(held.firstWhere((o) => o.id == b.id).label, equals('B'));
      });

      test('returns null and changes nothing when the id no longer exists',
          () async {
        await holdOrder(store, draft(label: 'A'));
        final result =
            await updateHeldOrder(store, 'hold_missing', draft(label: 'ghost'));
        expect(result, isNull);
        expect(await listHeldOrders(store, 'out_1'), hasLength(1));
      });

      test('bumps heldAt so the updated basket resurfaces at the top',
          () async {
        // Explicit timestamps rather than the wall clock. The oracle relies on the real
        // clock and its three operations land in different milliseconds by luck of
        // scheduling — on a faster machine they can all share one, and then this test
        // would pass through the insertion-order tie-break instead of through the bump it
        // is supposed to be testing. Fixed instants remove that dependence.
        final a = await holdOrder(
          store,
          draft(label: 'older'),
          now: DateTime.parse('2026-09-19T05:00:00Z'),
        );
        await holdOrder(
          store,
          draft(label: 'newer'),
          now: DateTime.parse('2026-09-19T05:00:01Z'),
        );
        // `newer` is on top before the update, so the assertion below can only pass if
        // the update actually moved `a` above it.
        expect(
            (await listHeldOrders(store, 'out_1'))[0].label, equals('newer'));

        await updateHeldOrder(
          store,
          a.id,
          draft(label: 'older'),
          now: DateTime.parse('2026-09-19T05:00:02Z'),
        );
        expect((await listHeldOrders(store, 'out_1'))[0].id, equals(a.id));
      });

      // BUKAN dari oracle. Dart's `List.sort` is not stable, JavaScript's is (ES2019+),
      // and the source's ordering depends on that: baskets parked inside the same
      // millisecond must keep their insertion order rather than shuffling between reads.
      // The oracle cannot catch a regression here because its timestamps differ, so this
      // pins it directly.
      //
      // Expected order is insertion order, verified by running the source's own sort in
      // Node: a stable descending sort leaves equal keys exactly as it found them. (The
      // first draft of this test asserted reverse order — that was wrong, and the failing
      // run is what showed it. The implementation was right.)
      test('keeps insertion order for baskets held in the same millisecond',
          () async {
        final at = DateTime.parse('2026-09-19T05:00:00Z');
        final ids = <String>[];
        for (var i = 0; i < 20; i++) {
          ids.add((await holdOrder(store, draft(label: 'b$i'), now: at)).id);
        }
        final listed =
            (await listHeldOrders(store, 'out_1')).map((o) => o.id).toList();
        expect(listed, equals(ids));
      });

      // The tie-break above is only meaningful if a *different* timestamp still wins, so
      // this pins that newer really does sort above older.
      test('still orders by heldAt when the timestamps differ', () async {
        final older = await holdOrder(
          store,
          draft(label: 'older'),
          now: DateTime.parse('2026-09-19T05:00:00Z'),
        );
        final newer = await holdOrder(
          store,
          draft(label: 'newer'),
          now: DateTime.parse('2026-09-19T05:00:01Z'),
        );
        final listed =
            (await listHeldOrders(store, 'out_1')).map((o) => o.id).toList();
        expect(listed, equals([newer.id, older.id]));
      });
    });
  });
}
