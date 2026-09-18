/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/preferences_port.dart';
import 'package:pos/native/preferences/preferences_shared.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

// The plugin's own seam is `SharedPreferencesAsyncPlatform.instance`; the in-memory platform it
// ships is the fake, so nothing here touches real storage or a `MethodChannel`.

/// Fails on demand, the way a platform does when the storage cannot be opened.
final class _FailingPlatform extends InMemorySharedPreferencesAsync {
  _FailingPlatform() : super.empty();

  bool failing = false;

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    if (failing) throw PlatformException(code: 'unavailable');
    return super.getString(key, options);
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    if (failing) throw PlatformException(code: 'unavailable');
    return super.setString(key, value, options);
  }
}

void main() {
  late _FailingPlatform platform;
  late SharedPrefs store;

  setUp(() {
    platform = _FailingPlatform();
    SharedPreferencesAsyncPlatform.instance = platform;
    store = SharedPrefs();
  });

  group('shared preferences store', () {
    test('reads back what was written', () async {
      await store.write('language', 'en');

      expect(await store.read('language'), 'en');
    });

    test('reads null for a key nothing was written to', () async {
      expect(await store.read('theme'), isNull);
    });

    test('says so as a PreferencesException when it cannot read', () async {
      platform.failing = true;

      await expectLater(
        store.read('language'),
        throwsA(isA<PreferencesException>()),
      );
    });

    test('says so as a PreferencesException when it cannot write', () async {
      platform.failing = true;

      await expectLater(
        store.write('language', 'en'),
        throwsA(isA<PreferencesException>()),
      );
    });
  });
}
