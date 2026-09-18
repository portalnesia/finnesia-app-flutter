/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:flutter/material.dart';
import 'package:pn_pos/src/pos_hold_fake.dart';
import 'package:pn_pos/src/pos_pending_sale_fake.dart';
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pn_types/src/native/app_info_fake.dart';
import 'package:pn_types/src/native/device_info_fake.dart';
import 'package:pn_types/src/native/link_port.dart';
import 'package:pn_types/src/native/opener_fake.dart';
import 'package:pn_types/src/native/preferences_fake.dart';
import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pos/native/scanner/scanner_fake.dart';
import 'package:pn_types/src/native/public_http_fake.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/preferences/app_preferences.dart';
import 'package:pos/preferences/enum_preference.dart';
import 'package:pos/session/session_holder.dart';

const paired = PosSession(
  baseUrl: 'https://erp.perusahaan.com',
  companyId: 'comp_1',
  outletId: 'out_1',
  sessionToken: 'tok_secret_value',
  sessionRefreshToken: 'refresh_secret_value',
  deviceToken: 'dev_tok_1',
);

/// The ports the app is wired with, all fakes, so a test can look at what went through them.
class Rig {
  /// [store] replaces the default one, for a test that needs a store that misbehaves.
  Rig([Map<String, String> stored = const {}, FakeStorePort? store])
    : store = store ?? FakeStorePort(stored);

  final FakeStorePort store;
  final http = FakePublicHttp();
  final opener = FakeOpener();

  /// Where held baskets are kept: in memory, since the real one is SQLite behind a platform plugin.
  final holdStore = FakeHoldOrderStore();

  /// Where sales that have not reached the server are kept: in memory, for the same reason.
  final pendingSaleStore = FakePendingSaleStore();
  final preferences = FakePreferences();

  /// Every event the app logged, so a test can assert on it.
  final analytics = FakeAnalytics();

  /// The platform identifier used as the device fingerprint. A fixed value, so a test can assert
  /// what pairing sent without a platform plugin.
  final deviceInfo = FakeDeviceInfo();

  /// The build the Menu shows. Set `answer` to `null` to be a platform that cannot say.
  final appInfo = FakeAppInfo();

  /// The thermal printer. Finds nothing until a test hands it devices: `printer = FakePrinter([..])`.
  FakePrinter printer = FakePrinter();

  /// The camera that reads the pairing QR. Reads nothing until a test says so: `scanner.read(..)`.
  final scanner = FakeScanner();

  // The same objects the app is given, so a test can pick a language the way a cashier does.
  late final EnumPreference<AppLanguage> language = languagePreference(
    preferences,
  );
  late final EnumPreference<ThemeMode> theme = themePreference(preferences);

  /// The clock the app reads, so a session can be "one day from expiring" without waiting.
  DateTime now = DateTime.utc(2026, 9, 20, 12);

  /// The wait between two login polls. No real waiting by default: a poll loop that wants to
  /// wait is driven by the test. The login screen is the one screen that can be *in* that wait,
  /// so a test of it needs to say when the wait ends.
  Future<void> Function() delay = () async {};

  /// How long a login may take. A test that wants the timeout path moves [now] instead of
  /// waiting for it.
  Duration pollTimeout = const Duration(minutes: 5);

  /// The offset the OS would report for the tablet. UTC by default, so a test does not depend on
  /// the zone of the machine it runs on.
  Duration deviceOffset = Duration.zero;

  Future<BootResult> boot() => _boot(http);

  /// Like [boot], over another HTTP port: a test that needs a request held open passes its own.
  Future<BootResult> bootWith({required PublicHttpPort http}) => _boot(http);

  /// Like [boot], over another HTTP port **and** a link port: a test of the Windows App Link
  /// needs to feed links into the same app the held HTTP serves.
  Future<BootResult> bootWithLink({
    required PublicHttpPort http,
    required LinkPort link,
  }) => _boot(http, link: link);

  Future<BootResult> _boot(PublicHttpPort http, {LinkPort? link}) => bootstrap(
    store: store,
    http: http,
    opener: opener,
    holdStore: holdStore,
    // Honours the company, like the real factory does. This used to discard the argument and
    // hand back [pendingSaleStore] whatever it was asked for, which meant the rig could never
    // build a store bound to a different company than the session — the exact condition the
    // cross-tenant guard exists to catch, and therefore the exact bug the tests could not see
    // (`tenant_rebind_test.dart`). Falling back to the rig's own store when the company matches
    // keeps every existing test's handle on the queue valid.
    pendingSaleStore: (companyId) => companyId == pendingSaleStore.companyId
        ? pendingSaleStore
        : FakePendingSaleStore(companyId: companyId),
    deviceInfo: deviceInfo,
    appInfo: appInfo,
    printer: printer,
    scanner: scanner,
    analytics: analytics,
    language: language,
    theme: theme,
    link: link,
    delay: delay,
    pollTimeout: pollTimeout,
    now: () => now,
    deviceOffset: () => deviceOffset,
  );

  /// Boots and expects the app to come up.
  Future<AppServices> ready() async {
    final result = await boot();
    expect(result, isA<BootReady>());
    return (result as BootReady).services;
  }
}

TransportResponse jsonOk() => TransportResponse(
  status: 200,
  headers: const {'Content-Type': 'application/json'},
  body: '{"data":1}',
);

/// What the backend answers to an activation with no `custom_domain`.
///
/// `status`, `revoked_at` and `last_seen_at` are deliberately absent: the device registry
/// removed them, and the app never read them. Presence is derived server-side now.
TransportResponse activatedResponse() => TransportResponse(
  status: 200,
  body: jsonEncode({
    'data': {
      'device': {
        'id': '01JDEV',
        'company_id': 'comp_1',
        'outlet_id': 'out_1',
        'name': 'Tablet Kasir 1',
        'device_fingerprint': '01J8ZQ000000000000000000AB',
        'activated_at': '2026-09-17T10:00:00Z',
        'created_at': '2026-09-17T10:00:00Z',
        'updated_at': '2026-09-17T10:00:00Z',
      },
      'branding': {'app_name': 'Toko Budi', 'account_mode': 'self_service'},
      'device_token': 'dev_tok_1',
    },
  }),
);

const loginUrl =
    'https://erp.perusahaan.com/api/auth/login?client=mobile&req=req_abc';

/// A poll answer saying the cashier finished signing in.
TransportResponse readyResponse() => TransportResponse(
  status: 200,
  body:
      '{"data":{"status":"ready","session_token":"sess_tok",'
      '"session_refresh_token":"sess_ref","expires_at":"2026-09-24T10:00:00Z",'
      '"user":{"id":"user_1","name":"Budi"},'
      '"companies":[{"id":"uc_1","user_id":"user_1","company_id":"comp_1",'
      '"role":"cashier","is_active":true}]}}',
);

/// What `/api/auth/refresh` answers: a new pair, and when the session now ends.
TransportResponse refreshedResponse() => TransportResponse(
  status: 200,
  body:
      '{"data":{"session_token":"tok_new","session_refresh_token":"ref_new",'
      '"expires_at":"2026-09-27T12:00:00Z"}}',
);

/// [paired], ending at [end] (or with no end at all).
PosSession endingAt(DateTime? end) =>
    paired.copyWith(expiresAt: end?.toUtc().toIso8601String());

Map<String, String> storedSession(PosSession s) => {
  sessionKey: jsonEncode(s.toJson()),
};
