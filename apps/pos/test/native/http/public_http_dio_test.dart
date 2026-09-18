/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pos/http/inspector/request_inspector.dart';
import 'package:pos/native/http/public_http_dio.dart';

import '../../support/dio_fakes.dart';

const host = 'https://apps.finnesia.com';

const stock = TransportRequest(
  method: HttpMethod.get,
  path: '/api/v1/pos/stock',
);

/// The port over a real [Dio] whose wire is [FakeAdapter]: everything the port does is real, and
/// nothing leaves the process.
class Rig {
  Rig(
    Future<ResponseBody> Function(RequestOptions) handler, {
    RequestInspector? inspector,
  }) : adapter = FakeAdapter(handler) {
    http = DioPublicHttp(inspector: inspector, adapter: adapter);
  }

  final FakeAdapter adapter;
  late final DioPublicHttp http;

  /// The one request that reached the wire.
  RequestOptions get wire {
    expect(adapter.sent, hasLength(1));
    return adapter.sent.single;
  }
}

void main() {
  group('the request', () {
    test('goes to the host it was given, at the path it was given', () async {
      final rig = Rig((_) async => json({}));

      await rig.http.send(host, stock);

      expect(rig.wire.uri.toString(), '$host/api/v1/pos/stock');
      expect(rig.wire.method, 'GET');
    });

    test('joins the host and the path with exactly one slash', () async {
      for (final base in [host, '$host/']) {
        final rig = Rig((_) async => json({}));

        await rig.http.send(base, stock);

        expect(rig.wire.uri.toString(), '$host/api/v1/pos/stock', reason: base);
      }
    });

    test('keeps the query string of the path', () async {
      final rig = Rig((_) async => json({}));

      await rig.http.send(
        host,
        const TransportRequest(
          method: HttpMethod.get,
          path: '/api/v1/products?search=kopi%20susu&page=2',
        ),
      );

      expect(rig.wire.uri.query, 'search=kopi%20susu&page=2');
    });

    test('carries the method, the headers and the body it was given', () async {
      final rig = Rig((_) async => json({}));

      await rig.http.send(
        host,
        const TransportRequest(
          method: HttpMethod.post,
          path: '/api/v1/pos/sales/checkout',
          headers: {
            'Authorization': 'Bearer tok_secret_value',
            'X-Company-ID': 'comp_1',
            'Content-Type': 'application/json',
          },
          body: '{"total":1000}',
        ),
      );

      expect(rig.wire.method, 'POST');
      expect(rig.wire.headers['Authorization'], 'Bearer tok_secret_value');
      expect(rig.wire.headers['X-Company-ID'], 'comp_1');
      expect(rig.wire.data, '{"total":1000}');
    });

    test('has a method for every verb the registry uses', () async {
      for (final method in HttpMethod.values) {
        final rig = Rig((_) async => json({}));

        await rig.http.send(host, TransportRequest(method: method, path: '/x'));

        expect(rig.wire.method, method.wire);
      }
    });

    // The transport is slow tablets on shop wifi: a request that never ends holds the till.
    test('gives up on a connection or an answer that never comes', () async {
      final rig = Rig((_) async => json({}));

      await rig.http.send(host, stock);

      expect(rig.wire.connectTimeout, isNotNull);
      expect(rig.wire.receiveTimeout, isNotNull);
    });
  });

  group('the answer', () {
    test('carries its status, its reason and its body as text', () async {
      final rig = Rig(
        (_) async => ResponseBody.fromString(
          '{"data":{"total":1500}}',
          201,
          statusMessage: 'Created',
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      final response = await rig.http.send(host, stock);

      expect(response.status, 201);
      expect(response.statusText, 'Created');
      expect(response.body, '{"data":{"total":1500}}');
      expect(response.ok, isTrue);
    });

    // The client decides whether a body is JSON. A port that parsed it would throw on the
    // gateway's error page before the client could say what it was.
    test(
      'does not parse the body, so a page that is not JSON still arrives',
      () async {
        final rig = Rig(
          (_) async => ResponseBody.fromString(
            'upstream connect error',
            502,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

        final response = await rig.http.send(host, stock);

        expect(response.status, 502);
        expect(response.body, 'upstream connect error');
      },
    );

    test(
      'has its headers with the lower-case names TransportResponse expects',
      () async {
        final rig = Rig(
          (_) async => json(
            {},
            headers: {
              'X-Session-Token': ['tok_rotated'],
              'X-Session-Expires': ['2030-01-01T00:00:00Z'],
              'Retry-After': ['12'],
            },
          ),
        );

        final response = await rig.http.send(host, stock);

        expect(response.header('x-session-token'), 'tok_rotated');
        expect(response.header('X-Session-Expires'), '2030-01-01T00:00:00Z');
        expect(response.header('retry-after'), '12');
      },
    );

    test('joins a header that came with several values', () async {
      final rig = Rig(
        (_) async => json(
          {},
          headers: {
            'x-note': ['a', 'b'],
          },
        ),
      );

      final response = await rig.http.send(host, stock);

      expect(response.header('x-note'), 'a, b');
    });

    test('has an empty body as an empty body', () async {
      final rig = Rig((_) async => ResponseBody.fromString('', 204));

      final response = await rig.http.send(host, stock);

      expect(response.status, 204);
      expect(response.body, anyOf(isNull, isEmpty));
    });

    // The client, and the offline queue behind it, tell a rejection from "no answer": a 4xx or
    // a 5xx is an answer.
    test('returns a 4xx or a 5xx as an answer, not as an exception', () async {
      for (final status in [400, 401, 404, 422, 429, 500, 503]) {
        final rig = Rig((_) async => json({'error': 'x'}, status: status));

        final response = await rig.http.send(host, stock);

        expect(response.status, status);
        expect(response.ok, isFalse);
      }
    });
  });

  // security.md §1.1: the token goes to the host it was paired with and nowhere else. This
  // port carries the bearer token and the refresh token, so a redirect to another host must
  // not be followed with them attached. The Location header is data for the caller; the port
  // does not act on it.
  group('a redirect', () {
    test('is not followed', () async {
      final rig = Rig(
        (_) async => ResponseBody.fromString(
          '',
          302,
          headers: {
            'location': ['https://evil.example/collect'],
          },
        ),
      );

      await rig.http.send(
        host,
        const TransportRequest(
          method: HttpMethod.get,
          path: '/api/v1/x',
          headers: {'Authorization': 'Bearer tok_secret_value'},
        ),
      );

      expect(rig.wire.followRedirects, isFalse);
      expect(rig.adapter.sent, hasLength(1));
    });

    test('comes back to the caller as the answer it is', () async {
      final rig = Rig(
        (_) async => ResponseBody.fromString(
          '',
          307,
          headers: {
            'location': ['https://evil.example/collect'],
          },
        ),
      );

      final response = await rig.http.send(host, stock);

      expect(response.status, 307);
      expect(response.ok, isFalse);
      expect(response.header('location'), 'https://evil.example/collect');
    });
  });

  group('no answer at all', () {
    final failures = <String, DioException Function(RequestOptions)>{
      'connectionTimeout': (o) => DioException.connectionTimeout(
        timeout: const Duration(seconds: 15),
        requestOptions: o,
      ),
      'sendTimeout': (o) => DioException.sendTimeout(
        timeout: const Duration(seconds: 30),
        requestOptions: o,
      ),
      'receiveTimeout': (o) => DioException.receiveTimeout(
        timeout: const Duration(seconds: 30),
        requestOptions: o,
      ),
      'connectionError': (o) => DioException.connectionError(
        requestOptions: o,
        reason: 'no route to host',
      ),
      'badCertificate': (o) => DioException.badCertificate(requestOptions: o),
    };

    for (final MapEntry(key: type, value: build) in failures.entries) {
      test('is a TransportException for $type', () async {
        final rig = Rig((options) async => throw build(options));

        await expectLater(
          rig.http.send(host, stock),
          throwsA(isA<TransportException>()),
        );
      });
    }

    test('is a TransportException for whatever else the stack threw', () async {
      final rig = Rig((_) async => throw StateError('socket closed'));

      await expectLater(
        rig.http.send(host, stock),
        throwsA(isA<TransportException>()),
      );
    });

    test('keeps what the stack threw as the cause, for a debugger', () async {
      final rig = Rig(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'no route to host',
        ),
      );

      await expectLater(
        rig.http.send(host, stock),
        throwsA(
          isA<TransportException>().having(
            (e) => e.cause,
            'cause',
            isA<DioException>(),
          ),
        ),
      );
    });

    // The exception's text ends up in logs and crash reports; the URL can carry a search term.
    test('says nothing about the URL, the headers or the body', () async {
      final rig = Rig(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'lookup of apps.finnesia.com failed',
        ),
      );

      await expectLater(
        rig.http.send(
          host,
          const TransportRequest(
            method: HttpMethod.post,
            path: '/api/v1/customers?search=budi',
            headers: {'Authorization': 'Bearer tok_secret_value'},
            body: '{"password":"hunter2"}',
          ),
        ),
        throwsA(
          isA<TransportException>().having(
            (e) => e.toString(),
            'text',
            allOf(
              isNot(contains('finnesia.com')),
              isNot(contains('budi')),
              isNot(contains('tok_secret_value')),
              isNot(contains('hunter2')),
            ),
          ),
        ),
      );
    });
  });

  group('the inspector', () {
    test(
      'records what passes through it, redacted, when one is given',
      () async {
        final inspector = RequestInspector();
        final rig = Rig((_) async => json({'ok': true}), inspector: inspector);

        await rig.http.send(
          host,
          const TransportRequest(
            method: HttpMethod.get,
            path: '/api/v1/x',
            headers: {'Authorization': 'Bearer tok_secret_value'},
          ),
        );

        final entry = inspector.entries.single;
        expect(entry.url, '$host/api/v1/x');
        expect(entry.requestHeaders['Authorization'], 'Bearer ***');
      },
    );

    test('is not needed', () async {
      final rig = Rig((_) async => json({}));

      await expectLater(rig.http.send(host, stock), completes);
    });
  });
}
