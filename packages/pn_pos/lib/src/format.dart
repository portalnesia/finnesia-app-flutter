/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// IDR formatting for the till, receipts, and reports.
///
/// Ported from `finnesia-monorepo/packages/shared/src/utils/format.ts`.
///
/// The source formats with `toLocaleString('id-ID')`; this uses
/// `NumberFormat.decimalPattern('id_ID')`. The two were compared value by value — thousands
/// separators, the decimal comma, the default three fraction digits
/// (`0.30000000000000004` renders as `0,3` in both), NaN, Infinity, and negative zero — and
/// agree on all of it.
///
/// The one place they diverge is magnitude: above roughly 9.2 quintillion, `intl` saturates
/// at the 64-bit integer limit while JavaScript keeps going. That is nine quintillion
/// rupiah, so it is not a case a till can reach; it is noted rather than worked around.
library;

import 'package:intl/intl.dart';

NumberFormat? _decimal;

/// Loads the `id_ID` number symbols.
///
/// **Must be called once before either formatter.** Same reason as
/// [initializePosDateTime] in `datetime.dart`: `Intl` and its locale data are part of the
/// JavaScript runtime, and in Dart they are a package that has to be asked for. Idempotent.
///
/// Kept separate from `initializePosDateTime` because this needs no timezone database —
/// pulling in the IANA zones to format a price would be work for nothing.
void initializePosNumberFormat() {
  _decimal ??= NumberFormat.decimalPattern('id_ID');
}

NumberFormat get _formatter {
  final f = _decimal;
  if (f == null) {
    throw StateError(
      'initializePosNumberFormat() must be called before formatting money. '
      'Call it during app startup, or in setUpAll for tests.',
    );
  }
  return f;
}

/// Formats a number as an IDR amount. Null renders as a dash.
///
/// Faithful to the source's guard, which is only `value === null || value === undefined`.
/// NaN therefore falls through and renders as the literal `Rp NaN`, and `-0` renders as
/// `Rp -0` — both verified to be the source's behaviour, not artefacts of this port.
///
/// A price or quantity that reaches NaN is a bug upstream (the cart maths clamps for that
/// reason), so showing it plainly beats hiding it behind a dash. Fixing the *rendering*
/// would mean fixing it in the source first — `.claude/rules/cross-repo.md` §4.
String formatCurrency(num? value) {
  if (value == null) return '-';
  return 'Rp ${_formatter.format(value)}';
}

/// Signed currency — used for report balances that can be negative.
///
/// The sign comes from `value < 0`, and the magnitude from `value.abs()`, exactly as in the
/// source. That combination is what makes `formatSigned(-0)` render `Rp 0` rather than
/// `-Rp 0`: `-0 < 0` is false, so there is no sign, and `abs` never introduces one.
///
/// Note the deliberate asymmetry with [formatCurrency], which has no sign logic and so
/// renders `-0` as `Rp -0`. Both were read off the running source rather than inferred.
String formatSigned(num? value) {
  if (value == null) return '-';
  final sign = value < 0 ? '-' : '';
  return '${sign}Rp ${_formatter.format(value.abs())}';
}
