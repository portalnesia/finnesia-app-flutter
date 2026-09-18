/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/preferences_fake.dart';
import 'package:pn_types/src/native/preferences_port.dart';
import 'package:pos/native/preferences/active.dart';
import 'package:pos/native/preferences/preferences_shared.dart';

void main() {
  group('active PreferencesPort', () {
    test('is the real one until something replaces it', () {
      expect(preferences, isA<SharedPrefs>());
    });

    // Tests swap it for the fake through this, not through a mock framework
    // (`.claude/rules/native-ports.md` §2.4).
    test('can be replaced, and then hands out the replacement', () {
      final original = preferences;
      addTearDown(() => setPreferences(original));
      final fake = FakePreferences();

      setPreferences(fake);

      expect(preferences, same(fake));
      expect(preferences, isA<PreferencesPort>());
    });

    test('can be put back', () {
      final original = preferences;

      setPreferences(FakePreferences());
      setPreferences(original);

      expect(preferences, same(original));
    });
  });
}
