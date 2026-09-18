/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

// ignore_for_file: invalid_annotation_target (freezed reads json_serializable's options from the factory constructor, which is the pattern its docs prescribe)

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pn_types/src/pos.dart';

import 'js_compat.dart';
import 'pos_calculations.dart';
import 'pos_cart.dart';
import 'pos_checkout.dart';

part 'pos_pending_sale.freezed.dart';
part 'pos_pending_sale.g.dart';

/// Where a queued sale stands.
///
/// Ported from `PendingSaleStatus` in
/// `finnesia-monorepo/apps/web/src/lib/pos-offline-queue.ts`.
///
/// An enum with a wire value rather than a plain string, for the reason `POSTenderMethod`
/// gives: the value is stored in a `TEXT` column and filtered on by a query, so a rename of
/// the Dart case must not silently change what the database holds. [tryParse] answers `null`
/// for a value it does not know — deliberately **not** a default, because a row whose status
/// is unreadable is a row this app cannot act on, and the queue's contract is to throw rather
/// than to treat it as pending (`plan/offline-queue/README.md` §4.1).
enum PendingSaleStatus {
  /// Not known to be recorded on the server. The drain loop sends these, in order.
  pending('pending'),

  /// The server understood the request and refused it. Replaying it verbatim can only fail
  /// again, so it waits for the cashier to retry or discard it.
  failed('failed');

  const PendingSaleStatus(this.wire);

  /// The exact string the database holds.
  final String wire;

  /// Returns `null` for a value this build does not know.
  static PendingSaleStatus? tryParse(String wire) {
    for (final s in PendingSaleStatus.values) {
      if (s.wire == wire) return s;
    }
    return null;
  }
}

/// One payment as the temporary receipt prints it.
///
/// **Not a type of its own.** `payload.payments` already holds the same list in the shape the
/// receipt formatter reads (`method`, `amount`), so the receipt carries no second copy: two
/// copies can disagree about how much money changed hands.
///
/// ## What the receipt holds that the payload does not
///
/// The payload is what the server is asked to record. The printed proof also needs the outlet's
/// and the cashier's **names** and the goods' **names**, none of which is a checkout field. See
/// `plan/offline-queue/README.md` §4.2.
///
/// The goods are [SalesInvoiceItem] — the wire type `pn_types` already owns, and the one
/// `apps/pos/lib/sale/invoice_item.dart` already maps into what the formatter reads. So the
/// printed bytes for a queued sale come from the same code path as for a recorded one, rather
/// than from a second receipt builder that would drift from it.
@freezed
abstract class PendingSaleReceipt with _$PendingSaleReceipt {
  @JsonSerializable(explicitToJson: true)
  const factory PendingSaleReceipt({
    /// Null when the outlet's name was not known at the till. Printed only when present,
    /// matching `formatReceiptEscPos`.
    String? outletName,
    String? cashierName,
    required num subtotal,
    required num discountAmount,
    required num taxAmount,
    required num grandTotal,
    required num tenderedAmount,
    required num changeAmount,
    required List<SalesInvoiceItem> items,
  }) = _PendingSaleReceipt;

  factory PendingSaleReceipt.fromJson(Map<String, dynamic> json) =>
      _$PendingSaleReceiptFromJson(json);
}

/// A sale the till has taken money for and the server has not confirmed.
///
/// Ported from `PendingSale` in `finnesia-monorepo/apps/web/src/lib/pos-offline-queue.ts`,
/// with the storage reshaped: the web app keeps one JSON blob per company in
/// `localStorage`, and this keeps one row per sale in SQLite
/// (`plan/offline-queue/README.md` §4.2). The fields are the same ones, plus the ones the
/// web app had no room for.
///
/// ## What is **not** in [payload]
///
/// [clientRef], [paidAt] and [shiftId] live in their own columns and are stamped onto the
/// payload only on the way out ([toCheckoutPayload]). Writing them twice would mean two
/// values that can disagree, and the one the server dedupes on is the one that must not.
///
/// ## Why `freezed` and `json_serializable`
///
/// All three questions `.claude/rules/patterns.md` §2a.5 asks: it is **compared** (a test
/// asserts a retry changed one field), **copied** (`copyWith` on mark-failed and retry), and
/// **serialized** (the store keeps it as JSON text). Hand-writing that is what §2a forbids.
@freezed
abstract class PendingSale with _$PendingSale {
  // `explicitToJson`: without it `payload` and `receipt` stay objects, and `jsonEncode` — which
  // is what the store does with this — would fail on them.
  @JsonSerializable(explicitToJson: true)
  const factory PendingSale({
    /// The idempotency key. The server looks a sale up by `(company, client_ref)` before
    /// creating one, which is what makes a retry safe. Unique in the database, not just in
    /// this list.
    required String clientRef,

    /// The tenant. Carried per row rather than taken from the session at send time: the
    /// queue outlives a sign-out, and a device re-paired to another tenant must not post the
    /// previous one's sales.
    required String companyId,
    required String outletId,

    /// **Who typed it**, not who sends it. The server attributes the sale to whoever is
    /// authenticated at send time and does not accept this field, so it is the only record
    /// of the cashier who actually took the money (`plan/offline-queue/findings.md` F4).
    required String cashierId,

    /// The shift the sale was rung up under, or null when the company runs without shifts.
    String? shiftId,
    required PendingSaleStatus status,

    /// The server's own sentence when it refused, so the panel can show what to fix.
    String? error,

    /// The tablet's clock when the money was taken, RFC 3339. Sent on retries only: the
    /// first attempt leaves it to the server, because a tablet clock more than five minutes
    /// ahead is refused outright (`findings.md` F2, README D-Q5).
    required String paidAt,

    /// When the entry was written, RFC 3339.
    required String createdAt,

    /// How many times a send has failed without a definite answer. Shown in the panel so a
    /// sale that keeps failing is visible rather than silently retrying forever.
    @Default(0) int attempts,

    /// The checkout payload, without the three fields above. See the class doc.
    required POSCheckoutDTO payload,

    /// What the temporary receipt prints. See [PendingSaleReceipt].
    required PendingSaleReceipt receipt,
  }) = _PendingSale;

