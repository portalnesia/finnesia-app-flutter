/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pos/native/db/app_database.dart';
import 'package:pos/native/queue/pending_sale_sqlite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// The real `PendingSaleStore`, against the real engine: SQLite in memory
// (`sqflite_common_ffi`), so the SQL is actually run — the `UNIQUE` column, the transaction, the
// `ORDER BY`. A store faked in memory never executes one line of it
// (`.claude/rules/testing.md` §2.1), and this queue holds money that has already been taken.
//
// The contract is the port's (`pn_pos/pos_pending_sale_store.dart`), and it is the **opposite**
// of the held orders: a write that fails throws, a read that fails throws, and a queue that
// cannot be read is never reported as empty. Those cases are below, next to the ones that pin
// the ordinary behaviour, because the reversal is the point of the whole port
// (`plan/offline-queue/README.md` §4.1).

const kopi = NamedRef(id: 'prd_1', name: 'Kopi Susu');

PendingSaleReceipt receipt() => const PendingSaleReceipt(
  outletName: 'Outlet Pusat',
  cashierName: 'Putu',
  subtotal: 1000,
  discountAmount: 0,
  taxAmount: 0,
  grandTotal: 1000,
  tenderedAmount: 1000,
  changeAmount: 0,
  items: [
    SalesInvoiceItem(
      id: 'inv_1',
      quantity: 1,
      price: 1000,
      lineSubtotal: 1000,
      lineTotal: 1000,
      product: kopi,
    ),
  ],
);

/// A queued sale whose stored payload carries no `clientRef`, no `paidAt` and no `shiftId`:
/// those live in their own columns so the same value is not written twice.
PendingSale sale({
  String clientRef = 'A',
  String companyId = 'comp_1',
  String outletId = 'out_1',
  String cashierId = 'user_1',
  String? shiftId = 'shift_1',
  PendingSaleStatus status = PendingSaleStatus.pending,
  String? error,
  int attempts = 0,
  String? customerId,
  String? notes,
  num? discountAmount,
}) => PendingSale(
  clientRef: clientRef,
  companyId: companyId,
  outletId: outletId,
  cashierId: cashierId,
  shiftId: shiftId,
  status: status,
  error: error,
  paidAt: '2026-09-21T03:00:00.000Z',
  createdAt: '2026-09-21T03:00:01.000Z',
  attempts: attempts,
  payload: POSCheckoutDTO(
    outletId: outletId,
    transactionDate: '2026-09-21',
    items: const [
      POSCheckoutItemDTO(
        productId: 'prd_1',
        unitId: 'unt_1',
        quantity: 1,
        price: 1000,
      ),
    ],
    payments: const [POSTenderDTO(method: POSTenderMethod.cash, amount: 1000)],
    customerId: customerId,
    notes: notes,
    discountAmount: discountAmount,
  ),
  receipt: receipt(),
);

/// A row written straight into the table, for the states the store refuses to create: another
/// tenant's sale, a status this build does not know, a payload that is not JSON.
///
/// The payload and the receipt are **real** encoded ones by default, so a test that breaks one
/// column fails for that column's reason and not because the row never decoded at all. A test
/// that passes for the wrong reason is not evidence (`testing.md` §0.3).
Map<String, Object?> rawRow({
  String clientRef = 'raw_1',
  String companyId = 'comp_1',
  String outletId = 'out_1',
  String status = 'pending',
  String? payload,
  String? receipt,
}) {
  final reference = sale(clientRef: clientRef, companyId: companyId);
  return {
    'client_ref': clientRef,
    'company_id': companyId,
    'outlet_id': outletId,
    'cashier_id': 'user_1',
    'status': status,
    'paid_at': '2026-09-21T03:00:00.000Z',
    'created_at': '2026-09-21T03:00:01.000Z',
    'payload': payload ?? jsonEncode(reference.payload.toJson()),
    'receipt': receipt ?? jsonEncode(reference.receipt.toJson()),
  };
}

