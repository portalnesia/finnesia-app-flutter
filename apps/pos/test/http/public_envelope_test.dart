/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pos/http/public_envelope.dart';

void main() {
  group('readEnvelopeData', () {
    test('returns the object under `data`', () {
      expect(readEnvelopeData('{"data":{"status":"ready"}}'), {
        'status': 'ready',
      });
    });

    test('returns null for a body that is missing', () {
      expect(readEnvelopeData(null), isNull);
    });

    test('returns null for a body that is not JSON', () {
      // A gateway error page, or a proxy that answered in place of the API.
      expect(readEnvelopeData('upstream connect error'), isNull);
      expect(readEnvelopeData(''), isNull);
    });

    test('returns null for JSON that is not an object', () {
      expect(readEnvelopeData('[1,2]'), isNull);
      expect(readEnvelopeData('"data"'), isNull);
      expect(readEnvelopeData('null'), isNull);
    });

    test('returns null when there is no envelope', () {
      expect(readEnvelopeData('{"status":"ready"}'), isNull);
    });

    test('returns null when `data` is not an object', () {
      expect(readEnvelopeData('{"data":"ready"}'), isNull);
      expect(readEnvelopeData('{"data":[1]}'), isNull);
      expect(readEnvelopeData('{"data":null}'), isNull);
    });

    test('returns an empty map for `data` that is an empty object', () {
      // An empty object is an answer with nothing in it, which is not the same as no answer.
      expect(readEnvelopeData('{"data":{}}'), isEmpty);
      expect(readEnvelopeData('{"data":{}}'), isNotNull);
    });
  });
}
