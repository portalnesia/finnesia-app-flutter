/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:math' show max, min;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pn_types/src/product.dart';

part 'pos_cart.freezed.dart';

/// One row of the cart the cashier is building.
///
/// Ported from `CartLine` in `finnesia-monorepo/packages/shared/src/pos/pos-cart.ts`.
///
/// The source has **two different types called `CartLine`** — `pos-calculations.ts`
/// exports one with no `id` and no product, this file's is the cart row. TypeScript keeps
/// them apart by module; Dart has a single namespace, so only one can keep the name. The
/// cart row keeps it because it is a real entity the whole flow passes around, while the
/// maths line is a transient argument; the maths side is named `CartMathLine`.
///
/// `freezed` rather than a hand-written class: every mutator below is a spread with one
/// field changed (`{ ...l, qty: l.qty + 1 }`), which is exactly `copyWith`.
/// `.claude/rules/patterns.md` §2a.2.
@freezed
abstract class CartLine with _$CartLine {
  const factory CartLine({
    required String id,
    required Product product,
    required num qty,

    /// A line carries a percentage **or** a flat amount, never both. See [CartDiscount].
    num? discountPercent,
    num? discountAmount,
  }) = _CartLine;
}

/// Line ids only have to be unique within one cart, and the cart never leaves the device.
/// A counter does that; a timestamp did not — a barcode gun adds several products inside
/// the same millisecond, and the duplicate keys rendered them as one row.
int _sequence = 0;
String _nextLineId() => 'line_${++_sequence}';

/// Adds a product to the cart, bumping the existing row instead of stacking a duplicate.
///
/// Returns a new list; the list it was given is left untouched. The source's React state
/// relied on that, and the port keeps it — a mutating version would make every caller's
/// change tracking depend on aliasing.
List<CartLine> addToCart(List<CartLine> lines, Product product) {
  final existing = lines.where((l) => l.product.id == product.id).firstOrNull;
  if (existing == null) {
    return [...lines, CartLine(id: _nextLineId(), product: product, qty: 1)];
  }
  return [
    for (final line in lines)
      if (line.id == existing.id) line.copyWith(qty: line.qty + 1) else line,
  ];
}

/// Sets a row's quantity, always landing on a positive whole number.
///
/// A bare number input hands back 0 when cleared, a negative when the minus key is hit,
/// and NaN while the field is empty. All three used to reach the payload: NaN turned the
/// grand total into NaN and froze the pay button, and a zero-quantity line was posted to
/// the server as a real sale line. Removing a line is the delete button's job, not a side
/// effect of typing 0.
///
/// The finiteness check comes **before** `floor()` on purpose: `floor()` throws on
/// infinity and NaN, so the guard is what makes those two inputs safe rather than an
/// extra tidy-up.
List<CartLine> setLineQty(List<CartLine> lines, String lineId, num qty) {
  final safe = qty.isFinite ? max(1, qty.floor()) : 1;
  return [
    for (final line in lines)
      if (line.id == lineId) line.copyWith(qty: safe) else line,
  ];
}

List<CartLine> removeLine(List<CartLine> lines, String lineId) =>
    lines.where((l) => l.id != lineId).toList();

/// Finds a product by an exact sku or barcode match.
///
/// A scanner sends the whole code and nothing else, so a partial match would ring up the
/// wrong product; the trim and the case fold are there because guns append whitespace and
/// some are configured to upper case.
Product? findProductByCode(List<Product> products, String code) {
  final needle = code.trim().toLowerCase();
  if (needle.isEmpty) return null;
  return products
      .where(
          (p) => _matchesCode(p.sku, needle) || _matchesCode(p.barcode, needle))
      .firstOrNull;
}

bool _matchesCode(String? value, String needle) =>
    (value ?? '').trim().toLowerCase() == needle;

/// A discount the cashier typed on a cart row: a percentage or a flat amount.
///
/// Modelled as a closed union rather than two nullable fields, because the invariant is
/// the whole point: **a line carries one or the other, never both.** The backend applies
/// `discount_amount` when it is set and only falls back to `discount_percent` otherwise,
/// so a line carrying both silently loses the percentage. Two nullable fields would let a
/// caller pass both and discover the loss at reconciliation; this shape makes it
/// unrepresentable. `.claude/rules/patterns.md` §2a.3.
///
/// Hand-written rather than `freezed`: it is never compared, copied, or serialized, only
/// matched on. §2a.5.
sealed class CartDiscount {
  const CartDiscount();
}

final class CartDiscountPercent extends CartDiscount {
  const CartDiscountPercent(this.percent);
  final num percent;
}

final class CartDiscountAmount extends CartDiscount {
  const CartDiscountAmount(this.amount);
  final num amount;
}

/// Sets a row's discount, clearing whichever kind it was not given.
///
/// Switching from "10%" to "5.000 off" is a replacement, not an addition — which is also
/// what the cashier means by typing the second one.
List<CartLine> setLineDiscount(
  List<CartLine> lines,
  String lineId,
  CartDiscount discount,
) {
  final (num percent, num amount) = switch (discount) {
    CartDiscountPercent(:final percent) => (_clampDiscountPercent(percent), 0),
    CartDiscountAmount(:final amount) => (0, _clampMoney(amount)),
  };
  return [
    for (final line in lines)
      if (line.id == lineId)
        line.copyWith(
          discountPercent: amount > 0 ? null : (percent != 0 ? percent : null),
          discountAmount: amount != 0 ? amount : null,
        )
      else
        line,
  ];
}

/// Clamps a percentage into 0..100.
///
/// Non-nullable, unlike the source's `number | undefined`. The source had to accept
/// `undefined` because its discount object carried two optional fields; [CartDiscount] is
/// a closed union, so a caller cannot reach here without a number. Accepting null anyway
/// would be a branch no test could ever execute.
num _clampDiscountPercent(num value) {
  if (!value.isFinite) return 0;
  return min(100, max(0, value));
}

/// Never negative, never NaN. Infinity collapses to 0 rather than staying infinite, which
/// is what the source's `Number.isFinite` guard did.
num _clampMoney(num value) {
  if (!value.isFinite) return 0;
  return max(0, value);
}

/// A whole-bill discount cannot exceed the bill; the server rejects a negative total and
/// there is no such thing as a sale that pays the customer.
num clampHeaderDiscount(num discount, num linesTotal) =>
    min(_clampMoney(discount), max(0, linesTotal));
