/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/opener_fake.dart';
import 'package:pn_types/src/native/opener_port.dart';
import 'package:test/test.dart';

void main() {
  group('FakeOpener', () {
    test('records every URL it is asked to open, in order', () async {
      final opener = FakeOpener();

      await opener.openUrl('https://erp.perusahaan.com/a');
      await opener.openUrl('https://erp.perusahaan.com/b');

      expect(opener.opened, [
        'https://erp.perusahaan.com/a',
        'https://erp.perusahaan.com/b',
      ]);
    });

    // The failure path the port rules require: a test that cannot make the browser fail never
    // exercises what login does about it.
    test('throws a queued failure, and still records the URL', () async {
      final opener = FakeOpener()..failNext(OpenerException('no browser'));

      await expectLater(
        opener.openUrl('https://erp.perusahaan.com/a'),
        throwsA(isA<OpenerException>()),
      );
      expect(opener.opened, ['https://erp.perusahaan.com/a']);
    });

    test('fails once per queued failure, then works again', () async {
      final opener = FakeOpener()..failNext(OpenerException('no browser'));

      await expectLater(opener.openUrl('a'), throwsA(isA<OpenerException>()));
      await opener.openUrl('b');

      expect(opener.opened, ['a', 'b']);
    });

    // The URL carries a request id, and this text ends up in test output and CI logs.
    test('does not put the URL in its exception text', () {
      expect(OpenerException('no browser').toString(), isNot(contains('http')));
    });
  });
}
