/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// The product-category fields the POS actually reads.
///
/// Ported from `finnesia-monorepo/packages/types/src/master-data.ts`, which declares the
/// full record including the Accurate account mapping. `.claude/rules/project.md` §2.2 says
/// to port **partially**: only what POS uses. This carries that subset and grows as modules
/// need more.
///
/// | Field | Read by |
/// | ----- | ------- |
/// | [id], [name] | `topLevelCategory`, kitchen-ticket grouping |
/// | [parent], [parentId] | `topLevelCategory`'s one-level roll-up |
///
/// `parent` is a `Category`, so the type is recursive — which is fine and is what the wire
/// actually sends: the API preloads exactly one level (`Category.Parent`, not the whole
/// lineage), which is why [topLevelCategory] caps at one level of ancestor.
///
/// `freezed` rather than a record: this is compared in tests, and it will be serialized by
/// the API layer. `.claude/rules/patterns.md` §2a.5.
@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,

    /// Present on a sub-category. Kept alongside [parent] because the wire carries both and
    /// a payload that loaded only the id still needs to be representable.
    @JsonKey(name: 'parent_id') String? parentId,

    /// The one level of ancestor the API preloads.
    Category? parent,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