  factory PendingSale.fromJson(Map<String, dynamic> json) =>
      _$PendingSaleFromJson(json);
}

/// The checkout payload to post for [sale].
///
/// Ported from `toCheckoutPayload` in
/// `finnesia-monorepo/apps/web/src/hooks/use-pos-sync.ts`.
///
/// The payload is built by **replacing** the three fields that live in columns rather than by
/// merging them in, so the row's own values are always the ones that go out. `client_ref` and
/// `paid_at` are what the server dedupes on; a stale copy inside the stored JSON would be a
/// second source of truth for the one value that must not be wrong.
///
/// ## `shift_id`
///
/// Sent **only when it is the shift that is open now**. A sale rung up against a shift that
/// has since closed cannot be posted to it — the server refuses to write into a closed
/// financial period — so dropping the id lets `resolveCheckoutShift` attach the sale to the
/// shift that is open now, opening one if the company runs without shifts. Keeping a stale id
/// is what used to fail these syncs permanently (`findings.md` F3).
///
/// ## Why the optional strings go through [orAbsent]
///
/// The source writes `if (sale.customer_id) payload.customer_id = ...`, and JavaScript treats
/// `''` as falsy (`.claude/rules/patterns.md` §1.1). The DTO writes a `''` as `''`, and
/// `customer_id: ''` is a customer that does not exist — the checkout is refused **after** the
/// money has been taken. `buildCheckoutPayload` closes that door on the way in; this closes it
/// on the way out, for an entry written by an older build.
///
/// `discount_amount` is **not** passed through it: the source checks `!== undefined`, so a
/// zero discount is a stated discount and is sent. The two checks differ on purpose.
POSCheckoutDTO toCheckoutPayload(PendingSale sale, {String? openShiftId}) {
  final payload = sale.payload;
  final shiftId = sale.shiftId;
  return payload.copyWith(
    clientRef: sale.clientRef,
    paidAt: sale.paidAt,
    shiftId: shiftId != null && shiftId == openShiftId ? shiftId : null,
    customerId: orAbsent(payload.customerId),
    tableNumber: orAbsent(payload.tableNumber),
    queueNumber: orAbsent(payload.queueNumber),
    notes: orAbsent(payload.notes),
  );
}

/// Whether a failed send is **final**: the server understood the request and refused it.
///
/// Ported from `isFinalError` in `use-pos-sync.ts`.
///
/// A 4xx is validation, stock or a closed period: replaying it verbatim can only fail again,
/// so the sale is parked as `failed` for the cashier to retry or discard. Anything else — no
/// answer, a 5xx, or a 2xx this app could not read — may have been recorded, so the sale stays
/// `pending` and the next pass tries again.
///
/// A status rather than an `ApiError` because the caller in `apps/pos` translates its own
/// failure types into one number, and because the rule is about the number: a 4xx means the
/// same thing whichever endpoint answered.
bool isFinalError(int status) => status >= 400 && status < 500;

