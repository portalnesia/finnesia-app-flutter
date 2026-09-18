/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/crash_report_fake.dart';
import 'package:test/test.dart';

void main() {
  group('FakeCrashReport', () {
    test('records every error it is asked to report, in order', () async {
      final crashReport = FakeCrashReport();
      final error = Exception('printer disconnected mid-chunk');

      await crashReport.recordError(error, null, reason: 'ble write');
      await crashReport.recordError('fatal boot failure', null, fatal: true);

      expect(crashReport.recorded, [
        (error: error, stack: null, reason: 'ble write', fatal: false),
        (error: 'fatal boot failure', stack: null, reason: null, fatal: true),
      ]);
    });

    test('records log breadcrumbs in order', () async {
      final crashReport = FakeCrashReport();

      await crashReport.log('shift opened');
      await crashReport.log('sale queued offline');

      expect(crashReport.logged, ['shift opened', 'sale queued offline']);
    });
  });
}
