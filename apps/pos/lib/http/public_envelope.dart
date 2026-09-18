/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

/// The object under `data` in an API response body, or `null` when the body is not that.
///
/// For the public calls (pairing, login, refresh), which run before there is a session and so
/// cannot go through `ApiClient`. Each of them treats a body that is not `{"data": {...}}` as
/// an answer it cannot use, and the source repeated this `json().catch(() => null)` chain in
/// every one.
Map<String, dynamic>? readEnvelopeData(String? body) {
  if (body == null) return null;
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (json is! Map<String, dynamic>) return null;
  final data = json['data'];
  return data is Map<String, dynamic> ? data : null;
}
