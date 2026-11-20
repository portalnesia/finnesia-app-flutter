/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/permissions.dart';
import 'package:pn_pos/src/pos_quick_create.dart';
import 'package:pn_types/src/master_data.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:test/test.dart';

// Mirrors `apps/web/src/lib/pos-quick-create.ts` (finnesia-monorepo, working tree of
// 2026-11-20). The web file has no test of its own for the permission pairs; the cases for
// them are written here from the server routes (`pos_routes.go`), which accept either code.

const pcs = Unit(id: 'u-pcs', name: 'Pieces', symbol: 'PCS');
const box = Unit(id: 'u-box', name: 'Kotak', symbol: 'BOX');
const kg = Unit(id: 'u-kg', name: 'Kilogram', symbol: 'KG');

Permissions granted(List<String> codes) =>
    Permissions.of(membership: null, granted: codes);

void main() {
  group('who may add a product from the till', () {
    test('a cashier holding pos.quick_create', () {
      expect(canQuickAddProduct(granted(['pos.quick_create'])), isTrue);
    });

    test('whoever already manages products', () {
      expect(canQuickAddProduct(granted(['master.product.manage'])), isTrue);
    });

    test('not someone who only manages contacts', () {
      expect(canQuickAddProduct(granted(['master.contact.manage'])), isFalse);
    });

    test('not anyone before the permission list has loaded', () {
      expect(canQuickAddProduct(granted([])), isFalse);
    });

    test('the owner, without a list', () {
      const owner = UserCompany(
        id: 'm1',
        userId: 'u1',
        companyId: 'co1',
        isActive: true,
        role: 'owner',
        roleId: 'role_sys_owner',
      );
      expect(canQuickAddProduct(Permissions.of(membership: owner)), isTrue);
    });
  });

  group('who may add a customer from the till', () {
    test('a cashier holding pos.quick_create', () {
      expect(canQuickAddCustomer(granted(['pos.quick_create'])), isTrue);
    });

    test('whoever already manages contacts', () {
      expect(canQuickAddCustomer(granted(['master.contact.manage'])), isTrue);
    });

    test('not someone who only manages products', () {
      expect(canQuickAddCustomer(granted(['master.product.manage'])), isFalse);
    });

    test('anyone granted the wildcard', () {
      expect(canQuickAddCustomer(granted(['*'])), isTrue);
    });
  });

  group('finding the company PCS', () {
    test('matches the symbol whatever its case', () {
      const lower = Unit(id: 'u-p', name: 'Biji', symbol: 'pcs');
      expect(findPcsUnit([box, lower]), lower);
    });

    test('is null when the company has none', () {
      expect(findPcsUnit([box, kg]), isNull);
    });

    test('is null for an empty list', () {
      expect(findPcsUnit(const []), isNull);
    });

    test('does not take a symbol that only contains PCS', () {
      const pcsBox = Unit(id: 'u-x', name: 'Pack', symbol: 'PCS-BOX');
      expect(findPcsUnit([pcsBox]), isNull);
    });
  });

  group('the unit choices', () {
    test('put the company PCS first, then the rest in list order', () {
      final choices = buildQuickUnitChoices([box, pcs, kg], pcs);

      expect(choices, [
        const QuickUnitExisting(pcs),
        const QuickUnitExisting(box),
        const QuickUnitExisting(kg),
      ]);
    });

    test('offer PCS to be created first when the company has none', () {
      final choices = buildQuickUnitChoices([box, kg], null);

      expect(choices.first, const QuickUnitPcsNew());
      expect(choices.skip(1), [
        const QuickUnitExisting(box),
        const QuickUnitExisting(kg),
      ]);
    });

    test('offer the company PCS even when it is not on the page', () {
      // Asked by symbol rather than read off the first page: a company with many units may not
      // have PCS on it, and offering "PCS (created on save)" next to an existing PCS is wrong.
      final choices = buildQuickUnitChoices([box], pcs);

      expect(choices, [
        const QuickUnitExisting(pcs),
        const QuickUnitExisting(box),
      ]);
    });

    test('still offer PCS when there are no units at all', () {
      expect(buildQuickUnitChoices(const [], null), [const QuickUnitPcsNew()]);
    });

    test('default to the first choice', () {
      expect(defaultQuickUnit(pcs), const QuickUnitExisting(pcs));
      expect(defaultQuickUnit(null), const QuickUnitPcsNew());
    });
  });

  group('what goes in unit_id', () {
    test('the id of an existing unit', () {
      expect(quickUnitPayload(const QuickUnitExisting(box)), 'u-box');
    });

    test('nothing for PCS to be created, so the server creates it', () {
      expect(quickUnitPayload(const QuickUnitPcsNew()), isNull);
    });
  });
}
