/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/opener_fake.dart';
import 'package:pn_types/src/native/opener_port.dart';
import 'package:pn_types/src/native/public_http_fake.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:pos/login/native_login.dart';
import 'package:pos/session/session_holder.dart';

// See `plan/api-client/findings.md` for the tests that were added, and why.

const tenantHost = 'https://erp.perusahaan.com';

const paired = PosSession(
  baseUrl: tenantHost,
  companyId: 'comp_1',
  outletId: 'out_1',
  deviceName: 'Tablet Kasir 1',
  sessionToken: '',
  branding: PosBranding(appName: 'Toko Budi', accountMode: 'self_service'),
);

const startedBody = '''
{"data":{"request_id":"req_abc",
 "login_url":"https://erp.perusahaan.com/api/auth/login?client=mobile&req=req_abc",
 "expires_in":300}}''';

const loginUrl =
    'https://erp.perusahaan.com/api/auth/login?client=mobile&req=req_abc';

const pendingBody = '{"data":{"status":"pending"}}';

const readyBody = '''
{"data":{"status":"ready","session_token":"sess_tok","session_refresh_token":"sess_ref",
 "expires_at":"2026-09-24T10:00:00Z",
 "user":{"id":"user_1","name":"Budi","email":"budi@perusahaan.com"},
 "companies":[{"id":"uc_1","user_id":"user_1","company_id":"comp_1","role":"cashier",
               "is_active":true}]}}''';

/// A `ready` poll answer whose fields are [readyBody]'s, with [overrides] applied. A key set to
/// `null` is removed.
String readyWith(Map<String, Object?> overrides) {
  final data = Map<String, Object?>.of(
    (jsonDecode(readyBody) as Map<String, dynamic>)['data']
        as Map<String, dynamic>,
  );
  for (final e in overrides.entries) {
    if (e.value == null) {
      data.remove(e.key);
    } else {
      data[e.key] = e.value;
    }
  }
  return jsonEncode({'data': data});
}

/// Everything a login touches, wired the way the app wires it: the session and the pending
/// marker share one store.
class Rig {
  final store = FakeStorePort();
  late final session = SessionHolder(store);
  final http = FakePublicHttp();
  final opener = FakeOpener();

  /// No real waiting: the poll loop is driven by this.
  Future<void> Function() delay = () async {};
  Duration pollTimeout = const Duration(seconds: 60);
  DateTime Function() now = DateTime.now;

  LoginDeps get deps => depsWith(http: http);

  /// The same wiring with the HTTP swapped, for a test that has to act while a call is on the
  /// wire.
  LoginDeps depsWith({required PublicHttpPort http}) => (
    store: store,
    http: http,
    opener: opener,
    session: session,
    delay: delay,
    pollTimeout: pollTimeout,
    now: now,
  );

  Future<void> pair([PosSession session = paired]) =>
      this.session.save(session);

  void answer(String body, {int status = 200}) =>
      http.respond(TransportResponse(status: status, body: body));

  /// The session as the next launch would read it from the store.
  Future<PosSession?> stored() => SessionHolder(store).hydrate();

  Map<String, dynamic> bodyOf(int call) =>
      jsonDecode(http.calls[call].request.body!) as Map<String, dynamic>;
}

Matcher isLoginFailure(LoginFailure reason) =>
    isA<LoginException>().having((e) => e.reason, 'reason', reason);

