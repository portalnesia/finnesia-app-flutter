/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:test/test.dart';

const stock = TransportRequest(
  method: HttpMethod.get,
  path: '/api/v1/pos/stock',
);
const checkout = TransportRequest(
  method: HttpMethod.post,
  path: '/api/v1/pos/sales/checkout',
  headers: {'Authorization': 'Bearer secret-token'},
  body: '{"total":1000}',
);

void main() {
  group('FakeApiTransport', () {
    test(
      'answers with the queued responses, in the order they were queued',
      () async {
        final t = FakeApiTransport()
          ..respond(TransportResponse(status: 200, body: 'first'))
          ..respond(TransportResponse(status: 404, body: 'second'));

        expect((await t.send(stock)).body, 'first');
        expect((await t.send(stock)).status, 404);
      },
    );

    test('records every request it is sent, in order', () async {
      final t = FakeApiTransport()
        ..respond(TransportResponse(status: 200))
        ..respond(TransportResponse(status: 200));

      await t.send(stock);
      await t.send(checkout);

      expect(t.requests, [stock, checkout]);
    });

    // The failure path the port rules require: a test that cannot make the network fail
    // never exercises what the offline queue does about it.
    test('throws a queued failure', () async {
      final t = FakeApiTransport()..fail(TransportException('offline'));

      await expectLater(t.send(stock), throwsA(isA<TransportException>()));
    });

    test('records a request even when it fails', () async {
      final t = FakeApiTransport()..fail(TransportException('offline'));

      await expectLater(t.send(stock), throwsA(isA<TransportException>()));

      expect(t.requests, [stock]);
    });

    test('interleaves responses and failures in queue order', () async {
      final t = FakeApiTransport()
        ..respond(TransportResponse(status: 200, body: 'a'))
        ..fail(TransportException('offline'))
        ..respond(TransportResponse(status: 200, body: 'b'));

      expect((await t.send(stock)).body, 'a');
      await expectLater(t.send(stock), throwsA(isA<TransportException>()));
      expect((await t.send(stock)).body, 'b');
    });

    // A fake that silently answers 200 hides a request the test forgot to expect.
    test('refuses a request it has no answer queued for', () async {
      final t = FakeApiTransport();

      await expectLater(t.send(stock), throwsA(isA<StateError>()));
    });

    test('names the unexpected request, and still records it', () async {
      final t = FakeApiTransport();

      await expectLater(
        t.send(stock),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('GET'), contains('/api/v1/pos/stock')),
          ),
        ),
      );
      expect(t.requests, [stock]);
    });

    test('answers each queued outcome exactly once', () async {
      final t = FakeApiTransport()..respond(TransportResponse(status: 200));

      await t.send(stock);

      await expectLater(t.send(stock), throwsA(isA<StateError>()));
    });

    // The error text lands in test output and CI logs. The request's headers carry the
    // bearer token, so they must not be in it (`security.md` §1).
    test('does not put request headers or body in its error', () async {
      final t = FakeApiTransport();

      await expectLater(
        t.send(checkout),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(isNot(contains('secret-token')), isNot(contains('1000'))),
          ),
        ),
      );
    });
  });
}
