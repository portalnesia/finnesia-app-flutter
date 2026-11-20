/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/exit_notice_fake.dart';
import 'package:pn_types/src/native/exit_notice_port.dart';
import 'package:test/test.dart';

void main() {
  group('FakeExitNotice', () {
    const notice = ExitNotice(title: 'Shift masih aktif', body: 'Shift SH-1');

    test(
      'holds the latest notice, and records every change in order',
      () async {
        final port = FakeExitNotice();

        await port.setNotice(notice);
        await port.setNotice(null);

        expect(port.changes, [notice, null]);
        expect(port.current, isNull);
      },
    );

    // The failure path the port rules require.
    test('throws a queued failure, and still records the change', () async {
      final port = FakeExitNotice()..failNext(ExitNoticeException('no host'));

      await expectLater(
        port.setNotice(notice),
        throwsA(isA<ExitNoticeException>()),
      );
      expect(port.changes, [notice]);
    });

    test('fails once per queued failure, then works again', () async {
      final port = FakeExitNotice()..failNext(ExitNoticeException('no host'));

      await expectLater(
        port.setNotice(notice),
        throwsA(isA<ExitNoticeException>()),
      );
      await port.setNotice(notice);

      expect(port.current, notice);
    });

    test('hands a close the platform held to whoever listens', () {
      final port = FakeExitNotice();
      var heard = 0;
      port.onCloseRequested = () => heard++;

      port.requestClose();

      expect(heard, 1);
    });

    test('a close nobody listens for goes nowhere', () {
      final port = FakeExitNotice()..onCloseRequested = null;

      port.requestClose();
    });

    test('compares notices by their text', () {
      expect(
        const ExitNotice(title: 'a', body: 'b'),
        const ExitNotice(title: 'a', body: 'b'),
      );
      expect(
        const ExitNotice(title: 'a', body: 'b'),
        isNot(const ExitNotice(title: 'a', body: 'c')),
      );
    });
  });
}
