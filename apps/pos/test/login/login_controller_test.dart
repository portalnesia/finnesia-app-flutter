/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pos/login/native_login.dart';

import '../support/boot_rig.dart';

// `LoginController` itself has no other unit test file: its behaviour (cancel, resume, the
// `_problem` mapping) is exercised end to end through `login_screen_test.dart` and the pure
// logic through `native_login_test.dart`. This file is only for what those do not cover: the
// analytics events `signIn`/`resume` are expected to log.

const startedBody = '''
{"data":{"request_id":"req_abc",
 "login_url":"https://erp.perusahaan.com/api/auth/login?client=mobile&req=req_abc",
 "expires_in":300}}''';

const readyBody = '''
{"data":{"status":"ready","session_token":"sess_tok","session_refresh_token":"sess_ref",
 "expires_at":"2026-09-24T10:00:00Z",
 "user":{"id":"user_1","name":"Budi"},
 "companies":[{"id":"uc_1","user_id":"user_1","company_id":"comp_1","role":"cashier",
               "is_active":true}]}}''';

TransportResponse json(int status, String body) =>
    TransportResponse(status: status, body: body);

void main() {
  group('signIn analytics', () {
    test('logs login_started then login_succeeded', () async {
      final rig = Rig(storedSession(paired));
      final services = await rig.ready();
      rig.http
        ..respond(json(200, startedBody))
        ..respond(json(200, readyBody));

      await services.login.signIn();

      expect(rig.analytics.logged.map((e) => e.$1), [
        'login_started',
        'login_succeeded',
      ]);
    });

    test(
      'logs login_failed with the reason, not the server sentence',
      () async {
        final rig = Rig(storedSession(paired));
        final services = await rig.ready();
        rig.http.fail(TransportException('down'));

        await services.login.signIn();

        expect(rig.analytics.logged.map((e) => e.$1), [
          'login_started',
          'login_failed',
        ]);
        expect(rig.analytics.logged.last.$2, {'reason': 'unavailable'});
      },
    );
  });

  group('resume analytics', () {
    // Deliberately no events at all: `resumePendingLogin` completes without an exception both
    // when it recovers a login and when there was nothing to recover, and `LoginController`
    // cannot tell the two apart without a bigger change to `native_login.dart`
    // (`plan/firebase/progress.md`). Logging on that signal would report every ordinary boot as
    // a "resume", which is worse than not reporting it at all.
    test('logs nothing, even when it actually recovers a login', () async {
      final rig = Rig({...storedSession(paired), pendingLoginKey: 'req_abc'});
      final services = await rig.ready();
      rig.http.respond(json(200, readyBody));

      await services.login.resume();

      expect(services.session.current?.sessionToken, 'sess_tok');
      expect(rig.analytics.logged, isEmpty);
    });

    test('logs nothing when there was nothing to resume', () async {
      final rig = Rig(storedSession(paired));
      final services = await rig.ready();

      await services.login.resume();

      expect(rig.http.calls, isEmpty);
      expect(rig.analytics.logged, isEmpty);
    });
  });
}
