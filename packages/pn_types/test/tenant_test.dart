/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/tenant.dart';
import 'package:test/test.dart';

// Inputs are wire JSON run through `jsonDecode`, as the login response will deliver them.
UserCompany parse(String json) =>
    UserCompany.fromJson(jsonDecode(json) as Map<String, dynamic>);

void main() {
  group('UserCompany.fromJson', () {
    test('reads the snake_case wire fields', () {
      final c = parse(
        '''
        {"id":"uc_1","user_id":"usr_1","company_id":"comp_1","role_id":"role_sys_owner",
         "branch_id":"b1","warehouse_id":"w1","outlet_id":"out_1","role":"owner","is_active":true}''',
      );

      expect(c.id, 'uc_1');
      expect(c.userId, 'usr_1');
      expect(c.companyId, 'comp_1');
      expect(c.roleId, 'role_sys_owner');
      expect(c.branchId, 'b1');
      expect(c.warehouseId, 'w1');
      expect(c.outletId, 'out_1');
      expect(c.role, 'owner');
      expect(c.isActive, isTrue);
    });

    test('leaves the optional ids null when the API omits them', () {
      final c = parse(
        '{"id":"uc_1","user_id":"u","company_id":"c","role":"cashier","is_active":true}',
      );

      expect(c.roleId, isNull);
      expect(c.branchId, isNull);
      expect(c.warehouseId, isNull);
      expect(c.outletId, isNull);
    });

    // The source types `role` as a union of known names plus `string`, because custom roles
    // exist. An enum here would throw on the first tenant that made one.
    test('keeps a role name it does not know', () {
      final c = parse(
        '{"id":"uc_1","user_id":"u","company_id":"c","role":"kepala_toko","is_active":false}',
      );

      expect(c.role, 'kepala_toko');
      expect(c.isActive, isFalse);
    });

    // Only the fields the POS reads are modelled (`project.md` §2.2). The API sends the
    // membership with its company, role model, branch and outlet attached.
    test('ignores the relations and timestamps it does not model', () {
      final c = parse('''
        {"id":"uc_1","user_id":"u","company_id":"c","role":"admin","is_active":true,
         "role_model":{"allowed_scope":"all"},
         "created_at":"2026-01-01T00:00:00Z","deleted_at":null}''');

      expect(c.role, 'admin');
    });

    // The company is carried because the header's avatar needs its name and logo together,
    // without a fetch per render. Only those two are modelled.
    test('reads the company relation it does model', () {
      final c = parse(
        '{"id":"uc_1","user_id":"u","company_id":"c","role":"admin","is_active":true,'
        '"company":{"id":"c","name":"Toko Budi","logo":{"id":"file_1",'
        '"status":"attached","url":"https://cdn.example/budi.png"}}}',
      );

      expect(c.company?.name, 'Toko Budi');
      expect(c.company?.logo?.renderableUrl, 'https://cdn.example/budi.png');
    });

    // `model.UserCompany.Company` is a pointer with `json:"company,omitempty"`, so an absent
    // company is a normal state and must not cost the parse.
    test('leaves the company null when the login omits it', () {
      final c = parse(
        '{"id":"uc_1","user_id":"u","company_id":"c","role":"admin","is_active":true}',
      );

      expect(c.company, isNull);
    });

    test('reads a company with a name but no logo', () {
      final c = parse(
        '{"id":"uc_1","user_id":"u","company_id":"c","role":"admin","is_active":true,'
        '"company":{"id":"c","name":"Toko Budi"}}',
      );

      expect(c.company?.name, 'Toko Budi');
      expect(c.company?.logo, isNull);
    });

    test('rejects a membership with no company_id', () {
      expect(
        () => parse(
          '{"id":"uc_1","user_id":"u","role":"cashier","is_active":true}',
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects a membership with no is_active', () {
      expect(
        () => parse(
          '{"id":"uc_1","user_id":"u","company_id":"c","role":"cashier"}',
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('Outlet.fromJson', () {
    Outlet outlet(String json) =>
        Outlet.fromJson(jsonDecode(json) as Map<String, dynamic>);

    test('reads the id and the name the Menu shows', () {
      final o = outlet('{"id":"o1","name":"Kasir Utama"}');

      expect(o.id, 'o1');
      expect(o.name, 'Kasir Utama');
    });

    test('ignores the rest of the record', () {
      // The record carries 15+ fields (branch, warehouses, per-outlet accounts). The till
      // shows a name, so the rest is not modelled and must not be an error.
      final o = outlet(
        '{"id":"o1","name":"X","company_id":"c","branch_id":"b","is_active":true,'
        '"is_within_quota":true,"warehouses":[{"id":"w1"}]}',
      );

      expect(o.name, 'X');
    });

    test('rejects an outlet with no name', () {
      expect(() => outlet('{"id":"o1"}'), throwsA(isA<TypeError>()));
    });
  });
}
