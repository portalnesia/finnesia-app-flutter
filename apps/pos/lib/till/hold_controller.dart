/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_pos/src/pos_hold_store.dart';
import 'package:pn_pos/src/pos_transaction_detail.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pos/till/cart_controller.dart';
import 'package:pos/till/transaction_detail_controller.dart';

/// What holding the basket came to.
enum HoldOutcome {
  /// Parked, and the till is clear for the next customer.
  held,

  /// The till was empty.
  nothingToHold,

  /// The store did not keep it, so it is still on the till.
  notStored,
}

/// What resuming a basket came to.
enum ResumeOutcome {
  resumed,

  /// The basket on the till could not be parked first, so nothing was changed.
  currentNotStored,
}

/// Parks baskets and takes them back: the till's side of `pos-hold`.
///
/// The queue itself is `pn_pos`'s (`holdOrder`, `updateHeldOrder`, ...); this joins it to the cart
/// and the detail on screen, and remembers which held basket, if any, the cart is a resumed copy
/// of.
class HoldController extends ChangeNotifier {
  HoldController({
    required this.store,
    required this.outletId,
    required this.cart,
    required this.detail,
    required this._analytics,
    this.now = DateTime.now,
  }) {
    cart.addListener(_onCartChanged);
  }

  final HoldOrderStore store;
  final String outletId;
  final CartController cart;
  final TransactionDetailController detail;
  final AnalyticsPort _analytics;
  final DateTime Function() now;

  /// An empty cart can never legitimately be "the resumed basket": whether it emptied by
  /// "Clear" or by removing the last line one at a time, forgetting the link is what stops a
  /// later, unrelated hold from overwriting that basket's slot.
  void _onCartChanged() {
    if (cart.lines.isNotEmpty || _resumed == null) return;
    _resumed = null;
    notifyListeners();
  }

  @override
  void dispose() {
    cart.removeListener(_onCartChanged);
    super.dispose();
  }

  List<HeldOrder> _orders = const [];

  /// The held basket the cart on screen is a resumed copy of, if it is one. Holding the cart again
  /// updates this slot instead of adding a second basket with a re-typed name.
  HeldOrder? _resumed;

  /// The name of the resumed basket, or null when the cart is a fresh one.
  String? get resumedLabel => _resumed?.label;

  /// The baskets of this outlet that are waiting, latest first. Not the one on the till: it is
  /// already resumed, and listing it would let a tap reload its stale pre-edit snapshot over
  /// whatever has changed since.
  List<HeldOrder> get waiting => [
    for (final o in _orders)
      if (o.id != _resumed?.id) o,
  ];

  /// How many are waiting: the number the till shows beside "Held".
  int get count => waiting.length;

  /// Reads the queue again. A store that cannot be read has nothing in it (the port's contract).
  Future<void> refresh() async {
    _orders = await listHeldOrders(store, outletId);
    notifyListeners();
  }

  /// Parks what is on the till under [label], or under the time when there is none.
  ///
  /// The till is cleared only once the basket is **known to be stored**. The store swallows a
  /// failed write (a parked basket must never interrupt a sale), so a write that did not happen
  /// looks exactly like one that did, and clearing the cart on faith would lose the customer's
  /// goods. Reading it back costs one read, and a basket that is not there stays where it is.
  Future<HoldOutcome> hold({String label = ''}) async {
    if (cart.lines.isEmpty) return HoldOutcome.nothingToHold;
    // A resumed basket keeps the name it was given: holding it again must not ask twice.
    final named = label.trim();
    final name = named.isNotEmpty ? named : (_resumed?.label ?? _timeLabel());
    if (!await _saveCurrent(name)) return HoldOutcome.notStored;
    cart.clear();
    detail.reset();
    await refresh();
    await _analytics.logEvent('basket_held');
    return HoldOutcome.held;
  }

  /// Writes what is on the till to the queue, and says whether it is there afterwards.
  ///
  /// A resumed basket updates its own slot; a fresh one, or one whose slot vanished from under it
  /// (dropped elsewhere while it was open), becomes a new entry.
  Future<bool> _saveCurrent(String name) async {
    final draft = _draft(name);
    final resumed = _resumed;
    final saved =
        (resumed == null
            ? null
            : await updateHeldOrder(store, resumed.id, draft, now: now())) ??
        await holdOrder(store, draft, now: now());
    return (await store.readAll()).any((o) => o.id == saved.id);
  }

  /// The time in the tablet's zone, which is what a cashier calls a basket when they have not
  /// named it: "the one I parked at half past twelve".
  String _timeLabel() =>
      formatDateTime(now().toIso8601String()).split(', ').last;

  HeldOrderDraft _draft(String label) {
    final d = detail.detail;
    return HeldOrderDraft(
      label: label,
      outletId: outletId,
      customerId: d.customerId.isEmpty ? null : d.customerId,
      customerMemo: _orNull(d.customerMemo),
      tableNumber: _orNull(d.tableNumber),
      queueNumber: _orNull(d.queueNumber),
      headerDiscount: 0,
      lines: cart.lines.toList(),
    );
  }

  /// Throws a basket away, from the list. Dropping the one on the till forgets the link and leaves
  /// the cart as it is: it is now a fresh basket.
  Future<void> drop(HeldOrder order) async {
    await dropHeldOrder(store, order.id);
    if (_resumed?.id == order.id) _resumed = null;
    await refresh();
    await _analytics.logEvent('basket_discarded');
  }

  /// The cart was paid for: a resumed basket is finally removed from the queue.
  Future<void> paid() async {
    final resumed = _resumed;
    if (resumed == null) return;
    _resumed = null;
    await dropHeldOrder(store, resumed.id);
    await refresh();
  }

  /// Puts [order] on the till.
  ///
  /// It stays in the queue: it is only removed once it is paid for.
  ///
  /// The basket already on the till is parked first, not discarded: resuming must never be the
  /// reason a cashier loses a sale they were halfway through. When it cannot be parked nothing is
  /// changed.
  Future<ResumeOutcome> resume(HeldOrder order) async {
    if (cart.lines.isNotEmpty &&
        !await _saveCurrent(_resumed?.label ?? _timeLabel())) {
      return ResumeOutcome.currentNotStored;
    }
    cart.replaceAll(order.lines);
    // Not awaited: the name is for the row, and the basket is usable without it.
    detail.restore(
      TransactionDetail(
        customerId: order.customerId ?? '',
        customerMemo: order.customerMemo ?? '',
        tableNumber: order.tableNumber ?? '',
        queueNumber: order.queueNumber ?? '',
      ),
    );
    _resumed = order;
    await refresh();
    await _analytics.logEvent('basket_resumed');
    return ResumeOutcome.resumed;
  }
}

String? _orNull(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}
