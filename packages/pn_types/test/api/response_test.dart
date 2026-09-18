/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/api/response.dart';
import 'package:test/test.dart';

List<int> ints(Object? json) => (json as List<Object?>).cast<int>();

ResponseData<List<int>> parse(String json) =>
    ResponseData.fromJson(jsonDecode(json) as Map<String, dynamic>, ints);

void main() {
  group('ResponseData.fromJson', () {
    test('hands the data value to the caller-supplied parser', () {
      expect(parse('{"data":[1,2,3]}').data, [1, 2, 3]);
    });

    test('reads the cursor pagination meta', () {
      final r = parse(
        '''
        {"data":[1],"meta":{"next_cursor":"abc","prev_cursor":"xyz","page_size":20,"page":2,"total":42}}''',
      );

      expect(r.meta?.nextCursor, 'abc');
      expect(r.meta?.prevCursor, 'xyz');
      expect(r.meta?.pageSize, 20);
      expect(r.meta?.page, 2);
      expect(r.meta?.total, 42);
    });

    test('has no meta when the response carries none', () {
      expect(parse('{"data":[1]}').meta, isNull);
    });

    // The last page has no next cursor. The wire sends an explicit null, and a missing
    // key means the same thing — the caller must not have to tell them apart.
    test('reads a null cursor and an absent cursor the same way', () {
      expect(
        parse('{"data":[],"meta":{"next_cursor":null}}').meta?.nextCursor,
        isNull,
      );
      expect(parse('{"data":[],"meta":{"page":1}}').meta?.nextCursor, isNull);
    });

    test('reads the message and error of a failed envelope', () {
      final r = parse(
        '''
        {"data":[],"message":"Not found","error":{"code":404,"description":"No such sale"}}''',
      );

      expect(r.message, 'Not found');
      expect(r.error?.code, 404);
      expect(r.error?.description, 'No such sale');
    });

    test('leaves message and error null on a plain success', () {
      final r = parse('{"data":[]}');

      expect(r.message, isNull);
      expect(r.error, isNull);
    });

    // `data` may be absent or null (a delete returns nothing). The parser decides what
    // that means for its own type; the envelope must not throw before it gets the chance.
    test('passes an absent or null data to the parser as null', () {
      Object? seen = 'untouched';
      ResponseData.fromJson(<String, dynamic>{}, (json) => seen = json);
      expect(seen, isNull);

      seen = 'untouched';
      ResponseData.fromJson(<String, dynamic>{
        'data': null,
      }, (json) => seen = json);
      expect(seen, isNull);
    });

    test('lets a parser failure surface instead of swallowing it', () {
      expect(() => parse('{"data":"not a list"}'), throwsA(isA<TypeError>()));
    });
  });
}
