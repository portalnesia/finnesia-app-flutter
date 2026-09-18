/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/preferences_fake.dart';
import 'package:pn_types/src/native/preferences_port.dart';
import 'package:pos/preferences/enum_preference.dart';

enum Colour { red, green, blue }

EnumPreference<Colour> preference(FakePreferences port) => EnumPreference(
  port: port,
  key: 'colour',
  values: Colour.values,
  fallback: Colour.green,
);

void main() {
  group('enum preference', () {
    test('is the fallback until it has been loaded', () {
      final pref = preference(FakePreferences({'colour': 'blue'}));

      expect(pref.value, Colour.green);
    });

    test('takes the stored value on load and tells its listeners', () async {
      final pref = preference(FakePreferences({'colour': 'blue'}));
      var notified = 0;
      pref.addListener(() => notified++);

      await pref.load();

      expect(pref.value, Colour.blue);
      expect(notified, 1);
    });

    test('keeps the fallback when nothing was ever stored', () async {
      final pref = preference(FakePreferences());

      await pref.load();

      expect(pref.value, Colour.green);
    });

    test(
      'keeps the fallback when the stored value is not one of the choices',
      () async {
        // A name an older build wrote, or storage that was edited: neither may throw at start.
        final pref = preference(FakePreferences({'colour': 'purple'}));

        await pref.load();

        expect(pref.value, Colour.green);
      },
    );

    test('keeps the fallback when the storage cannot be read', () async {
      final port = FakePreferences({'colour': 'blue'})
        ..failNextRead(PreferencesException('unreadable'));
      final pref = preference(port);

      await pref.load();

      expect(pref.value, Colour.green);
    });

    group('a load that is still in flight', () {
      test('does not overwrite a choice made in the meantime', () async {
        final port = FakePreferences({'colour': 'blue'})..holdReads();
        final pref = preference(port);

        final loading = pref.load();
        await pref.select(Colour.red);
        port.releaseReads();
        await loading;

        expect(pref.value, Colour.red);
      });

      test('does not overwrite a choice that equals the value shown', () async {
        // Green is on screen; the cashier taps green while the stored blue is still coming.
        final port = FakePreferences({'colour': 'blue'})..holdReads();
        final pref = preference(port);

        final loading = pref.load();
        await pref.select(Colour.green);
        port.releaseReads();
        await loading;

        expect(pref.value, Colour.green);
      });

      test('does not notify a listener that was disposed', () async {
        final port = FakePreferences({'colour': 'blue'})..holdReads();
        final pref = preference(port);

        final loading = pref.load();
        pref.dispose();
        port.releaseReads();

        await expectLater(loading, completes);
      });
    });

    group('select', () {
      test(
        'changes the value, tells its listeners and stores the name',
        () async {
          final port = FakePreferences();
          final pref = preference(port);
          var notified = 0;
          pref.addListener(() => notified++);

          await pref.select(Colour.red);

          expect(pref.value, Colour.red);
          expect(notified, 1);
          expect(port.values, {'colour': 'red'});
        },
      );

      test('does nothing when the choice is already the value', () async {
        final port = FakePreferences();
        final pref = preference(port);
        var notified = 0;
        pref.addListener(() => notified++);

        await pref.select(Colour.green);

        expect(notified, 0);
        expect(port.writes, isEmpty);
      });

      test(
        'still applies the choice when the storage cannot be written',
        () async {
          final port = FakePreferences()
            ..failNextWrite(PreferencesException('full'));
          final pref = preference(port);

          await pref.select(Colour.red);

          expect(pref.value, Colour.red);
        },
      );
    });
  });
}
