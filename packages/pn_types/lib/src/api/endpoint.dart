/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'client.dart';
import 'http_method.dart';
import 'page.dart';

/// The path parameter of every endpoint that addresses one record: `/shifts/:id`.
typedef ById = ({String id});

// `call` lives on the endpoint VALUE, not on the client. With `api.call(endpoint, data)`
// the payload type is inferred freely and `12345` for a `CheckoutDTO` compiles; with
// `PosApi.checkout.call(api, 12345)` the type is fixed by the value and it does not.
// Probed with `dart analyze` — see `plan/api-client/README.md` §1.

/// A GET without path parameters. No body, so nothing to get wrong.
class ReadEndpoint<Res> {
  const ReadEndpoint(this.path, this.parse);

  final String path;
  final Res Function(Object? data) parse;

  HttpMethod get method => HttpMethod.get;

  Future<Res> call(ApiClient api, {Map<String, Object?>? query}) =>
      api.request(method: method, path: path, query: query, parse: parse);
}

/// A GET for a list the cashier scrolls: the rows and the cursor of the next page, where
/// [ReadEndpoint] would keep the rows and drop the cursor.
class PagedEndpoint<Item> {
  const PagedEndpoint(this.path, this.parse);

  final String path;
  final List<Item> Function(Object? data) parse;

  HttpMethod get method => HttpMethod.get;

  /// The first page, or the one after [cursor] (the `nextCursor` of the page before).
  Future<CursorPage<Item>> call(
    ApiClient api, {
    String? cursor,
    Map<String, Object?>? query,
  }) => api.requestPaged(
    method: method,
    path: path,
    query: {...?query, if (cursor != null) 'next_cursor': cursor},
    parse: parse,
  );
}

/// A GET with path parameters. [P] is a record, and the path is built from its fields, so a
/// parameter that is not given is a compile error rather than a request to `/things/:id`.
class ReadEndpointP<P extends Record, Res> {
  const ReadEndpointP(this.buildPath, this.parse);

  final String Function(P params) buildPath;
  final Res Function(Object? data) parse;

  HttpMethod get method => HttpMethod.get;

  Future<Res> call(ApiClient api, P params, {Map<String, Object?>? query}) =>
      api.request(
        method: method,
        path: buildPath(params),
        query: query,
        parse: parse,
      );
}

/// A POST/PUT/PATCH/DELETE without path parameters. [Req] is the typed request value and
/// [encode] turns it into the JSON the server expects.
class WriteEndpoint<Req, Res> {
  const WriteEndpoint(this.method, this.path, this.parse, this.encode);

  final HttpMethod method;
  final String path;
  final Res Function(Object? data) parse;
  final Object? Function(Req data) encode;

  Future<Res> call(ApiClient api, Req data, {Map<String, Object?>? query}) =>
      api.request(
        method: method,
        path: path,
        body: encode(data),
        query: query,
        parse: parse,
      );
}

/// A write that addresses one record: `POST /shifts/:id/close`.
///
/// The sketch in the plan had three endpoint classes; `pos.shifts.close` and
/// `pos.shifts.recordCashMovement` need this fourth.
class WriteEndpointP<P extends Record, Req, Res> {
  const WriteEndpointP(this.method, this.buildPath, this.parse, this.encode);

  final HttpMethod method;
  final String Function(P params) buildPath;
  final Res Function(Object? data) parse;
  final Object? Function(Req data) encode;

  Future<Res> call(
    ApiClient api,
    P params,
    Req data, {
    Map<String, Object?>? query,
  }) => api.request(
    method: method,
    path: buildPath(params),
    body: encode(data),
    query: query,
    parse: parse,
  );
}

/// A request body for an endpoint whose typed DTO is not ported yet: the JSON map as is.
///
/// A marker like `parseRaw`: it gives up the compile-time check on the payload, and is
/// replaced by a real DTO and `encode` in the change that ports it.
typedef JsonMap = Map<String, Object?>;

JsonMap encodeRaw(JsonMap data) => data;
