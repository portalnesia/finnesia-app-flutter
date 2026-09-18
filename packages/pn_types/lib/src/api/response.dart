/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';

import 'api_error.dart';

part 'response.freezed.dart';
part 'response.g.dart';

/// Cursor pagination info from a list response.
///
/// Ported from the `meta` object of `ResponseData` in
/// `finnesia-monorepo/packages/shared/src/api/types.ts`. A `null` cursor and an absent
/// one both mean "no more pages".
@freezed
abstract class PaginationMeta with _$PaginationMeta {
  const factory PaginationMeta({
    @JsonKey(name: 'next_cursor') String? nextCursor,
    @JsonKey(name: 'prev_cursor') String? prevCursor,
    @JsonKey(name: 'page_size') int? pageSize,
    int? page,
    int? total,
  }) = _PaginationMeta;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);
}

/// The envelope every API response arrives in: `{ data, meta?, message?, error? }`.
///
/// Ported from `ResponseData<R>` in the same file. `R` is whatever the endpoint's parser
/// makes of `data`; the source's `PaginationResponse` and `IResponse` are not ported — no
/// POS code uses them.
///
/// The TypeScript client attaches `meta` onto the returned array as an expando property.
/// Dart cannot, which is why the envelope keeps it alongside `data` instead.
@Freezed(genericArgumentFactories: true)
abstract class ResponseData<R> with _$ResponseData<R> {
  const factory ResponseData({
    required R data,
    ApiErrorTypes? error,
    String? message,
    PaginationMeta? meta,
  }) = _ResponseData<R>;

  factory ResponseData.fromJson(
    Map<String, dynamic> json,
    R Function(Object? json) fromJsonR,
  ) => _$ResponseDataFromJson(json, fromJsonR);
}
