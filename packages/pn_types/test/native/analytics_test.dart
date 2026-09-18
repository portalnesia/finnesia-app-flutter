/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAnalytics', () {
    test('records every event it is asked to log, in order', () async {
      final analytics = FakeAnalytics();

      await analytics.logEvent('checkout_completed', parameters: {'total': 1});
      await analytics.logEvent('shift_closed');

      // Record equality is field-wise `==`, and `Map` is identity-only — so the parameters are
      // asserted separately rather than folded into one record comparison.
      expect(analytics.logged.map((e) => e.$1), [
        'checkout_completed',
        'shift_closed',
      ]);
      expect(analytics.logged[0].$2, {'total': 1});
      expect(analytics.logged[1].$2, isNull);
    });
  });
}
