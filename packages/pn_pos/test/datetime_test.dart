/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/datetime.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/packages/shared/src/utils/datetime.test.ts`.
// Inputs and expectations are copied unchanged; only the syntax changed
// (describe/it -> group/test, toBe -> equals). 15 cases.
//
// Two JS-specific cases are adapted rather than copied verbatim, both marked below: the
// source's `timezone === 'auto'` sentinel and its "unknown zone" fallback both mean "use
// the host zone", and the host zone differs between the two runtimes. The Dart tests
// assert the same *relationship* the source asserts (equals the host's own answer) rather
// than a fixed string, because pinning a string would be asserting the machine, not the
// code.
void main() {
  // Both data sets are loaded explicitly: JavaScript has `Intl` and the zone database in
  // the runtime, Dart does not. Without this every test throws rather than silently using
  // the wrong zone — which is the failure mode we want.
  setUpAll(initializePosDateTime);

  group('localToday', () {
    test(
        'returns the Jakarta date, not the UTC date, during the WIB '
        'early-morning window', () {
      // 2026-09-04T17:30Z is 2026-09-05 00:30 in Jakarta (WIB, UTC+7).
      // The old helper did new Date().toISOString().slice(0, 10), which is the UTC
      // calendar day and therefore a day behind for every tenant east of Greenwich.
      final at = DateTime.parse('2026-09-04T17:30:00Z');
      expect(localToday(at, 'Asia/Jakarta'), equals('2026-09-05'));
    });

    test('returns the UTC date when the tenant timezone is UTC', () {
      final at = DateTime.parse('2026-09-04T17:30:00Z');
      expect(localToday(at, 'UTC'), equals('2026-09-04'));
    });

    test('uses the host timezone when the preference is "auto"', () {
      final at = DateTime.parse('2026-09-04T17:30:00Z');
      // "auto" and a null/absent preference are the same request — defer to the host.
      // The host zone itself differs between the JS and Dart runtimes, so this asserts
      // the *equivalence* the source asserts, not a fixed date string: pinning a string
      // here would be asserting the machine the test runs on.
      expect(localToday(at, 'auto'), equals(localToday(at, null)));
      expect(localToday(at, ''), equals(localToday(at, null)));
    });

    test('treats a missing preference as "auto" rather than throwing', () {
      final at = DateTime.parse('2026-09-04T17:30:00Z');
      expect(localToday(at, null), equals(localToday(at, 'auto')));
    });

    test('falls back to the host when the stored timezone is unknown', () {
      final at = DateTime.parse('2026-09-04T17:30:00Z');
      expect(localToday(at, 'Mars/Olympus'), equals(localToday(at, 'auto')));
    });
  });

  group('formatDateOnly', () {
    test('renders a date-only column without shifting the day', () {
      // journal_date is a DATE column: it carries no time, so it must be parsed as a
      // local calendar date. Treating it as an instant and rendering it in a western
      // zone is what made rows appear on the wrong day. The default display is
      // day-first, so 2026-09-04 prints as 04/09/2026 in every zone.
      expect(formatDateOnly('2026-09-04', null, 'Asia/Jakarta'),
          equals('04/09/2026'));
      expect(formatDateOnly('2026-09-04', null, 'UTC'), equals('04/09/2026'));
    });

    test('is stable for a Makassar tenant (UTC+8)', () {
      expect(formatDateOnly('2026-03-01', null, 'Asia/Makassar'),
          equals('01/03/2026'));
    });

    test('honours the ISO date_format preference', () {
      // The settings page stores the display label, not a token pattern.
      expect(
        formatDateOnly('2026-09-04', 'ISO (2023-08-09)', 'Asia/Jakarta'),
        equals('2026-09-04'),
      );
    });

    test('honours the Indonesia date_format preference', () {
      expect(
        formatDateOnly('2026-09-04', 'Indonesia (9 Agu 2023)', 'Asia/Jakarta'),
        equals('04/09/2026'),
      );
    });

    test('returns the raw value when the input is not a date', () {
      expect(formatDateOnly('not-a-date', null, 'Asia/Jakarta'),
          equals('not-a-date'));
    });

    test('returns a dash for empty input', () {
      expect(formatDateOnly('', null, 'Asia/Jakarta'), equals('-'));
    });

    test('still renders a legacy timestamp-shaped value as the right day', () {
      // Rows written before the backend switched DATE columns to ISODate carry a full
      // "2026-09-05T00:00:00Z". They must not render as raw ISO text, and must not be
      // re-interpreted as an instant — the day is whatever the string says.
      expect(
        formatDateOnly('2026-09-05T00:00:00Z', null, 'Asia/Jakarta'),
        equals('05/09/2026'),
      );
      expect(
        formatDateOnly(
            '2026-09-05T00:00:00Z', 'ISO (2023-08-09)', 'Asia/Jakarta'),
        equals('2026-09-05'),
      );
    });
  });

  group('formatDateTime', () {
    test('renders an instant in the tenant timezone', () {
      // 17:30 UTC is 00:30 on the following day in Jakarta, so the date must roll over.
      const at = '2026-09-04T17:30:00Z';
      expect(formatDateTime(at, 'Asia/Jakarta', 'Asia/Jakarta'),
          contains('5 Sep 2026'));
    });

    test('shows a different clock than UTC for the same instant', () {
      const at = '2026-09-04T17:30:00Z';
      expect(
        formatDateTime(at, 'Asia/Jakarta', 'Asia/Jakarta'),
        isNot(equals(formatDateTime(at, 'UTC', 'UTC'))),
      );
    });

    test('returns the raw value when the input is unparseable', () {
      expect(
          formatDateTime('garbage', null, 'Asia/Jakarta'), equals('garbage'));
    });
  });

  // Written new: JavaScript answers "the host zone" from the runtime, and `timezone` has no
  // such thing (its `tz.local` is UTC until told otherwise), so the device's zone has to be
  // handed in. A tablet in WIB that formats in UTC shows a shift opened at 06:00 as 23:00 the
  // day before, and calls it stale.
  group('useFixedLocalZone', () {
    tearDown(() => useFixedLocalZone(Duration.zero));

    test('makes the host zone the offset it was given', () {
      useFixedLocalZone(const Duration(hours: 7));

      expect(formatDateTime('2026-09-19T23:30:00Z'), contains('20 Sep 2026'));
      expect(localToday(DateTime.utc(2026, 9, 19, 23, 30)), '2026-09-20');
    });

    test('still leaves an explicit zone alone', () {
      useFixedLocalZone(const Duration(hours: 7));

      expect(
        formatDateTime('2026-09-19T23:30:00Z', 'UTC'),
        contains('19 Sep 2026'),
      );
    });

    test('goes back to UTC when given no offset', () {
      useFixedLocalZone(const Duration(hours: 7));
      useFixedLocalZone(Duration.zero);

      expect(localToday(DateTime.utc(2026, 9, 19, 23, 30)), '2026-09-19');
    });
  });
}
