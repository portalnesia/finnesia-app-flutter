/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/public_http_fake.dart';
import 'package:test/test.dart';

const activate = TransportRequest(
  method: HttpMethod.post,
  path: '/api/v1/pos/devices/activate',
  body: '{"code":"AB3K7M"}',
);

void main() {
  group('FakePublicHttp', () {
    // The whole point of the port: the host is an argument, because there is no session to
    // read it from yet.
    test(
      'records the host each request was sent to, with the request',
      () async {
        final http = FakePublicHttp()..respond(TransportResponse(status: 200));

        await http.send('https://apps.finnesia.com', activate);

        expect(http.calls, [
          (baseUrl: 'https://apps.finnesia.com', request: activate),
        ]);
      },
    );

    test('answers with the queued response', () async {
      final http = FakePublicHttp()
        ..respond(TransportResponse(status: 401, body: 'no'));

      final response = await http.send('https://apps.finnesia.com', activate);

      expect(response.status, 401);
      expect(response.body, 'no');
    });

    test('throws a queued failure, and still records the call', () async {
      final http = FakePublicHttp()..fail(TransportException('offline'));

      await expectLater(
        http.send('https://apps.finnesia.com', activate),
        throwsA(isA<TransportException>()),
      );
      expect(http.calls, hasLength(1));
    });

    test('refuses a request it has no answer queued for', () async {
      final http = FakePublicHttp();

      await expectLater(
        http.send('https://apps.finnesia.com', activate),
        throwsA(isA<StateError>()),
      );
    });
  });
}
