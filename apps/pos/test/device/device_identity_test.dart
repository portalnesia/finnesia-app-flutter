/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/ulid.dart';
import 'package:pn_types/src/native/device_info_fake.dart';
import 'package:pn_types/src/native/device_info_port.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pos/device/device_identity.dart';

// The name rules were checked against the backend's own validator (`max=255` counts runes)
// and against the TypeScript module directly — see `plan/api-client/findings.md`.

/// A store whose reads work and whose writes fail: the disk that filled up after the first
/// read. `FakeStorePort.failNext` cannot aim at a write, because a read comes first.
class WritesFail implements StorePort {
  WritesFail(this.inner);

  final FakeStorePort inner;

  @override
  Future<String?> read(String key) => inner.read(key);

  @override
  Future<void> write(String key, String value) =>
      Future.error(StoreException('disk full'));

  @override
  Future<void> remove(String key) => inner.remove(key);
}

// The registry keys `pos_devices` on `(company_id, device_fingerprint)`, and activation upserts
// on it. A fingerprint that changes when the app is reinstalled therefore does not update the
// tablet's row: it adds one, and each reinstall eats a slot from the outlet's ten. The platform's
// own identifier is the only thing that survives an uninstall.
void main() {
  group('the fingerprint, from the platform', () {
    test('is the platform identifier when there is one', () async {
      final identity = await buildDeviceIdentity(
        FakeStorePort(),
        FakeDeviceInfo(id: 'android-abc'),
      );

      expect(identity.deviceFingerprint, 'android-abc');
    });

    // The whole point of switching to it: an uninstall takes the app's own storage with it, so a
    // stored identifier is gone by the next install while the platform's is not. Nothing is
    // written, which is what makes that true. (The read still happens — an existing value wins,
    // so a device paired before the switch keeps the row its fingerprint is keyed on.)
    test('stores nothing, so an uninstall cannot lose it', () async {
      final store = FakeStorePort();

      await buildDeviceIdentity(store, FakeDeviceInfo(id: 'android-abc'));

      expect(store.operations.where((o) => o.op == StoreOp.write), isEmpty);
      expect(store.values[deviceIdKey], isNull);
    });

    // A reinstall is a fresh store but the same tablet, so the fingerprint must come out the
    // same. This is the bug the switch exists to fix.
    test(
      'is the same on a fresh store, so a reinstall is the same device',
      () async {
        final first = await buildDeviceIdentity(
          FakeStorePort(),
          FakeDeviceInfo(id: 'android-abc'),
        );
        final afterReinstall = await buildDeviceIdentity(
          FakeStorePort(),
          FakeDeviceInfo(id: 'android-abc'),
        );

        expect(afterReinstall.deviceFingerprint, first.deviceFingerprint);
      },
    );

    // A device that had already been paired keeps its identity: the row on the server was keyed
    // on this value, and changing it would leave that row orphaned and add a second one.
    test('keeps what was stored before the platform id was used', () async {
      final store = FakeStorePort({deviceIdKey: '01J8ZQ000000000000000000AB'});

      final identity = await buildDeviceIdentity(
        store,
        FakeDeviceInfo(id: 'android-abc'),
      );

      expect(identity.deviceFingerprint, '01J8ZQ000000000000000000AB');
    });

    // An empty string is not an identifier. Falling back is right here: there is nothing usable
    // to send, and the backend's column is NOT NULL.
    test('falls back when the platform answers with an empty string', () async {
      final identity = await buildDeviceIdentity(
        FakeStorePort(),
        FakeDeviceInfo(id: ''),
      );

      expect(identity.deviceFingerprint, hasLength(ulidLength));
    });
  });

  group('the fingerprint, when the platform has none', () {
    // Not Android, or a device that refuses to report one. An identifier the app mints is worse
    // across reinstalls, but a working device beats a broken one.
    test('is minted and stored when the platform answers null', () async {
      final store = FakeStorePort();

      final identity = await buildDeviceIdentity(
        store,
        FakeDeviceInfo(id: null),
      );

      expect(identity.deviceFingerprint, hasLength(ulidLength));
      expect(store.values[deviceIdKey], identity.deviceFingerprint);
    });

    // The platform failed, which is not the same as "no identifier": it may well have one. The
    // exception reaches the caller rather than being read as `null`, because the fallback would
    // mint a throwaway fingerprint and register a duplicate device row.
    test('is not replaced by a minted one when the platform fails', () async {
      final info = FakeDeviceInfo()
        ..failure = DeviceInfoException('platform error');

      await expectLater(
        buildDeviceIdentity(FakeStorePort(), info),
        throwsA(isA<DeviceInfoException>()),
      );
    });

    test(
      'does not fall back to a minted one when the platform fails',
      () async {
        final store = FakeStorePort();
        final info = FakeDeviceInfo()
          ..failure = DeviceInfoException('platform error');

        await expectLater(
          buildDeviceIdentity(store, info),
          throwsA(isA<DeviceInfoException>()),
        );

        expect(store.values[deviceIdKey], isNull);
      },
    );
  });

  group('the fingerprint, when it is minted', () {
    // A platform with no identifier: the only case where the app mints one.
    FakeDeviceInfo none() => FakeDeviceInfo(id: null);

    test('is a ULID minted the first time, and stored', () async {
      final store = FakeStorePort();

      final identity = await buildDeviceIdentity(store, none());

      expect(identity.deviceFingerprint, hasLength(ulidLength));
      expect(store.values[deviceIdKey], identity.deviceFingerprint);
    });

    test('is the same on every later call', () async {
      final store = FakeStorePort();
      final info = none();

      final first = await buildDeviceIdentity(store, info);
      final second = await buildDeviceIdentity(store, info);

      expect(second.deviceFingerprint, first.deviceFingerprint);
    });

    // A device paired before the platform identifier was used keeps the value its server row
    // was keyed on. Changing it would orphan that row and add a second one.
    test('reuses one that was already persisted', () async {
      final store = FakeStorePort({deviceIdKey: '01J8ZQ000000000000000000AB'});

      final identity = await buildDeviceIdentity(store, none());

      expect(identity.deviceFingerprint, '01J8ZQ000000000000000000AB');
    });

    test('does not write again when it already has one', () async {
      final store = FakeStorePort({deviceIdKey: '01J8ZQ000000000000000000AB'});

      await buildDeviceIdentity(store, none());

      expect(store.operations.where((o) => o.op == StoreOp.write), isEmpty);
    });

    test('is sortable, and its timestamp is now', () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      final identity = await buildDeviceIdentity(FakeStorePort(), none());
      final after = DateTime.now().millisecondsSinceEpoch;

      final mintedAt = ulidTime(identity.deviceFingerprint);
      expect(mintedAt, isNotNull);
      expect(mintedAt, greaterThanOrEqualTo(before));
      expect(mintedAt, lessThanOrEqualTo(after));
    });

    test('is different per install', () async {
      final first = await buildDeviceIdentity(FakeStorePort(), none());
      final second = await buildDeviceIdentity(FakeStorePort(), none());

      expect(second.deviceFingerprint, isNot(first.deviceFingerprint));
    });
  });

  // Not in the oracle. Written because the fingerprint is the one thing here that cannot be
  // lost: it is the key activation upserts on.
  group('the fingerprint, when the storage misbehaves', () {
    FakeDeviceInfo none() => FakeDeviceInfo(id: null);

    // The source tests `if (existing)`, so an empty string is not an identity. An empty value
    // also must not shadow the platform's identifier, which is the better answer.
    test('falls back when what is stored is an empty string', () async {
      final store = FakeStorePort({deviceIdKey: ''});

      final identity = await buildDeviceIdentity(store, none());

      expect(identity.deviceFingerprint, hasLength(ulidLength));
      expect(store.values[deviceIdKey], identity.deviceFingerprint);
    });

    // A read that fails is not "no fingerprint yet". Minting a new one and writing it over
    // would orphan the device's row on the server.
    test('does not mint a replacement when the read fails', () async {
      final store = FakeStorePort({deviceIdKey: '01J8ZQ000000000000000000AB'})
        ..failNext(StoreException('disk error'));

      await expectLater(
        buildDeviceIdentity(store, none()),
        throwsA(isA<StoreException>()),
      );

      expect(store.values[deviceIdKey], '01J8ZQ000000000000000000AB');
      expect(store.operations.where((o) => o.op == StoreOp.write), isEmpty);
    });

    // A fingerprint that could not be persisted is not returned: pairing would go ahead with
    // it, register it with the server, and the next launch would mint a different one.
    test('fails when the fingerprint it minted cannot be saved', () async {
      final store = WritesFail(FakeStorePort());

      await expectLater(
        buildDeviceIdentity(store, none()),
        throwsA(isA<StoreException>()),
      );
    });
  });

  group('the name', () {
    Future<String> nameFor([String? requested]) async =>
        (await buildDeviceIdentity(
          FakeStorePort(),
          FakeDeviceInfo(id: null),
          requestedName: requested,
        )).deviceName;

    test('is something a human can pick out of the dashboard list', () async {
      final name = await nameFor();

      expect(name, defaultDeviceName);
      expect(name, isNotEmpty);
      expect(name.runes.length, lessThanOrEqualTo(deviceNameMax));
    });

    // The DTO caps device_name at 255; a longer one is a 400, not a warning.
    test('is cut to what the backend would accept', () async {
      expect(await nameFor('x' * 400), hasLength(deviceNameMax));
    });

    test('keeps a name of exactly the maximum untouched', () async {
      expect(await nameFor('y' * deviceNameMax), 'y' * deviceNameMax);
    });

    // An empty name fails the DTO's `required`, so fall back rather than send a blank.
    test(
      'falls back to the default when given an empty or blank one',
      () async {
        expect(await nameFor(''), defaultDeviceName);
        expect(await nameFor('   '), defaultDeviceName);
      },
    );

    test('trims a name before sending it', () async {
      expect(await nameFor('  Tablet Kasir 1  '), 'Tablet Kasir 1');
    });

    // Trimming comes before cutting: a name that is mostly padding is not "too long".
    test('trims before it cuts', () async {
      expect(await nameFor('${' ' * 300}Kasir Depan'), 'Kasir Depan');
    });
  });

  // Not in the oracle. The backend's `max=255` is `utf8.RuneCountInString`, so the cap is 255
  // characters. JavaScript's `slice(0, 255)` counts UTF-16 units instead, which can cut an
  // emoji in half and leave a lone surrogate — harmless to the server, but not a name.
  group('the name, when it holds characters outside the basic plane', () {
    final emoji = String.fromCharCodes([0x1F600]);

    Future<String> nameFor(String requested) async =>
        (await buildDeviceIdentity(
          FakeStorePort(),
          FakeDeviceInfo(id: null),
          requestedName: requested,
        )).deviceName;

    test('is cut at 255 characters, not 255 UTF-16 units', () async {
      final name = await nameFor(emoji * 300);

      expect(name.runes.length, deviceNameMax);
      expect(name, emoji * deviceNameMax);
    });

    test('keeps an emoji that is the 255th character whole', () async {
      final name = await nameFor('${'x' * 254}$emoji');

      expect(name, '${'x' * 254}$emoji');
    });

    test('never ends in half of an emoji', () async {
      final name = await nameFor('${'x' * 254}${emoji * 3}');

      // A lone surrogate does not survive UTF-8: it comes back as U+FFFD.
      expect(utf8.decode(utf8.encode(name)), name);
      expect(name.runes.length, deviceNameMax);
    });
  });

  // Not in the oracle; from running this against the TypeScript module over 236 names (see
  // `plan/api-client/findings.md`). Both tests passed the first time they ran — the behaviour
  // follows from Dart's own `trim` — so there was no RED to observe.
  group('the name, and Unicode whitespace', () {
    Future<String> nameFor(String requested) async =>
        (await buildDeviceIdentity(
          FakeStorePort(),
          FakeDeviceInfo(id: null),
          requestedName: requested,
        )).deviceName;

    // These agree with JavaScript's trim, checked one code point at a time.
    test(
      'trims the spaces a phone keyboard or a chat app can produce',
      () async {
        final nbsp = String.fromCharCode(0xa0);
        final ideographic = String.fromCharCode(0x3000);
        final lineSeparator = String.fromCharCode(0x2028);
        final byteOrderMark = String.fromCharCode(0xfeff);

        expect(await nameFor('${nbsp}Kasir$nbsp'), 'Kasir');
        expect(await nameFor('${ideographic}Kasir$ideographic'), 'Kasir');
        expect(await nameFor('Kasir$lineSeparator'), 'Kasir');
        expect(await nameFor('${byteOrderMark}Kasir'), 'Kasir');
      },
    );

    // The one place Dart and JavaScript disagree: U+0085 (NEXT LINE) is Unicode White_Space,
    // so Dart's trim removes it and JavaScript's does not. JavaScript would send a name that
    // is a single invisible control character; a blank name falls back to the default.
    test('treats a name that is only a next-line character as blank', () async {
      final nextLine = String.fromCharCode(0x85);

      expect(await nameFor(nextLine), defaultDeviceName);
      expect(await nameFor('$nextLine$nextLine'), defaultDeviceName);
    });
  });
}
