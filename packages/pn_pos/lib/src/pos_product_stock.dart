/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/product.dart';

/// Decides whether a POS catalog card shows a stock badge, and what it says.
///
/// A service ([ProductType.nonInventory]) never has a badge — it has no stock to run out
/// of. A bundle owns no stock of its own either, but the API merges an estimated "how many
/// could be assembled right now" into the same `product_id -> quantity` map inventory
/// products use (`GetOutletStock`'s `annotateBundleAvailability`), keyed by the bundle's own
/// id. So a bundle only gets a badge when that key is actually present — absence means the
/// bundle has no inventory-tracked component to constrain it, not "zero in stock".
/// An [ProductType.inventory] product absent from the map, by contrast, legitimately means
/// zero: it has never moved, so `stock ?? 0` is correct there.
///
/// Ported from `resolveProductStockBadge` in
/// `finnesia-monorepo/packages/shared/src/pos/pos-product-stock.ts`.
///
/// Returns a **record**, not a class: two named fields, compared by value, never
/// serialized. A record gives that from `dart:core` — `freezed` would add a generated file
/// for nothing, and a hand-written `==` would be the duplication
/// `.claude/rules/patterns.md` §2a.2 forbids.
///
/// `quantity` is nullable on purpose, and it is not the same as zero. `tracked: true` with
/// `quantity: null` would be incoherent, so the two always agree: a badge is shown exactly
/// when there is a number to show.
///
/// ## The one deliberate divergence from the source
///
/// The source branches on `stock !== undefined`, and JavaScript keeps `undefined` distinct
/// from `null`. Feeding it `null` returns `{ tracked: true, quantity: null }` — "show the
/// badge" with no number, which a caller writing `if (tracked) render(quantity)` would
/// print as the word "null". Dart has a single absent value, so that distinction cannot be
/// expressed, and only one reading can be kept.
///
/// [ProductType.bundle] with an absent stock is treated as **no badge**, because:
///
///   - It is unreachable from the typed path anyway. `pos.stock` is declared
///     `Record<string, number>` (`packages/shared/src/api/all-endpoints/pos.ts:60`), the Go
///     side is a `map[string]float64` that can only emit numbers, and indexing a missing key
///     yields `undefined`, never `null`.
///   - It matches the intent written in the source's own comment: *"a bundle only gets a
///     badge when that key is actually present."* The `null` branch is a gap in the
///     TypeScript type, not a designed behaviour worth preserving.
///
/// A bundle the server **did** compute as `0` stays tracked, because that is a real
/// "cannot be assembled right now" and not the same thing as no estimate.
({bool tracked, num? quantity}) resolveProductStockBadge(
  ProductType productType,
  num? stock,
) {
  if (productType == ProductType.inventory) {
    return (tracked: true, quantity: stock ?? 0);
  }
  if (productType == ProductType.bundle && stock != null) {
    return (tracked: true, quantity: stock);
  }
  return (tracked: false, quantity: null);
}
