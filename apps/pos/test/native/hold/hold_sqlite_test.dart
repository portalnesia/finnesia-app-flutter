/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_types/src/category.dart';
import 'package:pn_types/src/product.dart';
import 'package:pos/native/db/app_database.dart';
import 'package:pos/native/hold/hold_sqlite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// The real `HoldOrderStore`, against the real engine: SQLite in memory (`sqflite_common_ffi`), so
// the SQL is actually run: the constraints, the transaction, the order. A store faked in memory
// never executes one line of it (`.claude/rules/testing.md` §2.1).
//
// The contract is the port's (`pn_pos/pos_hold_store.dart`): an unreadable store looks empty and a
// failed write is swallowed, because a parked basket must never interrupt a sale in progress.

const kopi = Product(
  id: 'p1',
  name: 'Kopi Susu',
  sku: 'KS-1',
  unitId: 'u1',
  sellPrice: 15000,
  type: ProductType.inventory,
  isActive: true,
);

HeldOrder order(
  String id, {
  String outletId = 'out_1',
  String heldAt = '2026-09-21T03:00:00.000Z',
  List<CartLine>? lines,
}) => HeldOrder(
  id: id,
  label: 'Meja $id',
  outletId: outletId,
  headerDiscount: 0,
  lines: lines ?? [const CartLine(id: 'l1', product: kopi, qty: 2)],
  heldAt: heldAt,
);

Future<SqliteHoldOrderStore> store() async {
  sqfliteFfiInit();
  final db = await openAppDatabase(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
  addTearDown(db.close);
  return SqliteHoldOrderStore(() async => db);
}

void main() {
  group('what is kept', () {
    test('an order comes back as it went in, with its goods and every '
        'optional field', () async {
      final s = await store();
      final full = HeldOrder(
        id: 'h1',
        label: 'Meja 4',
        outletId: 'out_1',
        customerId: 'c1',
        customerMemo: 'Alergi kacang',
        tableNumber: '4',
        queueNumber: 'A-7',
        headerDiscount: 2500.5,
        lines: [
          const CartLine(id: 'l1', product: kopi, qty: 2, discountPercent: 10),
          const CartLine(
            id: 'l2',
            product: kopi,
            qty: 1.5,
            discountAmount: 500,
          ),
        ],
        heldAt: '2026-09-21T03:00:00.000Z',
      );

      await s.writeAll([full]);

      expect(await s.readAll(), [full]);
    });

    test('a new database has nothing held', () async {
      final s = await store();

      expect(await s.readAll(), isEmpty);
    });

    test('keeps the order it was given, also for equal timestamps: the list '
        'orders ties by insertion', () async {
      final s = await store();
      final same = '2026-09-21T03:00:00.000Z';

      await s.writeAll([
        order('c', heldAt: same),
        order('a', heldAt: same),
        order('b', heldAt: same),
      ]);

      expect((await s.readAll()).map((o) => o.id), ['c', 'a', 'b']);
    });

    test('writing replaces the whole list, it does not add to it', () async {
      final s = await store();
      await s.writeAll([order('a'), order('b')]);

      await s.writeAll([order('b'), order('c')]);

      expect((await s.readAll()).map((o) => o.id), ['b', 'c']);
    });

    test('writing nothing empties it', () async {
      final s = await store();
      await s.writeAll([order('a')]);

      await s.writeAll([]);

      expect(await s.readAll(), isEmpty);
    });

    test('holds the baskets of several outlets side by side', () async {
      final s = await store();

      await s.writeAll([order('a'), order('b', outletId: 'out_2')]);

      expect((await s.readAll()).map((o) => (o.id, o.outletId)), [
        ('a', 'out_1'),
        ('b', 'out_2'),
      ]);
    });

    test('a product keeps its category and the parent of it: the kitchen '
        'ticket groups on that', () async {
      final s = await store();
      final withCategory = order(
        'a',
        lines: [
          CartLine(
            id: 'l1',
            product: kopi.copyWith(
              category: const Category(
                id: 'c2',
                name: 'Kopi',
                parentId: 'c1',
                parent: Category(id: 'c1', name: 'Minuman'),
              ),
            ),
            qty: 1,
          ),
        ],
      );

      await s.writeAll([withCategory]);

      expect(await s.readAll(), [withCategory]);
    });
  });

  group('when the storage misbehaves', () {
    test('a row that cannot be read is left out, and the rest is returned: '
        'one corrupted basket must not take the queue down', () async {
      final sqlite = await _database();
      final s = SqliteHoldOrderStore(() async => sqlite);
      await s.writeAll([order('a'), order('c')]);
      await sqlite.insert('held_orders', {
        'id': 'broken',
        'label': 'x',
        'outlet_id': 'out_1',
        'header_discount': 0,
        'held_at': '2026-09-21T03:00:00.000Z',
        'lines': '{not json',
      });

      expect((await s.readAll()).map((o) => o.id), ['a', 'c']);
    });

    test('an unreadable store looks empty, and does not throw', () async {
      final sqlite = await _database();
      final s = SqliteHoldOrderStore(() async => sqlite);
      await s.writeAll([order('a')]);
      await sqlite.close();

      expect(await s.readAll(), isEmpty);
    });

    test('a failed write is swallowed: it must not interrupt a sale', () async {
      final sqlite = await _database();
      final s = SqliteHoldOrderStore(() async => sqlite);
      await sqlite.close();

      await s.writeAll([order('a')]); // completes; a throw fails the test
    });

    test('a write that fails half way changes nothing: the whole list is '
        'replaced or none of it is', () async {
      final s = await store();
      await s.writeAll([order('a'), order('b')]);

      // Two orders with one id: the second insert violates the primary key.
      await s.writeAll([order('x'), order('x')]);

      expect((await s.readAll()).map((o) => o.id), ['a', 'b']);
    });
  });
}

Future<Database> _database() async {
  sqfliteFfiInit();
  final db = await openAppDatabase(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
  addTearDown(() async {
    if (db.isOpen) await db.close();
  });
  return db;
}
