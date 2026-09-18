/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'api_error.dart';
import 'http_method.dart';
import 'page.dart';
import 'query.dart';
import 'response.dart';
import 'transport.dart';

/// Builds requests and reads responses. Knows nothing about hosts, tokens or `dio`.
///
/// Ported from `_callApi` in
/// `finnesia-monorepo/packages/shared/src/api/internal/api.base.ts`, minus what does not
/// apply to POS: CSRF (bearer auth), the `localStorage` company id (the tenant comes from
/// pairing and the transport supplies the header), and React Query.
class ApiClient {
  ApiClient({required this.transport, required this.language});

  final ApiTransport transport;

  /// The UI language for `Accept-Language`, read on every request so a change of language
  /// takes effect without rebuilding the client.
  final String Function() language;

  Future<Res> request<Res>({
    required HttpMethod method,
    required String path,
    required Res Function(Object? data) parse,
    Map<String, Object?>? query,
    Object? body,
  }) async {
    final (response, decoded) = await _send(method, path, query, body);
    return _read(response, decoded, () => parse(_unwrap(decoded)));
  }

  /// Like [request] for a list, keeping the `meta` cursor that [request] drops.
  ///
  /// The TypeScript client hangs `meta` on the returned array as an expando; Dart cannot, so
  /// the rows and the cursor come back together.
  Future<CursorPage<Item>> requestPaged<Item>({
    required HttpMethod method,
    required String path,
    required List<Item> Function(Object? data) parse,
    Map<String, Object?>? query,
  }) async {
    final (response, decoded) = await _send(method, path, query, null);
    return _read(
      response,
      decoded,
      () => CursorPage(
        items: parse(_unwrap(decoded)),
        nextCursor: _nextCursor(decoded),
      ),
    );
  }

  Future<(TransportResponse, Object?)> _send(
    HttpMethod method,
    String path,
    Map<String, Object?>? query,
    Object? body,
  ) async {
    final response = await transport.send(
      _buildRequest(method, path, query, body),
    );
    final decoded = _decodeJson(response);
    if (!response.ok) throw _failure(response, decoded);
    return (response, decoded);
  }

  Res _read<Res>(
    TransportResponse response,
    Object? decoded,
    Res Function() make,
  ) {
    try {
      return make();
    } on Object catch (e) {
      // A 200 whose payload no longer fits the model means the app is out of step with
      // the server. Only the three ways bad *data* fails are translated; anything else is
      // a bug in the parser and must not be hidden behind a server error.
      if (e is TypeError || e is FormatException || e is ArgumentError) {
        throw ApiError(
          'Unexpected response from server',
          status: response.status,
          data: decoded,
        );
      }
      rethrow;
    }
  }

  // An empty cursor is no cursor: a page that says "next is ''" would otherwise send the
  // list into a request for a page that does not exist.
  String? _nextCursor(Object? decoded) {
    final meta = decoded is Map<String, dynamic> ? decoded['meta'] : null;
    if (meta == null) return null;
    final cursor = PaginationMeta.fromJson(
      meta as Map<String, dynamic>,
    ).nextCursor;
    return cursor == null || cursor.isEmpty ? null : cursor;
  }

  ApiError _failure(TransportResponse response, Object? decoded) {
    final body = decoded is Map<String, dynamic> ? decoded : null;
    final error = body?['error'];
    final errorObject = error is Map<String, dynamic> ? error : null;

    // ponytail: this is `firstNonEmpty` from `pn_pos`'s js_compat, written again because
    // `pn_types` cannot import `pn_pos`. Move js_compat down to `pn_types` as its own
    // refactor when a second caller here needs it.
    String message = 'Request failed';
    for (final candidate in [
      body?['message'],
      errorObject?['description'],
      errorObject?['message'],
      response.statusText,
    ]) {
      if (candidate is String && candidate.isNotEmpty) {
        message = candidate;
        break;
      }
    }

    return ApiError(
      message,
      status: response.status,
      data: decoded,
      errorData: _parseErrorObject(errorObject),
      retryAfter: parseRetryAfter(
        status: response.status,
        header: response.header('retry-after'),
      ),
    );
  }

  // `ApiErrorTypes.fromJson` throws on a wrong shape where the source only casts. The
  // real status and message must survive a malformed `error` object, so a shape that does
  // not fit is dropped rather than allowed to replace the error it describes.
  ApiErrorTypes? _parseErrorObject(Map<String, dynamic>? errorObject) {
    if (errorObject == null) return null;
    try {
      return ApiErrorTypes.fromJson(errorObject);
    } on TypeError {
      return null;
    }
  }

  // Content-Type decides whether the body is read at all: a proxy's HTML error page must
  // not be parsed as though it were the API's answer. A body that claims JSON and is not
  // reads as no body, as in the source.
  Object? _decodeJson(TransportResponse response) {
    final body = response.body;
    final isJson = (response.header('content-type') ?? '').contains(
      'application/json',
    );
    if (body == null || !isJson) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  // The source asks `'data' in json`, not "is it truthy", so a legitimate 0, false, '' or
  // empty list is data. Without the key the whole body is the payload.
  Object? _unwrap(Object? decoded) =>
      decoded is Map<String, dynamic> && decoded.containsKey('data')
      ? decoded['data']
      : decoded;

  TransportRequest _buildRequest(
    HttpMethod method,
    String path,
    Map<String, Object?>? query,
    Object? body,
  ) {
    final queryString = query == null ? '' : buildQueryString(query);
    return TransportRequest(
      method: method,
      path: queryString.isEmpty
          ? path
          : '$path${path.contains('?') ? '&' : '?'}$queryString',
      headers: {
        'Accept': 'application/json',
        'Accept-Language': language(),
        if (body != null) 'Content-Type': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    );
  }
}
