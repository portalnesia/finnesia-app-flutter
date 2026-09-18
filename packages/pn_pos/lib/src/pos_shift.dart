/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'datetime.dart';
import 'js_compat.dart';

/// What the close-shift dialog has to show, and when it may submit.
///
/// Ported from `ShiftCloseState` in
/// `finnesia-monorepo/packages/shared/src/pos/pos-shift.ts`.
///
/// A record rather than a class: four fields, compared by value, never serialized.
/// `.claude/rules/patterns.md` §2a.2 — `freezed` would add a generated file for nothing.
typedef ShiftCloseState = ({
  num expectedCash,
  num countedCash,
  num variance,
  bool needsNote,
  bool canClose,
});

/// What the close-shift dialog has to show, and when it may submit.
///
/// The dialog used to ask for a counted figure and nothing else: no expected cash, no
/// running difference, and no note when the two disagreed. The server rejects a close with
/// an unexplained variance, so the cashier met that rule as a failed request after counting
/// the drawer instead of as a field in front of them.
///
/// The variance is shown exactly as it falls. Rounding or hiding a small difference is how
/// a till loses money quietly.
///
/// [isOverride] marks a close performed by someone other than the shift's holder, through
/// `pos.shift.override`. The server requires a reason for that even when the drawer matches
/// exactly — the note says why this cashier, and not the holder, decided the figures — so
/// the dialog must ask for one before the cashier counts, not after.
ShiftCloseState shiftCloseState({
  required num expectedCash,
  required num countedCash,
  required String notes,
  bool? isOverride,
}) {
  final safeExpected = _safe(expectedCash);
  final safeCounted = _safe(countedCash);
  final variance = _round2(safeCounted - safeExpected);
  final needsNote = variance != 0 || isOverride == true;
  return (
    expectedCash: safeExpected,
    countedCash: safeCounted,
    variance: variance,
    needsNote: needsNote,
    canClose: !needsNote || notes.trim().isNotEmpty,
  );
}

num _safe(num value) => value.isFinite ? value : 0;

/// Money compared at two decimals: the drawer is counted in rupiah, but expected cash is
/// a sum of numeric(18,4) columns, and a 0.0000001 float artefact must not be reported to
/// the cashier as a difference they have to explain.
num _round2(num value) {
  final rounded = jsRound(value * 100) / 100;
  // Rounding a tiny negative gives -0, which formats as "-Rp 0" and reads to a cashier
  // as a shortfall that isn't there. Dart has no `-0` for `num`, but `-0.0` is a real
  // `double` and `-0.0 == 0` is true, so the comparison catches it and returns integer 0.
  return rounded == 0 ? 0 : rounded;
}

/// Whether the open shift at this outlet predates today, and who opened it.
///
/// Ported from `OpenShiftNotice` in the same source file.
typedef OpenShiftNotice = ({
  /// The shift was opened on an earlier calendar day than the one the till is running in
  /// now — the exact "shift kemarin lupa ditutup" case the info screen exists for.
  bool stale,
  String openedAt,
  String? cashierName,
  String number,
});

/// Whether the open shift at this outlet predates today, and who opened it.
///
/// The till used to render straight into the cart whenever any shift was open, with no
/// indication of when it started or by whom — a shift left open overnight looked exactly
/// like a fresh one, so the cashier kept selling into yesterday's reconciliation.
///
/// "Today" is the calendar day in the tenant's timezone, not the UTC day: a shift opened at
/// 00:30 WIB is today in WIB even though its ISO timestamp still reads yesterday.
///
/// The source takes a `shift` object with an optional nested `cashier`. Dart has no
/// structural typing, so the two fields this function actually reads are named parameters
/// instead of a shape the caller has to conform to. Same reasoning as
/// `hasCashTender` in `pos_tender.dart`.
OpenShiftNotice openShiftNotice({
  required String number,
  required String? openedAt,
  String? cashierName,
  DateTime? now,
  String? timezone,
}) {
  final opened = openedAt ?? '';
  var stale = false;
  if (opened.isNotEmpty) {
    final at = DateTime.tryParse(opened);
    if (at != null) {
      // `tryParse` returning null is the port's `Number.isNaN(at.getTime())` check: an
      // unparsable timestamp must leave `stale` false rather than throw, because a
      // malformed row from an older API must not take the till down.
      stale = localToday(at, timezone).compareTo(
            localToday(now ?? DateTime.now(), timezone),
          ) <
          0;
    }
  }
  return (
    stale: stale,
    openedAt: opened,
    cashierName: cashierName,
    number: number,
  );
}
