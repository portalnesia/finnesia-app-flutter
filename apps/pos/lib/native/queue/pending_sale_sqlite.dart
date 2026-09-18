/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_types/src/pos.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/utils/utils.dart';

/// The pending-sale queue, in SQLite.
///
/// Implements the port's contract (`pn_pos/pos_pending_sale_store.dart`), and that contract is
/// the **opposite** of [SqliteHoldOrderStore]'s: every failure throws
/// [PendingSaleStoreException], and nothing here ever answers "empty" for "unreadable".
///
/// ## Why the company is a constructor argument
///
/// It is the store's identity, not a per-call argument — see the port's class doc for the safety
/// reason. The column stays on every row and every statement filters on it, so a store can only
/// ever see and change its own tenant's sales.
///
/// ## Why a row that cannot be read is an exception rather than a skipped row
///
/// The held orders skip a corrupted row and return the rest, because losing one parked basket
/// costs that basket. Here a row that cannot be decoded is a **sale that cannot be sent**, and
/// skipping it would report a clean pass over money nobody can account for. So a bad row makes
/// the read throw, and the caller sees the queue as unreadable rather than as nearly empty.
class SqlitePendingSaleStore implements PendingSaleStore {
  SqlitePendingSaleStore(this._open, {required this.companyId});

  final Future<Database> Function() _open;

  @override
  final String companyId;

  static const _table = 'pending_sales';

