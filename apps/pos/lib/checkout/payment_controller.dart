/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/pos_tender.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pos/checkout/checkout_service.dart';

/// The payment screen's state: the rows the cashier is editing, and what happens when they
/// confirm.
///
/// There is no module to port: the screen's state and its confirm handler are one thing in a
/// page. It is a controller here for one reason that is not tidiness: the rules live in
/// `pn_pos` (`buildPOSTenders`, `tenderSummary`), and a controller is what lets those rules be
/// tested without a widget, and the screen be tested without money moving.
///
/// **It does not decide whether the sale was recorded.** That is [CheckoutService]'s answer, and
/// the three outcomes exist so the cashier is told which one happened. This only drives it.
class PaymentController extends ChangeNotifier {
  PaymentController({required this.grandTotal}) {
    // A payment starts pre-filled with the exact amount in cash: most sales are one method,
    // paid exactly, and typing the total again would be the commonest thing a cashier does.
    _tenders = [
      TenderDraft(
        id: _nextId(),
        method: POSTenderMethod.cash,
        amount: grandTotal,
      ),
    ];
  }

  final num grandTotal;

  late List<TenderDraft> _tenders;
  var _seq = 0;
  var _isPaying = false;

  /// The rows, in the order they are shown. A copy: the screen must not be able to change
  /// them without going through the methods here, which is where listeners are told.
  List<TenderDraft> get tenders => List.unmodifiable(_tenders);

  /// Whether the confirm button may be pressed. False while a sale is being sent, so a double
  /// tap cannot send two.
  bool get canConfirm => problem == null && !_isPaying;

  /// Why the payment cannot be confirmed yet, or null when it can.
  ///
  /// The screen shows this rather than only disabling the button: a button that refuses without
  /// saying why leaves the cashier to guess what is wrong with the money they are holding.
  TenderProblem? get problem => switch (buildPOSTenders(_tenders, grandTotal)) {
    TenderBuildFailed(:final problem) => problem,
    TenderBuildOk() => null,
  };

  TenderSummary get summary => tenderSummary(_tenders, grandTotal);

  bool get isPaying => _isPaying;

  void setAmount(String id, num amount) {
    _update(id, (t) => t.copyWith(amount: amount));
  }

  /// Changes the method of a row.
  ///
  /// A row that stops being cash is clamped to the bill and loses its reference: only the
  /// drawer gives change, so an amount above the bill on a transfer is an unallocated receipt
  /// this flow does not create, and a reference belongs to a transfer, not to cash.
  void setMethod(String id, POSTenderMethod method) {
    _update(
      id,
      (t) => t.copyWith(
        method: method,
        amount: isCashTender(method)
            ? t.amount
            : (t.amount > grandTotal ? grandTotal : t.amount),
        reference: isCashTender(method) ? null : t.reference,
      ),
    );
  }

  void setReference(String id, String? reference) {
    _update(id, (t) => t.copyWith(reference: reference));
  }

  /// Adds a row for whatever is still owed, so the commonest split (part cash, part transfer)
  /// is one tap away.
  void addRow() {
    _tenders = [
      ..._tenders,
      TenderDraft(
        id: _nextId(),
        method: POSTenderMethod.transfer,
        amount: summary.remaining,
      ),
    ];
    notifyListeners();
  }

  /// Removes a row. The last one stays: a payment with no rows has no field to type in, and no
  /// way back to one.
  void removeRow(String id) {
    if (_tenders.length < 2) return;
    _tenders = [..._tenders.where((t) => t.id != id)];
    notifyListeners();
  }

  /// Fills [id] with what is still owed after the other rows.
  ///
  /// The remainder, not the whole bill: filling the bill on a second row would leave the first
  /// cash row looking like change on a transfer.
  void fillExact(String id) {
    final row = _tenders.where((t) => t.id == id).firstOrNull;
    if (row == null) return;
    final others = _tenders.where((t) => t.id != id);
    num paid = 0;
    for (final t in others) {
      paid += t.amount.isFinite ? t.amount : 0;
    }
    final left = grandTotal - paid;
    setAmount(id, left > 0 ? left : 0);
  }

  /// The tenders to send, or the reason they cannot be sent.
  ///
  /// Handed straight to `buildPOSTenders`, so the button's rule and the payload's rule are one
  /// rule: the screen must not be able to confirm something the builder would refuse.
  TenderBuildResult buildTenders() => buildPOSTenders(_tenders, grandTotal);

  /// Sends the sale and reports what happened to it.
  ///
  /// [submit] is `CheckoutService.submit`, injected so a test can answer without a transport.
  /// [payload] is built by the caller because the basket, the shift and the date are the till's,
  /// not this screen's.
  ///
  /// Anything that is not a checkout outcome (a bug, a programming error) is **not** turned
  /// into one: it reaches the caller so it stays loud, and this only makes sure the screen is
  /// not left saying "Memproses…".
  Future<CheckoutOutcome> submit({
    required Future<CheckoutOutcome> Function(POSCheckoutDTO payload) submit,
    required POSCheckoutDTO payload,
  }) async {
    // The screen disables the button in this state. Reaching here means a caller skipped that,
    // and sending a basket that does not add up would take money for a sale the server refuses.
    if (buildTenders() case TenderBuildFailed()) {
      throw StateError('submit() called with tenders that do not add up');
    }
    if (_isPaying) {
      throw StateError('submit() called while a payment is already out');
    }

    _isPaying = true;
    notifyListeners();
    try {
      return await submit(payload);
    } finally {
      // Even when it throws: the cashier must not be left on a screen that says it is still
      // working on something that already failed.
      _isPaying = false;
      notifyListeners();
    }
  }

  void _update(String id, TenderDraft Function(TenderDraft) change) {
    final index = _tenders.indexWhere((t) => t.id == id);
    if (index < 0) return;
    final next = [..._tenders];
    next[index] = change(next[index]);
    _tenders = next;
    notifyListeners();
  }

  String _nextId() => 'tender_${++_seq}';
}
