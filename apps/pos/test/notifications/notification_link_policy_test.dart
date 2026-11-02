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
      'permits the configured OIDC origin for normal login navigation only',
      () {
        final policy = NotificationLinkPolicy(_session());
        final login = Uri.parse('https://accounts.portalnesia.com/authorize');

        expect(policy.resolveDestination(login.toString()), isNull);
        expect(policy.allowsNavigation(login), isTrue);
        expect(
          policy.allowsNavigation(
            Uri.parse('https://accounts.portalnesia.com.evil.test/authorize'),
          ),
          isFalse,
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
