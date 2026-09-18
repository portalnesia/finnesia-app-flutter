/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:test/test.dart';

void main() {
  group('TransportResponse.ok', () {
    // Same rule as fetch's `Response.ok`. Derived from the status rather than stored, so
    // a fake cannot build a response that says success and carries a 500.
    test('is true for every 2xx', () {
      for (final status in [200, 201, 204, 299]) {
        expect(TransportResponse(status: status).ok, isTrue, reason: '$status');
      }
    });

    test('is false outside 2xx, at both edges', () {
      for (final status in [199, 300, 302, 400, 401, 404, 429, 500, 503]) {
        expect(
          TransportResponse(status: status).ok,
          isFalse,
          reason: '$status',
        );
      }
    });
  });

  group('TransportResponse.header', () {
    // HTTP header names are case-insensitive, and the runtime decides the casing it hands
    // back. The rotation header the POS transport must persist is read by a lowercase name.
    test('finds a header whatever its casing', () {
      final r = TransportResponse(
        status: 200,
        headers: {'X-Session-Token': 'abc'},
      );

      expect(r.header('x-session-token'), 'abc');
      expect(r.header('X-SESSION-TOKEN'), 'abc');
      expect(r.header('X-Session-Token'), 'abc');
    });

    test('is null for a header that is not there', () {
      expect(TransportResponse(status: 200).header('x-session-token'), isNull);
    });
  });

  group('TransportRequest', () {
    test('has no headers and no body unless it is given some', () {
      const r = TransportRequest(
        method: HttpMethod.get,
        path: '/api/v1/pos/stock',
      );

      expect(r.headers, isEmpty);
      expect(r.body, isNull);
    });

    // The fake's tests compare whole requests, and that reads better than five `expect`s.
    test('is equal to another request with the same content', () {
      const a = TransportRequest(
        method: HttpMethod.post,
        path: '/x',
        headers: {'Accept': 'application/json'},
        body: '{}',
      );
      const b = TransportRequest(
        method: HttpMethod.post,
        path: '/x',
        headers: {'Accept': 'application/json'},
        body: '{}',
      );

      expect(a, b);
      expect(a, isNot(b.copyWith(path: '/y')));
    });
  });

  group('TransportException', () {
    // "No response at all" (connection dropped, timeout, no route) is a different fact from
    // "the server said no". The offline queue retries the first and must not retry a 4xx,
    // so the seam reports it as its own type instead of a generic exception.
    test('is an Exception, distinct from ApiError', () {
      expect(TransportException('offline'), isA<Exception>());
    });

    test('prints the message', () {
      expect(TransportException('offline').toString(), contains('offline'));
    });

    // The cause is whatever the HTTP stack threw; it can carry the request URL, which can
    // carry a search term or a customer name. This string reaches logs and crash reports.
    test('does not print the cause', () {
      final e = TransportException(
        'offline',
        cause: Exception(
          'GET https://x.example/contacts?q=Budi+Santoso failed',
        ),
      );

      expect(e.toString(), isNot(contains('Budi')));
    });
  });
}
