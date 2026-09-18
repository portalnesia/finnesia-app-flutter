/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:math' show max;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pn_types/src/pos.dart';

part 'pos_tender.freezed.dart';

// The methods the till can record, in the order the panel shows them. QRIS here is a
// manual record of a payment confirmed outside the app; the gateway that confirms it
// automatically is feat_pos_qris and still unreleased. GIRO removed and EDC/KOMPLIMEN
// added 2026-09-09 — KOMPLIMEN is a free give-away, not money received, and settles
// into an expense account instead of cash/bank (see DefaultPOSTenderAccounts on the API).
const posTenderMethods = <POSTenderMethod>[
  POSTenderMethod.cash,
  POSTenderMethod.transfer,
  POSTenderMethod.edc,
  POSTenderMethod.qris,
  POSTenderMethod.komplimen,
];

bool isCashTender(POSTenderMethod method) => method == POSTenderMethod.cash;

/// Whether a **wire** method value names cash.
///
/// The source's `isCashTender` takes the enum, but its `hasCashTender` accepts
/// `{ method: POSTenderMethod }[]` structurally — which is how the shift report feeds it
/// `sales_by_method` keys and `NonCashTenderLine.method`, both plain strings that may
/// carry a `GIRO` the enum no longer knows (`pos.dart`). Dart has no structural typing, so
/// the split is explicit: this takes the string, and the enum-typed [isCashTender] stays
/// for the checkout flow where the method really is a known choice.
///
/// Compares against `POSTenderMethod.cash.wire` rather than a bare `'CASH'` literal so the
/// enum remains the single place that string is written down.
bool isCashMethod(String method) => method == POSTenderMethod.cash.wire;

/// A receipt's "cash tendered / change" line only makes sense when real cash actually
/// changed hands. sale.tendered_amount/change_amount are totals across every payment
/// method, so a pure KOMPLIMEN (or TRANSFER/EDC/QRIS-only) sale still carried a tendered
/// amount equal to the bill and a change of 0 — printing as if the customer had paid cash
/// for a free give-away.
///
/// Takes the wire values, not the enum: the report side holds strings that may include a
/// historical `GIRO`, and there is no enum constant to route it through. Answering from
/// the string itself means the method's name is never lost to a failed parse.
bool hasCashTender(Iterable<String>? methods) =>
    (methods ?? const <String>[]).any(isCashMethod);

/// A payment row the cashier is still editing.
@freezed
abstract class TenderDraft with _$TenderDraft {
  const factory TenderDraft({
    required String id,
    required POSTenderMethod method,
    required num amount,
    String? reference,
  }) = _TenderDraft;
}

enum TenderProblem {
  insufficient,
  overpaidNonCash,
  emptyCart,
}

@freezed
abstract class TenderSummary with _$TenderSummary {
  const factory TenderSummary({
    required num paid,
    required num remaining,
    required num change,
  }) = _TenderSummary;
}

TenderSummary tenderSummary(List<TenderDraft> tenders, num grandTotal) {
  num paid = 0;
  for (final t in tenders) {
    paid += t.amount.isFinite ? t.amount : 0;
  }
  return TenderSummary(
    paid: paid,
    remaining: max(0, grandTotal - paid),
    change: max(0, paid - grandTotal),
  );
}

/// Either the payload the API takes, or the reason it cannot be built.
///
/// A `sealed class`, not two nullable fields. The TypeScript source is a discriminated
/// union `{ tenders } | { problem }`; translating that into two nullable fields would
/// let a caller write `result.tenders!` on the failure branch and crash on the money
/// path. The compiler now forces both branches to be handled, and there is no `!`.
///
/// `.claude/rules/patterns.md` §2a.3.
@freezed
sealed class TenderBuildResult with _$TenderBuildResult {
  const factory TenderBuildResult.ok(List<POSTenderDTO> tenders) =
      TenderBuildOk;
  const factory TenderBuildResult.failed(TenderProblem problem) =
      TenderBuildFailed;
}

/// Turns the payment rows into the payload the API takes, or names why it cannot.
///
/// Same rules the service enforces, so the button disables instead of the cashier
/// discovering the rejection after pressing it:
///   - the tenders together have to cover the bill
///   - change is only ever handed back from the drawer, so the overpayment must be
///     covered by the cash rows; a transfer above the bill is an unallocated receipt
///     this flow does not create
///
/// The account each tender lands in is deliberately absent: it comes from the POS
/// preferences, set once by whoever keeps the books. A cashier cannot be expected to pick
/// a chart-of-accounts entry, and a wrong one is a bookkeeping error nobody notices until
/// reconciliation.
TenderBuildResult buildPOSTenders(List<TenderDraft> tenders, num grandTotal) {
  if (grandTotal <= 0)
    return const TenderBuildResult.failed(TenderProblem.emptyCart);

  // A row the cashier added but left at zero is not a payment; the server rejects
  // amount <= 0 outright.
  final filled =
      tenders.where((t) => t.amount.isFinite && t.amount > 0).toList();
  final summary = tenderSummary(filled, grandTotal);
  if (summary.paid < grandTotal) {
    return const TenderBuildResult.failed(TenderProblem.insufficient);
  }

  num cashPaid = 0;
  for (final t in filled) {
    if (isCashTender(t.method)) cashPaid += t.amount;
  }
  if (summary.change > cashPaid) {
    return const TenderBuildResult.failed(TenderProblem.overpaidNonCash);
  }

  return TenderBuildResult.ok([
    for (final t in filled)
      POSTenderDTO(
        method: t.method,
        amount: t.amount,
        // `trim() || undefined` in the source: a whitespace-only reference is absent,
        // not an empty string.
        reference: _normalizeReference(t.reference),
      ),
  ]);
}

/// Trims a reference, or drops it when there is nothing left.
///
/// Written without `!` on purpose: `.claude/rules/security.md` §2 forbids null
/// assertions on the money path, and "the reference is null" is a normal state here.
String? _normalizeReference(String? reference) {
  final trimmed = reference?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

/// Change is only ever handed back from the drawer.
num tenderChange(List<TenderDraft> tenders, num grandTotal) =>
    tenderSummary(tenders, grandTotal).change;

/// Shared by the outlet-level override form and the company-wide POS settings page —
/// both store one COA id per non-cash tender method and need identical set/clear
/// behavior: an empty accountId clears the override back to "use company default"
/// rather than storing an empty string.
Map<String, String> setTenderMethodAccount(
  Map<String, String>? current,
  POSTenderMethod method,
  String accountId,
) {
  final next = {...?current};
  if (accountId.isNotEmpty) {
    next[method.wire] = accountId;
  } else {
    next.remove(method.wire);
  }
  return next;
}
