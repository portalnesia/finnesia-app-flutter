/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_crashlytics_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/native/crash_report/crash_report_firebase.dart';

/// `FirebaseCrashlyticsPlatform.instanceFor` asserts on this plugin constant at construction
/// time, so the default `setupFirebaseCoreMocks()` (which answers no plugin constants at all)
/// is not enough here — mirrored from `firebase_crashlytics-*/test/mock.dart`'s own
/// `MockFirebaseAppWithCollectionEnabled`, which exists for exactly this reason.
class _CoreHostApi implements TestFirebaseCoreHostApi {
  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async => _response(appName);

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async => [
    _response(defaultFirebaseAppName),
  ];

  @override
  Future<CoreFirebaseOptions> optionsFromResource() async => _options;

  static final _options = CoreFirebaseOptions(
    apiKey: 'fake-api-key',
    projectId: 'fake-project',
    appId: 'fake-app-id',
    messagingSenderId: 'fake-sender-id',
  );

  CoreInitializeResponse _response(String appName) => CoreInitializeResponse(
    name: appName,
    options: _options,
    pluginConstants: {
      'plugins.flutter.io/firebase_crashlytics': {
        'isCrashlyticsCollectionEnabled': true,
      },
    },
  );
}

/// Firebase Crashlytics' own Pigeon test seam — no `MethodChannel` mock, no device
/// (`firebase_crashlytics-*/test/mock.dart` uses the same two classes).
class _FakeHostApi implements TestFirebaseCrashlyticsHostApi {
  RecordErrorRequest? lastRecordError;
  String? lastLogMessage;

  @override
  Future<void> recordError(RecordErrorRequest request) async {
    lastRecordError = request;
  }

  @override
  Future<void> log(String message) async {
    lastLogMessage = message;
  }

  @override
  Future<bool> checkForUnsentReports() async => true;

  @override
  Future<void> crash() async {}

  @override
  Future<void> deleteUnsentReports() async {}

  @override
  Future<bool> didCrashOnPreviousExecution() async => false;

  @override
  Future<void> sendUnsentReports() async {}

  @override
  Future<bool> setCrashlyticsCollectionEnabled(bool enabled) async => enabled;

  @override
  Future<void> setUserIdentifier(String identifier) async {}

  @override
  Future<void> setCustomKey(String key, String value) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestFirebaseCoreHostApi.setUp(_CoreHostApi());

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  late _FakeHostApi hostApi;

  setUp(() {
    hostApi = _FakeHostApi();
    TestFirebaseCrashlyticsHostApi.setUp(hostApi);
  });

  group('FirebaseCrashReport', () {
    test('sends the exception, stack, reason and fatal flag', () async {
      await FirebaseCrashReport().recordError(
        Exception('printer disconnected mid-chunk'),
        StackTrace.current,
        reason: 'ble write',
        fatal: true,
      );

      final request = hostApi.lastRecordError!;
      expect(request.exception, contains('printer disconnected mid-chunk'));
      expect(request.reason, 'ble write');
      expect(request.fatal, isTrue);
    });

    test('defaults fatal to false', () async {
      await FirebaseCrashReport().recordError('boot warning', null);

      expect(hostApi.lastRecordError!.fatal, isFalse);
    });

    test('sends log breadcrumbs', () async {
      await FirebaseCrashReport().log('shift opened');

      expect(hostApi.lastLogMessage, 'shift opened');
    });

    // The failure path the port rules require (`.claude/rules/native-ports.md` §4): reporting a
    // crash must never cause a second one.
    test('does not throw when the platform cannot record the error', () async {
      TestFirebaseCrashlyticsHostApi.setUp(_ThrowingHostApi());

      await expectLater(
        FirebaseCrashReport().recordError('boot failure', null),
        completes,
      );
    });
  });
}

class _ThrowingHostApi extends _FakeHostApi {
  @override
  Future<void> recordError(RecordErrorRequest request) async {
    throw PlatformException(code: 'unavailable');
  }
}
