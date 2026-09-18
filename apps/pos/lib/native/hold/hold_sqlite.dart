/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_pos/src/pos_hold_store.dart';
import 'package:pn_types/src/product.dart';
import 'package:sqflite/sqflite.dart';

/// The held-order queue, in SQLite.
///
/// Implements the port's contract (`pn_pos/pos_hold_store.dart`): whole lists in and out.
class SqliteHoldOrderStore implements HoldOrderStore {
  SqliteHoldOrderStore(this._open);

  final Future<Database> Function() _open;

  static const _table = 'held_orders';

  /// Called by `openAppDatabase` when the database is created.
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_table (
        position INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT NOT NULL UNIQUE,
        label TEXT NOT NULL,
        outlet_id TEXT NOT NULL,
        customer_id TEXT,
        customer_memo TEXT,
        table_number TEXT,
        queue_number TEXT,
        header_discount REAL NOT NULL,
        held_at TEXT NOT NULL,
        lines TEXT NOT NULL
      )
    ''');
  }

  /// An unreadable store looks empty: a private database that cannot be opened, or one that is
  /// closed, must not take the till down mid-shift (the port's contract).
  ///
  /// A **row** that cannot be read (its lines are not JSON, a field is missing) is left out and the
  /// rest returned. One corrupted basket costs that basket, not the queue. The next write drops it
  /// for good, which loses nothing that was readable.
  @override
  Future<List<HeldOrder>> readAll() async {
    try {
      final db = await _open();
      final rows = await db.query(_table, orderBy: 'position');
      return [for (final row in rows) ?_tryRead(row)];
    } on Object {
      // Anything the storage can throw looks the same to the caller: nothing is held. There is
      // nothing a cashier could do with the difference, and the port says to return empty.
      return const [];
    }
  }

  /// Replaces the whole list, or none of it: one transaction, and one batch inside it, so a write
  /// that fails half way changes nothing and the number of round trips does not grow with the
  /// number of baskets.
  ///
  /// A failure is swallowed (the port's contract): a full or blocked disk leaves the cart in front
  /// of the cashier untouched, and throwing here would interrupt a sale in progress.
  @override
  Future<void> writeAll(List<HeldOrder> orders) async {
    try {
      final db = await _open();
      await db.transaction((txn) async {
        await txn.delete(_table);
        final batch = txn.batch();
        for (final order in orders) {
          batch.insert(_table, _toRow(order));
        }
        await batch.commit(noResult: true);
      });
    } on Object {
      // Only the parking queue is affected, and the transaction has already rolled back.
    }
  }
}

HeldOrder? _tryRead(Map<String, Object?> row) {
  try {
    return _fromRow(row);
  } on Object {
    return null;
  }
}

Map<String, Object?> _toRow(HeldOrder o) => {
  'id': o.id,
  'label': o.label,
  'outlet_id': o.outletId,
  'customer_id': o.customerId,
  'customer_memo': o.customerMemo,
  'table_number': o.tableNumber,
  'queue_number': o.queueNumber,
  'header_discount': o.headerDiscount,
  'held_at': o.heldAt,
  'lines': jsonEncode([
    for (final l in o.lines)
      {
        'id': l.id,
        'product': l.product.toJson(),
        'qty': l.qty,
        'discount_percent': l.discountPercent,
        'discount_amount': l.discountAmount,
      },
  ]),
};

HeldOrder _fromRow(Map<String, Object?> row) => HeldOrder(
  id: row['id']! as String,
  label: row['label']! as String,
  outletId: row['outlet_id']! as String,
  customerId: row['customer_id'] as String?,
  customerMemo: row['customer_memo'] as String?,
  tableNumber: row['table_number'] as String?,
  queueNumber: row['queue_number'] as String?,
  headerDiscount: row['header_discount']! as num,
  heldAt: row['held_at']! as String,
  lines: [
    for (final l in jsonDecode(row['lines']! as String) as List<Object?>)
      CartLine(
        id: (l! as Map<String, Object?>)['id']! as String,
        product: Product.fromJson(
          (l as Map<String, Object?>)['product']! as Map<String, dynamic>,
        ),
        qty: l['qty']! as num,
        discountPercent: l['discount_percent'] as num?,
        discountAmount: l['discount_amount'] as num?,
      ),
  ],
);
