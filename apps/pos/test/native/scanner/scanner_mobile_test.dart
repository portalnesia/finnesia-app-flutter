/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/native/scanner/active.dart';
import 'package:pos/native/scanner/scanner_fake.dart';
import 'package:pos/native/scanner/scanner_mobile.dart';

void main() {
  // `mobile_scanner` ships Android, iOS, macOS and web. On Windows its channels do not exist, and
  // opening the view throws `MissingPluginException` from inside the plugin, where nothing here
  // can catch it: so the button is simply not offered there.
  group('MobileScannerReader', () {
    test('is available on Android', () {
      expect(
        MobileScannerReader(platform: TargetPlatform.android).isAvailable,
        isTrue,
      );
    });

    test('is not available on Windows', () {
      expect(
        MobileScannerReader(platform: TargetPlatform.windows).isAvailable,
        isFalse,
      );
    });
  });

  group('active ScannerPort', () {
    test('can be replaced, and then hands out the replacement', () {
      final original = scanner;
      addTearDown(() => setScanner(original));
      final fake = FakeScanner();

      setScanner(fake);

      expect(scanner, same(fake));
    });
  });
}