  /// Called by `openAppDatabase` when the database is created.
  ///
  /// The schema lives here rather than in `app_database.dart` for the same reason the held
  /// orders' does: the columns and the code that reads them are one thing, and splitting them
  /// across two files is how they drift.
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE pending_sales (
        position INTEGER PRIMARY KEY AUTOINCREMENT,
        client_ref TEXT NOT NULL UNIQUE,
        company_id TEXT NOT NULL,
        outlet_id TEXT NOT NULL,
        cashier_id TEXT NOT NULL,
        shift_id TEXT,
        status TEXT NOT NULL,
        error TEXT,
        paid_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        payload TEXT NOT NULL,
        receipt TEXT NOT NULL
      )
    ''');

    // The queue is read by status and in send order (the drain loop), and by outlet for the
    // close-shift guard (`.claude/rules/optimization.md` §4.1). `position` is in the first index
    // because the plan writes it there; **it is not what makes the `ORDER BY` free** — `position`
    // is the rowid, which every index entry already carries, so an index on `(status)` alone also
    // returns rows in that order. Measured with `EXPLAIN QUERY PLAN` on both shapes: neither
    // shows a sort step, and a control query ordering by an unindexed column does. The test says
    // so (`test/native/db/app_database_test.dart`).
    await db.execute(
      'CREATE INDEX pending_sales_status ON pending_sales (status, position)',
    );
    await db.execute(
      'CREATE INDEX pending_sales_outlet ON pending_sales (outlet_id, status)',
    );
  }

  /// Every entry of this store's company, oldest first — the order they were rung up in, which
  /// is the order they are sent in.
  ///
  /// Ordered by `position`, which is the rowid: SQLite numbers an `INTEGER PRIMARY KEY` from the
  /// insert order, so the send order is the arrival order without a second column to maintain.
  ///
  /// ## The `ORDER BY` is load-bearing, and today it cannot be observed
  ///
  /// Measured, not assumed. With the schema as it stands the filter is on `company_id`, which no
  /// index leads with, so this is a full scan — and a scan already returns rowid order, so
  /// **removing the clause changes nothing and no test can tell the difference**. A probe that
  /// took it away passed (`plan/offline-queue/findings.md` F11).
  ///
  /// It stays because the measurement that matters is the other one: with an index leading on
  /// `company_id` — a realistic addition for a store read by outlet — the plan becomes an index
  /// search, and then the clause is what keeps the order right. Measured on the same data with
  /// `(company_id, outlet_id)` in place: with the clause the rows come back `r0,r1,r2,r3`, and
  /// without it `r1,r3,r0,r2`. The cheaper plan is the wrong one, which is exactly why the
  /// clause has to be there before anyone goes looking for the plan.
  @override
  Future<List<PendingSale>> readAll() => _guard('read the queue', () async {
    final db = await _open();
    final rows = await db.query(
      _table,
      where: 'company_id = ?',
      whereArgs: [companyId],
      orderBy: 'position',
    );
    return [for (final row in rows) _fromRow(row)];
  });

  /// Adds [sale], or does nothing when its `client_ref` is already queued.
  ///
  /// ## Idempotency is the database's, not this method's
  ///
  /// The `UNIQUE` column is the authority, and the catch below is what turns its refusal into the
  /// no-op the contract asks for. A check-then-insert would leave a window where a second writer
  /// — the drain loop and the cashier both retrying — slips a second row in for money taken once.
  ///
  /// Only the `client_ref` violation is treated as "already queued". Any other constraint failure
  /// is a real write failure and is reported as one: a sale that was not written must never look
  /// written, which is the whole point of this port.
  ///
  /// No explicit transaction: a single `INSERT` is already atomic in SQLite, so wrapping it would
  /// add a round trip and change nothing (`plan/offline-queue/README.md` §4.3).
  @override
  Future<void> enqueue(PendingSale sale) async {
    if (sale.companyId != companyId) {
      // The column would accept the row and no read would ever return it — a sale silently
      // outside its own queue. The port throws for this, and it throws before touching the disk.
      throw ArgumentError.value(
        sale.companyId,
        'sale.companyId',
        'belongs to another company than this store ($companyId)',
      );
    }
    await _guard('queue a sale', () async {
      final db = await _open();
      try {
        await db.insert(_table, _toRow(sale));
      } on DatabaseException catch (error) {
        if (error.isUniqueConstraintError('$_table.client_ref')) return;
        rethrow;
      }
    });
  }

  @override
  Future<int> count({
    String? outletId,
    PendingSaleStatus? status = PendingSaleStatus.pending,
  }) => _guard('count the queue', () async {
    final db = await _open();
    final where = <String>['company_id = ?'];
    final args = <Object?>[companyId];
    if (outletId != null) {
      where.add('outlet_id = ?');
      args.add(outletId);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status.wire);
    }
    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM $_table WHERE ${where.join(' AND ')}',
      args,
    );
    // `firstIntValue` rather than a cast: the count's SQLite type differs per platform, and this
    // is the helper `sqflite` ships for exactly this query (`.claude/rules/patterns.md` §2a).
    return firstIntValue(rows) ?? 0;
  });

  @override
  Future<void> markFailed(String clientRef, String error) => _guard(
    'mark a sale failed',
    () async => (await _open()).update(
      _table,
      {'status': PendingSaleStatus.failed.wire, 'error': error},
      where: 'client_ref = ? AND company_id = ?',
      whereArgs: [clientRef, companyId],
    ),
  );

  @override
  Future<void> retry(String clientRef) => _guard(
    'put a sale back in the queue',
    () async => (await _open()).update(
      _table,
      // The reason goes with the status: a pending sale has nothing to explain.
      {'status': PendingSaleStatus.pending.wire, 'error': null},
      where: 'client_ref = ? AND company_id = ?',
      whereArgs: [clientRef, companyId],
    ),
  );

  @override
  Future<void> remove(String clientRef) => _guard(
    'remove a sale from the queue',
    () async => (await _open()).delete(
      _table,
      where: 'client_ref = ? AND company_id = ?',
      whereArgs: [clientRef, companyId],
    ),
  );

  @override
  Future<void> recordAttempt(String clientRef, {String? reason}) => _guard(
    'count an attempt',
    () async => (await _open()).rawUpdate(
      // Counted by the database rather than read-then-write: two passes must not lose an attempt
      // between them, and this is one statement.
      //
      // `COALESCE` is what makes `reason` optional in the same statement: a non-null reason
      // replaces `error`, and a null one leaves whatever the server last said untouched — a
      // later network failure must not erase the explanation the cashier can act on
      // (`pos_pending_sale_store.dart`).
      'UPDATE $_table SET attempts = attempts + 1, error = COALESCE(?, error) '
      'WHERE client_ref = ? AND company_id = ?',
      [reason, clientRef, companyId],
    ),
  );

  /// Runs [body], turning anything the storage threw into [PendingSaleStoreException].
  ///
  /// One place rather than a `try` per method, so no method can quietly forget to report a
  /// failure — a method that swallowed one would be the exact bug this port exists to prevent.
  /// The message names the operation, never a payload or a token (`security.md` §1).
  Future<T> _guard<T>(String what, Future<T> Function() body) async {
    try {
      return await body();
    } on PendingSaleStoreException {
      // Already ours: a row that could not be decoded says so itself, with the detail.
      rethrow;
    } on Object catch (error) {
      throw PendingSaleStoreException('could not $what', cause: error);
    }
  }
}

Map<String, Object?> _toRow(PendingSale sale) => {
  'client_ref': sale.clientRef,
  'company_id': sale.companyId,
  'outlet_id': sale.outletId,
  'cashier_id': sale.cashierId,
  'shift_id': sale.shiftId,
  'status': sale.status.wire,
  'error': sale.error,
  'paid_at': sale.paidAt,
  'created_at': sale.createdAt,
  'attempts': sale.attempts,
  // The three fields that have their own columns are **removed** here rather than trusted to be
  // absent. `toCheckoutPayload` stamps them back on the way out from the columns, so a copy left
  // inside this JSON could only ever be a second, stale value of the one field the server dedupes
  // on (`plan/offline-queue/README.md` §4.2).
  'payload': jsonEncode(
    sale.payload
        .copyWith(clientRef: null, paidAt: null, shiftId: null)
        .toJson(),
  ),
  'receipt': jsonEncode(sale.receipt.toJson()),
};

PendingSale _fromRow(Map<String, Object?> row) {
  final clientRef = row['client_ref']! as String;
  final wire = row['status']! as String;
  final status = PendingSaleStatus.tryParse(wire);
  if (status == null) {
    // Not a default: reading an unknown status as `pending` would post a sale that a newer build
    // had deliberately parked (`pos_pending_sale.dart`).
    throw PendingSaleStoreException(
      'queued sale $clientRef has a status this build does not know ($wire)',
    );
  }
  return PendingSale(
    clientRef: clientRef,
    companyId: row['company_id']! as String,
    outletId: row['outlet_id']! as String,
    cashierId: row['cashier_id']! as String,
    shiftId: row['shift_id'] as String?,
    status: status,
    error: row['error'] as String?,
    paidAt: row['paid_at']! as String,
    createdAt: row['created_at']! as String,
    attempts: row['attempts']! as int,
    payload: _decode(clientRef, 'payload', POSCheckoutDTO.fromJson, row),
    receipt: _decode(clientRef, 'receipt', PendingSaleReceipt.fromJson, row),
  );
}

/// Decodes one JSON column, reporting **which** sale and which column failed.
///
/// The detail matters: "the queue cannot be read" alone leaves a cashier with a till that will
/// not open and nothing to tell anyone. The `client_ref` is an idempotency key, not a credential
/// and not a customer's name, so it is safe to name (`security.md` §1).
T _decode<T>(
  String clientRef,
  String column,
  T Function(Map<String, dynamic>) parse,
  Map<String, Object?> row,
) {
  try {
    return parse(jsonDecode(row[column]! as String) as Map<String, dynamic>);
  } on Object catch (error) {
    throw PendingSaleStoreException(
      'queued sale $clientRef has an unreadable $column',
      cause: error,
    );
  }
}
