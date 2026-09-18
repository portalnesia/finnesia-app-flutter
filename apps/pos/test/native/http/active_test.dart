/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/public_http_fake.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pos/native/http/active.dart';
import 'package:pos/native/http/public_http_dio.dart';

void main() {
  group('active PublicHttpPort', () {
    test('is the real one until something replaces it', () {
      expect(publicHttp, isA<DioPublicHttp>());
    });

    // Tests swap it for the fake through this, not through a mock framework
    // (`.claude/rules/native-ports.md` §2.4).
    test('can be replaced, and then hands out the replacement', () {
      final original = publicHttp;
      addTearDown(() => setPublicHttp(original));
      final fake = FakePublicHttp();

      setPublicHttp(fake);

      expect(publicHttp, same(fake));
      expect(publicHttp, isA<PublicHttpPort>());
    });

    test('can be put back', () {
      final original = publicHttp;

      setPublicHttp(FakePublicHttp());
      setPublicHttp(original);

      expect(publicHttp, same(original));
    });
  });
}
