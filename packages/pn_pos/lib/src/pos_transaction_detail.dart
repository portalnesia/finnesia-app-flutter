/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pos_transaction_detail.freezed.dart';

/// Everything about the sale that is not a line item: who it is for, and what the kitchen or
/// the floor needs to know about it.
///
/// Four plain strings and one nullable name. **Not** a nullable
/// pair, and **not** an enum: `''` is the source's "nothing here", and the reason it is a
/// string rather than `null` is that the cashier types into these fields one character at a
/// time.
///
/// `freezed` for the three questions `.claude/rules/patterns.md` §2a.5 asks. It is **copied**
/// on every keystroke (`copyWith`), **compared** (a test asserts a detail that changed one
/// field is a different detail, which is how the screen knows to rebuild), and the empty value
/// is a default rather than a hand-written constant. It is **not** serialized: nothing here
/// reaches the wire, because `buildCheckoutPayload` takes the four strings and owns the rule
/// about which of them may be sent (`pn_pos/src/pos_checkout.dart`).
@freezed
abstract class TransactionDetail with _$TransactionDetail {
  const factory TransactionDetail({
    /// The picked customer, or `''` for none. The source's `customerId: ''`.
    @Default('') String customerId,

    /// The name behind [customerId], carried along so the cart's summary row can name the
    /// customer without a second lookup.
    ///
    /// Null and `''` are not the same answer, and the source says why: a row that stayed silent
    /// for an id it holds would read "no detail yet" for a sale that has a customer on it. The
    /// till never attaches an id without a name today (see [shownCustomerName]), so null is what
    /// this carries in practice; the distinction is kept because it is the source's, and because
    /// the held-basket path in C7 is what will produce the other one.
    String? customerName,

    /// The free note that prints on the receipt, not the customer's own record.
    @Default('') String customerMemo,

    /// Only shown when the outlet asks for it (`POSPreferences.showTableNumber`).
    @Default('') String tableNumber,

    /// Only shown when the outlet asks for it (`POSPreferences.showQueueNumber`).
    @Default('') String queueNumber,
  }) = _TransactionDetail;

  const TransactionDetail._();

  /// Nothing filled in. What a fresh transaction starts from, and what `resetCart` writes back.
  static const empty = TransactionDetail();

  /// What the summary row shows for the customer, or null when no customer is attached.
  ///
  /// An empty string is a customer whose name is not known yet, and it is deliberately **not**
  /// the same as null. Nothing in the till produces that today: the picker always sends the name
  /// it has, and the one path that carries an id without one (a basket resumed from the held
  /// list, where the source resolves the name back from the picker's own list) belongs to C7,
  /// which is blocked by G2. The rule is kept rather than collapsed to `customerName`, because
  /// collapsing it is exactly the change C7 would have to undo.
  String? get shownCustomerName =>
      customerId.isEmpty ? null : (customerName ?? '');

  /// The table number to show, or null when there is none.
  ///
  /// **Not trimmed, matching the source.** `detail.tableNumber &&` in JavaScript is true for a
  /// string of spaces, so the source shows them. Trimming belongs to `buildCheckoutPayload`,
  /// which answers a different question (what the server is sent) and trims there.
  String? get shownTableNumber => tableNumber.isEmpty ? null : tableNumber;

  /// The queue number to show, or null when there is none. Not trimmed, as
  /// [shownTableNumber].
  String? get shownQueueNumber => queueNumber.isEmpty ? null : queueNumber;

  /// The note to show, or null when there is none. Not trimmed, as [shownTableNumber].
  String? get shownMemo => customerMemo.isEmpty ? null : customerMemo;

  /// Whether the summary row has anything to say. When it does not, the row offers to add a
  /// detail instead of showing one.
  bool get hasAnything =>
      customerId.isNotEmpty ||
      tableNumber.isNotEmpty ||
      queueNumber.isNotEmpty ||
      customerMemo.isNotEmpty;

  /// What the summary row prints for the customer and for the note, after the owner's rule
  /// about where the note goes (2026-09-21).
  ///
  /// The note is folded into the customer's parentheses for the company's **default** customer,
  /// and stands on its own row for any other. The default is a shared walk-in record ("UMUM"),
  /// so the note is what tells one of its sales from another; a customer the cashier picked by
  /// name is already identified by that name, and hanging the note off it reads as part of the
  /// name.
  ///
  /// Either way the note is printed **once**: folded, or on its own, never both and never
  /// neither. It is folded only when there is a name to fold it into, because folding it into
  /// nothing would drop it.
  ///
  /// **`''` is not a name.** An id whose name is not known yet ([shownCustomerName] is `''`)
  /// must not fold, or the row would read `" (meja 4)"` as if the note were the customer. The
  /// source's own guard is `detail.customerName &&`, and `''` is falsy in JavaScript
  /// (`.claude/rules/patterns.md` §1.1).
  ///
  /// Nothing here is trimmed, matching [shownMemo] and the source's `detail.notes &&`.
  ({String? customer, String? memo}) summaryTexts({
    required bool isDefaultCustomer,
  }) {
    final name = shownCustomerName;
    final memo = shownMemo;
    final foldable = name != null && name.isNotEmpty;
    if (isDefaultCustomer && foldable && memo != null) {
      return (customer: '$name ($memo)', memo: null);
    }
    return (customer: name, memo: memo);
  }

  /// Picks [id] as the customer, with the [name] the picker knows.
  ///
  /// [name] is null when the id is not in the list the picker holds, and the name is then
  /// cleared rather than kept: the source clears it for the same reason, so a stale name can
  /// never sit next to a different customer's id.
  TransactionDetail withCustomer({required String id, required String? name}) =>
      copyWith(customerId: id, customerName: name);
}