/// Builds the queue entry for a sale the till has just taken money for.
///
/// Step 1 of `plan/offline-queue/README.md` §3: the till confirms payment, and **before**
/// anything is sent the sale is written down. The web app has no equivalent — it keeps a sale
/// only after a send failed, which loses one when the app dies mid-request.
///
/// ## Why this is one function rather than two (payload + receipt)
///
/// The payload is what the server is asked to record; the receipt is what the customer is
/// handed. They are built from **the same** lines and the same payments in the same call,
/// because building them apart is how the printed slip and the recorded sale start to disagree
/// about what was sold.
///
/// ## What it deliberately does not do
///
/// It does not write anything and it does not send anything: the store's `enqueue` and the
/// transport are the caller's. It also does not choose `clientRef` — the ref is
/// `CheckoutService`'s, because only it knows whether this basket has already been sent under
/// one.
///
/// [now] is injected rather than read from the clock: it becomes `paid_at`, which the server
/// validates against its own clock (`findings.md` F2), so a test that used the wall clock would
/// produce a different sale every time it ran.
///
/// The four optional strings are **nullable**, matching `TransactionDetail` at the till, and an
/// empty or absent one is left out of the payload by `buildCheckoutPayload`: `customer_id: ''`
/// is a customer that does not exist, and the checkout is refused **after** the money has been
/// taken (`pos_checkout.dart`).
PendingSale buildPendingSale({
  required String clientRef,
  required String companyId,
  required String outletId,
  required String cashierId,
  required String? shiftId,
  required String transactionDate,
  required List<CartLine> lines,
  required List<POSTenderDTO> payments,
  required num discountAmount,
  String? customerId,
  String? notes,
  String? tableNumber,
  String? queueNumber,
  String? outletName,
  String? cashierName,
  DateTime? now,
}) {
  final at = (now ?? DateTime.now()).toUtc().toIso8601String();
  final totals = totalsOfLines(lines);
  final tendered = _tendered(payments);
  // The bill discount comes off the total, exactly as the server computes it
  // (`pos_service.go:1395`: `grandTotal = subtotal + tax - discount_amount`). The receipt has to
  // show the figure the customer will be charged, and the goods the cashier is handing over, so
  // both come from the same maths rather than from a second formula that could drift.
  final grandTotal = clampHeaderDiscount(discountAmount, totals.grandTotal);
  final billDiscount = grandTotal;
  final payable = totals.grandTotal - billDiscount;
  final amounts = [
    for (final line in lines)
      calcLineAmounts(
        CartMathLine(
          quantity: line.qty,
          price: line.product.sellPrice ?? 0,
          discountPercent: line.discountPercent,
          discountAmount: line.discountAmount,
        ),
      ),
  ];

  return PendingSale(
    clientRef: clientRef,
    companyId: companyId,
    outletId: outletId,
    cashierId: cashierId,
    shiftId: shiftId,
    status: PendingSaleStatus.pending,
    paidAt: at,
    createdAt: at,
    // `shiftId` is passed to `buildCheckoutPayload` as null on purpose: it lives in its own
    // column, and `toCheckoutPayload` stamps the column's value onto the payload on the way
    // out. Two copies could disagree about the shift the sale landed in.
    payload: buildCheckoutPayload(
      shiftId: null,
      outletId: outletId,
      customerId: customerId ?? '',
      notes: notes ?? '',
      tableNumber: tableNumber ?? '',
      queueNumber: queueNumber ?? '',
      discountAmount: discountAmount,
      transactionDate: transactionDate,
      lines: lines,
      payments: payments,
    ),
    receipt: PendingSaleReceipt(
      outletName: outletName,
      cashierName: cashierName,
      // The sum of the **net** line subtotals, not the gross before the line discounts: that is
      // what the server writes into `sale.subtotal` (`pos_service.go:1318-1321`), and a printed
      // receipt whose rows do not add up to its own subtotal is one a customer will argue with.
      subtotal: amounts.fold<num>(0, (sum, a) => sum + a.lineSubtotal),
      // The bill discount only. A line's own discount is already inside its net subtotal, so
      // putting it here too would take it off twice.
      discountAmount: billDiscount,
      taxAmount: amounts.fold<num>(0, (sum, a) => sum + a.lineTax),
      grandTotal: payable,
      // Across every payment, not the cash row: a split bill's change is still the drawer's.
      tenderedAmount: tendered,
      changeAmount: calcChange(tendered, payable),
      // The goods, with their names. A sale that has not been sent has no server record to
      // print from, so this copy is the only proof the customer gets (README D-Q3).
      items: [
        for (final (index, line) in lines.indexed)
          SalesInvoiceItem(
            // A line id is unique within one cart and never leaves the device
            // (`pos_cart.dart`), which is all a receipt row needs.
            id: line.id,
            quantity: line.qty,
            price: line.product.sellPrice ?? 0,
            lineSubtotal: amounts[index].lineSubtotal,
            lineTotal: amounts[index].lineTotal,
            description: null,
            product: NamedRef(id: line.product.id, name: line.product.name),
          ),
      ],
    ),
  );
}

/// What the customer handed over, across every payment.
num _tendered(List<POSTenderDTO> payments) {
  num total = 0;
  for (final payment in payments) {
    total += payment.amount.isFinite ? payment.amount : 0;
  }
  return total;
}
