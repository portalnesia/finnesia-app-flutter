/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/parsers.dart';
import 'package:pn_types/src/category.dart';
import 'package:test/test.dart';

// Every failure below is a TypeError on purpose: `ApiClient.request` turns exactly that
// (plus FormatException and ArgumentError) into an ApiError, so a payload that does not fit
// the model never reaches the UI as a crash.

void main() {
  group('parseObject', () {
    test('builds the model from a JSON object', () {
      final c = parseObject(Category.fromJson)({'id': 'c1', 'name': 'Minuman'});

      expect(c, const Category(id: 'c1', name: 'Minuman'));
    });

    test('rejects a value that is not an object', () {
      expect(
        () => parseObject(Category.fromJson)([1]),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => parseObject(Category.fromJson)(null),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('parseList', () {
    test('builds one model per element, in order', () {
      final list = parseList(Category.fromJson)([
        {'id': 'c1', 'name': 'A'},
        {'id': 'c2', 'name': 'B'},
      ]);

      expect(list.map((c) => c.id), ['c1', 'c2']);
    });

    test('is empty for an empty list', () {
      expect(parseList(Category.fromJson)([]), isEmpty);
    });

    test('rejects a value that is not a list', () {
      expect(
        () => parseList(Category.fromJson)({'id': 'c1'}),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => parseList(Category.fromJson)(null),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects a list with an element that is not an object', () {
      expect(
        () => parseList(Category.fromJson)([
          {'id': 'c1', 'name': 'A'},
          'oops',
        ]),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('parseOrNull', () {
    // `pos.shifts.getActive` answers null when no shift is open — an ordinary state, not a
    // malformed response.
    test('is null for null', () {
      expect(parseOrNull(Category.fromJson)(null), isNull);
    });

    test('builds the model otherwise', () {
      expect(
        parseOrNull(Category.fromJson)({'id': 'c1', 'name': 'A'}),
        const Category(id: 'c1', name: 'A'),
      );
    });

    test('still rejects a value that is neither null nor an object', () {
      expect(
        () => parseOrNull(Category.fromJson)('x'),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('parseStrings', () {
    test('reads a JSON array of strings, in order', () {
      expect(parseStrings(['pos.cashier.access', '*']), [
        'pos.cashier.access',
        '*',
      ]);
    });

    test('reads null as empty', () {
      // A Go nil slice marshals to `null`, not `[]`: `GET /team/my-permissions` ends in a
      // repository call that can return one, and "no permissions" must not be an error.
      expect(parseStrings(null), isEmpty);
    });

    test('reads an empty array as empty', () {
      expect(parseStrings(<Object?>[]), isEmpty);
    });

    test('rejects an element that is not a string', () {
      // Eagerly: a lazy `cast` would let the wrong type through and fail later, at the
      // first `contains`, far from the response that caused it.
      expect(() => parseStrings(['ok', 7]), throwsA(isA<TypeError>()));
    });

    test('rejects a value that is not an array', () {
      expect(() => parseStrings({'a': 1}), throwsA(isA<TypeError>()));
    });
  });

  group('parseStock', () {
    test('reads product id to quantity, whole or fractional', () {
      expect(parseStock({'p1': 3, 'p2': 2.5, 'p3': 0}), {
        'p1': 3,
        'p2': 2.5,
        'p3': 0,
      });
    });

    test('is empty for an empty object', () {
      expect(parseStock(<String, dynamic>{}), isEmpty);
    });

    test('rejects a quantity that is not a number', () {
      expect(() => parseStock({'p1': '3'}), throwsA(isA<TypeError>()));
    });

    test('rejects a value that is not an object', () {
      expect(() => parseStock([1]), throwsA(isA<TypeError>()));
      expect(() => parseStock(null), throwsA(isA<TypeError>()));
    });
  });

  group('parseNothing and parseRaw', () {
    test(
      'parseNothing accepts whatever the server sent and returns nothing',
      () {
        expect(() => parseNothing(null), returnsNormally);
        expect(() => parseNothing({'x': 1}), returnsNormally);
      },
    );

    // Endpoints whose model is not ported yet. The value is handed over untouched so the
    // day the model lands, the change is one line in the registry.
    test('parseRaw hands the data over untouched', () {
      const data = {'a': 1};

      expect(identical(parseRaw(data), data), isTrue);
      expect(parseRaw(null), isNull);
    });
  });
}
