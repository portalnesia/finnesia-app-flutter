/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/native/analytics/analytics_firebase.dart';

/// Firebase Analytics' `logEvent` goes through Pigeon
/// (`firebase_analytics_platform_interface`'s `messages.pigeon.dart`), not the legacy raw
/// `MethodChannel` its own `channel` constant names — verified by reading the method channel
/// implementation, not assumed. No `TestFirebaseAnalyticsHostApi` is exported (unlike
/// Crashlytics' `test.dart`), and the Pigeon codec class itself is private
/// (`_PigeonCodec`) — so this mocks the exact channel name Pigeon generates, with the plain
/// `StandardMessageCodec` it delegates to for every type this payload uses (`Map`, `String`,
/// `num`, `bool` — no custom Pigeon class appears in a `logEvent` call).
const _logEventChannelName =
    'dev.flutter.pigeon.firebase_analytics_platform_interface.FirebaseAnalyticsHostApi.logEvent';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  final channel = const BasicMessageChannel<Object?>(
    _logEventChannelName,
    StandardMessageCodec(),
  );

  List<Object?>? lastEvent;

  setUp(() {
    lastEvent = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(channel, (message) async {
          lastEvent = message as List<Object?>?;
          return <Object?>[null];
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(channel, null);
  });

  group('FirebaseAnalyticsPort', () {
    test('logs the event name and parameters', () async {
      await FirebaseAnalyticsPort().logEvent(
        'checkout_completed',
        parameters: {'total': 45000},
      );

      final event = lastEvent!.single as Map;
      expect(event['eventName'], 'checkout_completed');
      expect(event['parameters'], {'total': 45000});
    });

    test('logs an event with no parameters', () async {
      await FirebaseAnalyticsPort().logEvent('shift_closed');

      final event = lastEvent!.single as Map;
      expect(event['parameters'], isNull);
    });

    // The failure path the port rules require (`.claude/rules/native-ports.md` §4): losing an
    // event must never take a sale down with it.
    test('does not throw when the platform cannot log the event', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(channel, (message) async {
            throw PlatformException(code: 'unavailable');
          });

      await expectLater(
        FirebaseAnalyticsPort().logEvent('checkout_completed'),
        completes,
      );
    });
  });
}