Future<Database> database({String? path}) async {
  sqfliteFfiInit();
  final db = await openAppDatabase(
    factory: databaseFactoryFfi,
    path: path ?? inMemoryDatabasePath,
  );
  addTearDown(() async {
    if (db.isOpen) await db.close();
  });
  return db;
}

Future<SqlitePendingSaleStore> store({String companyId = 'comp_1'}) async {
  final db = await database();
  return SqlitePendingSaleStore(() async => db, companyId: companyId);
}

void main() {
  group('what is kept', () {
    test('a new queue is empty', () async {
      final s = await store();

      expect(await s.readAll(), isEmpty);
      expect(await s.count(), 0);
    });

    test('a queued sale comes back as it went in, with its payload and '
        'receipt', () async {
      // The payload is what gets posted and the receipt is what gets printed, so a field lost
      // here is a field lost in both. The optional ones are the ones a round trip drops.
      final s = await store();
      final full = sale(
        customerId: 'cust_1',
        notes: 'tanpa gula',
        discountAmount: 500,
      );

      await s.enqueue(full);

      expect(await s.readAll(), [full]);
    });

    test('the payload is stored without the three fields that have their own '
        'columns', () async {
      // `toCheckoutPayload` stamps `client_ref`, `paid_at` and `shift_id` onto the payload from
      // the columns on the way out. A copy left inside the stored JSON would be a second value of
      // the one field the server dedupes on, and the stale one is what would go out
      // (README §4.2). The helper above builds a payload without them, so this one puts them
      // there on purpose: the stripping has to be the store's doing, not the caller's.
      final s = await store();
      final stale = sale(clientRef: 'A').payload.copyWith(
        clientRef: 'STALE',
        paidAt: '1999-01-01T00:00:00.000Z',
        shiftId: 'shift_lama',
      );

      await s.enqueue(sale(clientRef: 'A').copyWith(payload: stale));

      final stored = (await s.readAll()).single;
      expect(stored.payload.clientRef, isNull);
      expect(stored.payload.paidAt, isNull);
      expect(stored.payload.shiftId, isNull);
      // And the columns still carry the real values, which is what goes out.
      expect(stored.clientRef, 'A');
      expect(stored.paidAt, '2026-09-21T03:00:00.000Z');
    });

    test('the goods of the temporary receipt survive: the printed copy comes '
        'from here, not from the server', () async {
      // A sale that has not been sent has no server record to print from, so this copy is the
      // only proof the customer gets (README D-Q3).
      final s = await store();
      await s.enqueue(sale());

      final entry = (await s.readAll()).single;
      expect(entry.receipt.items.single.product?.name, 'Kopi Susu');
      expect(entry.receipt.items.single.lineTotal, 1000);
      expect(entry.receipt.cashierName, 'Putu');
      expect(entry.receipt.changeAmount, 0);
      // Not a second copy of the payments: they are already in the payload, in the shape the
      // formatter reads, and two copies can disagree about how much money changed hands.
      expect(entry.payload.payments.single.amount, 1000);
    });

    test('reads the queue in the order it was written', () async {
      // Send order. A sale rung up first belongs in the drawer first.
      final s = await store();

      await s.enqueue(sale(clientRef: 'A'));
      await s.enqueue(sale(clientRef: 'B'));
      await s.enqueue(sale(clientRef: 'C'));

      expect((await s.readAll()).map((e) => e.clientRef), ['A', 'B', 'C']);
    });

    test('keeps the send order across a day of mixed outlets and cashiers', () async {
      // The shape a real day has: several outlets and a change of cashier, interleaved. The
      // order is financial — a sale rung up first must be recorded first, and the receipt
      // numbering and the shift it lands in both depend on it — so it is asserted against the
      // shape that would expose a reordering, not against three identical rows.
      final s = await store();

      await s.enqueue(sale(clientRef: 'A', outletId: 'out_2', cashierId: 'u1'));
      await s.enqueue(sale(clientRef: 'B', outletId: 'out_1', cashierId: 'u1'));
      await s.enqueue(sale(clientRef: 'C', outletId: 'out_2', cashierId: 'u2'));
      await s.enqueue(sale(clientRef: 'D', outletId: 'out_1', cashierId: 'u2'));

      expect((await s.readAll()).map((e) => e.clientRef), ['A', 'B', 'C', 'D']);
    });

    test('a sale with no shift comes back with no shift', () async {
      // A company that runs without shifts is an ordinary case, and the column is nullable
      // for it (`findings.md` F3).
      final s = await store();

      await s.enqueue(sale(shiftId: null));

      expect((await s.readAll()).single.shiftId, isNull);
    });

    test('keeps each company queue separate, including a row this store '
        'would refuse to write', () async {
      // Tenant safety. The other tenant's row is written straight into the table, so this
      // proves the filter rather than the absence of data: a shared queue would post one
      // tenant's sales to another on a re-paired device.
      final db = await database();
      final s = SqlitePendingSaleStore(() async => db, companyId: 'comp_1');
      await db.insert('pending_sales', rawRow(companyId: 'comp_2'));
      await s.enqueue(sale(companyId: 'comp_1'));

      expect((await s.readAll()).single.companyId, 'comp_1');
      expect(await s.count(), 1);
      expect(await db.query('pending_sales'), hasLength(2));
    });
  });

  group('the tenant belongs to the store, not to the caller', () {
    test('refuses a sale belonging to another company, loudly, and writes '
        'nothing', () async {
      // The column would accept it and no read would ever return it — a sale silently outside
      // its own queue, which is the failure this port exists to prevent.
      final s = await store();

      await expectLater(
        s.enqueue(sale(companyId: 'comp_2')),
        throwsA(isA<ArgumentError>()),
      );
      expect(await s.readAll(), isEmpty);
    });
  });

  group('idempotency', () {
    test('queuing the same client_ref twice writes it once', () async {
      // The real case: a caller retried after a timeout and the first write did land. A second
      // row would be a second sale for money taken once.
      final s = await store();

      await s.enqueue(sale(clientRef: 'A'));
      await s.enqueue(sale(clientRef: 'A'));

      expect(await s.count(), 1);
    });

    test(
      're-queuing does not overwrite the entry that is already there',
      () async {
        // The first write is the one that knows when the money was taken; a retry carrying a
        // rebuilt payload must not replace it.
        final s = await store();

        await s.enqueue(sale(clientRef: 'A', notes: 'asli'));
        await s.enqueue(sale(clientRef: 'A', notes: 'berbeda'));

        expect((await s.readAll()).single.payload.notes, 'asli');
      },
    );

    test('the second enqueue is not an error: the UNIQUE column is the last '
        'line of defence, not a signal to the caller', () async {
      // The store checks before writing, but two writers can race — a second pass and the
      // cashier both retrying. The insert then fails on `client_ref UNIQUE`, and that is the
      // answer the store already knows how to give. Letting it out would make a harmless
      // retry look like a failing disk.
      final s = await store();
      await s.enqueue(sale(clientRef: 'A'));

      await s.enqueue(
        sale(clientRef: 'A'),
      ); // completes; a throw fails the test

      expect(await s.count(), 1);
    });
  });

  group('counting', () {
    test('counts only pending sales', () async {
      final s = await store();
      await s.enqueue(sale(clientRef: 'A'));
      await s.enqueue(sale(clientRef: 'B'));

      await s.markFailed('B', 'boom');

      expect(await s.count(), 1);
    });

    test('can count per outlet', () async {
      final s = await store();
      await s.enqueue(sale(clientRef: 'A', outletId: 'out_1'));
      await s.enqueue(sale(clientRef: 'B', outletId: 'out_2'));

      expect(await s.count(outletId: 'out_1'), 1);
      expect(await s.count(), 2);
    });

    test('counts pending and failed together when the status is not narrowed: '
        'what the close-shift guard asks', () async {
      // The guard refuses while there is a `pending` **or** `failed` sale at the outlet
      // (README §6), and it asks that question with `status: null`.
      final s = await store();
      await s.enqueue(sale(clientRef: 'A'));
      await s.enqueue(sale(clientRef: 'B'));
      await s.markFailed('B', 'boom');

      expect(await s.count(outletId: 'out_1', status: null), 2);
      expect(await s.count(status: null), 2);
    });

    test('an outlet with nothing queued counts zero, and so does another '
        'tenant', () async {
      final s = await store();
      await s.enqueue(sale(clientRef: 'A', outletId: 'out_1'));

      expect(await s.count(outletId: 'out_2'), 0);
      expect(await s.count(status: null), 1);
    });
  });

  group('marking and removing', () {
    test('removes the sale once it has been sent', () async {
      final s = await store();
      await s.enqueue(sale(clientRef: 'A'));

      await s.remove('A');

      expect(await s.readAll(), isEmpty);
    });

    test('keeps a failed sale in the list and records why', () async {
      // The goods have already left the shop, so it stays visible for the cashier to retry or
      // discard knowing the drawer will be short.
      final s = await store();
      await s.enqueue(sale(clientRef: 'A'));

      await s.markFailed('A', 'stock habis');

      final entry = (await s.readAll()).single;
      expect(entry.status, PendingSaleStatus.failed);
      expect(entry.error, 'stock habis');
    });

    test(
      'puts a retried sale back in the pending queue, without its reason',
      () async {
        final s = await store();
        await s.enqueue(sale(clientRef: 'A'));
        await s.markFailed('A', 'boom');

        await s.retry('A');

        final entry = (await s.readAll()).single;
        expect(entry.status, PendingSaleStatus.pending);
        expect(entry.error, isNull);
        expect(await s.count(), 1);
      },
    );

    test('counts the attempts a sale has failed to send', () async {
      // Shown in the panel, so a sale that keeps failing is visible rather than silently
      // retrying forever.
      final s = await store();
      await s.enqueue(sale(clientRef: 'A'));

      await s.recordAttempt('A');
      await s.recordAttempt('A');

      expect((await s.readAll()).single.attempts, 2);
    });

    test(
      'records the reason and counts the attempt in the same write',
      () async {
        // A sale the server blocks (402, or 403 `outlet_inactive`) stays `pending`, so it never
        // reaches `markFailed` — the attempt counter alone would leave the cashier with no idea
        // why the sale is not going through. The reason goes into the existing `error` column,
        // in one statement, because a second statement could land between two passes
        // (spec §3c).
        final s = await store();
        await s.enqueue(sale(clientRef: 'A'));

        await s.recordAttempt(
          'A',
          reason: 'Masa berlaku langganan telah berakhir',
        );

        final entry = (await s.readAll()).single;
        expect(entry.status, PendingSaleStatus.pending);
        expect(entry.attempts, 1);
        expect(entry.error, 'Masa berlaku langganan telah berakhir');
      },
    );

    test('a newer reason replaces the older one', () async {
      // The latest answer is the true one: the block may have changed from one key to another
      // between passes.
      final s = await store();
      await s.enqueue(sale(clientRef: 'A'));

      await s.recordAttempt('A', reason: 'langganan habis');
      await s.recordAttempt('A', reason: 'kuota outlet penuh');

      final entry = (await s.readAll()).single;
      expect(entry.attempts, 2);
      expect(entry.error, 'kuota outlet penuh');
    });

    test('an attempt without a reason leaves the last reason in place', () async {
      // A later pass that failed on the network or a 5xx must not erase the explanation the
      // server gave — that is the one thing the cashier can act on (spec §3c).
      final s = await store();
      await s.enqueue(sale(clientRef: 'A'));
      await s.recordAttempt('A', reason: 'langganan habis');

      await s.recordAttempt('A');

      final entry = (await s.readAll()).single;
      expect(entry.attempts, 2);
      expect(entry.error, 'langganan habis');
    });

    test('retry clears a reason an attempt wrote, not only a mark', () async {
      // Pressing Ulangi is the cashier saying the state has been fixed, so the explanation goes
      // with it. The blocked entry is `pending` rather than `failed`, so this is the one path
      // that clears it (spec §3c).
      final s = await store();
      await s.enqueue(sale(clientRef: 'A'));
      await s.recordAttempt('A', reason: 'langganan habis');

      await s.retry('A');

      final entry = (await s.readAll()).single;
      expect(entry.status, PendingSaleStatus.pending);
      expect(entry.error, isNull);
    });

    test('an unknown client_ref changes nothing, and does not throw', () async {
      // "The row is gone" is an ordinary state: another pass may have removed it, or the
      // cashier discarded it while this one was retrying.
      final s = await store();
      await s.enqueue(sale(clientRef: 'A'));

      await s.markFailed('tidak-ada', 'boom');
      await s.retry('tidak-ada');
      await s.recordAttempt('tidak-ada');
      await s.remove('tidak-ada');

      expect((await s.readAll()).single.status, PendingSaleStatus.pending);
    });

    test('removing one sale leaves the others alone, and in order', () async {
      final s = await store();
      await s.enqueue(sale(clientRef: 'A'));
      await s.enqueue(sale(clientRef: 'B'));
      await s.enqueue(sale(clientRef: 'C'));

      await s.remove('B');

      expect((await s.readAll()).map((e) => e.clientRef), ['A', 'C']);
    });
  });

  group('what survives the process', () {
    test(
      'a queued sale is still there when the file is opened again',
      () async {
        // The whole point of the queue: the app dies mid-request and the sale is on disk. SQLite
        // in memory cannot show this, so this one uses a real file.
        final path = await _tempFile();

        final first = await database(path: path);
        await SqlitePendingSaleStore(
          () async => first,
          companyId: 'comp_1',
        ).enqueue(sale(clientRef: 'A'));
        await first.close();

        final second = await database(path: path);
        final entry = (await SqlitePendingSaleStore(
          () async => second,
          companyId: 'comp_1',
        ).readAll()).single;
        expect(entry.clientRef, 'A');
        expect(entry.status, PendingSaleStatus.pending);
        expect(entry.receipt.items.single.product?.name, 'Kopi Susu');
      },
    );

    test('a failed sale is still failed after a restart: it is not retried by '
        'itself', () async {
      final path = await _tempFile();

      final first = await database(path: path);
      final before = SqlitePendingSaleStore(
        () async => first,
        companyId: 'comp_1',
      );
      await before.enqueue(sale(clientRef: 'A'));
      await before.markFailed('A', 'stock habis');
      await first.close();

      final second = await database(path: path);
      final after = SqlitePendingSaleStore(
        () async => second,
        companyId: 'comp_1',
      );
      expect((await after.readAll()).single.status, PendingSaleStatus.failed);
      expect(await after.count(), 0);
      expect(await after.count(status: null), 1);
    });
  });

  group('the reads and the indexes', () {
    // `optimization.md` §4.1 asks for the index to be checked, and a table that merely has one
    // proves nothing: a query can ignore it. These are the shapes the store's own statements
    // have, written out here so the engine can be asked which index it chose. Q0 checked the
    // schema; this checks that the store's reads are actually served by it.
    test(
      'counting by status, and by outlet, is answered from an index',
      () async {
        final db = await database();

        expect(
          await _plan(
            db,
            'SELECT COUNT(*) FROM pending_sales WHERE company_id = ? AND status = ?',
            ['comp_1', 'pending'],
          ),
          contains(contains('pending_sales_status')),
        );
        expect(
          await _plan(
            db,
            'SELECT COUNT(*) FROM pending_sales '
            'WHERE company_id = ? AND outlet_id = ? AND status = ?',
            ['comp_1', 'out_1', 'pending'],
          ),
          contains(contains('pending_sales_outlet')),
        );
        expect(
          await _plan(
            db,
            'UPDATE pending_sales SET attempts = attempts + 1 '
            'WHERE client_ref = ? AND company_id = ?',
            ['A', 'comp_1'],
          ),
          contains(contains('pending_sales')),
        );
      },
    );

    test('reading the whole queue is a full scan: the filter is not on an '
        'index prefix, and that is fine', () async {
      // Measured, not assumed. `readAll` filters on `company_id`, which no index leads with, so
      // the engine scans. That is the right plan here: the drain loop reads the **whole** queue
      // every pass, so an index on the filter would add a lookup per row and save nothing. It
      // would earn its place only if the queue were read for one tenant among many on one
      // device — which cannot happen, because a store is bound to one tenant (README §4.1).
      final db = await database();

      final steps = await _plan(
        db,
        'SELECT * FROM pending_sales WHERE company_id = ? ORDER BY position',
        ['comp_1'],
      );

      expect(steps, contains(contains('SCAN')));
      // No sort step: `position` is the rowid, so the scan already returns send order.
      expect(steps, isNot(contains(contains('TEMP B-TREE'))));
    });

    test('the plan check can fail: a query no index can serve is reported as '
        'a scan', () async {
      // The control for the two tests above. Without it, "the plan names the index" could be
      // true of every query, and "the plan is a scan" could be true of every query too — the
      // detector would never be able to report a miss (`testing.md` §0.3).
      final db = await database();

      final steps = await _plan(
        db,
        'SELECT COUNT(*) FROM pending_sales WHERE error = ?',
        ['x'],
      );

      expect(steps, contains(contains('SCAN')));
      expect(steps, isNot(contains(contains('pending_sales_status'))));
    });

    test('the ORDER BY is what keeps send order once an index leads on '
        'company_id', () async {
      // Today this read is a full scan and a scan already returns rowid order, so the `ORDER BY`
      // cannot be observed — a probe that took it away passed (`findings.md` F11). It is kept for
      // the case where it does matter, and this is that case: add an index leading on
      // `company_id` and the engine prefers an index search, so the order comes from the clause
      // alone. Measured on this exact data without the clause: `B, D, A, C`.
      //
      // The index is created here rather than in the schema, the same way the Q0 test builds both
      // index shapes to compare their plans: the claim is about what the clause does under a plan
      // the engine may choose later, so the plan has to be built to check it.
      final db = await database();
      final s = SqlitePendingSaleStore(() async => db, companyId: 'comp_1');
      await s.enqueue(sale(clientRef: 'A', outletId: 'out_2'));
      await s.enqueue(sale(clientRef: 'B', outletId: 'out_1'));
      await s.enqueue(sale(clientRef: 'C', outletId: 'out_2'));
      await s.enqueue(sale(clientRef: 'D', outletId: 'out_1'));
      await db.execute(
        'CREATE INDEX ix_company_outlet ON pending_sales (company_id, outlet_id)',
      );

      // Prove the plan really changed. Without this the test would pass against a full scan and
      // would not be testing the clause at all (`testing.md` §0.3).
      expect(
        await _plan(
          db,
          'SELECT * FROM pending_sales WHERE company_id = ? ORDER BY position',
          ['comp_1'],
        ),
        contains(contains('ix_company_outlet')),
      );

      expect((await s.readAll()).map((e) => e.clientRef), ['A', 'B', 'C', 'D']);
    });
  });

  group('when the storage misbehaves', () {
    test('a failed read throws, it does not read as empty', () async {
      // The reversal from the web app, and the point of the whole port: an unreadable queue
      // that looks empty lets the cashier close the shift and reset the tablet over sales
      // nobody can see.
      final db = await database();
      final s = SqlitePendingSaleStore(() async => db, companyId: 'comp_1');
      await s.enqueue(sale(clientRef: 'A'));
      await db.close();

      await expectLater(s.readAll(), throwsA(isA<PendingSaleStoreException>()));
    });

    test('a failed count throws too, so the guard does not read "nothing '
        'waiting"', () async {
      final db = await database();
      final s = SqlitePendingSaleStore(() async => db, companyId: 'comp_1');
      await db.close();

      await expectLater(s.count(), throwsA(isA<PendingSaleStoreException>()));
      await expectLater(
        s.count(status: null),
        throwsA(isA<PendingSaleStoreException>()),
      );
    });

    test('a failed write throws, so the cart is not cleared over it', () async {
      // The caller keeps the cashier on the pay screen and says the sale was not processed.
      // Swallowing it would let the cart be emptied for a sale with no record anywhere.
      final db = await database();
      final s = SqlitePendingSaleStore(() async => db, companyId: 'comp_1');
      await db.close();

      await expectLater(
        s.enqueue(sale(clientRef: 'A')),
        throwsA(isA<PendingSaleStoreException>()),
      );
    });

    test('a failed remove throws: the sale may still be queued', () async {
      // Silent here would tell the drain loop the sale is gone while it is still on disk, and
      // the next pass would post it a second time.
      final db = await database();
      final s = SqlitePendingSaleStore(() async => db, companyId: 'comp_1');
      await s.enqueue(sale(clientRef: 'A'));
      await db.close();

      await expectLater(
        s.remove('A'),
        throwsA(isA<PendingSaleStoreException>()),
      );
    });

    test(
      'a failed mark, retry or attempt throws, as every other write does',
      () async {
        final db = await database();
        final s = SqlitePendingSaleStore(() async => db, companyId: 'comp_1');
        await s.enqueue(sale(clientRef: 'A'));
        await db.close();

        await expectLater(
          s.markFailed('A', 'boom'),
          throwsA(isA<PendingSaleStoreException>()),
        );
        await expectLater(
          s.retry('A'),
          throwsA(isA<PendingSaleStoreException>()),
        );
        await expectLater(
          s.recordAttempt('A'),
          throwsA(isA<PendingSaleStoreException>()),
        );
      },
    );

    test('a row whose status this build does not know throws, instead of '
        'being treated as pending', () async {
      // A newer build may write a status this one has no rule for. Reading it as pending would
      // post a sale the newer build had deliberately parked.
      final db = await database();
      final s = SqlitePendingSaleStore(() async => db, companyId: 'comp_1');
      await db.insert('pending_sales', rawRow(status: 'sent'));
      await expectLater(s.readAll(), throwsA(isA<PendingSaleStoreException>()));
    });

    test('a row whose payload is not readable throws: a sale that cannot be '
        'sent must not be invisible', () async {
      final db = await database();
      final s = SqlitePendingSaleStore(() async => db, companyId: 'comp_1');
      await db.insert('pending_sales', rawRow(payload: '{not json'));

      await expectLater(s.readAll(), throwsA(isA<PendingSaleStoreException>()));
    });

    test('a row whose receipt is not readable throws, before it can be printed '
        'as a blank slip', () async {
      // A receipt that decodes to nothing would print a slip with no goods on it, which is
      // worse than an error the cashier can act on.
      final db = await database();
      final s = SqlitePendingSaleStore(() async => db, companyId: 'comp_1');
      await db.insert('pending_sales', rawRow(receipt: '{not json'));

      await expectLater(s.readAll(), throwsA(isA<PendingSaleStoreException>()));
    });

    test('the failure carries what the storage said, for the log', () async {
      // Not a token and not a payload: the message is for a developer reading a bug report,
      // and `security.md` §1 keeps the sale's contents out of it.
      final db = await database();
      final s = SqlitePendingSaleStore(() async => db, companyId: 'comp_1');
      await db.close();

      await expectLater(
        s.readAll(),
        throwsA(
          isA<PendingSaleStoreException>().having(
            (e) => e.message,
            'message',
            isNotEmpty,
          ),
        ),
      );
    });
  });
}

/// A database file of its own, in a directory that is removed afterwards.
Future<String> _tempFile() async {
  final directory = Directory.systemTemp.createTempSync('finnesia_queue_');
  addTearDown(() => directory.deleteSync(recursive: true));
  return '${directory.path}/finnesia_pos.db';
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
