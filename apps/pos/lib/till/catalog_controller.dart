/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/master.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/endpoints/products.dart';
import 'package:pn_types/src/category.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/product.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/paged_loadable.dart';

/// One page of the grid. The server does the searching and the paging, so a shop with more
/// products than fit on a screen still shows all of them.
const _pageSize = 50;

/// What the till sells from: the categories, the products (searched, filtered, paged) and the
/// stock of the outlet.
///
/// The three reads are separate [Loadable]s and not one, because they fail separately and the
/// screen shows them separately: a stock count that could not be read must not take the grid
/// with it, and a grid that could not be read must not look like an empty shop. This controller
/// itself only announces the two things the cashier picks, the search text and the category.
class CatalogController extends ChangeNotifier {
  CatalogController({
    required this.client,
    required this.outletId,
    required this._analytics,
    this.debounce = const Duration(milliseconds: 300),
  });

  final ApiClient client;
  final AnalyticsPort _analytics;

  /// The outlet this till sells from. Stock is per warehouse, and the outlet picks it.
  final String outletId;

  /// How long the search text has to sit still before the server is asked. The tablet's keyboard
  /// types a letter at a time, and a request per letter is what N+1 looks like from the UI.
  final Duration debounce;

  late final categories = Loadable<List<Category>>(
    // A category can opt out of the till's strip the same way a product opts out of the grid:
    // raw materials and back-office groupings are not things a cashier sells.
    () => MasterApi.categoriesList(
      client,
      query: {'pos_visible': 'true', 'page_size': 50},
    ),
  );

  late final products = PagedLoadable<Product>(
    (cursor) => ProductsApi.list(
      client,
      cursor: cursor,
      query: {
        if (_applied.isNotEmpty) 'q': _applied,
        if (_categoryId != null) 'category_id': _categoryId,
        // Raw materials and packaging exist as products but are never rung up.
        'sellable': 'true',
        'page_size': _pageSize,
      },
    ),
  );

  /// One request for the whole grid: product id to quantity on hand. A count fetched per card
  /// would be N+1 by construction, and the grid redraws on every keystroke.
  late final stock = Loadable<Map<String, num>>(
    () => PosApi.stock(client, query: {'outlet_id': outletId}),
  );

  String _search = '';
  // The trimmed text the products on screen were asked for. Apart from [_search] so that a
  // trailing space, which changes the field and nothing else, is not a new request.
  String _applied = '';
  String? _categoryId;
  Timer? _debounceTimer;
  bool _disposed = false;

  /// What is in the search field, as typed.
  String get search => _search;

  /// The category the grid is limited to, or null for all of them.
  String? get categoryId => _categoryId;

  /// The products the cashier may ring up: the server lists deactivated ones too, and the till
  /// must not sell them (`product-grid.tsx`).
  List<Product> get sellable => switch (products.state) {
    Ready(:final data) => data.items.where((p) => p.isActive != false).toList(),
    _ => const [],
  };

  /// Reads everything the grid shows, together, one request each.
  Future<void> load() =>
      Future.wait([categories.load(), products.load(), stock.load()]);

  Future<void> loadMore() => products.loadMore();

  /// Limits the grid to [id], or to everything when it is null. Starts again from the first
  /// page: the cursor of one list is meaningless in another.
  Future<void> selectCategory(String? id) {
    if (id == _categoryId) return Future.value();
    _categoryId = id;
    notifyListeners();
    unawaited(
      _analytics.logEvent(
        'category_selected',
        parameters: {'category_id': id ?? 'all'},
      ),
    );
    return products.load();
  }

  /// Records what the cashier typed now, and asks the server once they stop.
  void setSearch(String text) {
    _search = text;
    notifyListeners();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      final wanted = text.trim();
      if (_disposed || wanted == _applied) return;
      _applied = wanted;
      products.load();
    });
  }

  /// The product whose sku or barcode is exactly [code], or null when there is none.
  ///
  /// It asks the server rather than reading the grid, which is one page: a shop with a bigger
  /// catalogue would get "not found" for a product sitting on the shelf. The server search is a
  /// `LIKE`, so it also answers with near misses, and only an exact code may ring up: a scanner
  /// sends the whole code and nothing else, and a partial match would sell the wrong thing.
  ///
  /// A failure is thrown, for the screen to word. It is not an empty answer, which would tell a
  /// cashier the product does not exist.
  Future<Product?> findByCode(String code) async {
    final wanted = code.trim();
    if (wanted.isEmpty) return null;
    final page = await ProductsApi.list(
      client,
      query: {'q': wanted, 'sellable': 'true', 'page_size': 5},
    );
    return findProductByCode(
      page.items.where((p) => p.isActive != false).toList(),
      wanted,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    categories.dispose();
    products.dispose();
    stock.dispose();
    super.dispose();
  }
}
