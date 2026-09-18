/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/query.dart';
import 'package:test/test.dart';

// The expected strings below are what `URLSearchParams` produces. They were not written
// from memory: `plan/api-client/findings.md` records the differential run of this encoder
// against `URLSearchParams` over every printable ASCII character and a set of multi-byte
// inputs.

void main() {
  group('jsQueryEncode', () {
    test('keeps letters, digits and - . _ * as they are', () {
      expect(jsQueryEncode('AZaz09-._*'), 'AZaz09-._*');
    });

    test('turns a space into +', () {
      expect(jsQueryEncode('Rp 10'), 'Rp+10');
    });

    // The two characters where URLSearchParams and Dart's Uri.encodeQueryComponent
    // disagree. Both are right by their own spec; the request must match the web app.
    test('leaves * alone and encodes ~, unlike Uri.encodeQueryComponent', () {
      expect(jsQueryEncode('a*b'), 'a*b');
      expect(jsQueryEncode('a~b'), 'a%7Eb');
    });

    test('percent-encodes reserved characters in uppercase hex', () {
      expect(jsQueryEncode('a&b=c+d%e#f?g/h'), 'a%26b%3Dc%2Bd%25e%23f%3Fg%2Fh');
      expect(jsQueryEncode("o'brien"), 'o%27brien');
      expect(jsQueryEncode('!()'), '%21%28%29');
    });

    test('encodes multi-byte characters as their UTF-8 bytes', () {
      expect(jsQueryEncode('é'), '%C3%A9');
      expect(jsQueryEncode('中'), '%E4%B8%AD');
      expect(jsQueryEncode('😀'), '%F0%9F%98%80');
    });

    test('encodes control characters and DEL', () {
      expect(jsQueryEncode('\u0000'), '%00');
      expect(jsQueryEncode('\u001f'), '%1F');
      expect(jsQueryEncode('\u007f'), '%7F');
      expect(jsQueryEncode('a\nb'), 'a%0Ab');
    });

    test('is empty for an empty string', () {
      expect(jsQueryEncode(''), '');
    });
  });

  group('buildQueryString', () {
    test('joins key=value pairs with &, in insertion order', () {
      expect(
        buildQueryString({'shift_id': 's1', 'page_size': 50}),
        'shift_id=s1&page_size=50',
      );
    });

    // The source drops undefined, null and the empty string, and nothing else. A cleared
    // search box must not send `q=`, but page 0 and `false` are real values.
    test('drops null and empty-string values', () {
      expect(buildQueryString({'q': '', 'cursor': null, 'a': 'x'}), 'a=x');
    });

    test('keeps zero, false and the string "0"', () {
      expect(
        buildQueryString({'page': 0, 'active': false, 's': '0'}),
        'page=0&active=false&s=0',
      );
    });

    test('writes true and false as words', () {
      expect(buildQueryString({'active': true}), 'active=true');
    });

    test('is empty when there is nothing to send', () {
      expect(buildQueryString({}), '');
      expect(buildQueryString({'q': '', 'x': null}), '');
    });

    test('encodes keys as well as values', () {
      expect(buildQueryString({'a b': 'c&d'}), 'a+b=c%26d');
    });

    // The source lets `String(v)` swallow anything. A list or a map in a query is a
    // caller bug, and a double prints differently in Dart than in JavaScript (2.0 vs 2).
    test('rejects a value that is not a string, int or bool', () {
      expect(() => buildQueryString({'a': 2.5}), throwsArgumentError);
      expect(
        () => buildQueryString({
          'a': [1, 2],
        }),
        throwsArgumentError,
      );
    });
  });
}
