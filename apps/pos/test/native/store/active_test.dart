/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pos/native/store/active.dart';
import 'package:pos/native/store/store_secure.dart';

void main() {
  group('active StorePort', () {
    test('is the real one until something replaces it', () {
      expect(store, isA<SecureStore>());
    });

    // Tests swap it for the fake through this, not through a mock framework
    // (`.claude/rules/native-ports.md` §2.4).
    test('can be replaced, and then hands out the replacement', () {
      final original = store;
      addTearDown(() => setStore(original));
      final fake = FakeStorePort();

      setStore(fake);

      expect(store, same(fake));
      expect(store, isA<StorePort>());
    });

    test('can be put back', () {
      final original = store;

      setStore(FakeStorePort());
      setStore(original);

      expect(store, same(original));
    });
  });
}
