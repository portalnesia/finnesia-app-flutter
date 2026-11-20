/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/app_exit_fake.dart';
import 'package:pn_types/src/native/app_exit_port.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAppExit', () {
    test('records every exit it is asked for', () async {
      final appExit = FakeAppExit();

      await appExit.exit();
      await appExit.exit();

      expect(appExit.exits, 2);
    });

    // The failure path the port rules require: a caller that cannot make the exit fail never
    // exercises what it does when the platform refuses.
    test('throws a queued failure, and still records the attempt', () async {
      final appExit = FakeAppExit()..failNext(AppExitException('refused'));

      await expectLater(appExit.exit(), throwsA(isA<AppExitException>()));
      expect(appExit.exits, 1);
    });

    test('fails once per queued failure, then works again', () async {
      final appExit = FakeAppExit()..failNext(AppExitException('refused'));

      await expectLater(appExit.exit(), throwsA(isA<AppExitException>()));
      await appExit.exit();

      expect(appExit.exits, 2);
    });
  });
}
