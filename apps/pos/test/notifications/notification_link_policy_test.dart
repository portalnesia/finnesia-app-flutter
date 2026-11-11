/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/notifications/notification_link_policy.dart';

PosSession _session({
  String baseUrl = 'https://erp.perusahaan.com',
  String? customDomain,
}) => PosSession(
  baseUrl: baseUrl,
  companyId: 'comp_1',
  outletId: 'out_1',
  sessionToken: 'not-forwarded',
  branding: customDomain == null
      ? null
      : PosBranding(customDomain: customDomain),
);

void main() {
  group('notification link policy', () {
    test(
      'resolves an app-relative path only against the paired HTTPS origin',
      () {
        final policy = NotificationLinkPolicy(_session());

        final result = policy.resolveDestination('/reports/weekly?range=month');

        expect(
          result,
          Uri.parse('https://erp.perusahaan.com/reports/weekly?range=month'),
        );
      },
    );

    test(
      'allows only exact paired, custom, and configured canonical origins',
      () {
        final policy = NotificationLinkPolicy(
          _session(customDomain: 'https://shop.perusahaan.com'),
        );

        expect(
          policy.resolveDestination('https://shop.perusahaan.com/news/42'),
          Uri.parse('https://shop.perusahaan.com/news/42'),
        );
        expect(
          policy.resolveDestination('https://apps-dev.finnesia.com/n/42'),
          Uri.parse('https://apps-dev.finnesia.com/n/42'),
        );
        expect(
          policy.resolveDestination('https://apps.finnesia.com/n/42'),
          Uri.parse('https://apps.finnesia.com/n/42'),
        );
        expect(
          policy.resolveDestination('https://evil.apps-dev.finnesia.com/n/42'),
          isNull,
        );
      },
    );

    test(
      'rejects the identity provider as an initial notification destination',
      () {
        final policy = NotificationLinkPolicy(_session());

        expect(
          policy.resolveDestination(
            'https://accounts.portalnesia.com/authorize',
          ),
          isNull,
        );
      },
    );

    test('rejects insecure, ambiguous, and malformed destinations', () {
      final policy = NotificationLinkPolicy(_session());

      for (final value in [
        'http://erp.perusahaan.com/reports',
        '//attacker.example/reports',
        'reports/weekly',
        'javascript:alert(1)',
        'https://erp.perusahaan.com@attacker.example/reports',
        'https://erp.perusahaan.com.attacker.example/reports',
        'https://erp.perusahaan.com:444/reports',
        'https://erp.perusahaan.com\\@attacker.example/reports',
      ]) {
        expect(
          policy.resolveDestination(value),
          isNull,
          reason: 'must reject $value',
        );
      }
    });

    test('resolves CTA and body links by the web rules', () {
      final policy = NotificationLinkPolicy(_session());

      final inApp = policy.resolveAction(' /reports/weekly ');
      expect(
        inApp?.uri,
        Uri.parse('https://erp.perusahaan.com/reports/weekly'),
      );
      expect(inApp?.inApp, isTrue);

      for (final value in [
        'https://finnesia.com/promo',
        'HTTP://finnesia.com/promo',
        'mailto:cs@finnesia.com',
        'tel:+62811',
      ]) {
        final action = policy.resolveAction(value);
        expect(action?.uri, Uri.parse(value.trim()), reason: value);
        expect(action?.inApp, isFalse, reason: value);
      }

      for (final value in [
        '',
        '   ',
        '//attacker.example/x',
        '/\\attacker.example',
        'javascript:alert(1)',
        'data:text/html,x',
        'reports/weekly',
      ]) {
        expect(policy.resolveAction(value), isNull, reason: value);
      }
    });

    test('a relative CTA or body link works on any paired server, as on the web', () {
      // The web page resolves `/path` against its own origin whatever its scheme, so a
      // development server on plain HTTP keeps its relative links and buttons.
      final local = NotificationLinkPolicy(
        _session(baseUrl: 'http://localhost:4000'),
      );
      final action = local.resolveAction('/reports/weekly');
      expect(action?.uri, Uri.parse('http://localhost:4000/reports/weekly'));
      expect(action?.inApp, isTrue);
      expect(local.resolveAction('//localhost:4000/x'), isNull);
    });

    test('resolves an image the way an <img> on the web page would', () {
      final policy = NotificationLinkPolicy(_session());
      expect(
        policy.resolveMedia('/static/a.png?signature=s&expired=1'),
        Uri.parse(
          'https://erp.perusahaan.com/static/a.png?signature=s&expired=1',
        ),
      );
      expect(
        policy.resolveMedia('https://cdn.finnesia.com/a.png'),
        Uri.parse('https://cdn.finnesia.com/a.png'),
      );
      // A local server during development is plain HTTP; its images still load.
      expect(
        NotificationLinkPolicy(_session(baseUrl: 'http://localhost:4000'))
            .resolveMedia('/static/a.png'),
        Uri.parse('http://localhost:4000/static/a.png'),
      );
      for (final value in [
        '',
        '//cdn.example/a.png',
        'data:image/png;base64,x',
        'a.png',
      ]) {
        expect(policy.resolveMedia(value), isNull, reason: value);
      }
    });

    test(
      'does not resolve a relative link when the paired origin is not HTTPS',
      () {
        final policy = NotificationLinkPolicy(
          _session(baseUrl: 'http://localhost:4000'),
        );

        expect(policy.resolveDestination('/reports'), isNull);
        expect(
          policy.resolveDestination('https://apps-dev.finnesia.com/reports'),
          Uri.parse('https://apps-dev.finnesia.com/reports'),
        );
      },
    );
  });
}
