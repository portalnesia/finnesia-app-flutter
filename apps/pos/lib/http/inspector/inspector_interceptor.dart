/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:dio/dio.dart';
import 'package:pn_types/src/api/environment.dart';
import 'package:pos/http/inspector/redaction.dart';
import 'package:pos/http/inspector/request_inspector.dart';

// Where the interceptor keeps what it saw when the request went out, until the answer comes.
// Per request, in the request's own `extra`: two requests in flight at once must not share it.
const _pendingKey = 'pn_inspector_pending';

class _Pending {
  _Pending(this.startedAt, this.method, this.url, this.headers, this.body);

  final DateTime startedAt;
  final String method;
  final String url;
  final Map<String, String> headers;
  final Object? body;
}

/// Records every request that passes through [Dio] into a [RequestInspector], redacted.
///
/// Debug only (README §14): the app installs it through [installInspector], which does nothing
/// in a release build.
///
/// It only watches. Whatever goes wrong while it does — a value that cannot be printed, an
/// inspector that throws — must not reach the request: a debugging aid that can fail a sale is
/// worse than none.
class InspectorInterceptor extends Interceptor {
  InspectorInterceptor(this.inspector, {this._now = DateTime.now});

  final RequestInspector inspector;
  final DateTime Function() _now;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _watch(() => options.extra[_pendingKey] = _capture(options));
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _watch(() {
      final pending = _pendingOf(response.requestOptions);
      inspector.record(
        InspectedRequest(
          method: pending.method,
          url: pending.url,
          requestHeaders: pending.headers,
          requestBody: pending.body,
          at: pending.startedAt,
          statusCode: response.statusCode,
          responseHeaders: _headersOf(response),
          responseBody: redactBody(response.data),
          duration: _now().difference(pending.startedAt),
        ),
      );
    });
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _watch(() {
      final pending = _pendingOf(err.requestOptions);
      final response = err.response;
      inspector.record(
        InspectedRequest(
          method: pending.method,
          url: pending.url,
          requestHeaders: pending.headers,
          requestBody: pending.body,
          at: pending.startedAt,
          statusCode: response?.statusCode,
          responseHeaders: response == null ? null : _headersOf(response),
          responseBody: response == null ? null : redactBody(response.data),
          duration: _now().difference(pending.startedAt),
          // The type, not `err.toString()`: that carries the request and, for some failures,
          // the URL — and a URL can carry a search term.
          error: err.type.name,
        ),
      );
    });
    handler.next(err);
  }

  _Pending _capture(RequestOptions options) => _Pending(
    _now(),
    options.method,
    options.uri.toString(),
    redactHeaders({
      for (final MapEntry(:key, :value) in options.headers.entries)
        key: value.toString(),
    }),
    redactBody(options.data),
  );

  // Another interceptor can answer before the request is sent (a cache, a stub), so a response
  // can arrive for a request this one never saw go out. It is captured now, from what is left.
  _Pending _pendingOf(RequestOptions options) =>
      options.extra[_pendingKey] as _Pending? ?? _capture(options);

  Map<String, String> _headersOf(Response<dynamic> response) => redactHeaders({
    for (final MapEntry(:key, :value) in response.headers.map.entries)
      key: value.join(', '),
  });

  // Reason for the catch: see the class comment. It is deliberately broad — the point is that
  // nothing this class does can change what the caller of the request sees. The failure is not
  // reported anywhere, because there is nowhere safe to put it: a log line is readable by other
  // tools on the device (`.claude/rules/security.md` §1).
  void _watch(void Function() capture) {
    try {
      capture();
    } catch (_) {}
  }
}

/// Adds the inspector to [dio], but only in a debug app; returns whether it did.
///
/// [enabled] is a parameter, not a constant, so the release case can be tested: under
/// `flutter test` [isDebugApp] is always true. That is all this parameter buys: a constant that
/// crosses a parameter is not folded, so it does not remove the interceptor from a release build.
/// `DioPublicHttp` tests `isDebugApp` itself, where the tree-shaker can see it (measured on the
/// release APK, step 14).
/// The gate is the app's environment, not the endpoint's (README §14): the inspector is opened
/// after pairing, when the endpoint can no longer be chosen.
bool installInspector(
  Dio dio,
  RequestInspector inspector, {
  bool enabled = isDebugApp,
}) {
  if (!enabled) return false;
  dio.interceptors.add(InspectorInterceptor(inspector));
  return true;
}
