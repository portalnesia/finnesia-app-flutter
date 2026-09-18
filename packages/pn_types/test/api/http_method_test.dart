/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/http_method.dart';
import 'package:test/test.dart';

void main() {
  group('HttpMethod', () {
    // The wire string goes straight into the request line, so a typo here is a request
    // the server never routes.
    test('carries the uppercase verb the request line needs', () {
      expect(HttpMethod.get.wire, 'GET');
      expect(HttpMethod.post.wire, 'POST');
      expect(HttpMethod.put.wire, 'PUT');
      expect(HttpMethod.patch.wire, 'PATCH');
      expect(HttpMethod.delete.wire, 'DELETE');
    });

    test('has exactly the five methods the source declares', () {
      expect(HttpMethod.values, hasLength(5));
    });
  });
}
