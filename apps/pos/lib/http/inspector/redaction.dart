import 'dart:convert';
import 'dart:typed_data';

/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

const _hidden = '***';

// Lower case, because HTTP header names are not case-sensitive.
//
// README §14.1 lists the first three. The cookies (and `Proxy-Authorization`, handled with
// `Authorization` below) are added: this app
// authenticates with a bearer token and sets no cookie itself, but a response can still carry
// one, and a header that can hold a credential is hidden rather than trusted to be empty.
//
// `x-device-token` is the tablet's own credential: the server resolves the device row from it
// on every POS request, so a log line holding it lets anyone act as that device. It is not
// reissuable — activation returns it once and no endpoint fetches it again, so a leak costs a
// re-pair. Added when the device registry introduced the header.
const _credentialHeaders = {
  'x-session-token',
  'x-session-expires',
  'x-csrf-token',
  'x-device-token',
  'cookie',
  'set-cookie',
};

/// [headers] with every credential hidden, for the debug inspector (README §14.1).
///
/// `Authorization` keeps its scheme (`Bearer ***`), so the screen still shows which kind of
/// credential was sent; the other credential headers are hidden whole. `X-Company-ID` stays: it
/// is not a credential, and it is the header that is wrong most often. Names are kept as the
/// caller wrote them, and the map it was given is not changed.
Map<String, String> redactHeaders(Map<String, String> headers) => {
  for (final MapEntry(:key, :value) in headers.entries)
    key: _redactHeader(key.toLowerCase(), value),
};

String _redactHeader(String lowerCaseName, String value) {
  if (lowerCaseName == 'authorization' ||
      lowerCaseName == 'proxy-authorization') {
    return _redactAuthorization(value);
  }
  if (_credentialHeaders.contains(lowerCaseName)) return _hidden;
  return value;
}

String _redactAuthorization(String value) {
  final space = value.indexOf(' ');
  if (space <= 0 || space == value.length - 1) return _hidden;
  return '${value.substring(0, space)} $_hidden';
}

// Lower case.
//
// README §14.1 lists `password`, `token` and `refresh_token`, for a request body, and shows a
// response body as it is. The rest are added because they are what this API hands back or takes
// in for a login: the poll and the refresh answer with `session_token` and
// `session_refresh_token` (a screenshot of that is the leak §14.1 exists to prevent), and whoever
// holds a login's `request_id` (or the `login_url` that carries it) can collect its session.
const _credentialFields = {
  'password',
  'token',
  'refresh_token',
  'session_token',
  'session_refresh_token',
  'request_id',
  'login_url',
};

// Deeper than any body this API sends. It is a guard, not a limit anyone will meet: a structure
// with a cycle would otherwise be followed until the stack ran out, inside the code that is
// only there to watch a request.
const _maxDepth = 16;

// The inspector keeps the last 50 exchanges of a tablet that runs for days; a product list of
// thousands of rows, 50 times over, would use up its memory before anyone opens the screen.
const _maxChars = 20000;

/// [body] with every credential field hidden, for the debug inspector.
///
/// A JSON string is read first (that is how a request body arrives); text that is not JSON is
/// kept as it is, and an object that is not JSON-shaped (a form, a stream, bytes) is shown as its
/// type only, since nothing can be looked into to hide a credential. The input is not changed.
///
/// Redacts first and cuts second, so a credential cannot survive in the part that was kept. A
/// body that fits stays a structure; one that does not becomes text, cut at [_maxChars].
Object? redactBody(Object? body) {
  final Object? value;
  if (body is String) {
    try {
      value = jsonDecode(body);
    } on FormatException {
      return _cut(body);
    }
  } else {
    value = body;
  }
  return _cut(_redact(value, 0));
}

Object? _redact(Object? value, int depth) {
  if (depth > _maxDepth) return '…';
  return switch (value) {
    final Map<dynamic, dynamic> map => <String, Object?>{
      for (final MapEntry(:key, :value) in map.entries)
        key.toString(): _credentialFields.contains(key.toString().toLowerCase())
            ? (value == null ? null : _hidden)
            : _redact(value, depth + 1),
    },
    // Before `List`: a `Uint8List` is one, and there is no field in bytes to look for.
    TypedData() => '<${value.runtimeType}>',
    final List<dynamic> list => [
      for (final item in list) _redact(item, depth + 1),
    ],
    null || String() || num() || bool() => value,
    _ => '<${value.runtimeType}>',
  };
}

Object? _cut(Object? value) {
  final text = switch (value) {
    final String text => text,
    Map() || List() => jsonEncode(value),
    _ => null,
  };
  if (text == null || text.length <= _maxChars) return value;
  return '${text.substring(0, _maxChars)}… (${text.length - _maxChars} more characters)';
}
