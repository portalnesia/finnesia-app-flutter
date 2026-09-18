/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/category.dart';
import 'package:pn_types/src/product.dart';
import 'package:test/test.dart';

// Inputs are wire JSON run through `jsonDecode`, never built from the enums — see the
// note in `pos_test.dart`.
Product parse(String json) =>
    Product.fromJson(jsonDecode(json) as Map<String, dynamic>);

void main() {
  group('Product.fromJson', () {
    test('reads the snake_case wire fields', () {
      final p = parse('''
        {"id":"p1","name":"Kopi","sku":"K-1","barcode":"899","unit_id":"u1",
         "sell_price":15000,"type":"INVENTORY"}''');

      expect(p.id, 'p1');
      expect(p.name, 'Kopi');
      expect(p.sku, 'K-1');
      expect(p.barcode, '899');
      expect(p.unitId, 'u1');
      expect(p.sellPrice, 15000);
      expect(p.type, ProductType.inventory);
    });

    test('reads the wire value of every ProductType', () {
      for (final t in ProductType.values) {
        final p = parse(
          '{"id":"p","name":"n","unit_id":"u","type":"${t.wire}"}',
        );
        expect(p.type, t);
      }
      expect(
        parse(
          '{"id":"p","name":"n","unit_id":"u","type":"NON_INVENTORY"}',
        ).type,
        ProductType.nonInventory,
      );
    });

    test('accepts int and double sell_price', () {
      expect(
        parse('{"id":"p","name":"n","unit_id":"u","sell_price":10}').sellPrice,
        10,
      );
      expect(
        parse(
          '{"id":"p","name":"n","unit_id":"u","sell_price":10.5}',
        ).sellPrice,
        10.5,
      );
    });

    // The list endpoint still returns deactivated products, and the till must not sell them
    // (`product-grid.tsx`). Absent means active: older rows predate the field.
    test('says whether a product is active, and assumes so when not told', () {
      expect(
        parse('{"id":"p","name":"n","unit_id":"u","is_active":false}').isActive,
        isFalse,
      );
      expect(
        parse('{"id":"p","name":"n","unit_id":"u","is_active":true}').isActive,
        isTrue,
      );
      expect(parse('{"id":"p","name":"n","unit_id":"u"}').isActive, isNull);
    });

    test('ignores wire fields this build does not model', () {
      // The API sends the whole 40+ field catalogue record.
      final p = parse(
        '''
        {"id":"p","name":"n","unit_id":"u","accurate_account":"x","bundle_items":[1,2]}''',
      );
      expect(p.id, 'p');
    });

    test('leaves optional fields null when absent', () {
      final p = parse('{"id":"p","name":"n","unit_id":"u"}');
      expect(p.sku, isNull);
      expect(p.barcode, isNull);
      expect(p.sellPrice, isNull);
      expect(p.type, isNull);
      expect(p.category, isNull);
    });

    test('reads an unknown product type as null instead of throwing', () {
      // A catalogue from a newer API must not crash the till (`ProductType.tryParse`).
      expect(
        parse('{"id":"p","name":"n","unit_id":"u","type":"SUBSCRIPTION"}').type,
        isNull,
      );
    });

    test('reads a nested category with its one-level parent', () {
      final p = parse('''
        {"id":"p","name":"n","unit_id":"u",
         "category":{"id":"c2","name":"Es","parent_id":"c1",
                     "parent":{"id":"c1","name":"Minuman"}}}''');

      expect(p.category?.id, 'c2');
      expect(p.category?.parentId, 'c1');
      expect(p.category?.parent, const Category(id: 'c1', name: 'Minuman'));
    });

    test('rejects a payload without the required id', () {
      expect(
        () => parse('{"name":"n","unit_id":"u"}'),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects a payload without unit_id', () {
      // unit_id, not unitId: the camelCase spelling must not be accepted.
      expect(
        () => parse('{"id":"p","name":"n","unitId":"u"}'),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