void main() {
  group('loginNative — the start call', () {
    test('refuses to start when the device is not paired', () async {
      final rig = Rig()..answer(startedBody);

      await expectLater(
        loginNative(rig.deps),
        throwsA(isLoginFailure(LoginFailure.notPaired)),
      );
      expect(rig.http.calls, isEmpty);
    });

    // The source tests `!session?.baseUrl`, so an empty string is not a host either.
    test('refuses to start when the session has no host', () async {
      final rig = Rig()..answer(startedBody);
      await rig.pair(paired.copyWith(baseUrl: ''));

      await expectLater(
        loginNative(rig.deps),
        throwsA(isLoginFailure(LoginFailure.notPaired)),
      );
      expect(rig.http.calls, isEmpty);
    });

    test('POSTs to the tenant host, not the canonical one', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer(readyBody);
      await rig.pair();

      await loginNative(rig.deps);

      final call = rig.http.calls.first;
      expect(call.baseUrl, tenantHost);
      expect(call.request.path, '/api/auth/mobile/start');
    });

    test(
      'sends the device name, so the dashboard can tell the tablets apart',
      () async {
        final rig = Rig()
          ..answer(startedBody)
          ..answer(readyBody);
        await rig.pair();

        await loginNative(rig.deps);

        expect(rig.bodyOf(0), {'device_name': 'Tablet Kasir 1'});
      },
    );

    test(
      'opens the login URL in the browser rather than in the webview',
      () async {
        final rig = Rig()
          ..answer(startedBody)
          ..answer(readyBody);
        await rig.pair();

        await loginNative(rig.deps);

        // The whole flow depends on the OIDC session living in the browser's cookie jar and
        // never in the app's, so this URL must leave the app.
        expect(rig.opener.opened, [loginUrl]);
      },
    );

    test('reports unavailable when the start call fails', () async {
      final rig = Rig();
      rig.http.fail(TransportException('network down'));
      await rig.pair();

      await expectLater(
        loginNative(rig.deps),
        throwsA(isLoginFailure(LoginFailure.unavailable)),
      );
    });

    test(
      'reports unavailable when the start response is not the promised shape',
      () async {
        final rig = Rig()..answer('{"data":{}}');
        await rig.pair();

        await expectLater(
          loginNative(rig.deps),
          throwsA(isLoginFailure(LoginFailure.unavailable)),
        );
      },
    );

    final unusable = <String, String>{
      'a failing status': '',
      'no request id':
          '{"data":{"login_url":"https://erp.perusahaan.com/api/auth/login"}}',
      'an empty request id': '{"data":{"request_id":"","login_url":"https://erp.perusahaan.com/l"}}',
      // Without a URL there is nothing to open, and polling a request the browser can never
      // finish would just burn five minutes before timing out.
      'no login URL': '{"data":{"request_id":"req_abc"}}',
      'an empty login URL': '{"data":{"request_id":"req_abc","login_url":""}}',
      'a login URL that is not a string':
          '{"data":{"request_id":"req_abc","login_url":42}}',
    };
    for (final MapEntry(key: what, value: body) in unusable.entries) {
      test('reports unavailable, and opens nothing, for $what', () async {
        final rig = Rig();
        if (body.isEmpty) {
          rig.answer(startedBody, status: 500);
        } else {
          rig.answer(body);
        }
        await rig.pair();

        await expectLater(
          loginNative(rig.deps),
          throwsA(isLoginFailure(LoginFailure.unavailable)),
        );

        expect(rig.opener.opened, isEmpty);
        expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
      });
    }

    // The URL comes out of a response and goes to the OS, which will open any scheme it has a
    // handler for: an `intent:` URL starts another app, `file:` reads local storage. The
    // source hands it over unchecked; only a web page belongs in the browser.
    for (final url in [
      'intent://scan/#Intent;scheme=zxing;end',
      'file:///sdcard/Download/login.html',
      'javascript:alert(1)',
      'market://details?id=com.example',
      '/api/auth/login?req=req_abc',
      '//evil.example/login',
      'erp.perusahaan.com/api/auth/login',
    ]) {
      test('refuses to open $url, and remembers nothing', () async {
        final rig = Rig()
          ..answer(
            jsonEncode({
              'data': {'request_id': 'req_abc', 'login_url': url},
            }),
          );
        await rig.pair();

        await expectLater(
          loginNative(rig.deps),
          throwsA(isLoginFailure(LoginFailure.unavailable)),
        );

        expect(rig.opener.opened, isEmpty);
        expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
      });
    }

    test('opens an http URL: a debug build talks to a local backend', () async {
      final rig = Rig()
        ..answer(
          jsonEncode({
            'data': {
              'request_id': 'req_abc',
              'login_url': 'http://localhost:4000/api/auth/login?req=req_abc',
            },
          }),
        );
      rig.answer(readyBody);
      await rig.pair();

      await loginNative(rig.deps);

      expect(rig.opener.opened, [
        'http://localhost:4000/api/auth/login?req=req_abc',
      ]);
    });

    test('opens a URL whose scheme is upper case', () async {
      final rig = Rig()
        ..answer(
          jsonEncode({
            'data': {
              'request_id': 'req_abc',
              'login_url': 'HTTPS://erp.perusahaan.com/api/auth/login',
            },
          }),
        );
      rig.answer(readyBody);
      await rig.pair();

      await loginNative(rig.deps);

      expect(rig.opener.opened, hasLength(1));
    });

    // The request id is what lets the next launch collect a login the OS killed the app in the
    // middle of, so it has to be on disk before the browser takes the foreground.
    test('remembers the request before the browser opens', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer(readyBody);
      await rig.pair();
      final opener = _SnapshotOpener(rig.store);

      await loginNative((
        store: rig.store,
        http: rig.http,
        opener: opener,
        session: rig.session,
        delay: rig.delay,
        pollTimeout: rig.pollTimeout,
        now: rig.now,
      ));

      expect(opener.pendingWhenOpened, 'req_abc');
    });

    test(
      'forgets the request and reports unavailable when no browser opens',
      () async {
        final rig = Rig()..answer(startedBody);
        rig.opener.failNext(OpenerException('no browser'));
        await rig.pair();

        await expectLater(
          loginNative(rig.deps),
          throwsA(isLoginFailure(LoginFailure.unavailable)),
        );

        expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
      },
    );

    test(
      'lets a StoreException from remembering the request reach the caller',
      () async {
        final rig = Rig()..answer(startedBody);
        await rig.pair();
        rig.store.failNext(StoreException('disk full'));

        await expectLater(
          loginNative(rig.deps),
          throwsA(isA<StoreException>()),
        );

        // Nothing was remembered, so nothing may open a browser that nothing can collect from.
        expect(rig.opener.opened, isEmpty);
      },
    );
  });

  group('loginNative — polling', () {
    test(
      'keeps polling while the browser is still on the login page',
      () async {
        final rig = Rig()
          ..answer(startedBody)
          ..answer(pendingBody)
          ..answer(pendingBody)
          ..answer(readyBody);
        await rig.pair();

        await loginNative(rig.deps);

        // start + two pending polls + the ready poll
        expect(rig.http.calls, hasLength(4));
        expect(rig.http.calls[3].request.path, '/api/auth/mobile/poll');
        expect(rig.bodyOf(3), {'request_id': 'req_abc'});
      },
    );

    // Nothing but a poll is ever sent, and only to the host pairing locked.
    test('sends every call to the tenant host', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer(pendingBody)
        ..answer(readyBody);
      await rig.pair();

      await loginNative(rig.deps);

      expect(rig.http.calls.map((c) => c.baseUrl), everyElement(tenantHost));
    });

    test('stores the tokens the poll returned', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer(readyBody);
      await rig.pair();

      await loginNative(rig.deps);

      final session = (await rig.stored())!;
      expect(session.sessionToken, 'sess_tok');
      expect(session.sessionRefreshToken, 'sess_ref');
      expect(session.expiresAt, '2026-09-24T10:00:00Z');
    });

    test('keeps what pairing established', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer(readyBody);
      await rig.pair();

      await loginNative(rig.deps);

      final session = (await rig.stored())!;
      // Login gets the credential; it must not undo the host and outlet pairing locked.
      expect(session.baseUrl, tenantHost);
      expect(session.outletId, 'out_1');
      expect(session.companyId, 'comp_1');
      expect(session.branding?.appName, 'Toko Budi');
    });

    test('makes the session readable straight after login', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer(readyBody);
      await rig.pair();

      await loginNative(rig.deps);

      // The transport reads the session synchronously, so login has to fill the cache too.
      expect(rig.session.current?.sessionToken, 'sess_tok');
    });

    test('clears the pending marker once the login is done', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer(readyBody);
      await rig.pair();

      await loginNative(rig.deps);

      // A finished login must not be resumed later — the request id it would poll is spent.
      expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
    });

    test(
      'reports expired when the request id is gone, and forgets it',
      () async {
        final rig = Rig()
          ..answer(startedBody)
          ..answer('{"error":true}', status: 404);
        await rig.pair();

        await expectLater(
          loginNative(rig.deps),
          throwsA(isLoginFailure(LoginFailure.expired)),
        );
        expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
      },
    );

    test('reports timeout when the browser never finishes', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer(pendingBody);
      rig.pollTimeout = Duration.zero;
      await rig.pair();

      await expectLater(
        loginNative(rig.deps),
        throwsA(isLoginFailure(LoginFailure.timeout)),
      );
    });

    // The source only tests a timeout of zero. This one moves time with the delay, so the
    // boundary is exact: polls at 0s, 2s, 4s and 6s, and the fourth is the first past 5s.
    test('gives up at the deadline, not before and not after', () async {
      var clock = DateTime(2026, 9, 19);
      final rig = Rig()..answer(startedBody);
      for (var i = 0; i < 10; i++) {
        rig.answer(pendingBody);
      }
      rig
        ..pollTimeout = const Duration(seconds: 5)
        ..now = (() => clock)
        ..delay = (() async => clock = clock.add(const Duration(seconds: 2)));
      await rig.pair();

      await expectLater(
        loginNative(rig.deps),
        throwsA(isLoginFailure(LoginFailure.timeout)),
      );

      // start + polls at 0s, 2s, 4s, 6s
      expect(rig.http.calls, hasLength(5));
    });

    test('reports unavailable when a poll fails for a reason that is not the request id', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer('{"error":true}', status: 500);
      await rig.pair();

      await expectLater(
        loginNative(rig.deps),
        throwsA(isLoginFailure(LoginFailure.unavailable)),
      );
    });

    // A throttled poll is worth retrying; anything else is not.
    test('retries a throttled poll', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer('{"error":true}', status: 429)
        ..answer(readyBody);
      await rig.pair();

      await loginNative(rig.deps);

      expect(rig.http.calls, hasLength(3));
      expect(rig.session.current?.sessionToken, 'sess_tok');
    });

    // A poll that gets no answer must NOT end the login. The request is still alive in Redis
    // for its full TTL, and the backend hands a session out once: giving up here throws away a
    // login the cashier already completed in the browser, and the only way back is walking to
    // the dashboard for a fresh code.
    //
    // Measured on a real tablet (2026-09-20): three `200 pending` polls, then one dropped
    // connection, and the screen said "Belum bisa menghubungi server" while the login was still
    // waiting to be collected.
    test('keeps polling when a poll gets no answer, and keeps the request', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer(pendingBody);
      rig.http.fail(TransportException('network down'));
      rig.http.respond(TransportResponse(status: 200, body: readyBody));
      await rig.pair();

      await loginNative(rig.deps);

      // start, pending, dropped, ready — the dropped one did not end the login.
      expect(rig.http.calls, hasLength(4));
      expect(rig.session.current?.sessionToken, 'sess_tok');
      expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
    });

    // The cashier gave up, and that is still the cashier's call: a dropped poll in the same
    // wait must not turn a Batal into a five-minute wait.
    //
    // The wait is held open rather than left to the Rig's no-op `delay`, because the fake
    // transport refuses a poll with no queued answer — a second poll here would fail the test
    // for a reason that has nothing to do with cancelling.
    test('still stops on cancel after a poll gets no answer', () async {
      final rig = Rig()..answer(startedBody);
      rig.http.fail(TransportException('network down'));
      await rig.pair();

      final waiting = Completer<void>();
      rig.delay = () => waiting.future;

      final control = LoginControl();
      final login = loginNative(rig.deps, control: control);
      // Lets the dropped poll happen and the loop reach its wait.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      control.cancel();

      await expectLater(login, throwsA(isLoginFailure(LoginFailure.cancelled)));
      expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
    });

    // A dropped connection is not a licence to poll forever: the deadline still ends it, and
    // `timeout` is the honest reason (the request may be gone from Redis too).
    test(
      'still gives up at the deadline when every poll gets no answer',
      () async {
        final rig = Rig()..answer(startedBody);
        rig.http.fail(TransportException('network down'));
        await rig.pair();
        rig.pollTimeout = Duration.zero;

        await expectLater(
          loginNative(rig.deps),
          throwsA(isLoginFailure(LoginFailure.timeout)),
        );
      },
    );

    test('keeps polling past a 200 that is not an answer', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer('upstream connect error')
        ..answer('{"data":{}}')
        ..answer(readyBody);
      await rig.pair();

      await loginNative(rig.deps);

      expect(rig.http.calls, hasLength(4));
    });
  });

  // A cashier who tapped Masuk by mistake, or whose browser is signed in to the wrong account,
  // otherwise has five minutes of waiting or killing the app ahead of them (findings F5).
  group('loginNative — giving up', () {
    test(
      'does nothing at all when it was cancelled before it started',
      () async {
        final control = LoginControl()..cancel();
        final rig = Rig()..answer(startedBody);
        await rig.pair();

        await expectLater(
          loginNative(rig.deps, control: control),
          throwsA(isLoginFailure(LoginFailure.cancelled)),
        );

        expect(rig.http.calls, isEmpty);
        expect(rig.opener.opened, isEmpty);
        expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
      },
    );

    test(
      'opens no browser when it is cancelled while the start call is out',
      () async {
        final control = LoginControl();
        final http = _HookedHttp()
          ..respond(TransportResponse(status: 200, body: startedBody));
        // Stands in for the tap landing while the request is in flight.
        http.beforeSend = () async => control.cancel();
        final rig = Rig();
        await rig.pair();

        await expectLater(
          loginNative(rig.depsWith(http: http), control: control),
          throwsA(isLoginFailure(LoginFailure.cancelled)),
        );

        expect(rig.opener.opened, isEmpty);
        expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
      },
    );

    test('stops polling, and forgets the request', () async {
      final control = LoginControl();
      final rig = Rig()
        ..answer(startedBody)
        ..answer(pendingBody)
        ..answer(pendingBody)
        ..answer(readyBody);
      await rig.pair();
      // The tap lands between two polls.
      rig.delay = () async => control.cancel();

      await expectLater(
        loginNative(rig.deps, control: control),
        throwsA(isLoginFailure(LoginFailure.cancelled)),
      );

      // start + the poll that was already on its way; the one after it never happened.
      expect(rig.http.calls, hasLength(2));
      // An abandoned login must not sign the cashier in later: the next launch reads this
      // marker and would collect a session they walked away from.
      expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
      expect(rig.session.current?.sessionToken, isEmpty);
    });

    test('shrugs off a second cancel', () async {
      final control = LoginControl();
      final rig = Rig()
        ..answer(startedBody)
        ..answer(pendingBody);
      await rig.pair();
      rig.delay = () async {
        control.cancel();
        // The button can be tapped twice before the screen has changed.
        control.cancel();
      };

      await expectLater(
        loginNative(rig.deps, control: control),
        throwsA(isLoginFailure(LoginFailure.cancelled)),
      );

      expect(control.isCancelled, isTrue);
    });

    // The backend hands a session out once (`TakeMobileLoginResult` uses GetDel), so a poll
    // that already collected it must keep it: throwing it away would cost the cashier a second
    // walk through the browser, and there is nothing left to collect a second time.
    test('keeps a session that arrived as the cashier was giving up', () async {
      final control = LoginControl();
      final http = _HookedHttp();
      var sent = 0;
      http.beforeSend = () async {
        // The 2nd call is the first poll, the one that carries the finished login back.
        if (++sent == 2) control.cancel();
      };
      http
        ..respond(TransportResponse(status: 200, body: startedBody))
        ..respond(TransportResponse(status: 200, body: readyBody));
      final rig = Rig();
      await rig.pair();

      await loginNative(rig.depsWith(http: http), control: control);

      expect(rig.session.current?.sessionToken, 'sess_tok');
      expect(await rig.stored(), isNot(paired));
      expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
    });

    // Cancelling and coming back are the same event from the loop's point of view: it stops
    // waiting. Giving up has to win, or the resume would poll a login that is already over.
    test('a resume after giving up does not poll again', () async {
      final control = LoginControl();
      final rig = Rig()
        ..answer(startedBody)
        ..answer(pendingBody)
        ..answer(pendingBody);
      await rig.pair();
      rig.delay = () async {
        control.cancel();
        // The browser is brought back to the front after the tap.
        control.pollNow();
      };

      await expectLater(
        loginNative(rig.deps, control: control),
        throwsA(isLoginFailure(LoginFailure.cancelled)),
      );

      expect(rig.http.calls, hasLength(2));
    });
  });

  // Finishing in the browser and coming back to the app is the ordinary path. Waiting out the
  // poll interval first would leave the cashier watching a spinner whose answer is already
  // waiting.
  group('loginNative — coming back from the browser', () {
    test('polls at once instead of waiting out the interval', () async {
      final control = LoginControl();
      final rig = Rig()
        ..answer(startedBody)
        ..answer(pendingBody)
        ..answer(readyBody);
      await rig.pair();
      // The interval never ends on its own: only the resume can end this wait.
      final never = Completer<void>();
      rig.delay = () => never.future;

      final login = loginNative(rig.deps, control: control);
      await pumpEventQueue();
      control.pollNow();
      await login;

      // start + the poll that came back pending + the one the resume asked for.
      expect(rig.http.calls, hasLength(3));
      expect(rig.session.current?.sessionToken, 'sess_tok');
    });

    // A wake-up that stayed latched would poll again on every turn of the event loop: a tablet
    // hammering the backend for the whole five minutes.
    test('waits again afterwards, rather than polling in a loop', () async {
      final control = LoginControl();
      final rig = Rig()
        ..answer(startedBody)
        ..answer(pendingBody)
        ..answer(pendingBody)
        ..answer(pendingBody);
      await rig.pair();
      final never = Completer<void>();
      rig.delay = () => never.future;

      final login = loginNative(rig.deps, control: control);
      await pumpEventQueue();
      control.pollNow();
      await pumpEventQueue();

      expect(rig.http.calls, hasLength(3));

      control.cancel();
      await expectLater(login, throwsA(isLoginFailure(LoginFailure.cancelled)));
    });

    // The cashier can bring the app back while a poll is still out, and that resume must not be
    // dropped on the floor: the poll it was meant to answer is already on the wire.
    test('a resume that arrives during a poll is not lost', () async {
      final control = LoginControl();
      final http = _HookedHttp();
      var sent = 0;
      http.beforeSend = () async {
        if (++sent == 2) control.pollNow();
      };
      http
        ..respond(TransportResponse(status: 200, body: startedBody))
        ..respond(TransportResponse(status: 200, body: pendingBody))
        ..respond(TransportResponse(status: 200, body: pendingBody));
      final rig = Rig();
      await rig.pair();
      final never = Completer<void>();
      rig.delay = () => never.future;

      final login = loginNative(rig.depsWith(http: http), control: control);
      await pumpEventQueue();

      // start + the poll it was on + the one the resume asked for.
      expect(http.calls, hasLength(3));

      control.cancel();
      await expectLater(login, throwsA(isLoginFailure(LoginFailure.cancelled)));
    });
  });

  group('loginNative — the profile it stores', () {
    Future<PosSession> loggedIn(
      String ready, {
      PosSession from = paired,
    }) async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer(ready);
      await rig.pair(from);
      await loginNative(rig.deps);
      return (await rig.stored())!;
    }

    test('stores the cashier', () async {
      final user = (await loggedIn(readyBody)).user!;

      expect(user.id, 'user_1');
      expect(user.name, 'Budi');
    });

    // The Menu shows who is signed in. The backend's user always carries an email and may
    // carry no name at all, and a profile without a name used to leave the Menu with no way to
    // tell which cashier was at the till.
    test(
      'stores the email too, so a cashier without a name is still identifiable',
      () async {
        expect((await loggedIn(readyBody)).user!.email, 'budi@perusahaan.com');
      },
    );

    test('drops an email that is not a string rather than storing a shape the UI cannot read', () async {
      final ready = readyWith({
        'user': {'id': 'user_1', 'name': 'Budi', 'email': 42},
      });

      expect((await loggedIn(ready)).user!.email, isNull);
    });

    // `users.name` is NOT NULL but not non-empty: a profile provisioned from an OIDC account can
    // carry "". Stored as-is it is truthy-checked away by every display site and the Menu ends
    // up saying "Unknown" for a cashier whose email it has all along.
    test(
      'treats a blank name as absent, so the email can stand in for it',
      () async {
        final ready = readyWith({
          'user': {
            'id': 'user_1',
            'name': '   ',
            'email': 'budi@perusahaan.com',
          },
        });

        final user = (await loggedIn(ready)).user!;
        expect(user.name, isNull);
        expect(user.email, 'budi@perusahaan.com');
      },
    );

    test('stores a name and an email trimmed', () async {
      final ready = readyWith({
        'user': {'id': 'user_1', 'name': '  Budi ', 'email': ' b@p.com '},
      });

      final user = (await loggedIn(ready)).user!;
      expect(user.name, 'Budi');
      expect(user.email, 'b@p.com');
    });

    test('has no cashier when the user carries no id', () async {
      for (final user in <Object?>[
        {'name': 'Budi'},
        {'id': 7, 'name': 'Budi'},
        'user_1',
        <Object?>[],
      ]) {
        expect((await loggedIn(readyWith({'user': user}))).user, isNull);
      }
    });

    test(
      'keeps the cashier it already had when the answer carries none',
      () async {
        const before = SessionUser(id: 'user_0', name: 'Sri');
        final session = await loggedIn(
          readyWith({'user': null}),
          from: paired.copyWith(user: before),
        );

        expect(session.user, before);
      },
    );

    // The memberships carry the cashier's role in the company. Without them the app can never
    // answer "may this person take payment?" and the till is unusable.
    test('stores the company memberships the poll returned', () async {
      final companies = (await loggedIn(readyBody)).companies!;

      expect(companies, hasLength(1));
      expect(companies.single.companyId, 'comp_1');
      expect(companies.single.role, 'cashier');
    });

    // The session is persisted and read back by later app versions, so a shape this build does
    // not recognise must not reach the screens that scan it for a role.
    test('ignores a companies field that is not a list', () async {
      final session = await loggedIn(readyWith({'companies': 'not-a-list'}));

      expect(session.companies, isNull);
    });

    test(
      'keeps the memberships it already had when the answer carries none',
      () async {
        const before = UserCompany(
          id: 'uc_0',
          userId: 'user_1',
          companyId: 'comp_1',
          role: 'owner',
          isActive: true,
        );
        final session = await loggedIn(
          readyWith({'companies': null}),
          from: paired.copyWith(companies: [before]),
        );

        expect(session.companies, [before]);
      },
    );

    test('drops a membership that is not one, and keeps the rest', () async {
      final ready = readyWith({
        'companies': [
          {
            'id': 'uc_1',
            'user_id': 'user_1',
            'company_id': 'comp_1',
            'role': 'cashier',
            'is_active': true,
          },
          {
            'id': 'uc_2',
            'user_id': 'user_1',
            'role': 'cashier',
          }, // no company_id
          {'id': 'uc_3', 'user_id': 'user_1', 'company_id': 9, 'role': 'x'},
          {'company_id': 'comp_9'}, // a company id and nothing else
          'comp_1',
          null,
          7,
        ],
      });

      final companies = (await loggedIn(ready)).companies!;
      expect(companies.map((c) => c.id), ['uc_1']);
    });

    // A list is an answer: "this cashier belongs to no company" is a fact, not silence.
    test('stores an empty list when every membership was unusable', () async {
      final session = await loggedIn(readyWith({'companies': <Object?>[]}));

      expect(session.companies, isEmpty);
    });

    test(
      'keeps the previous expiry when the answer carries none, or a bad one',
      () async {
        const before = PosSession(
          baseUrl: tenantHost,
          companyId: 'comp_1',
          outletId: 'out_1',
          sessionToken: '',
          expiresAt: '2026-09-01T00:00:00Z',
        );

        for (final expiresAt in <Object?>[null, 12345, true]) {
          final session = await loggedIn(
            readyWith({'expires_at': expiresAt}),
            from: before,
          );
          expect(session.expiresAt, '2026-09-01T00:00:00Z');
        }
      },
    );
  });

  // The backend hands the session out once. A `ready` that cannot be used is a login lost, and
  // an app that crashes on it or saves half of it leaves the cashier with neither.
  group('loginNative — a ready answer it cannot use', () {
    final unusable = <String, Map<String, Object?>>{
      'no session token': {'session_token': null},
      'an empty session token': {'session_token': ''},
      'a session token that is not a string': {'session_token': 12},
      'no refresh token': {'session_refresh_token': null},
      'an empty refresh token': {'session_refresh_token': ''},
      'a refresh token that is not a string': {'session_refresh_token': false},
    };

    for (final MapEntry(key: what, value: overrides) in unusable.entries) {
      test(
        'reports unavailable, forgets the request, and saves nothing, for $what',
        () async {
          final rig = Rig()
            ..answer(startedBody)
            ..answer(readyWith(overrides));
          await rig.pair();

          await expectLater(
            loginNative(rig.deps),
            throwsA(isLoginFailure(LoginFailure.unavailable)),
          );

          expect(rig.session.current, paired);
          expect(await rig.stored(), paired);
          expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
        },
      );
    }
  });

  // The reset button on the login screen clears the session. A poll that finished anyway would
  // write the session back and silently undo that reset, so a login that no longer belongs to
  // the current pairing must not complete.
  group('loginNative — the device changes under it', () {
    test(
      'gives up when the device is reset while the browser is still open',
      () async {
        final rig = Rig()
          ..answer(startedBody)
          ..answer(pendingBody)
          ..answer(readyBody);
        await rig.pair();
        // Stands in for the cashier tapping reset between two polls.
        rig.delay = rig.session.clear;

        await loginNative(rig.deps);

        expect(rig.session.current, isNull);
        expect(await rig.stored(), isNull);
        // And the stale request id goes with it, so a later boot does not poll a login that
        // belongs to the pairing this device no longer has.
        expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
        // It stopped polling rather than collecting a session it would then have to discard:
        // the backend hands it out once.
        expect(rig.http.calls, hasLength(2));
      },
    );

    test(
      'gives up when the device is paired to another outlet meanwhile',
      () async {
        final rig = Rig()
          ..answer(startedBody)
          ..answer(pendingBody)
          ..answer(readyBody);
        await rig.pair();
        rig.delay = () => rig.session.save(paired.copyWith(outletId: 'out_2'));

        await loginNative(rig.deps);

        final session = (await rig.stored())!;
        expect(session.outletId, 'out_2');
        expect(session.sessionToken, isEmpty);
        expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
      },
    );

    // A refresh replaces the session object without the device going anywhere.
    test('carries on when only the credential changed', () async {
      final rig = Rig()
        ..answer(startedBody)
        ..answer(pendingBody)
        ..answer(readyBody);
      await rig.pair();
      rig.delay = () =>
          rig.session.save(paired.copyWith(sessionToken: 'rotated'));

      await loginNative(rig.deps);

      expect(rig.session.current?.sessionToken, 'sess_tok');
    });
  });

  // A cashier who backgrounds the app mid-login, or whose OS kills it, must not have to walk
  // back through the dashboard for a new code — the request is still waiting in Redis.
  group('resumePendingLogin', () {
    test('does nothing when there is no pending request', () async {
      final rig = Rig()..answer(readyBody);
      await rig.pair();

      await resumePendingLogin(rig.deps);

      expect(rig.http.calls, isEmpty);
    });

    test('picks the login back up from the stored request id', () async {
      final rig = Rig()..answer(readyBody);
      await rig.store.write(pendingLoginKey, 'req_abc');
      await rig.pair();

      await resumePendingLogin(rig.deps);

      expect(rig.http.calls, hasLength(1));
      expect(rig.http.calls.single.request.path, '/api/auth/mobile/poll');
      expect(rig.bodyOf(0), {'request_id': 'req_abc'});
      expect(rig.session.current?.sessionToken, 'sess_tok');
      expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
    });

    test('does nothing when the device is not paired', () async {
      final rig = Rig()..answer(readyBody);
      await rig.store.write(pendingLoginKey, 'req_abc');

      await resumePendingLogin(rig.deps);

      expect(rig.http.calls, isEmpty);
    });

    // The source tests `if (!requestId)`, so an empty string is not a request id.
    test('does nothing when the stored request id is empty', () async {
      final rig = Rig()..answer(readyBody);
      await rig.store.write(pendingLoginKey, '');
      await rig.pair();

      await resumePendingLogin(rig.deps);

      expect(rig.http.calls, isEmpty);
    });

    // Two callers can ask at the same time, and a second poll loop for one request id would be
    // pure waste: the backend hands the session out once, so the loser would sit for the full
    // timeout and then fail. Sharing the future makes the second caller wait for the first.
    test('polls once when two resumes race', () async {
      final rig = Rig()..answer(readyBody);
      await rig.store.write(pendingLoginKey, 'req_abc');
      await rig.pair();

      await Future.wait([
        resumePendingLogin(rig.deps),
        resumePendingLogin(rig.deps),
      ]);

      expect(rig.http.calls, hasLength(1));
    });

    // The guard is for a resume that is *in flight*: one that has finished, failed or not, must
    // not stand in the way of the next.
    test('resumes again once the previous resume has finished', () async {
      final rig = Rig()
        ..answer('{"error":true}', status: 404)
        ..answer(readyBody);
      await rig.store.write(pendingLoginKey, 'req_abc');
      await rig.pair();

      await expectLater(
        resumePendingLogin(rig.deps),
        throwsA(isLoginFailure(LoginFailure.expired)),
      );

      // The expired request was forgotten; a fresh one is what a new login would store.
      await rig.store.write(pendingLoginKey, 'req_def');
      await resumePendingLogin(rig.deps);

      expect(rig.http.calls, hasLength(2));
      expect(rig.bodyOf(1), {'request_id': 'req_def'});
      expect(rig.session.current?.sessionToken, 'sess_tok');
    });

    test(
      'lets a StoreException from reading the request id reach the caller',
      () async {
        final rig = Rig()..answer(readyBody);
        await rig.pair();
        rig.store.failNext(StoreException('disk unreadable'));

        // Not "nothing pending": a login the browser already finished would be abandoned.
        await expectLater(
          resumePendingLogin(rig.deps),
          throwsA(isA<StoreException>()),
        );
        expect(rig.http.calls, isEmpty);
      },
    );
  });

  group('refreshSession', () {
    const signedIn = PosSession(
      baseUrl: tenantHost,
      companyId: 'comp_1',
      outletId: 'out_1',
      deviceName: 'Tablet Kasir 1',
      sessionToken: 'old_tok',
      sessionRefreshToken: 'old_ref',
      expiresAt: '2026-09-20T10:00:00Z',
      user: SessionUser(id: 'user_1', name: 'Budi'),
      companies: [
        UserCompany(
          id: 'uc_1',
          userId: 'user_1',
          companyId: 'comp_1',
          role: 'cashier',
          isActive: true,
        ),
      ],
    );

    const newTokens = '''
{"data":{"session_token":"new_tok","session_refresh_token":"new_ref",
 "expires_at":"2026-09-25T10:00:00Z"}}''';

    test('trades the refresh token for a new pair', () async {
      final rig = Rig()..answer(newTokens);
      await rig.pair(signedIn);

      expect(await refreshSession(rig.deps), isTrue);

      final call = rig.http.calls.single;
      expect(call.baseUrl, tenantHost);
      expect(call.request.path, '/api/auth/refresh');
      expect(rig.bodyOf(0), {'refresh_token': 'old_ref'});

      final session = (await rig.stored())!;
      expect(session.sessionToken, 'new_tok');
      expect(session.sessionRefreshToken, 'new_ref');
      expect(session.expiresAt, '2026-09-25T10:00:00Z');
      expect(rig.session.current?.sessionToken, 'new_tok');
    });

    // A refresh only trades tokens; it carries no profile. Dropping the memberships here would
    // strip the cashier's permissions mid-shift.
    test(
      'keeps the memberships and the cashier when the answer carries none',
      () async {
        final rig = Rig()..answer(newTokens);
        await rig.pair(signedIn);

        await refreshSession(rig.deps);

        expect(rig.session.current?.companies, signedIn.companies);
        expect(rig.session.current?.user, signedIn.user);
      },
    );

    test('takes the profile the answer does carry', () async {
      final rig = Rig()
        ..answer(
          readyWith({
            'user': {'id': 'user_1', 'name': 'Budi S.'},
          }),
        );
      await rig.pair(signedIn);

      await refreshSession(rig.deps);

      expect(rig.session.current?.user?.name, 'Budi S.');
    });

    test('keeps what pairing established', () async {
      final rig = Rig()..answer(newTokens);
      await rig.pair(signedIn);

      await refreshSession(rig.deps);

      final session = rig.session.current!;
      expect(session.baseUrl, tenantHost);
      expect(session.outletId, 'out_1');
      expect(session.companyId, 'comp_1');
    });

    for (final token in <String?>[null, '']) {
      test(
        'returns false, without asking, when the refresh token is ${token == null ? 'absent' : 'empty'}',
        () async {
          final rig = Rig()..answer(newTokens);
          await rig.pair(paired.copyWith(sessionRefreshToken: token));

          expect(await refreshSession(rig.deps), isFalse);
          expect(rig.http.calls, isEmpty);
        },
      );
    }

    test(
      'returns false, without asking, when the device is not paired',
      () async {
        final rig = Rig()..answer(newTokens);

        expect(await refreshSession(rig.deps), isFalse);
        expect(rig.http.calls, isEmpty);
      },
    );

    // A 401 means the session is gone — logged out or revoked — and the caller has to send the
    // cashier back through a full login rather than retrying.
    test('returns false when the backend refuses the refresh token', () async {
      final rig = Rig()..answer('{"error":true}', status: 401);
      await rig.pair(signedIn);

      expect(await refreshSession(rig.deps), isFalse);
    });

    // The stored session is deliberately left untouched on failure, so a transient network
    // problem does not throw away a token that still works.
    test('leaves the stored session alone when the refresh fails', () async {
      final failures = <String, void Function(Rig)>{
        'refused': (rig) => rig.answer('{"error":true}', status: 401),
        'server error': (rig) => rig.answer('{"error":true}', status: 500),
        'no answer': (rig) => rig.http.fail(TransportException('network down')),
        'not JSON': (rig) => rig.answer('upstream connect error'),
        'no tokens in it': (rig) => rig.answer('{"data":{}}'),
        'an empty token': (rig) => rig.answer(
          '{"data":{"session_token":"","session_refresh_token":"new_ref"}}',
        ),
        'a token that is not a string': (rig) => rig.answer(
          '{"data":{"session_token":5,"session_refresh_token":"new_ref"}}',
        ),
      };

      for (final MapEntry(key: what, value: fail) in failures.entries) {
        final rig = Rig();
        fail(rig);
        await rig.pair(signedIn);

        expect(await refreshSession(rig.deps), isFalse, reason: what);
        expect(await rig.stored(), signedIn, reason: what);
      }
    });

    // The refresh is a network call, and the cashier can tap reset while it is out. Saving what
    // comes back would write the whole session back and silently re-pair a device that was
    // just reset — the same hazard the login poll guards against.
    test(
      'does not write the session back when the device was reset meanwhile',
      () async {
        final http = _HookedHttp()
          ..respond(TransportResponse(status: 200, body: newTokens));
        final rig = Rig();
        await rig.pair(signedIn);
        http.beforeSend = rig.session.clear;

        final deps = (
          store: rig.store,
          http: http,
          opener: rig.opener,
          session: rig.session,
          delay: rig.delay,
          pollTimeout: rig.pollTimeout,
          now: rig.now,
        );

        expect(await refreshSession(deps), isFalse);
        expect(rig.session.current, isNull);
        expect(await rig.stored(), isNull);
      },
    );
  });
}

/// A [FakePublicHttp] that runs [beforeSend] while the request is "on the wire".
class _HookedHttp extends FakePublicHttp {
  Future<void> Function()? beforeSend;

  @override
  Future<TransportResponse> send(
    String baseUrl,
    TransportRequest request,
  ) async {
    await beforeSend?.call();
    return super.send(baseUrl, request);
  }
}

/// Records what the pending marker was at the moment the browser was asked to open.
class _SnapshotOpener implements OpenerPort {
  _SnapshotOpener(this.store);

  final FakeStorePort store;
  String? pendingWhenOpened;

  @override
  Future<void> openUrl(String url) async {
    pendingWhenOpened = store.values[pendingLoginKey];
  }
}
