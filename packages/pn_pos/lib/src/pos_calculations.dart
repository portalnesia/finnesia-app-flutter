/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:math' show max;

import 'pos_cart.dart';

/// Line shape used by the cart maths.
///
/// Named [CartMathLine] rather than the source's `CartLine` because `pos-cart.ts`
/// exports a **different** type under that same name (a cart row with an `id` and a
/// `Product`). TypeScript keeps the two apart by module; Dart has one namespace, so one
/// of them has to give, and the maths side is the one that is only ever a transient
/// argument.
///
/// The field names keep the wire spelling on purpose. This one mirrors the payload the
/// Go backend accepts (`apps/api/internal/dto/pos.go`: `json:"discount_percent"`,
/// `json:"discount_amount"`), and the web app builds it in exactly that shape before
/// calling the maths (`apps/web/src/pages/pos/pos-cart-page.tsx`). Renaming the fields
/// would break the JSON without changing any behaviour.
///
/// The cart's own `CartLine` in `pos_cart.dart` is camelCase because it never leaves
/// the device.
class CartMathLine {
  const CartMathLine({
    required this.quantity,
    required this.price,
    this.discountPercent,
    this.discountAmount,
    this.taxRate,
  });

  final num quantity;
  final num price;
  final num? discountPercent;
  final num? discountAmount;
  final num? taxRate;
}

class CartTotals {
  const CartTotals({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.grandTotal,
  });

  final num subtotal;
  final num discount;
  final num tax;
  final num grandTotal;
}

num calcLineTotal(CartMathLine line) => calcLineAmounts(line).lineTotal;

/// One line's money, before and after tax.
///
/// Split out of [calcLineTotal] because two readers need different halves: a receipt prints the
/// net line beside the taxed one, and the totals need the sum. One implementation is what stops
/// the printed rows from disagreeing with the printed total.
///
/// The halves mirror the wire fields the server writes (`pos_service.go:1314-1330`):
/// `line_subtotal` is after the line's own discount and before tax, `line_total` is after both.
({num lineSubtotal, num lineTax, num lineTotal}) calcLineAmounts(
  CartMathLine line,
) {
  final base = line.quantity * line.price;
  final discPct =
      line.discountPercent != null ? base * (line.discountPercent! / 100) : 0;
  final discAmt = line.discountAmount ?? 0;
  final lineSubtotal = max(0, base - discPct - discAmt);
  final lineTax =
      line.taxRate != null ? lineSubtotal * (line.taxRate! / 100) : 0;
  return (
    lineSubtotal: lineSubtotal,
    lineTax: lineTax,
    lineTotal: lineSubtotal + lineTax,
  );
}

CartTotals calcCartTotals(List<CartMathLine> lines) {
  num subtotal = 0;
  num discount = 0;
  num tax = 0;
  for (final l in lines) {
    final base = l.quantity * l.price;
    subtotal += base;
    final discPct =
        l.discountPercent != null ? base * (l.discountPercent! / 100) : 0;
    final discAmt = l.discountAmount ?? 0;
    discount += discPct + discAmt;
    final afterDisc = max(0, base - discPct - discAmt);
    tax += l.taxRate != null ? afterDisc * (l.taxRate! / 100) : 0;
  }
  final grandTotal = max(0, subtotal - discount + tax);
  return CartTotals(
    subtotal: subtotal,
    discount: discount,
    tax: tax,
    grandTotal: grandTotal,
  );
}

num calcChange(num tendered, num grandTotal) => max(0, tendered - grandTotal);

bool isTenderSufficient(num tendered, num grandTotal) => tendered >= grandTotal;

/// What a basket of [CartLine]s comes to, priced at `sell_price`.
///
/// Here rather than beside the cart controller, because **two** things read it and they must
/// agree: the size of a basket in the held list, and the entry the offline queue writes
/// (`buildPendingSale`). A product with no price counts as free, as `pos-page.tsx` does — the
/// server is what refuses a sale it cannot price.
///
/// Takes `num` and is null-tolerant rather than taking a `Product`: this file is about money,
/// and it should not have to know what a catalogue row is.
CartTotals totalsOfLines(List<CartLine> lines) => calcCartTotals([
      for (final line in lines)
        CartMathLine(
          quantity: line.qty,
          price: line.product.sellPrice ?? 0,
          discountPercent: line.discountPercent,
          discountAmount: line.discountAmount,
        ),
    ]);
