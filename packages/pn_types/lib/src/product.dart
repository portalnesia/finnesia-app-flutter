/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';

import 'category.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// What kind of thing a product is, which decides whether it can run out.
///
/// Ported from `export type ProductType = 'INVENTORY' | 'NON_INVENTORY' | 'BUNDLE'`
/// in `finnesia-monorepo/packages/types/src/product.ts`.
///
/// A hand-written enum with a [wire] value and a `tryParse`, rather than `freezed`,
/// because the wire strings differ from the Dart names and the parser has to answer
/// honestly for a value it does not know. `.claude/rules/patterns.md` §2a.4 lists
/// "enum dengan nilai wire" as something codegen does not produce.
///
/// `valueField: 'wire'` makes json_serializable read and write [wire] instead of the
/// Dart name — see `POSTenderMethod`.
@JsonEnum(valueField: 'wire')
enum ProductType {
  /// Stocked and counted. An absent entry in the stock map means zero.
  inventory('INVENTORY'),

  /// A service. It has no stock to run out of, so it never shows a stock badge.
  nonInventory('NON_INVENTORY'),

  /// Assembled from other products at sale time. Owns no stock of its own.
  bundle('BUNDLE');

  const ProductType(this.wire);

  /// The exact string the API sends and expects.
  final String wire;

  /// Returns `null` for a wire value this enum does not know.
  ///
  /// Same shape as `POSTenderMethod.tryParse`: a catalogue from a newer API must not
  /// crash the till just because it carries a product type this build has not heard of.
  static ProductType? tryParse(String wire) {
    for (final t in ProductType.values) {
      if (t.wire == wire) return t;
    }
    return null;
  }
}

/// The product fields the POS actually reads.
///
/// Ported from `finnesia-monorepo/packages/types/src/product.ts`, which declares the
/// full catalogue record — 40+ fields including the Accurate account mapping and the
/// bundle graph. `.claude/rules/project.md` §2.2 says to port **partially**: only what
/// POS uses. This carries that subset and grows as modules need more.
///
/// | Field | Read by |
/// | ----- | ------- |
/// | [id] | `addToCart` line identity, checkout payload |
/// | [name] | cart row, kitchen ticket |
/// | [sku], [barcode] | `findProductByCode` |
/// | [unitId], [sellPrice] | checkout payload |
/// | [type] | `resolveProductStockBadge` |
/// | [category] | kitchen/bar ticket grouping (`topLevelCategory`) |
/// | [isActive] | the catalogue grid (a deactivated product is listed but not sold) |
///
/// `fromJson` reads exactly these fields and ignores the rest of the record. That is a
/// read model, not a lossy copy: a later screen that needs another field adds it here,
/// and `product_test.dart` fails until the wire name is right.
///
/// camelCase in Dart, snake_case on the wire (`@JsonKey(name:)`). This is a domain object,
/// not a payload shape — unlike `CartMathLine` in `pn_pos`, which mirrors the JSON the
/// backend accepts and therefore keeps the wire spelling. `.claude/rules/style.md` §3.1.
@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    String? sku,
    String? barcode,
    @JsonKey(name: 'unit_id') required String unitId,

    /// Nullable because the source's only read site treats it as possibly absent: the
    /// checkout payload writes `l.product.sell_price ?? 0`
    /// (`apps/web/src/pages/pos/pos-cart-page.tsx`). The TypeScript type declares it
    /// non-optional, so that `?? 0` is the observed contract and it wins.
    @JsonKey(name: 'sell_price') num? sellPrice,

    /// What kind of thing this is. Drives the stock badge and whether it can run out.
    /// A type this build does not know reads as `null`, matching
    /// [ProductType.tryParse]: a newer catalogue must not crash the till.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    ProductType? type,

    /// The product's own category, which may be nested one level. `topLevelCategory`
    /// rolls a sub-category up to its parent for kitchen/bar tickets.
    Category? category,

    /// Null on rows that predate the field, which the till reads as active
    /// (`p.is_active !== false`).
    @JsonKey(name: 'is_active') bool? isActive,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
