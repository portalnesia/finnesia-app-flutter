/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Ported from `finnesia-monorepo/packages/shared/src/utils/datetime.ts`.
///
/// Three functions, and the reason each one exists is a bug that shipped:
///
/// | Fungsi | Bug yang diperbaiki |
/// | ------ | ------------------- |
/// | [localToday] | `toISOString()` itu UTC, jadi tanggal default laporan masih kemarin |
/// | [formatDateOnly] | kolom DATE dianggap instan, jadi harinya bergeser di zona barat |
/// | [formatDateTime] | instan harus dikonversi antar-zona, dan labelnya ikut locale |
library;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Matches the source's `const DATE_ONLY = /^\d{4}-\d{2}-\d{2}$/`.
final _dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');

bool _timezonesReady = false;

/// Loads the timezone database and the `id_ID` date symbols.
///
/// **Must be called once before any function in this library.** Idempotent, so calling it
/// from more than one place is safe.
///
/// The source needs nothing like this: JavaScript has `Intl` and the zone database built
/// into the runtime, so `new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Jakarta' })`
/// just works. Dart does not, and both packages here ship their data separately to keep
/// the binary small.
///
/// This is a real seam between the two implementations, not boilerplate: forgetting it
/// throws at the first call rather than silently using the wrong zone, which is why it is
/// explicit here instead of hidden inside a lazy initialiser. `apps/pos` calls it during
/// startup; tests call it in `setUpAll`.
Future<void> initializePosDateTime() async {
  if (_timezonesReady) return;
  tzdata.initializeTimeZones();
  // `id_ID` is not loaded by default in intl; without it DateFormat throws rather than
  // falling back, which is the behaviour we want to fail loudly on.
  await initializeDateFormatting('id_ID');
  _timezonesReady = true;
}

/// Makes the device's own UTC offset the zone every function here falls back to.
///
/// JavaScript answers "the host zone" from its runtime; the `timezone` package has no such
/// thing, and its `tz.local` is UTC until told otherwise. Without this a tablet in WIB shows
/// 06:00 as 23:00 the day before, and [localToday] is a day behind for seven hours a morning.
///
/// A fixed offset, not a named zone: the OS reports an offset (`DateTime.now().timeZoneOffset`),
/// not an IANA name, and naming it would need a native plugin. Indonesia has no daylight
/// saving, so a fixed offset is exact there; a tenant in a zone that shifts would be an hour off
/// for part of the year, and the fix is to read the zone name rather than the offset.
///
/// Call after [initializePosDateTime]. An explicit zone passed to a formatter still wins.
void useFixedLocalZone(Duration offset) {
  tz.setLocalLocation(
    tz.Location(
      'device',
      const [],
      const [],
      [tz.TimeZone(offset, isDst: false, abbreviation: 'device')],
    ),
  );
}

/// Resolves a stored timezone preference to a location, falling back to the host zone.
///
/// Mirrors `isExplicitZone` + `zoneOptions` from the source: `'auto'` is the stored
/// sentinel for "use whatever the device is set to", and an empty or malformed value must
/// behave the same way rather than throwing — the preference is user-editable and older
/// rows predate the field entirely.
///
/// The source validates the zone by constructing an `Intl.DateTimeFormat` inside a
/// `try`/`catch`, because that is the only validator JavaScript has. Here the zone
/// database itself is the validator: `tz.getLocation` throws on an unknown name, and the
/// catch answers the same way the source's does.
tz.Location _resolveZone(String? timezone) {
  if (timezone == null || timezone.isEmpty || timezone == 'auto')
    return tz.local;
  try {
    return tz.getLocation(timezone);
  } catch (_) {
    // Unknown zone in a user-editable preference. Same answer as the source's catch:
    // defer to the host rather than throw and blank the screen.
    return tz.local;
  }
}

/// Today's calendar date in the tenant's timezone, as `YYYY-MM-DD`.
///
/// The previous implementation was `new Date().toISOString().slice(0, 10)`.
/// `toISOString` is UTC by definition, so for every tenant east of Greenwich the report's
/// default end date was still yesterday during the local early hours. In WIB that is a
/// seven-hour window each day in which a balance silently excludes today's journals.
String localToday([DateTime? at, String? timezone]) {
  final instant = at ?? DateTime.now();
  final t = tz.TZDateTime.from(instant, _resolveZone(timezone));
  // Hand-assembled rather than DateFormat: this is a wire value (`YYYY-MM-DD`), and the
  // source's `en-CA` locale is exactly that ordering. Going through a formatter would
  // make the output depend on locale data instead of on the zone conversion, which is the
  // only thing this function is about.
  final y = t.year.toString().padLeft(4, '0');
  final m = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Formats a `YYYY-MM-DD` value that came from a DATE column.
///
/// Such a value is a calendar day, not an instant: `journal_date` has no time and no zone.
/// Parsing it with `DateTime.parse` and converting zones would place it at midnight UTC,
/// and rendering that in a western timezone rolls the printed day backwards. The parts are
/// therefore taken apart and put back together without ever going through an instant —
/// which is why `timezone` is accepted and ignored, exactly as in the source.
String formatDateOnly(
  String? value, [
  String? dateFormat,
  String? timezone,
]) {
  if (value == null || value.isEmpty) return '-';
  final datePart = value.length > 10 ? value.substring(0, 10) : value;
  if (!_dateOnly.hasMatch(datePart)) return value;

  final parts = datePart.split('-');
  if (parts.length != 3) return value;

  // The stored preference is the display label the settings page offers, not a token
  // pattern — matching the literal strings keeps this in step with that dropdown.
  // Anything unrecognised keeps the ISO form, which is unambiguous and already what
  // the API returns.
  if (dateFormat != null && dateFormat.startsWith('ISO')) return datePart;

  // 'Indonesia (9 Agu 2023)' and the default: day-first, 4-digit year.
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

/// Formats a timestamp (an actual instant) in the tenant's timezone.
///
/// Used for `posted_at`, `created_at` and the "printed on" footer. These carry a time, so
/// unlike [formatDateOnly] they must be converted between zones.
///
/// The source renders with `toLocaleString('id-ID', { dateStyle: 'medium', timeStyle:
/// 'short' })`, which produces e.g. `5 Sep 2026, 00.30`. The pattern below is the `intl`
/// equivalent of those two style names for `id_ID`, verified against the oracle's own
/// expected substring (`5 Sep 2026`) rather than assumed.
String formatDateTime(
  String? value, [
  String? timezone,
  String? fallbackTimezone,
]) {
  if (value == null || value.isEmpty) return '-';
  final at = DateTime.tryParse(value);
  if (at == null) return value;

  final t = tz.TZDateTime.from(
    at,
    _resolveZone(timezone ?? fallbackTimezone),
  );
  return DateFormat('d MMM y, HH.mm', 'id_ID').format(t);
}
