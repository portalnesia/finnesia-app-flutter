/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/native/store/store_secure.dart';
import 'package:pos/session/session_holder.dart';

/// The plugin's own in-memory platform (its seam for tests: no `MethodChannel`, no Keystore),
/// with a way to make the next operation fail the way a broken Keystore does.
class FlakyPlatform extends TestFlutterSecureStoragePlatform
    with MockPlatformInterfaceMixin {
  FlakyPlatform() : super({});

  PlatformException? failure;

  void _failIfTold() {
    final f = failure;
    if (f != null) {
      failure = null;
      throw f;
    }
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    _failIfTold();
    return super.read(key: key, options: options);
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    _failIfTold();
    return super.write(key: key, value: value, options: options);
  }

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    _failIfTold();
    return super.delete(key: key, options: options);
  }
}

PlatformException brokenKeystore() =>
    PlatformException(code: 'KeyStoreException', message: 'could not decrypt');

void main() {
  late FlakyPlatform platform;
  late SecureStore store;

  setUp(() {
    platform = FlakyPlatform();
    FlutterSecureStoragePlatform.instance = platform;
    store = SecureStore();
  });

  group('SecureStore', () {
    test('reads back what it wrote', () async {
      await store.write('session', '{"a":1}');

      expect(await store.read('session'), '{"a":1}');
    });

    test('reads a key that is not there as null', () async {
      expect(await store.read('session'), isNull);
    });

    test('keeps the empty string as a value, and not as absence', () async {
      await store.write('session', '');

      expect(await store.read('session'), '');
    });

    test('replaces what was there', () async {
      await store.write('session', 'one');
      await store.write('session', 'two');

      expect(await store.read('session'), 'two');
    });

    test('keeps its keys apart', () async {
      await store.write('session', 'a');
      await store.write('device_id', 'b');

      expect(await store.read('session'), 'a');
      expect(await store.read('device_id'), 'b');
    });

    test(
      'removes a key, and removing one that is not there is not an error',
      () async {
        await store.write('session', 'a');

        await store.remove('session');
        await store.remove('never_written');

        expect(await store.read('session'), isNull);
      },
    );

    test('is a StorePort', () {
      expect(store, isA<StorePort>());
    });
  });

  // `StorePort` says a failing storage is not "the key is absent": reading a Keystore that
  // failed as "not paired" could send a cashier to re-pair a device that is in fact paired.
  group('a Keystore that fails', () {
    test('is a StoreException on read, not a missing value', () async {
      await store.write('session', 'a');
      platform.failure = brokenKeystore();

      await expectLater(store.read('session'), throwsA(isA<StoreException>()));
    });

    test('is a StoreException on write, and leaves what was there', () async {
      await store.write('session', 'old');
      platform.failure = brokenKeystore();

      await expectLater(
        store.write('session', 'new'),
        throwsA(isA<StoreException>()),
      );
      expect(await store.read('session'), 'old');
    });

    test('is a StoreException on remove', () async {
      await store.write('session', 'a');
      platform.failure = brokenKeystore();

      await expectLater(
        store.remove('session'),
        throwsA(isA<StoreException>()),
      );
    });

    test(
      'keeps what the platform threw as the cause, for a debugger',
      () async {
        platform.failure = brokenKeystore();

        await expectLater(
          store.read('session'),
          throwsA(
            isA<StoreException>().having(
              (e) => e.cause,
              'cause',
              isA<PlatformException>(),
            ),
          ),
        );
      },
    );

    // Exception text ends up in logs and crash reports; the value is a bearer token.
    test('says nothing about the key or the value', () async {
      platform.failure = PlatformException(
        code: 'KeyStoreException',
        message: 'failed on tok_secret_value',
        details: 'session=tok_secret_value',
      );

      await expectLater(
        store.write('session', 'tok_secret_value'),
        throwsA(
          isA<StoreException>().having(
            (e) => e.toString(),
            'text',
            allOf(
              isNot(contains('tok_secret_value')),
              isNot(contains('session')),
            ),
          ),
        ),
      );
    });

    test('works again once the platform does', () async {
      platform.failure = brokenKeystore();
      await expectLater(store.read('session'), throwsA(isA<StoreException>()));

      await store.write('session', 'a');

      expect(await store.read('session'), 'a');
    });
  });

  // The whole point of a real store: the session it holds survives the app being closed. A
  // second `SessionHolder` over the same storage stands in for the next launch.
  group('the session on it', () {
    const paired = PosSession(
      baseUrl: 'https://erp.perusahaan.com',
      companyId: 'comp_1',
      outletId: 'out_1',
      sessionToken: 'tok_secret_value',
      sessionRefreshToken: 'refresh_secret_value',
    );

    test('is there at the next launch', () async {
      await SessionHolder(store).save(paired);

      final nextLaunch = SessionHolder(SecureStore());
      await nextLaunch.hydrate();

      expect(nextLaunch.current, paired);
    });

    test('is gone after a reset', () async {
      final holder = SessionHolder(store);
      await holder.save(paired);
      await holder.clear();

      final nextLaunch = SessionHolder(SecureStore());
      await nextLaunch.hydrate();

      expect(nextLaunch.current, isNull);
    });

    test(
      'is not read as "not paired" when the Keystore fails at launch',
      () async {
        await SessionHolder(store).save(paired);
        platform.failure = brokenKeystore();

        await expectLater(
          SessionHolder(SecureStore()).hydrate(),
          throwsA(isA<StoreException>()),
        );
      },
    );
  });
}
