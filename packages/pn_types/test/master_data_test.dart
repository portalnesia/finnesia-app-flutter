/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/master_data.dart';
import 'package:test/test.dart';

Map<String, dynamic> obj(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

void main() {
  group('Contact', () {
    test('reads the fields the customer picker shows', () {
      final c = Contact.fromJson(
        obj(
          '{"id":"c1","name":"Budi","type":"CUSTOMER","phone":"0812","email":"b@x.id"}',
        ),
      );

      expect(c.id, 'c1');
      expect(c.name, 'Budi');
      expect(c.type, ContactType.customer);
      expect(c.phone, '0812');
      expect(c.email, 'b@x.id');
    });

    test('reads a null field as null, not as an error', () {
      // The source declares these `string | null`: the API sends an explicit null.
      final c = Contact.fromJson(
        obj(
          '{"id":"c1","name":"Budi","type":"CUSTOMER","phone":null,"company_name":null}',
        ),
      );

      expect(c.phone, isNull);
      expect(c.companyName, isNull);
    });

    test('reads the wire type, not the Dart name', () {
      ContactType type(String wire) =>
          Contact.fromJson(obj('{"id":"c","name":"n","type":"$wire"}')).type!;

      expect(type('CUSTOMER'), ContactType.customer);
      expect(type('SUPPLIER'), ContactType.supplier);
      expect(type('SALES'), ContactType.sales);
    });

    test('reads a type this build does not know as null', () {
      expect(
        Contact.fromJson(obj('{"id":"c","name":"n","type":"PARTNER"}')).type,
        isNull,
      );
    });
  });

  group('CreateContactDTO', () {
    test('writes a customer as active, with the wire type', () {
      const dto = CreateContactDTO(name: 'Budi', type: ContactType.customer);

      expect(dto.toJson(), {
        'name': 'Budi',
        'type': 'CUSTOMER',
        'is_active': true,
      });
    });

    test('sends the optional fields that were filled in, and only those', () {
      final json = const CreateContactDTO(
        name: 'Budi',
        type: ContactType.customer,
        phone: '0812',
        companyName: 'CV Maju',
      ).toJson();

      expect(json['phone'], '0812');
      expect(json['company_name'], 'CV Maju');
      expect(json.containsKey('email'), isFalse);
      expect(json.containsKey('address'), isFalse);
    });
  });

  group('ChartOfAccount', () {
    test('reads the code and the name the account picker labels with', () {
      final a = ChartOfAccount.fromJson(
        obj(
          '{"id":"a1","code":"1-1100","name":"Kas Kecil","type":"ASSET","is_active":true}',
        ),
      );

      expect(a.id, 'a1');
      expect(a.code, '1-1100');
      expect(a.name, 'Kas Kecil');
    });
  });
}
