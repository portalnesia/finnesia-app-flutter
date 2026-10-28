/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/native/device_info_fake.dart';
import 'package:pn_types/src/native/push_messaging_fake.dart';
import 'package:pn_types/src/native/push_messaging_port.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/notifications/push_lifecycle_controller.dart';
import 'package:pos/session/session_holder.dart';

const _signedIn = PosSession(
  baseUrl: 'https://erp.perusahaan.com',
  companyId: 'comp_1',
  outletId: 'out_1',
  sessionToken: 'session_for_test',
  user: SessionUser(id: 'cashier_1'),
);

TransportResponse _noContent() =>
    TransportResponse(status: 204, headers: const {}, body: null);

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('PushLifecycleController', () {
    late FakeStorePort store;
    late SessionHolder session;
    late FakeApiTransport transport;
    late FakePushMessaging messaging;
    late FakeDeviceInfo deviceInfo;
    late PushLifecycleController controller;

    setUp(() async {
      store = FakeStorePort();
      session = SessionHolder(store);
      await session.hydrate();
      transport = FakeApiTransport();
      messaging = FakePushMessaging();
      deviceInfo = FakeDeviceInfo(id: 'android-install-id');
      controller = PushLifecycleController(
        client: ApiClient(transport: transport, language: () => 'id'),
        messaging: messaging,
        session: session,
        deviceInfo: deviceInfo,
        locale: () => 'id',
      );
    });

    tearDown(() async {
      controller.dispose();
      await messaging.dispose();
    });

    test('does not request permission at startup or while the cashier is signed out', () async {
      messaging.status = PushAuthorizationStatus.notDetermined;
      await controller.start();

      expect(messaging.requestPermissionCalls, 0);
      expect(transport.requests, isEmpty);
      expect(
        controller.authorizationStatus.value,
        PushAuthorizationStatus.notDetermined,
      );

      await session.save(_signedIn);
      await _flushEvents();
      expect(transport.requests, isEmpty);
    });

    test(
      'registers a token only after permission and an authenticated session',
      () async {
        messaging.status = PushAuthorizationStatus.authorized;
        messaging.token = 'fcm-token-1';
        transport.respond(_noContent());
        await controller.start();

        expect(transport.requests, hasLength(0));
        await session.save(_signedIn);
        await _flushEvents();

        final request = transport.requests.single;
        expect(request.path, '/api/v1/push-tokens');
        expect(jsonDecode(request.body!), {
          'token': 'fcm-token-1',
          'platform': 'android',
          'app': 'pos',
          'device_id': 'android-install-id',
          'locale': 'id',
        });
        expect(messaging.requestPermissionCalls, 0);
      },
    );

    test(
      'asks permission only on explicit request and registers after grant',
      () async {
        await session.save(_signedIn);
        messaging.status = PushAuthorizationStatus.notDetermined;
        messaging.permissionResult = PushAuthorizationStatus.authorized;
        transport.respond(_noContent());
        await controller.start();

        expect(transport.requests, isEmpty);
        final result = await controller.requestPermission();
        await _flushEvents();

        expect(result, PushAuthorizationStatus.authorized);
        expect(messaging.requestPermissionCalls, 1);
        expect(transport.requests.single.path, '/api/v1/push-tokens');
      },
    );

    test(
      'updates the backend on token refresh and ignores foreground messages',
      () async {
        await session.save(_signedIn);
        messaging.status = PushAuthorizationStatus.authorized;
        transport.respond(_noContent());
        transport.respond(_noContent());
        await controller.start();
        final opened = <PushMessage>[];
        final subscription = controller.openedMessages.listen(opened.add);

        messaging.emitForegroundMessage(
          PushMessage(data: const {'notification_id': 'foreground_1'}),
        );
        messaging.emitTokenRefresh('fcm-token-2');
        await _flushEvents();

        expect(opened, isEmpty);
        expect(transport.requests, hasLength(2));
        expect(
          jsonDecode(transport.requests.last.body!)['token'],
          'fcm-token-2',
        );

        messaging.emitOpenedMessage(
          PushMessage(
            data: const {
              'notification_id': 'notification_42',
              'company_id': 'comp_1',
              'link': 'https://untrusted.example/ignore',
            },
          ),
        );
        await _flushEvents();

        expect(opened, hasLength(1));
        expect(opened.single.data['notification_id'], 'notification_42');
        expect(opened.single.data, {
          'notification_id': 'notification_42',
          'company_id': 'comp_1',
        });
        await subscription.cancel();
      },
    );

    test(
      'delivers the terminated-launch tap after FCM is initialized',
      () async {
        await session.save(_signedIn);
        messaging.status = PushAuthorizationStatus.authorized;
        messaging.launchMessage = PushMessage(
          data: const {
            'notification_id': 'notification_launch',
            'company_id': 'comp_1',
            'link': 'https://untrusted.example/ignore',
          },
        );
        transport.respond(_noContent());
        final opened = <PushMessage>[];
        final subscription = controller.openedMessages.listen(opened.add);

        await controller.start();
        await _flushEvents();

        expect(opened, hasLength(1));
        expect(opened.single.data, {
          'notification_id': 'notification_launch',
          'company_id': 'comp_1',
        });
        await subscription.cancel();
      },
    );

    test('does not forward tap data without a notification id', () async {
      await session.save(_signedIn);
      messaging.status = PushAuthorizationStatus.authorized;
      transport.respond(_noContent());
      await controller.start();
      final opened = <PushMessage>[];
      final subscription = controller.openedMessages.listen(opened.add);

      messaging.emitOpenedMessage(
        PushMessage(data: const {'company_id': 'comp_1'}),
      );
      await _flushEvents();

      expect(opened, isEmpty);
      await subscription.cancel();
    });

    test('registration failure does not interrupt startup', () async {
      await session.save(_signedIn);
      messaging.status = PushAuthorizationStatus.authorized;
      transport.respond(
        TransportResponse(
          status: 503,
          headers: const {'content-type': 'application/json'},
          body: '{"message":"temporarily unavailable"}',
        ),
      );

      await expectLater(controller.start(), completes);
      expect(transport.requests.single.path, '/api/v1/push-tokens');
    });

    test(
      'sign-out unregisters before the session credential is cleared',
      () async {
        await session.save(_signedIn);
        messaging.status = PushAuthorizationStatus.authorized;
        transport.respond(_noContent());
        transport.respond(_noContent());
        await controller.start();

        await controller.unregisterCurrentToken();

        expect(transport.requests.map((request) => request.path), [
          '/api/v1/push-tokens',
          '/api/v1/push-tokens/unregister',
        ]);
        expect(jsonDecode(transport.requests.last.body!), {
          'token': 'fcm-token-1',
        });
        expect(session.current?.sessionToken, _signedIn.sessionToken);
      },
    );
  });
}
