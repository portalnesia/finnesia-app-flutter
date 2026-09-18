/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Kitchen and bar ticket grouping by top-level category.
///
/// Ported from `apps/web/src/lib/pos-print-category.ts` in `finnesia-monorepo`.
///
/// Both entry points here take their text through parameters — [Product]'s name, and the
/// `uncategorizedLabel` / `fallbackName` labels. That is what `.claude/rules/style.md` §7.1
/// requires of reusable logic: it must not reach for a translation itself, and `pn_pos` has
/// no language context by design. The caller resolves the label and passes it in.
library;

import 'package:pn_types/src/category.dart';
import 'package:pn_types/src/product.dart';

import 'js_compat.dart';
import 'pos_cart.dart';
import 'pos_receipt.dart';

/// A line as a ticket prints it.
typedef PrintableLine = ({
  String id,
  String name,
  num quantity,
  String categoryKey,
  String categoryName,
});

/// One category's worth of lines, in the order they were rung up.
typedef CategoryGroup = ({
  String key,
  String name,
  List<PrintableLine> lines,
});

/// The category a ticket files an item under, as a key/name pair.
///
/// Kitchen and bar tickets are printed per top-level category ("Makanan", "Minuman"), not
/// per the product's own (possibly nested) category — a "Nasi Goreng" sub-category still
/// prints on the "Makanan" ticket.
///
/// Capped at **one level** of ancestor: the categories this app's product list actually
/// preloads (`Category.Parent`, not the whole lineage), which covers the two-level trees
/// every real tenant has used so far. A deeper tree would need the API to preload more, not
/// a loop here.
///
/// Returns `null` for a missing category so the caller can supply its own "uncategorized"
/// label — see [_toPrintableLine].
({String key, String name})? topLevelCategory(Category? category) {
  if (category == null) return null;
  final parent = category.parent;
  return parent != null
      ? (key: parent.id, name: parent.name)
      : (key: category.id, name: category.name);
}

/// The one line shape both mappers below produce.
///
/// Building the item's own printable name/category is the same two lookups regardless of
/// where the line comes from (a posted sale's invoice items, or the live cart) — only the
/// input differs, so both share this. `.claude/rules/patterns.md` §2.1.
PrintableLine _toPrintableLine({
  required String id,
  required String name,
  required num quantity,
  required Category? category,
  required String uncategorizedLabel,
}) {
  final top = topLevelCategory(category);
  return (
    id: id,
    name: name,
    quantity: quantity,
    // The sentinel key is the source's, and it is load-bearing: every uncategorized line
    // must land in ONE group, so the key has to be a constant rather than the label. Using
    // the label would merge two different labels into one group and split the same label
    // across two if the caller ever passed different text.
    categoryKey: top?.key ?? '__none__',
    categoryName: top?.name ?? uncategorizedLabel,
  );
}

/// A completed sale's lines, for the category tickets printed alongside (or instead of) the
/// customer receipt.
///
/// Requires the API to have preloaded `Invoice.Items.Product.Category` (and
/// `.Category.Parent`) — see `pos_sale_repository.go` `FindByID`.
///
/// The name chain is `product?.name || description || fallbackName`, and as in
/// [posReceiptLines] the JavaScript `||` treats `''` as absent. Dart's `??` does not, so the
/// empty case is handled explicitly; a literal port would print a blank line on a kitchen
/// ticket, which is worse than on a receipt — the kitchen has nothing to cook from.
List<PrintableLine> receiptLinesWithCategory({
  required List<InvoiceItem>? invoiceItems,
  required String fallbackName,
  required String uncategorizedLabel,
}) {
  final items = invoiceItems ?? const <InvoiceItem>[];
  return [
    for (final item in items)
      _toPrintableLine(
        id: item.id,
        name: firstNonEmpty([item.productName, item.description, fallbackName]),
        quantity: item.quantity,
        category: item.category,
        uncategorizedLabel: uncategorizedLabel,
      ),
  ];
}

/// The live (or held) cart's lines, for printing a kitchen/bar ticket before the sale ever
/// reaches the server — a hold is never posted, so it has no invoice to read lines from.
List<PrintableLine> cartLinesWithCategory(
  List<CartLine> lines,
  String uncategorizedLabel,
) =>
    [
      for (final line in lines)
        _toPrintableLine(
          id: line.id,
          // No `||` chain here: the cart line's product is required and its name is
          // required, so there is nothing to fall back to. The source is the same.
          name: line.product.name,
          quantity: line.qty,
          category: line.product.category,
          uncategorizedLabel: uncategorizedLabel,
        ),
    ];

/// Groups lines by category, **in first-seen order, not alphabetically** — the category a
/// cashier rang up first is the one they expect to see (and print) first.
///
/// Built with a map for the lookup and a list for the order, exactly as the source does:
/// `Map` iteration order in Dart is insertion order, but relying on that would be relying on
/// an implementation detail when the list states the intent outright.
List<CategoryGroup> groupByCategory(List<PrintableLine> lines) {
  final groups = <CategoryGroup>[];
  final byKey = <String, int>{};
  for (final line in lines) {
    final existing = byKey[line.categoryKey];
    if (existing == null) {
      byKey[line.categoryKey] = groups.length;
      groups.add((
        key: line.categoryKey,
        name: line.categoryName,
        lines: [line],
      ));
    } else {
      groups[existing].lines.add(line);
    }
  }
  return groups;
}
