/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';

import 'http_method.dart';

part 'transport.freezed.dart';

/// One request as the client builds it, before any host or credential is known.
///
/// [path] is relative to the tenant host and already carries the query string
/// (`/api/v1/products?page=1`). Turning it into an absolute URL, adding `Authorization`
/// and the tenant header, and persisting a rotated token are the transport's job — the
/// client cannot know the host (it comes from pairing) and must not hold the token.
///
/// The source splits this across `resolveUrl`, `authHeaders` and `send` on `Transport`;
/// the Dart seam is one call, so a fake has one method to implement.
@freezed
abstract class TransportRequest with _$TransportRequest {
  const factory TransportRequest({
    required HttpMethod method,
    required String path,
    @Default(<String, String>{}) Map<String, String> headers,

    /// Already encoded (JSON text). The client sets `Content-Type`.
    String? body,
  }) = _TransportRequest;
}

/// No response was obtained: the connection dropped, timed out, or had no route.
///
/// Any response that arrives — including 4xx and 5xx — is a [TransportResponse], never
/// this. The distinction matters to the offline queue: it retries the first and must not
/// retry a rejection.
class TransportException implements Exception {
  TransportException(this.message, {this.cause});

  final String message;

  /// Whatever the HTTP stack threw, for a debugger. Never printed: it can carry the
  /// request URL, and a URL can carry a search term.
  final Object? cause;

  @override
  String toString() => 'TransportException: $message';
}

/// The single seam between the API client and the network.
///
/// Implementations: the POS transport in `apps/pos` (bearer, tenant header, token
/// rotation, over `dio`) and [FakeApiTransport] for tests. Throws [TransportException]
/// when there is no response; returns a [TransportResponse] for every status.
abstract interface class ApiTransport {
  Future<TransportResponse> send(TransportRequest request);
}

/// What came back from the server — any status, including 4xx and 5xx.
///
/// The Dart counterpart of `TransportResponse` in
/// `finnesia-monorepo/packages/shared/src/api/internal/transport.ts`, in a shape that does
/// not mention `dio`: a fake can build one without a single HTTP object, so `dart test`
/// stays pure. [body] is the raw text; the client decides whether it is JSON.
class TransportResponse {
  TransportResponse({
    required this.status,
    this.statusText = '',
    Map<String, String> headers = const {},
    this.body,
  }) : headers = Map.unmodifiable({
         for (final e in headers.entries) e.key.toLowerCase(): e.value,
       });

  final int status;
  final String statusText;

  /// Names are lowercased on the way in: HTTP names are case-insensitive, and the
  /// runtime decides the casing it hands back.
  final Map<String, String> headers;

  final String? body;

  /// Same rule as fetch's `Response.ok`. Derived, not stored, so no response can say
  /// success while carrying a 500.
  bool get ok => status >= 200 && status < 300;

  /// The value of [name], whatever its casing, or `null`.
  String? header(String name) => headers[name.toLowerCase()];
}
