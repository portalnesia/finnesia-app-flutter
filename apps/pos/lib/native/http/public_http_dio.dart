/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:dio/dio.dart';
import 'package:pn_types/src/api/environment.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pos/http/inspector/inspector_interceptor.dart';
import 'package:pos/http/inspector/request_inspector.dart';

final _trailingSlashes = RegExp(r'/+$');

/// [PublicHttpPort] over `dio`: the real HTTP stack under the API client, the pairing and the
/// login. Everything else that touches the network goes through here, so what it promises is
/// what the app promises.
///
/// - **Every status is an answer.** A 4xx or a 5xx comes back as a [TransportResponse], never as
///   an exception; only "no answer at all" is a [TransportException]. The client, and the offline
///   queue behind it, tell a rejection from a dropped connection by exactly that.
/// - **The body is text.** Whether it is JSON is the client's call: a port that parsed it would
///   throw on a gateway's error page before anything could say what it was.
/// - **A redirect is not followed** (`.claude/rules/security.md` §1.1). This port carries the
///   bearer token and the refresh token; following a redirect to another host would take them
///   there. The `Location` header reaches the caller as data, and the 3xx as the answer it is.
/// - **Nothing about the request is in an error.** The URL can carry a search term, and the
///   headers carry the token, so a [TransportException] has a fixed message per kind of failure
///   and keeps whatever dio threw only as its `cause`.
class DioPublicHttp implements PublicHttpPort {
  /// [inspector] is installed only in a debug app (README §14). [adapter] is what dio sends
  /// with; the default is dio's own, and a test passes one that never reaches a network.
  DioPublicHttp({
    RequestInspector? inspector,
    HttpClientAdapter? adapter,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration sendTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) : _dio = Dio(
         BaseOptions(
           connectTimeout: connectTimeout,
           sendTimeout: sendTimeout,
           receiveTimeout: receiveTimeout,
           responseType: ResponseType.plain,
           validateStatus: (_) => true,
           followRedirects: false,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    // `isDebugApp` is tested here, at the call site, and not only inside `installInspector`:
    // a constant that crosses a parameter is not folded, and the interceptor stayed in the
    // release binary (measured on the release APK, step 14).
    if (isDebugApp && inspector != null) installInspector(_dio, inspector);
  }

  final Dio _dio;

  @override
  Future<TransportResponse> send(
    String baseUrl,
    TransportRequest request,
  ) async {
    final Response<String> response;
    try {
      response = await _dio.request<String>(
        '${baseUrl.replaceFirst(_trailingSlashes, '')}${request.path}',
        data: request.body,
        options: Options(method: request.method.wire, headers: request.headers),
      );
    } on DioException catch (failure) {
      throw TransportException(_describe(failure.type), cause: failure);
    }
    return TransportResponse(
      status: response.statusCode ?? 0,
      statusText: response.statusMessage ?? '',
      headers: {
        for (final MapEntry(:key, :value) in response.headers.map.entries)
          key: value.join(', '),
      },
      body: response.data,
    );
  }

  // One fixed sentence per kind of failure: nothing about the request.
  String _describe(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout => 'the connection timed out',
    DioExceptionType.sendTimeout => 'sending the request timed out',
    DioExceptionType.receiveTimeout => 'waiting for the answer timed out',
    DioExceptionType.badCertificate => 'the server certificate was rejected',
    DioExceptionType.connectionError => 'there is no connection to the server',
    DioExceptionType.cancel => 'the request was cancelled',
    DioExceptionType.transformTimeout => 'reading the answer took too long',
    DioExceptionType.badResponse => 'the answer could not be used',
    DioExceptionType.unknown => 'the request failed',
  };
}
