/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// The JavaScript semantics Dart does not have, in one place.
///
/// Every function here exists because a faithful port of `finnesia-monorepo` needs a
/// behaviour that Dart either lacks or spells differently. They live together because the
/// reason they exist is the same reason, and because three separate copies of the same
/// three-line helper is exactly the duplication `.claude/rules/patterns.md` §2.1 forbids.
///
/// **Extracted when [firstNonEmpty] reached its third caller** — `pos_receipt.dart`,
/// `pos_print_category.dart`, then `pos_escpos_format.dart`. That is the point both earlier
/// ports named in their own comments as "extract it then", so the threshold was met rather
/// than moved. [jsRound] came with it: `pos_shift.dart` and `escpos.dart` held
/// byte-identical copies, and leaving them behind would leave a module named "JS compat"
/// that omits the helper with the highest stakes attached to it.
library;

/// `Math.round(x)` from JavaScript: rounds **half toward positive infinity**.
///
/// Not `num.round()`. Dart's `round()` rounds half **away from zero**, so the two disagree
/// on every negative half:
///
/// | Value | `Math.round` (JS) | `.round()` (Dart) |
/// | ----- | ----------------- | ----------------- |
/// | -0.5  | -0                | -1                |
/// | -1.5  | -1                | -2                |
/// | -2.5  | -2                | -3                |
///
/// Reachable on the money path rather than theoretical: `pos_shift.dart` rounds a cash
/// variance to two decimals, where `-0.015` is `-0.01` in JavaScript — and on the web app
/// the cashier is comparing against — but `-0.02` under Dart's `round()`.
///
/// `floor(x + 0.5)` is the standard equivalent. Verified by differentially running both
/// implementations over boundary values, float dust, and negatives: every result matched.
int jsRound(num x) => (x + 0.5).floor();

/// `String(n)` for a JavaScript Number.
///
/// Needed because Dart has **two** numeric types where JavaScript has one, and a Dart
/// `double` keeps a trailing `.0` that JavaScript drops:
///
/// | Value | `String(n)` (JS)      | Dart `toString()`          |
/// | ----- | --------------------- | -------------------------- |
/// | `2`   | `2`                   | `2` (int), **`2.0`** (double) |
/// | `-0`  | `0`                   | **`-0.0`**                 |
/// | `1e20`| `100000000000000000000` | **`100000000000000000000.0`** |
///
/// This is reachable, not defensive: the quantities a ticket prints come from a
/// `numeric(18,4)` column, and `jsonDecode` hands Dart a `double` for a wire value of
/// `2.0` where TypeScript would have had a plain `number`. Printing `2.0 x Rp 10.000` on a
/// customer receipt where the web app prints `2 x Rp 10.000` is the entire failure mode.
///
/// ## Why this strips the suffix instead of going through `toInt()`
///
/// `toInt()` was the first attempt and it was **wrong**: it saturates at 64 bits, so
/// `(1e20).toInt()` returns `9223372036854775807` — a receipt printing a wildly different
/// number, on the money path. Stripping the `.0` leaves the digits exactly as Dart's own
/// shortest-round-trip formatter produced them, which was verified to agree with
/// JavaScript's `String(n)` on every value probed: `0.1`, `1/3`, `1e-7`, `1e21`, `1e22`,
/// `123456789012345680000`, NaN, and both infinities. Above 1e21 Dart already switches to
/// the same exponential spelling (`1e+21`), so there is no suffix to strip there.
///
/// ## The one thing this cannot fix
///
/// A Dart `int` beyond 2^53 prints exactly while the equivalent JavaScript literal has
/// already lost precision, so the two disagree — because the *values* differ, not the
/// formatting. Unreachable for a quantity or a rupiah amount.
String jsNumber(num value) {
  if (value is int) return value.toString();
  if (value.isNaN) return 'NaN';
  if (value.isInfinite) return value.isNegative ? '-Infinity' : 'Infinity';
  // Covers -0.0, which JavaScript prints as '0' — and `-0.0 == 0` is true, so the check
  // catches both signs without inspecting the sign bit.
  if (value == 0) return '0';
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

/// The first value JavaScript would consider truthy, ignoring `null`.
///
/// Mirrors `a || b || c` for strings: skips `null` **and** the empty string. That second
/// part is the whole reason this exists — Dart's `??` only skips `null`, so a literal port
/// lets `''` win and prints a blank line where the web app prints the fallback.
///
/// Deliberately does **not** trim. `'   '` is truthy in JavaScript and passes through
/// unchanged, and that asymmetry is preserved rather than tidied: trimming here would be a
/// behaviour change the oracle does not sanction (`.claude/rules/cross-repo.md` §4).
///
/// Returns `''` when nothing qualifies, which is what the source's chain evaluates to.
String firstNonEmpty(List<String?> candidates) {
  for (final value in candidates) {
    if (value != null && value.isNotEmpty) return value;
  }
  return '';
}

/// `value || undefined` for one string: `null` and `''` are absent, anything else is kept.
///
/// The single-value form of [firstNonEmpty], for the place the source writes
/// `if (x) payload.x = x` rather than a chain. The difference from `??` is the whole point:
/// `customer_id: ''` is a customer that does not exist, and the server refuses the checkout
/// **after** the cashier has taken the money (`pos_checkout.dart` says so at the field that
/// first needed this).
///
/// Does not trim, for the reason [firstNonEmpty] gives: `'   '` is truthy in JavaScript.
///
/// Extracted here when the pending-sale payload builder became its second caller — the
/// threshold `.claude/rules/patterns.md` §2.1 sets, and the same one [firstNonEmpty] was
/// extracted on.
String? orAbsent(String? value) =>
    value == null || value.isEmpty ? null : value;
