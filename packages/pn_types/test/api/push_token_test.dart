/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/push_token.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:test/test.dart';

TransportResponse _noContent() =>
    TransportResponse(status: 204, headers: const {}, body: null);

void main() {
  group('push token API', () {
    late FakeApiTransport transport;
    late ApiClient client;

    setUp(() {
      transport = FakeApiTransport();
      client = ApiClient(transport: transport, language: () => 'id');
    });

    test('registers a POS Android token using the server contract', () async {
      transport.respond(_noContent());

      await PushTokenApi.register.call(client, (
        token: 'fcm-token-1',
        platform: 'android',
        app: 'pos',
        deviceId: 'android-install-id',
        locale: 'id',
      ));

      final request = transport.requests.single;
      expect(request.method, HttpMethod.post);
      expect(request.path, '/api/v1/push-tokens');
      expect(jsonDecode(request.body!), {
        'token': 'fcm-token-1',
        'platform': 'android',
        'app': 'pos',
        'device_id': 'android-install-id',
        'locale': 'id',
      });
    });

    test(
      'omits the optional device id when the platform cannot provide one',
      () async {
        transport.respond(_noContent());

        await PushTokenApi.register.call(client, (
          token: 'fcm-token-2',
          platform: 'android',
          app: 'pos',
          deviceId: null,
          locale: 'en',
        ));

        expect(jsonDecode(transport.requests.single.body!), {
          'token': 'fcm-token-2',
          'platform': 'android',
          'app': 'pos',
          'locale': 'en',
        });
      },
    );

    test('unregisters a token through the authenticated endpoint', () async {
      transport.respond(_noContent());

      await PushTokenApi.unregister.call(client, (token: 'fcm-token-3'));

      final request = transport.requests.single;
      expect(request.method, HttpMethod.post);
      expect(request.path, '/api/v1/push-tokens/unregister');
      expect(jsonDecode(request.body!), {'token': 'fcm-token-3'});
    });
  });
}
