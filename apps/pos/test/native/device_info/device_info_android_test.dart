/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/device_info_fake.dart';
import 'package:pn_types/src/native/device_info_port.dart';
import 'package:pos/native/device_info/active.dart';
import 'package:pos/native/device_info/device_info_android.dart';

/// `android_id`'s own seam for tests: the method channel it invokes, with no platform behind it.
/// The plugin has no platform-interface class to swap, so the channel is what a test can reach.
///
/// Answers [result], or throws [failure], and records how often it was asked.
class _FakeChannel {
  _FakeChannel() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidIdInfo.channel, _handle);
  }

  static const _channel = MethodChannel('android_id');
  static const _name = 'getId';

  String? result = 'android-abc';
  Object? failure;
  var calls = 0;

  Future<Object?> _handle(MethodCall call) async {
    if (call.method != _name) return null;
    calls++;
    if (failure != null) throw failure!;
    return result;
  }

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidIdInfo', () {
    late _FakeChannel channel;

    setUp(() => channel = _FakeChannel());
    tearDown(() => channel.dispose());

    test('returns the identifier the platform reports', () async {
      expect(await AndroidIdInfo().androidId(), 'android-abc');
    });

    // A device that refuses to report one answers with an empty string. That is no identifier,
    // not an identifier of "" — the caller falls back rather than sending a blank fingerprint
    // to a NOT NULL column.
    test('reads an empty answer as no identifier', () async {
      channel.result = '';

      expect(await AndroidIdInfo().androidId(), isNull);
    });

    test('reads a null answer as no identifier', () async {
      channel.result = null;

      expect(await AndroidIdInfo().androidId(), isNull);
    });

    // A platform that fails is NOT the same as a platform with no identifier: it may well have
    // one. Reported as an exception so the caller does not fall back and register a duplicate
    // device row.
    test('reports a failing platform rather than answering null', () async {
      channel.failure = PlatformException(code: 'UNAVAILABLE');

      await expectLater(
        AndroidIdInfo().androidId(),
        throwsA(
          isA<DeviceInfoException>().having(
            (e) => e.cause,
            'cause',
            isA<PlatformException>(),
          ),
        ),
      );
    });

    // Not Android, or a build without the plugin: no identifier is the truthful answer, and the
    // caller's fallback is exactly right there.
    test('reads a missing plugin as no identifier', () async {
      channel.failure = MissingPluginException('no implementation');

      expect(await AndroidIdInfo().androidId(), isNull);
    });

    // The identifier is a credential to the server: it must not travel in the exception.
    test('does not put the identifier in what it throws', () async {
      channel.failure = PlatformException(code: 'UNAVAILABLE');

      await expectLater(
        AndroidIdInfo().androidId(),
        throwsA(
          isA<DeviceInfoException>().having(
            (e) => e.toString(),
            'text',
            isNot(contains('android-abc')),
          ),
        ),
      );
    });
  });

  group('describe', () {
    // What `device_info_plus` reads from `android.os.Build`: only the parts this app uses matter.
    AndroidDeviceInfo android({String manufacturer = 'samsung'}) =>
        AndroidDeviceInfo.fromMap({
          'version': {
            'release': '14',
            'codename': 'REL',
            'incremental': 'x',
            'sdkInt': 34,
          },
          'board': 'b',
          'bootloader': 'b',
          'brand': 'samsung',
          'device': 'd',
          'display': 'd',
          'fingerprint': 'f',
          'hardware': 'h',
          'host': 'h',
          'id': 'i',
          'manufacturer': manufacturer,
          'model': 'SM-X110',
          'product': 'p',
          'tags': 't',
          'type': 't',
          'isPhysicalDevice': true,
          'freeDiskSize': 0,
          'totalDiskSize': 0,
          'isLowRamDevice': false,
          'physicalRamSize': 0,
          'availableRamSize': 0,
        });

    WindowsDeviceInfo windows() => WindowsDeviceInfo(
      computerName: 'KASIR-1',
      numberOfCores: 4,
      systemMemoryInMegabytes: 8192,
      userName: 'kasir',
      majorVersion: 10,
      minorVersion: 0,
      buildNumber: 26220,
      platformId: 2,
      csdVersion: '',
      servicePackMajor: 0,
      servicePackMinor: 0,
      suitMask: 0,
      productType: 1,
      reserved: 0,
      buildLab: '',
      buildLabEx: '',
      digitalProductId: Uint8List(0),
      displayVersion: '25H2',
      editionId: 'Core',
      installDate: DateTime(2026),
      productId: '',
      productName: 'Windows 11 Home',
      registeredOwner: '',
      releaseId: '',
      deviceId: '{x}',
    );

    test(
      'names an Android tablet: the release and the maker with the model',
      () async {
        final info = AndroidIdInfo(
          plugin: DeviceInfoPlugin.setMockInitialValues(
            androidDeviceInfo: android(),
          ),
          platform: TargetPlatform.android,
        );

        expect(await info.describe(), (
          platform: 'android',
          osVersion: '14',
          deviceModel: 'samsung SM-X110',
        ));
      },
    );

    test(
      'names a Windows machine by its version, and has no model to give',
      () async {
        final info = AndroidIdInfo(
          plugin: DeviceInfoPlugin.setMockInitialValues(
            windowsDeviceInfo: windows(),
          ),
          platform: TargetPlatform.windows,
        );

        expect(await info.describe(), (
          platform: 'windows',
          osVersion: '10.0.26220',
          deviceModel: null,
        ));
      },
    );

    // Display-only: a platform that cannot be asked must not stop a tablet from pairing.
    test(
      'still says which platform it is when the platform cannot be asked',
      () async {
        final info = AndroidIdInfo(platform: TargetPlatform.android);

        expect(await info.describe(), (
          platform: 'android',
          osVersion: null,
          deviceModel: null,
        ));
      },
    );
  });

  group('active DeviceInfoPort', () {
    test('is the real one until something replaces it', () {
      expect(deviceInfo, isA<AndroidIdInfo>());
    });

    test('can be replaced, and then hands out the replacement', () {
      final original = deviceInfo;
      addTearDown(() => setDeviceInfo(original));
      final fake = FakeDeviceInfo(id: 'x');

      setDeviceInfo(fake);

      expect(deviceInfo, same(fake));
    });

    test('can be put back', () {
      final original = deviceInfo;

      setDeviceInfo(FakeDeviceInfo(id: 'x'));
      setDeviceInfo(original);

      expect(deviceInfo, same(original));
    });
  });
}
