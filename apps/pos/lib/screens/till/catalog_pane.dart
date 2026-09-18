/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_product_stock.dart';
import 'package:pn_types/src/product.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/money_text.dart';
import 'package:pn_ui/src/widgets/state_view.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/till/catalog_controller.dart';

/// The categories and the products, as a grid.
///
/// A grid and not a list: a cashier picks goods hundreds of times a shift, and the same product
/// sits in the same place every time, which is a muscle memory a scrolling list cannot give.
///
/// It listens to the catalogue's own parts and not to the cart, so adding an item does not
/// rebuild it (`plan/ui/README.md` §3.2).
class CatalogPane extends StatelessWidget {
  const CatalogPane({super.key, required this.catalog, required this.onPick});

  final CatalogController catalog;
  final ValueChanged<Product> onPick;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _CategoryStrip(catalog: catalog),
      Expanded(
        child: _Grid(catalog: catalog, onPick: onPick),
      ),
    ],
  );
}

/// A horizontal strip rather than a select: a shop's categories are few and reached for
/// constantly, and a dropdown hides them behind an extra tap.
class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.catalog});

  final CatalogController catalog;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([catalog, catalog.categories]),
      builder: (context, _) {
        // Categories that could not be read leave "all" alone rather than an error strip: the
        // grid is the point of the screen, and it still works without them.
        final categories = switch (catalog.categories.state) {
          Ready(:final data) => data,
          _ => const [],
        };
        return SizedBox(
          height: PnTouch.min + 8,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              _Chip(
                label: l10n.tillCategoryAll,
                selected: catalog.categoryId == null,
                onSelected: () => catalog.selectCategory(null),
              ),
              for (final category in categories)
                _Chip(
                  label: category.name,
                  selected: catalog.categoryId == category.id,
                  onSelected: () => catalog.selectCategory(category.id),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final pn = context.pn;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        // The one amber on this screen besides nothing else: the chosen category. Not a pill.
        selectedColor: pn.accent,
        labelStyle: TextStyle(color: selected ? pn.onAccent : pn.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PnRadius.control),
          side: BorderSide(color: selected ? pn.accent : pn.outline),
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.catalog, required this.onPick});

  final CatalogController catalog;
  final ValueChanged<Product> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([catalog.products, catalog.stock]),
      builder: (context, _) {
        return switch (catalog.products.state) {
          Loading() => StateView.loading(label: l10n.commonLoading),
          // A failed catalogue is not "no products": that would read to a cashier as "we do not
          // sell this", and on a tablet that decides whether they call someone. The server's own
          // sentence when it refused; this screen's when nobody answered.
          Failed(:final error) => StateView(
            title: failedReadText(error, l10n.tillCatalogLoadFailed),
            actionLabel: l10n.commonRetry,
            onAction: catalog.products.load,
          ),
          Ready() => _products(context, l10n),
        };
      },
    );
  }

  Widget _products(BuildContext context, L10n l10n) {
    final products = catalog.sellable;
    if (products.isEmpty) {
      return StateView(
        title: l10n.tillNoProducts,
        description: l10n.tillNoProductsDesc,
      );
    }
    // Null when the stock could not be read (or has not been yet): the cards then say nothing of
    // it, because "Habis" for goods that are on the shelf sends customers away.
    final stock = switch (catalog.stock.state) {
      Ready(:final data) => data,
      _ => null,
    };

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Near the end, ask for the next page. The controller ignores it when there is none, or
        // one is already on its way.
        if (notification.metrics.extentAfter < 600) catalog.loadMore();
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 190,
          mainAxisExtent: 104,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: products.length,
        itemBuilder: (context, i) => ProductCard(
          product: products[i],
          stockKnown: stock != null,
          stock: stock?[products[i].id],
          onPick: onPick,
        ),
      ),
    );
  }
}

/// One product: its name, its price, and what is left of it when it is counted.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.stockKnown,
    required this.stock,
    required this.onPick,
  });

  final Product product;

  /// Whether the stock was read at all. Without it there is no badge, not a badge saying zero.
  final bool stockKnown;

  /// The quantity on hand. Null with [stockKnown] means the product has no entry, which for
  /// counted goods is zero.
  final num? stock;
  final ValueChanged<Product> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final type = product.type;
    // Only counted goods show a badge: INVENTORY always does, and a BUNDLE only once the API has
    // computed a quantity for it. A service shows nothing at all.
    final quantity = type == null || !stockKnown
        ? null
        : resolveProductStockBadge(type, stock).quantity;

    return Material(
      color: pn.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PnRadius.surface),
        side: BorderSide(color: pn.border),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PnRadius.surface),
        ),
        onTap: () => onPick(product),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleSmall,
                    ),
                  ),
                  if (quantity != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      quantity <= 0 ? l10n.tillOutOfStock : '$quantity',
                      style: theme.labelMedium!.copyWith(
                        // The word carries the meaning; the colour only helps.
                        color: quantity <= 0 ? pn.errorText : pn.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              MoneyText(
                formatCurrency(product.sellPrice ?? 0),
                style: theme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
