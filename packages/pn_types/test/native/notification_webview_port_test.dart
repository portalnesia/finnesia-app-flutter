/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/notification_webview_fake.dart';
import 'package:pn_types/src/native/notification_webview_port.dart';
import 'package:test/test.dart';

void main() {
  group('FakeNotificationWebViewPort', () {
    test('records the validated destination and navigation policy', () async {
      final port = FakeNotificationWebViewPort();
      final destination = Uri.parse('https://shop.example.test/orders/7');
      bool allows(Uri uri) => uri.host == 'shop.example.test';

      final opened = await port.openUrl(destination, allowsNavigation: allows);

      expect(opened, isTrue);
      expect(port.opened.single.destination, destination);
      expect(
        port.opened.single.allowsNavigation(
          Uri.parse('https://shop.example.test/login'),
        ),
        isTrue,
      );
      expect(
        port.opened.single.allowsNavigation(
          Uri.parse('https://attacker.example.test/'),
        ),
        isFalse,
      );
    });

    test(
      'reports an unavailable native runtime without pretending to open',
      () async {
        final port = FakeNotificationWebViewPort()..available = false;

        final opened = await port.openUrl(
          Uri.parse('https://shop.example.test/'),
          allowsNavigation: (_) => true,
        );

        expect(opened, isFalse);
        expect(port.opened, hasLength(1));
      },
    );

    test('can simulate a native launch failure', () async {
      final port = FakeNotificationWebViewPort()
        ..failNext(const NotificationWebViewException('native launch failed'));

      await expectLater(
        port.openUrl(
          Uri.parse('https://shop.example.test/'),
          allowsNavigation: (_) => true,
        ),
        throwsA(isA<NotificationWebViewException>()),
      );
      expect(port.opened, hasLength(1));
    });
  });
}
