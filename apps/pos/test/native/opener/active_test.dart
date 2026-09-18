/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/opener_fake.dart';
import 'package:pn_types/src/native/opener_port.dart';
import 'package:pos/native/opener/active.dart';
import 'package:pos/native/opener/opener_url_launcher.dart';

void main() {
  group('active OpenerPort', () {
    test('is the real one until something replaces it', () {
      expect(opener, isA<UrlLauncherOpener>());
    });

    // Tests swap it for the fake through this, not through a mock framework
    // (`.claude/rules/native-ports.md` §2.4).
    test('can be replaced, and then hands out the replacement', () {
      final original = opener;
      addTearDown(() => setOpener(original));
      final fake = FakeOpener();

      setOpener(fake);

      expect(opener, same(fake));
      expect(opener, isA<OpenerPort>());
    });

    test('can be put back', () {
      final original = opener;

      setOpener(FakeOpener());
      setOpener(original);

      expect(opener, same(original));
    });
  });
}
