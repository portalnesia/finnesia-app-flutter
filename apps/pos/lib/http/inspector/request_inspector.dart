/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';

part 'request_inspector.freezed.dart';

/// One request the inspector recorded, **already redacted** (`redaction.dart`).
///
/// Nothing in here may hold a credential: the generated `toString` prints every field, and this
/// object is what ends up on a screen that anyone holding the tablet can read. Build it from
/// redacted values only.
@freezed
abstract class InspectedRequest with _$InspectedRequest {
  const factory InspectedRequest({
    required String method,
    required String url,
    required Map<String, String> requestHeaders,
    required Object? requestBody,
    required DateTime at,
    int? statusCode,
    Map<String, String>? responseHeaders,
    Object? responseBody,
    Duration? duration,

    /// What went wrong, as a short code (`connectionTimeout`, `badResponse`). Not the
    /// exception's own text: that can carry the URL, and a URL can carry a search term.
    String? error,
  }) = _InspectedRequest;
}

/// Records the last few exchanges for the debug screen (README §14).
///
/// Apart from the transport so it can be tested without a network: what is tested is the
/// buffer, and the redaction that feeds it, not HTTP.
class RequestInspector {
  RequestInspector({this.maxEntries = 50}) {
    if (maxEntries < 1) {
      throw ArgumentError.value(
        maxEntries,
        'maxEntries',
        'must hold at least one entry',
      );
    }
  }

  /// A ring of fixed size: the tablet runs for days, and a buffer that grows without a limit
  /// would use up the memory before anyone opens the screen.
  final int maxEntries;
  final _entries = <InspectedRequest>[];

  /// What was recorded, oldest first. A snapshot: a later [record] does not change it.
  List<InspectedRequest> get entries => List.unmodifiable(_entries);

  void record(InspectedRequest entry) {
    _entries.add(entry);
    if (_entries.length > maxEntries) _entries.removeAt(0);
  }

  void clear() => _entries.clear();
}
