/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/permission_viewer.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:test/test.dart';

// The module has no monorepo counterpart. The case after `// New` covers what the earlier
// suite never asserted.

const membership = UserCompany(
  id: 'uc_1',
  userId: 'usr_1',
  companyId: 'comp_1',
  role: 'cashier',
  isActive: true,
);

const otherMembership = UserCompany(
  id: 'uc_2',
  userId: 'usr_1',
  companyId: 'comp_9',
  role: 'owner',
  isActive: true,
);

const signedIn = PosSession(
  baseUrl: 'https://erp.perusahaan.com',
  companyId: 'comp_1',
  outletId: 'out_1',
  deviceName: 'Tablet Kasir 1',
  sessionToken: 'tok_1',
  user: SessionUser(id: 'usr_1', name: 'Budi'),
);

void main() {
  group('resolvePermissionViewer', () {
    test('is empty when the device has no session', () {
      // A device that has not been paired cannot name a company at all.
      expect(resolvePermissionViewer(null), (
        activeCompanyId: null,
        activeUserCompany: null,
      ));
    });

    test('names the paired company before the memberships are known', () {
      // Pairing locks the company, login brings the memberships. Between the two the app
      // still knows which company it is asking about, which is what enables the
      // permission query; it just has no role yet.
      expect(resolvePermissionViewer(signedIn), (
        activeCompanyId: 'comp_1',
        activeUserCompany: null,
      ));
    });

    test('resolves the membership belonging to the paired company', () {
      final viewer = resolvePermissionViewer(
        signedIn.copyWith(companies: [membership]),
      );

      expect(viewer.activeCompanyId, 'comp_1');
      expect(viewer.activeUserCompany, same(membership));
    });

    test('does not adopt a membership from another company', () {
      // The device is paired to one company; a membership in a different one carries a
      // role for a company this till does not sell for, and using it would grant the
      // wrong rights.
      final viewer = resolvePermissionViewer(
        signedIn.copyWith(companies: [otherMembership]),
      );

      expect(viewer.activeCompanyId, 'comp_1');
      expect(viewer.activeUserCompany, isNull);
    });

    test('picks the right membership out of several', () {
      final viewer = resolvePermissionViewer(
        signedIn.copyWith(companies: [otherMembership, membership]),
      );

      expect(viewer.activeUserCompany, same(membership));
    });

    // New.

    test('reads a login that returned no memberships as no membership', () {
      // `companies: []` (the login returned none) is a different fact from `null` (not
      // signed in), but both mean there is no role to ask about.
      final viewer = resolvePermissionViewer(signedIn.copyWith(companies: []));

      expect(viewer.activeUserCompany, isNull);
    });
  });
}
