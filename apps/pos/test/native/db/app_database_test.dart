/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_types/src/product.dart';
import 'package:pos/native/db/app_database.dart';
import 'package:pos/native/hold/hold_sqlite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Where the database file goes, and that what is written to it is still there when it is opened
// again, which SQLite in memory cannot show.
//
// The rule is one for every platform: the application support directory, which is where the
// other plugins already keep their files on Windows (`%APPDATA%\<company>\<product>`, from
// `Runner.rc`). Nothing here names a folder, so a rename of the app moves this file with the rest.
// The factory is FFI in these tests on any platform; only the path is what is being checked.

void main() {
  late Directory support;

  setUp(() {
    sqfliteFfiInit();
    support = Directory.systemTemp.createTempSync('finnesia_support_');
    addTearDown(() => support.deleteSync(recursive: true));
  });

  HeldOrder order() => const HeldOrder(
    id: 'h1',
    label: 'Meja 4',
    outletId: 'out_1',
    headerDiscount: 0,
    lines: [
      CartLine(
        id: 'l1',
        product: Product(id: 'p', name: 'Kopi', unitId: 'u'),
        qty: 2,
      ),
    ],
    heldAt: '2026-09-21T03:00:00.000Z',
  );

  for (final windows in [true, false]) {
    group('on ${windows ? 'Windows' : 'Android'}', () {
      test('the file is in the application support directory', () async {
        final db = await openAppDatabase(
          factory: databaseFactoryFfi,
          windows: windows,
          supportDirectory: () async => support,
        );
        await db.close();

        expect(File('${support.path}/finnesia_pos.db').existsSync(), isTrue);
      });

      test('what was written survives closing and opening it again', () async {
        Future<dynamic> open() => openAppDatabase(
          factory: databaseFactoryFfi,
          windows: windows,
          supportDirectory: () async => support,
        );
        final first = await open();
        await SqliteHoldOrderStore(() async => first).writeAll([order()]);
        await first.close();

        final second = await open();
        addTearDown(second.close);

        expect(await SqliteHoldOrderStore(() async => second).readAll(), [
          order(),
        ]);
      });
    });
  }

  test('the directory is made when it is not there yet', () async {
    final missing = Directory('${support.path}/not/yet');

    final db = await openAppDatabase(
      factory: databaseFactoryFfi,
      supportDirectory: () async => missing,
    );
    await db.close();

    expect(File('${missing.path}/finnesia_pos.db').existsSync(), isTrue);
  });

  // The queue's table (Q0 of `plan/offline-queue`). It is created in `_create` beside the held
  // orders, and these tests read the schema back out of SQLite: the columns, the constraints the
  // store will lean on, and the indexes the queue is read by.

  group('the pending sales table', () {
    test('a new database has both tables', () async {
      final db = await _inMemory();

      expect(
        await _tableNames(db),
        containsAll(['held_orders', 'pending_sales']),
      );
    });

    test('it carries every column the queue needs, with the constraints it '
        'leans on', () async {
      final db = await _inMemory();

      final columns = {
        for (final row in await db.rawQuery('PRAGMA table_info(pending_sales)'))
          row['name']! as String: row,
      };

      expect(columns.keys, [
        'position',
        'client_ref',
        'company_id',
        'outlet_id',
        'cashier_id',
        'shift_id',
        'status',
        'error',
        'paid_at',
        'created_at',
        'attempts',
        'payload',
        'receipt',
      ]);

      // The idempotency key is the database's promise, not the store's: a second enqueue of the
      // same basket must fail the insert instead of quietly writing a second sale.
      expect(columns['client_ref']!['notnull'], 1);
      // `position` is the send order, so it is the primary key rather than a column that is sorted.
      expect(columns['position']!['pk'], 1);
      // Retries are counted from zero, so the column has to default rather than be passed in.
      expect(columns['attempts']!['dflt_value'], '0');
      // A basket that is not in a shift, and one that has not failed, are ordinary states.
      expect(columns['shift_id']!['notnull'], 0);
      expect(columns['error']!['notnull'], 0);
    });

    test(
      'the indexes are there, over the columns the queue is read by',
      () async {
        final db = await _inMemory();

        expect(await _indexColumns(db, 'pending_sales_status'), [
          'status',
          'position',
        ]);
        expect(await _indexColumns(db, 'pending_sales_outlet'), [
          'outlet_id',
          'status',
        ]);
      },
    );

    test('the queue reads use those indexes: the plan says so, not the '
        'schema', () async {
      // `optimization.md` §4.1 asks for the index to be checked, and a table that merely has one
      // proves nothing: a query can ignore it. The plan is the engine's own answer, so the drain
      // loop and the close-shift guard are each explained here.
      final db = await _inMemory();

      expect(
        await _plan(
          db,
          'SELECT * FROM pending_sales WHERE status = ? '
          'ORDER BY position',
          ['pending'],
        ),
        contains(contains('pending_sales_status')),
      );
      // `COUNT(*)` over two indexed columns is answered from the index alone ("COVERING"), which
      // is still the index and not a table scan, so the assertion is on the name.
      expect(
        await _plan(
          db,
          'SELECT COUNT(*) FROM pending_sales '
          'WHERE outlet_id = ? AND status = ?',
          ['out_1', 'pending'],
        ),
        contains(contains('pending_sales_outlet')),
      );
    });

    test('the plan check can fail: a query the index cannot serve does not '
        'name it', () async {
      // The control for the test above. Without this, "the plan names the index" could be true of
      // every query, including ones the index does not help — the detector would never be able to
      // report a miss (`testing.md` §0.3).
      final db = await _inMemory();

      final steps = await _plan(
        db,
        'SELECT * FROM pending_sales WHERE error = ?',
        ['x'],
      );

      expect(steps, isNot(contains(contains('pending_sales_status'))));
      expect(steps, contains(contains('SCAN')));
    });

    test('the second column of the status index buys nothing: the rowid is '
        'already in every entry', () async {
      // Q0 built the index as `(status, position)` on the plan's reasoning that `position` is the
      // send order. It is — but `position` is `INTEGER PRIMARY KEY`, so it **is** the rowid, and
      // every index entry already carries the rowid. An index on `(status)` alone answers
      // `ORDER BY position` with no sort step.
      //
      // This asserts that directly rather than trusting the reasoning: the same query against the
      // same table, with the second column taken away. If a future SQLite stops ordering by rowid
      // for free, the `ORDER BY` appears here and the column earns its place.
      final db = await _inMemory();
      const query =
          'SELECT * FROM pending_sales WHERE status = ? '
          'ORDER BY position';

      await db.execute('DROP INDEX pending_sales_status');
      await db.execute(
        'CREATE INDEX pending_sales_status ON pending_sales (status)',
      );
      final withoutPosition = await _plan(db, query, ['pending']);

      await db.execute('DROP INDEX pending_sales_status');
      await db.execute(
        'CREATE INDEX pending_sales_status ON pending_sales (status, position)',
      );
      final withPosition = await _plan(db, query, ['pending']);

      // Neither shape sorts, so the second column is decoration. The control above is what makes
      // this readable: it shows a sort step *is* visible when one exists.
      expect(withoutPosition, isNot(contains(contains('TEMP B-TREE'))));
      expect(withPosition, isNot(contains(contains('TEMP B-TREE'))));
    });

    test('a row goes in with only the required fields: the rest default or '
        'stay empty', () async {
      final db = await _inMemory();

      await db.insert('pending_sales', {
        'client_ref': '01J0REF',
        'company_id': 'comp_1',
        'outlet_id': 'out_1',
        'cashier_id': 'user_1',
        'status': 'pending',
        'paid_at': '2026-09-21T03:00:00.000Z',
        'created_at': '2026-09-21T03:00:00.000Z',
        'payload': '{}',
        'receipt': '{}',
      });

      final row = (await db.query('pending_sales')).single;
      expect(row['position'], 1);
      expect(row['attempts'], 0);
      expect(row['shift_id'], isNull);
      expect(row['error'], isNull);
    });

    test('the same client_ref cannot be queued twice: the database refuses it, '
        'not the store', () async {
      // The store checks too, but this is the constraint that holds when two writers race, and
      // the sale it guards has already been paid for.
      final db = await _inMemory();
      Future<void> enqueue() => db.insert('pending_sales', {
        'client_ref': '01J0REF',
        'company_id': 'comp_1',
        'outlet_id': 'out_1',
        'cashier_id': 'user_1',
        'status': 'pending',
        'paid_at': '2026-09-21T03:00:00.000Z',
        'created_at': '2026-09-21T03:00:00.000Z',
        'payload': '{}',
        'receipt': '{}',
      });
      await enqueue();

      await expectLater(enqueue(), throwsA(isA<DatabaseException>()));
      expect(await db.query('pending_sales'), hasLength(1));
    });

    test('a database made before the queue keeps its version and does not '
        'silently gain the table', () async {
      // A development tablet holds a version 1 file with only the held orders in it. There is no
      // migration before the first release (`plan/offline-queue` §4.2), so the version stays 1 and
      // the missing table fails loudly rather than appearing empty.
      final before = await databaseFactoryFfi.openDatabase(
        '${support.path}/finnesia_pos.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) => SqliteHoldOrderStore.createTable(db),
        ),
      );
      await before.close();

      final after = await openAppDatabase(
        factory: databaseFactoryFfi,
        supportDirectory: () async => support,
      );
      addTearDown(after.close);

      expect(await after.getVersion(), 1);
      expect(await _tableNames(after), isNot(contains('pending_sales')));
    });
  });
}

Future<Database> _inMemory() async {
  sqfliteFfiInit();
  final db = await openAppDatabase(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
  addTearDown(db.close);
  return db;
}

Future<List<String>> _tableNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  );
  return [for (final row in rows) row['name']! as String];
}

Future<List<String>> _indexColumns(Database db, String index) async {
  final rows = await db.rawQuery('PRAGMA index_info($index)');
  return [for (final row in rows) row['name']! as String];
}

/// `EXPLAIN QUERY PLAN`, as one string per step, so a test can ask which index the engine chose.
Future<List<String>> _plan(
  Database db,
  String sql, [
  List<Object?> args = const [],
]) async {
  final rows = await db.rawQuery('EXPLAIN QUERY PLAN $sql', args);
  return [for (final row in rows) row['detail']! as String];
}
