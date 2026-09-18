/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/environment.dart';
import 'package:test/test.dart';

// `dart test` is a JIT run, so `isDebugApp` is true here and only the debug branch of
// `canonicalHost` executes. The release branch is proven on the APK instead — see
// `plan/api-client/README.md` §13.7 and §15.

void main() {
  group('canonicalHost', () {
    test('production is https://apps.finnesia.com', () {
      expect(
        canonicalHost(EndpointEnvironment.production),
        'https://apps.finnesia.com',
      );
    });

    test('staging is https://apps-dev.finnesia.com', () {
      expect(
        canonicalHost(EndpointEnvironment.staging),
        'https://apps-dev.finnesia.com',
      );
    });

    test('lokal is http://localhost:4000', () {
      expect(canonicalHost(EndpointEnvironment.lokal), 'http://localhost:4000');
    });
  });

  group('canChooseEndpoint', () {
    test('a debug app that is not paired yet may choose', () {
      expect(canChooseEndpoint(isPaired: false), isTrue);
    });

    // The hole this closes: a tablet paired to staging being moved to production would
    // post real sales to the production database from a device registered nowhere there.
    test('a paired device may not choose', () {
      expect(canChooseEndpoint(isPaired: true), isFalse);
    });

    // Release has exactly one endpoint, so there is nothing to choose — paired or not.
    test('a release app never may, even before pairing', () {
      expect(canChooseEndpoint(isPaired: false, debug: false), isFalse);
      expect(canChooseEndpoint(isPaired: true, debug: false), isFalse);
    });

    test('a debug app before pairing may', () {
      expect(canChooseEndpoint(isPaired: false, debug: true), isTrue);
    });
  });
}
