/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

// The WHATWG application/x-www-form-urlencoded set that `URLSearchParams` leaves alone:
// A-Z a-z 0-9 and `*` `-` `.` `_`. Dart's `Uri.encodeQueryComponent` differs on exactly two
// characters — it encodes `*` and leaves `~` — so a request built with it would not match
// the one the web app sends.
bool _isUnreserved(int byte) =>
    (byte >= 0x30 && byte <= 0x39) ||
    (byte >= 0x41 && byte <= 0x5a) ||
    (byte >= 0x61 && byte <= 0x7a) ||
    byte == 0x2a ||
    byte == 0x2d ||
    byte == 0x2e ||
    byte == 0x5f;

/// Encodes [value] the way `URLSearchParams` does: space becomes `+`, the unreserved set
/// above stays, and every other UTF-8 byte becomes `%XX` in uppercase hex.
///
/// Query strings only. Path parameters use `Uri.encodeComponent`, which matches
/// `encodeURIComponent` exactly.
String jsQueryEncode(String value) {
  final out = StringBuffer();
  for (final byte in utf8.encode(value)) {
    if (byte == 0x20) {
      out.write('+');
    } else if (_isUnreserved(byte)) {
      out.writeCharCode(byte);
    } else {
      out
        ..write('%')
        ..write(byte.toRadixString(16).toUpperCase().padLeft(2, '0'));
    }
  }
  return out.toString();
}

// `String(v)` in the source swallows anything. A double is refused because it prints
// differently in Dart (`2.0`) than in JavaScript (`2`), and the query of every POS call is
// strings, ints and bools; a list or a map is a caller bug.
String _valueText(Object value) => switch (value) {
  final String s => s,
  final int n => '$n',
  final bool b => '$b',
  _ => throw ArgumentError.value(
    value,
    'query value',
    'must be a String, int or bool',
  ),
};

/// The query string for [query], without the leading `?`.
///
/// Drops `null` and the empty string and nothing else — `0` and `false` are real values —
/// exactly as `_callApi` in `finnesia-monorepo/packages/shared/src/api/internal/api.base.ts`
/// does before it hands the pairs to `URLSearchParams`. Order is insertion order.
String buildQueryString(Map<String, Object?> query) {
  final pairs = <String>[];
  for (final MapEntry(:key, :value) in query.entries) {
    if (value == null || value == '') continue;
    pairs.add('${jsQueryEncode(key)}=${jsQueryEncode(_valueText(value))}');
  }
  return pairs.join('&');
}
