/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// What a printed receipt lists.
///
/// Ported from `apps/web/src/lib/pos-receipt.ts` in `finnesia-monorepo`.
///
/// The lines live on the sale's invoice, not on the sale: `pos_sales` has no items table,
/// and `POSSale` carries no `Items` field. The receipt used to read `sale.items` — a field
/// the server never sends — so `?? []` swallowed it and every receipt printed a header, a
/// total, and no goods at all. It then printed `product_id`, so the first thing a fixed
/// receipt would have shown the customer was a ULID.
library;

import 'dart:math' show max;

import 'package:pn_types/src/category.dart';

import 'js_compat.dart';

/// One line of a sale's invoice, reduced to what a receipt reads.
///
/// A record rather than a ported class: [posReceiptLines] is the only thing that consumes
/// it, the fields are never serialized, and the real wire type belongs to the API layer
/// that will declare the whole invoice payload in one place. Declaring a partial
/// `SalesInvoiceItem` class here would create a second, thinner definition of a wire type
/// that already has an owner.
typedef InvoiceItem = ({
  /// The line's own id, carried through so a caller can key rows by it.
  String id,

  /// The related product's name, when the invoice was loaded with the relation.
  String? productName,

  /// Free text for a line typed by hand. May be empty.
  String? description,
  num quantity,
  num price,

  /// `line_subtotal` from the server: the line after its discount, before tax.
  num lineSubtotal,

  /// `line_total` from the server: what the customer actually pays for this line.
  num lineTotal,

  /// The related product's category, when the invoice was loaded with the relation. Used by
  /// `pos_print_category.dart` for kitchen/bar tickets; the customer receipt ignores it.
  Category? category,
});

/// One row of the receipt.
///
/// [discount] is the gap between what the line would have cost and what the server says it
/// actually cost, so it is always the discount the customer really got — not a re-derivation
/// from `discount_percent` or `discount_amount`, which can both be set and neither of which
/// accounts for a line-level override.
typedef ReceiptLine = ({
  String id,
  String name,
  num quantity,
  num price,
  num discount,
  num total,
});

/// Builds the receipt rows for a sale.
///
/// [invoiceItems] is `sale.invoice?.items`; pass `null` or an empty list for a sale whose
/// invoice was not loaded. A sale from the list endpoint carries no invoice relation, and
/// the receipt must render empty rather than throw on the way to the printer.
///
/// [fallbackName] covers a product deleted since the sale. It is passed in rather than
/// chosen here because it is a translated string — `.claude/rules/style.md` §7.1: a reusable
/// piece of logic must not reach for a translation itself, and `pn_pos` has no language
/// context by design.
///
/// ## The name chain, and why it is not `??`
///
/// The source is `item.product?.name || item.description || fallbackName`. JavaScript's `||`
/// treats `''` as absent, so an empty product name falls through to the description and then
/// to the fallback. **Dart's `??` only treats `null` as absent**, so a literal port would let
/// an empty name win and print a blank line on the customer's receipt.
///
/// Verified against the running source: `product.name = ''` yields the fallback there, and
/// so does `description = ''`. A product whose name was cleared in the catalogue is enough
/// to reach it. Hence [firstNonEmpty].
///
/// Note the chain does **not** trim: `'   '` is truthy in JavaScript and passes through
/// unchanged, and that is preserved. Trimming here would be a behaviour change the oracle
/// does not sanction, and the whitespace-only name would have to be rejected upstream first
/// (`.claude/rules/cross-repo.md` §4).
List<ReceiptLine> posReceiptLines({
  required List<InvoiceItem>? invoiceItems,
  required String fallbackName,
}) {
  final items = invoiceItems ?? const <InvoiceItem>[];
  return [
    for (final item in items)
      (
        id: item.id,
        // A product relation is the normal case; description covers a line typed by hand,
        // and the caller's translated fallback covers a product deleted since the sale.
        name: firstNonEmpty([item.productName, item.description, fallbackName]),
        quantity: item.quantity,
        price: item.price,
        // Derived, not copied: a line may be discounted by percent, by amount, or both, and
        // the difference the customer actually got is the gap the server already resolved.
        //
        // `max` from `dart:math`, not a ternary: `Math.max(0, NaN)` is `NaN` in JavaScript
        // and `dart:math`'s `max` matches it, while a hand-rolled `v > 0 ? v : 0` returns
        // `0`. Reachable from a NaN price or subtotal, and a receipt showing `Rp NaN` for a
        // discount is at least visible, whereas silently reporting `0` would hide the
        // upstream bug. (Compare `pos_shift.dart`, where the value *is* compared rather
        // than displayed and rounding to 0 is the correct answer.)
        discount: max(0, item.quantity * item.price - item.lineSubtotal),
        total: item.lineTotal,
      ),
  ];
}
