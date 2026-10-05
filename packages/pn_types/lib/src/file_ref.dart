/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_ref.freezed.dart';
part 'file_ref.g.dart';

/// Cast toleran per field: satu field bertipe salah jadi default, bukan TypeError.
String _asString(Object? v) => v is String ? v : '';
String? _asNullableString(Object? v) => v is String ? v : null;

/// A stored file, as the API describes it: branding logos, company logos, product photos.
///
/// Ported from `model.FileRef` in `finnesia-monorepo/apps/api/internal/model/file.go`,
/// partially (`project.md` §2.2): only `id`, `name`, `status` and `url`. `size_bytes`,
/// `content_type` and `created_at` are not modelled — every field parsed is a field that
/// can fail a pairing.
///
/// Each field is cast by hand because the default cast throws. `pairing.dart` catches that
/// `TypeError` and reports the whole activation unavailable, so one image field of the wrong
/// type must not cost a cashier their till.
@freezed
abstract class FileRef with _$FileRef {
  const factory FileRef({
    @JsonKey(fromJson: _asString) @Default('') String id,
    @JsonKey(fromJson: _asNullableString) String? name,

    /// One of `pending | attached | detached | deleting`, kept a plain string: an unknown
    /// value from a newer API has to mean "do not render", not a parse failure.
    @JsonKey(fromJson: _asString) @Default('') String status,
    @JsonKey(fromJson: _asString) @Default('') String url,
  }) = _FileRef;

  const FileRef._();

  factory FileRef.fromJson(Map<String, dynamic> json) =>
      _$FileRefFromJson(json);

  /// The one decision about "may this be rendered", used by all three render sites.
  ///
  /// Empty rather than a bool so a caller cannot skip the check: `null` is the fallback,
  /// and only an attached file with a url reaches an `Image.network`.
  String? get renderableUrl =>
      status == 'attached' && url.isNotEmpty ? url : null;
}
