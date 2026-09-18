/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:test/test.dart';

// The contract of `StorePort`, exercised through its fake. What it pins: absent is null, a
// value round-trips, a write overwrites, a remove clears, keys are independent.

void main() {
  group('reading and writing', () {
    test('a key that was never written reads as null', () async {
      expect(await FakeStorePort().read('session'), isNull);
    });

    test('a written value reads back', () async {
      final store = FakeStorePort();

      await store.write('session', '{"outletId":"out_1"}');

      expect(await store.read('session'), '{"outletId":"out_1"}');
    });

    test('a second write overwrites the first', () async {
      final store = FakeStorePort();

      await store.write('session', 'first');
      await store.write('session', 'second');

      expect(await store.read('session'), 'second');
    });

    test('removing a key clears it', () async {
      final store = FakeStorePort();

      await store.write('session', 'value');
      await store.remove('session');

      expect(await store.read('session'), isNull);
    });

    // A device that was never paired has no session to remove. Reset must not fail on it.
    test('removing a key that is not there does nothing', () async {
      final store = FakeStorePort();

      await expectLater(store.remove('session'), completes);
    });

    test('keeps values independent per key', () async {
      final store = FakeStorePort();

      await store.write('session', 'a');
      await store.write('device_id', 'b');
      await store.remove('session');

      expect(await store.read('session'), isNull);
      expect(await store.read('device_id'), 'b');
    });

    // The empty string is a value, not the absence of one. A store that folded the two
    // together would read a written-but-empty field as "never written".
    test('an empty string is a value, not absence', () async {
      final store = FakeStorePort();

      await store.write('note', '');

      expect(await store.read('note'), '');
    });
  });

  group('recording', () {
    // Fakes must be visible (`native-ports.md` §2.3): a test asserts that the session was
    // written once, or that nothing was read, instead of trusting that it happened.
    test('records every operation with its key, in order', () async {
      final store = FakeStorePort();

      await store.read('session');
      await store.write('session', 'x');
      await store.remove('device_id');

      expect(store.operations, [
        (op: StoreOp.read, key: 'session'),
        (op: StoreOp.write, key: 'session'),
        (op: StoreOp.remove, key: 'device_id'),
      ]);
    });

    // The value of `session` is a bearer token. The record is for asserting what was
    // touched, and it ends up in test output, so it must not carry the value.
    test('does not record the values it is given', () async {
      final store = FakeStorePort();

      await store.write('session', 'secret-token-123');

      expect(store.operations.toString(), isNot(contains('secret-token-123')));
    });
  });

  group('failing', () {
    // The failure path the port rules require: a test that cannot make the storage fail
    // never exercises what `session` does about it.
    test('a queued failure makes the next read throw it', () async {
      final store = FakeStorePort()..failNext(StoreException('disk error'));

      await expectLater(store.read('session'), throwsA(isA<StoreException>()));
    });

    test(
      'a queued failure makes the next write and the next remove throw it',
      () async {
        final store = FakeStorePort()
          ..failNext(StoreException('a'))
          ..failNext(StoreException('b'));

        await expectLater(
          store.write('k', 'v'),
          throwsA(isA<StoreException>()),
        );
        await expectLater(store.remove('k'), throwsA(isA<StoreException>()));
      },
    );

    // The promise on `StorePort.write`: a write that fails leaves what was there. A store
    // that half-applied it would leave a torn session behind.
    test('a failed write leaves the previous value in place', () async {
      final store = FakeStorePort();
      await store.write('session', 'old');
      store.failNext(StoreException('disk full'));

      await expectLater(
        store.write('session', 'new'),
        throwsA(isA<StoreException>()),
      );

      expect(await store.read('session'), 'old');
    });

    test('a failed remove leaves the value in place', () async {
      final store = FakeStorePort();
      await store.write('session', 'kept');
      store.failNext(StoreException('locked'));

      await expectLater(
        store.remove('session'),
        throwsA(isA<StoreException>()),
      );

      expect(await store.read('session'), 'kept');
    });

    test('a failure applies once, then the store works again', () async {
      final store = FakeStorePort()..failNext(StoreException('blip'));

      await expectLater(store.read('k'), throwsA(isA<StoreException>()));
      await store.write('k', 'v');

      expect(await store.read('k'), 'v');
    });

    test('a failed operation is still recorded', () async {
      final store = FakeStorePort()..failNext(StoreException('x'));

      await expectLater(
        store.write('session', 'v'),
        throwsA(isA<StoreException>()),
      );

      expect(store.operations, [(op: StoreOp.write, key: 'session')]);
    });

    test('throws exactly the exception it was given', () async {
      final failure = StoreException('disk error');
      final store = FakeStorePort()..failNext(failure);

      await expectLater(store.read('k'), throwsA(same(failure)));
    });
  });

  group('seeding and inspecting', () {
    // How `session` will be tested against corrupt data, and against a device that is
    // already paired, without first driving a write through the store.
    test('starts with the values it is given', () async {
      final store = FakeStorePort({'session': '{not json', 'device_id': 'abc'});

      expect(await store.read('session'), '{not json');
      expect(await store.read('device_id'), 'abc');
    });

    test('does not count seeded values as operations', () {
      final store = FakeStorePort({'session': 'x'});

      expect(store.operations, isEmpty);
    });

    test('copies the map it is seeded from', () async {
      final seed = {'session': 'x'};
      final store = FakeStorePort(seed);

      seed['session'] = 'changed';
      seed['other'] = 'y';

      expect(await store.read('session'), 'x');
      expect(await store.read('other'), isNull);
    });

    test('exposes what it holds without letting a test edit it', () async {
      final store = FakeStorePort({'a': '1'});
      await store.write('b', '2');

      expect(store.values, {'a': '1', 'b': '2'});
      expect(() => store.values['c'] = '3', throwsUnsupportedError);
    });

    // Reading `values` is not an operation: it is the test looking, not the app touching.
    test('reading values does not record an operation', () {
      final store = FakeStorePort({'a': '1'});

      store.values;

      expect(store.operations, isEmpty);
    });
  });

  group('StoreException', () {
    test('is an Exception', () {
      expect(StoreException('disk full'), isA<Exception>());
    });

    test('prints the message', () {
      expect(StoreException('disk full').toString(), contains('disk full'));
    });

    // The cause is whatever the platform threw, and it can carry a file path or the value
    // that was being written. This string reaches logs and crash reports.
    test('does not print the cause', () {
      final e = StoreException(
        'disk full',
        cause: Exception(
          'writing session=secret-token-123 to /data/pos.json failed',
        ),
      );

      expect(e.toString(), isNot(contains('secret-token-123')));
    });
  });
}
