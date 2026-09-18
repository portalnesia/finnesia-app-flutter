/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import '../../product.dart';
import '../endpoint.dart';
import '../parsers.dart';

/// `finnesia-monorepo/packages/shared/src/api/all-endpoints/products.ts`
abstract final class ProductsApi {
  // Paged: the catalog is scrolled, and a shop can have more products than one page.
  static final list = PagedEndpoint<Product>(
    '/api/v1/products',
    parseList(Product.fromJson),
  );
}
