/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/permissions.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:test/test.dart';

// Written new. The rule is the pure half of `usePermission`
// (`finnesia-monorepo/packages/shared/src/hooks/use-permission.ts`), which mixes it with a
// React Query call and has no test file. What the hook does, read from its source:
//   isOwner = role === 'owner' || role_id === 'role_sys_owner'
//   can(code) = isOwner || permissions.includes('*') || permissions.includes(code)
//   permissions = data || []   (so "not loaded yet" is "granted nothing")

UserCompany member({String role = 'cashier', String? roleId}) => UserCompany(
      id: 'uc_1',
      userId: 'usr_1',
      companyId: 'comp_1',
      role: role,
      roleId: roleId,
      isActive: true,
    );

void main() {
  group('Permissions.isOwner', () {
    test('is true for the owner role', () {
      expect(Permissions.of(membership: member(role: 'owner')).isOwner, isTrue);
    });

    test('is true for the system owner role id, whatever the role string says',
        () {
      expect(
        Permissions.of(
          membership: member(role: 'custom', roleId: 'role_sys_owner'),
        ).isOwner,
        isTrue,
      );
    });

    test('is false for any other role', () {
      expect(Permissions.of(membership: member()).isOwner, isFalse);
      expect(
        Permissions.of(
          membership: member(role: 'admin', roleId: 'role_sys_admin'),
        ).isOwner,
        isFalse,
      );
    });

    test('is false with no membership at all', () {
      expect(Permissions.of(membership: null).isOwner, isFalse);
    });

    test('is case sensitive, like the strict equality it ports', () {
      expect(
        Permissions.of(membership: member(role: 'Owner')).isOwner,
        isFalse,
      );
    });
  });

  group('Permissions.can', () {
    test('lets an owner do anything, even with nothing granted', () {
      final owner = Permissions.of(membership: member(role: 'owner'));

      expect(owner.can('pos.cashier.access'), isTrue);
      expect(owner.can('anything.at.all'), isTrue);
    });

    test(
        'lets the wildcard the server gives an owner or superadmin do anything',
        () {
      // `team_service.go`: `["*"]` for an owner or superadmin.
      final p = Permissions.of(membership: member(), granted: ['*']);

      expect(p.can('pos.shift.override'), isTrue);
    });

    test('allows exactly the permissions that were granted', () {
      final p = Permissions.of(
        membership: member(),
        granted: ['pos.cashier.access'],
      );

      expect(p.can('pos.cashier.access'), isTrue);
      expect(p.can('pos.shift.override'), isFalse);
    });

    test('grants nothing until the permissions have loaded', () {
      // The safe direction for a permission question: a Pay button that appears for a
      // moment and is then withdrawn is worse than one that appears a moment late.
      final p = Permissions.of(membership: member(), granted: null);

      expect(p.can('pos.cashier.access'), isFalse);
    });

    test('grants nothing to a cashier with an empty list', () {
      final p = Permissions.of(membership: member(), granted: const []);

      expect(p.can('pos.cashier.access'), isFalse);
    });

    test(
        'does not treat a permission that merely contains a granted one as granted',
        () {
      final p = Permissions.of(membership: member(), granted: ['pos.cashier']);

      expect(p.can('pos.cashier.access'), isFalse);
    });

    test('is not changed by the list it was built from', () {
      final list = ['pos.cashier.access'];
      final p = Permissions.of(membership: member(), granted: list);

      list.clear();

      expect(p.can('pos.cashier.access'), isTrue);
    });
  });
}
