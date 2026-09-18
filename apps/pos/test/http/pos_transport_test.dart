/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/public_http_fake.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/http/pos_transport.dart';
import 'package:pos/session/session_holder.dart';

// Two of the cases in the TypeScript suite are not portable: both are about browser dev (a
// relative URL through the Vite proxy), and there is no browser dev in Flutter. See
// `plan/api-client/findings.md`.

const tenantHost = 'https://erp.perusahaan.com';

const signedIn = PosSession(
  baseUrl: tenantHost,
  companyId: 'comp_1',
  outletId: 'out_1',
  sessionToken: 'tok_secret_value',
  sessionRefreshToken: 'refresh_secret_value',
  deviceToken: 'dev_tok_1',
);

const stock = TransportRequest(
  method: HttpMethod.get,
  path: '/api/v1/pos/stock',
);

/// A transport wired the way the app wires it: the session lives in a store.
class Rig {
  final store = FakeStorePort();
  late final session = SessionHolder(store);
  final http = _HookedHttp();

  /// A transport with a refresh behind it, the way the app wires one, when [withRefresh].
  bool withRefresh = false;

  /// What the refresh answers, and what it saves as the session when it succeeds.
  bool refreshSucceeds = true;
  PosSession? refreshedTo;
  int refreshCalls = 0;

  Future<bool> _refresh() async {
    refreshCalls++;
    // Not instant, so a second 401 arriving meanwhile finds it still running.
    await Future<void>.delayed(Duration.zero);
    final next = refreshedTo;
    if (refreshSucceeds && next != null) await session.save(next);
    return refreshSucceeds;
  }

  /// How close to its end a session has to be for the transport to renew it before a request.
  Duration? refreshWithin;

  /// The clock the transport reads.
  DateTime now = DateTime.utc(2026, 9, 20, 12);

  PosTransport get transport => PosTransport(
    session: session,
    http: http,
    refresh: withRefresh ? _refresh : null,
    refreshWithin: refreshWithin,
    now: () => now,
  );

  Future<void> pair([PosSession s = signedIn]) => session.save(s);

  /// The session as the next launch would read it from the store.
  Future<PosSession?> stored() => SessionHolder(store).hydrate();

  void answer({int status = 200, Map<String, String> headers = const {}}) =>
      http.respond(TransportResponse(status: status, headers: headers));

  /// The single request that went out.
  PublicHttpCall get sent {
    expect(http.calls, hasLength(1));
    return http.calls.single;
  }
}

void main() {
  group('resolving the host', () {
    test(
      'sends to the locked tenant host, with the path the caller gave',
      () async {
        final rig = Rig()..answer();
        await rig.pair();

        await rig.transport.send(stock);

        expect(rig.sent.baseUrl, tenantHost);
        expect(rig.sent.request.path, '/api/v1/pos/stock');
      },
    );

    test('passes the method and the body through', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await rig.transport.send(
        const TransportRequest(
          method: HttpMethod.post,
          path: '/api/v1/pos/sales/checkout',
          body: '{"total":1000}',
        ),
      );

      expect(rig.sent.request.method, HttpMethod.post);
      expect(rig.sent.request.body, '{"total":1000}');
    });

    test('returns whatever the server answered, status included', () async {
      final rig = Rig()..answer(status: 422);
      await rig.pair();

      final response = await rig.transport.send(stock);

      expect(response.status, 422);
    });

    test(
      'does not double the slash when the stored host has a trailing one',
      () async {
        final rig = Rig()..answer();
        await rig.pair(signedIn.copyWith(baseUrl: '$tenantHost/'));

        await rig.transport.send(stock);

        expect(rig.sent.baseUrl, tenantHost);
      },
    );

    test(
      'follows the session when the device is paired to another host',
      () async {
        final rig = Rig()
          ..answer()
          ..answer();
        await rig.pair();
        await rig.transport.send(stock);

        await rig.pair(signedIn.copyWith(baseUrl: 'https://toko.contoh.com'));
        await rig.transport.send(stock);

        expect(rig.http.calls.map((c) => c.baseUrl), [
          tenantHost,
          'https://toko.contoh.com',
        ]);
      },
    );

    test('refuses to send when the device is not paired', () async {
      final rig = Rig()..answer();

      await expectLater(
        rig.transport.send(stock),
        throwsA(isA<NotPairedException>()),
      );
      expect(rig.http.calls, isEmpty);
    });

    // The source tests `!baseUrl`, so an empty string is not a host either.
    test('refuses to send when the session has no host', () async {
      final rig = Rig()..answer();
      await rig.pair(signedIn.copyWith(baseUrl: ''));

      await expectLater(
        rig.transport.send(stock),
        throwsA(isA<NotPairedException>()),
      );
      expect(rig.http.calls, isEmpty);
    });

    test(
      'lets a TransportException from the HTTP stack through untouched',
      () async {
        final rig = Rig();
        rig.http.fail(TransportException('network down'));
        await rig.pair();

        await expectLater(
          rig.transport.send(stock),
          throwsA(isA<TransportException>()),
        );
      },
    );
  });
  group('the bearer token', () {
    test('sends the bearer token', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await rig.transport.send(stock);

      expect(
        rig.sent.request.headers['Authorization'],
        'Bearer tok_secret_value',
      );
    });

    test(
      'sends no CSRF header — bearer requests are never CSRF-checked',
      () async {
        final rig = Rig()..answer();
        await rig.pair();

        await rig.transport.send(
          const TransportRequest(method: HttpMethod.post, path: '/api/v1/x'),
        );

        final names = rig.sent.request.headers.keys.map((k) => k.toLowerCase());
        expect(
          names,
          isNot(contains(predicate<String>((n) => n.contains('csrf')))),
        );
      },
    );

    test('sends no Authorization header when there is no token yet', () async {
      final rig = Rig()..answer();
      await rig.pair(signedIn.copyWith(sessionToken: ''));

      await rig.transport.send(stock);

      // Unpaired or logged out: no header produces the accurate 401, instead of masking the
      // real error behind a malformed `Bearer ` with nothing after it.
      expect(
        rig.sent.request.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('authorization')),
      );
    });

    test('sends no Authorization header when the device is not paired', () async {
      final rig = Rig()..answer();

      // There is no host to send to, so there is no request to carry a header.
      await expectLater(
        rig.transport.send(stock),
        throwsA(isA<NotPairedException>()),
      );
      expect(rig.http.calls, isEmpty);
    });

    test('keeps the headers the caller set', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await rig.transport.send(
        const TransportRequest(
          method: HttpMethod.get,
          path: '/api/v1/x',
          headers: {'Accept': 'application/json'},
        ),
      );

      expect(rig.sent.request.headers['Accept'], 'application/json');
    });

    test(
      'does not add a second Authorization when the caller set one',
      () async {
        final rig = Rig()..answer();
        await rig.pair();

        await rig.transport.send(
          const TransportRequest(
            method: HttpMethod.get,
            path: '/api/v1/x',
            headers: {'authorization': 'Bearer explicit'},
          ),
        );

        final auth = rig.sent.request.headers.entries.where(
          (e) => e.key.toLowerCase() == 'authorization',
        );
        expect(auth.map((e) => e.value), ['Bearer explicit']);
      },
    );
  });

  // `ResolveTenant` refuses a request with no company on a canonical host, and nothing on the
  // tablet writes the company for the caller. The transport already knows the tenant from the
  // session, so it supplies the header rather than every call site having to remember it.
  group('the company header', () {
    Map<String, String> headersOf(Rig rig) => rig.sent.request.headers;

    test('sends the company header the tenant middleware requires', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await rig.transport.send(stock);

      expect(headersOf(rig)['X-Company-ID'], 'comp_1');
    });

    // An explicit header wins: that is the caller saying it knows better.
    test('keeps a company header the caller set explicitly', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await rig.transport.send(
        const TransportRequest(
          method: HttpMethod.get,
          path: '/api/v1/x',
          headers: {'X-Company-ID': 'comp_other'},
        ),
      );

      expect(headersOf(rig)['X-Company-ID'], 'comp_other');
    });

    // The source checks `!headers['X-Company-ID']`, which is case-sensitive; HTTP header
    // names are not, so `x-company-id` from a caller would go out next to a second copy.
    test('keeps a company header the caller set in another case, without a duplicate', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await rig.transport.send(
        const TransportRequest(
          method: HttpMethod.get,
          path: '/api/v1/x',
          headers: {'x-company-id': 'comp_other'},
        ),
      );

      final company = headersOf(rig).entries
          .where((e) => e.key.toLowerCase() == 'x-company-id');
      expect(company.map((e) => e.value), ['comp_other']);
    });

    // The source tests `session?.companyId &&`, so an empty string is not a company.
    test('sends no company header when the session has none', () async {
      final rig = Rig()..answer();
      await rig.pair(signedIn.copyWith(companyId: ''));

      await rig.transport.send(stock);

      expect(
        headersOf(rig).keys.map((k) => k.toLowerCase()),
        isNot(contains('x-company-id')),
      );
    });

    test('sends nothing at all when the device is not paired', () async {
      final rig = Rig()..answer();

      await expectLater(
        rig.transport.send(stock),
        throwsA(isA<NotPairedException>()),
      );
      expect(rig.http.calls, isEmpty);
    });
  });

  // The device token is what the server resolves the tablet from. Without it the request is
  // still authenticated (the bearer carries the cashier) but the device is anonymous: no
  // presence is written, and a device deleted from the dashboard keeps transacting.
  group('the device header', () {
    Map<String, String> headersOf(Rig rig) => rig.sent.request.headers;

    test('sends the token activation issued', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await rig.transport.send(stock);

      expect(headersOf(rig)['X-Device-Token'], 'dev_tok_1');
    });

    // A device paired before the registry change has no token. The contract is explicit that
    // this must not become an empty header: the server reads an empty one as a present-but-
    // invalid token and answers 401, which would strand a working tablet at the pairing screen.
    test('sends no device header when the session has no token', () async {
      final rig = Rig()..answer();
      await rig.pair(signedIn.copyWith(deviceToken: null));

      await rig.transport.send(stock);

      expect(
        headersOf(rig).keys.map((k) => k.toLowerCase()),
        isNot(contains('x-device-token')),
      );
    });

    // Same reading of "no token" as the company header: an empty string is absence, not a value.
    test('sends no device header when the token is an empty string', () async {
      final rig = Rig()..answer();
      await rig.pair(signedIn.copyWith(deviceToken: ''));

      await rig.transport.send(stock);

      expect(
        headersOf(rig).keys.map((k) => k.toLowerCase()),
        isNot(contains('x-device-token')),
      );
    });

    // Same rule as the company header: a caller that set its own keeps it, in whatever case.
    test('keeps a device header the caller set in another case', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await rig.transport.send(
        const TransportRequest(
          method: HttpMethod.get,
          path: '/api/v1/x',
          headers: {'x-device-token': 'tok_other'},
        ),
      );

      final device = headersOf(rig).entries
          .where((e) => e.key.toLowerCase() == 'x-device-token');
      expect(device.map((e) => e.value), ['tok_other']);
    });

    // The device header is a credential. It goes only to the host pairing locked, exactly like
    // the bearer — the same guard covers both because both are set here.
    test('is not sent when the device is not paired', () async {
      final rig = Rig()..answer();

      await expectLater(
        rig.transport.send(stock),
        throwsA(isA<NotPairedException>()),
      );
      expect(rig.http.calls, isEmpty);
    });
  });
  // The backend no longer rotates a bearer session on its own (`middleware/auth.go`: only a
  // cookie session is rotated, and no header is sent). A bearer session changes only through a
  // refresh, so a response is never a reason to change the stored token.
  group('a response that carries a rotation header', () {
    test('does not change the session', () async {
      final rig = Rig()
        ..answer(
          headers: {
            'x-session-token': 'tok_from_a_header',
            'x-session-expires': '2030-01-01T00:00:00Z',
          },
        );
      await rig.pair(signedIn.copyWith(expiresAt: '2026-09-24T10:00:00Z'));

      await rig.transport.send(stock);

      expect(rig.session.current?.sessionToken, 'tok_secret_value');
      expect(rig.session.current?.expiresAt, '2026-09-24T10:00:00Z');
      expect((await rig.stored())?.sessionToken, 'tok_secret_value');
    });

    test(
      'leaves the stored token alone when the response carries none',
      () async {
        final rig = Rig()..answer();
        await rig.pair();

        await rig.transport.send(stock);

        expect(rig.session.current?.sessionToken, 'tok_secret_value');
      },
    );
  });

  // The token goes to `baseUrl + path`, and the port joins them. A path that is really a URL
  // would send the bearer token to a host the device never paired with. Callers build paths
  // from the registry, so this is a guard against a bug, not against an attacker — but it is
  // the one line that makes "the token only goes to the locked host" true whatever a caller
  // does (`.claude/rules/security.md` §1.1).
  group('a path that could leave the host', () {
    for (final path in [
      'https://evil.example/x',
      '//evil.example/x',
      r'/\evil.example/x',
      'api/v1/pos/stock',
      '',
      'evil.example/x',
    ]) {
      test('is refused, and nothing is sent: "$path"', () async {
        final rig = Rig()..answer();
        await rig.pair();

        await expectLater(
          rig.transport.send(
            TransportRequest(method: HttpMethod.get, path: path),
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(rig.http.calls, isEmpty);
      });
    }

    for (final path in [
      '/api/v1/pos/stock',
      '/api/v1/products?search=//x',
      '/api/v1/products?next=https://x.example',
      '/api/v1/x#a//b',
    ]) {
      test('is sent: "$path"', () async {
        final rig = Rig()..answer();
        await rig.pair();

        await rig.transport.send(
          TransportRequest(method: HttpMethod.get, path: path),
        );

        expect(rig.sent.request.path, path);
      });
    }

    test(
      'does not put the path in its error: a path can carry a search term',
      () async {
        final rig = Rig()..answer();
        await rig.pair();

        await expectLater(
          rig.transport.send(
            const TransportRequest(
              method: HttpMethod.get,
              path: 'https://evil.example/?q=pelanggan-rahasia',
            ),
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'text',
              isNot(contains('pelanggan-rahasia')),
            ),
          ),
        );
      },
    );
  });

  // A leaked token in a log line is a credential leak (`.claude/rules/security.md` §1).
  group('the token, where it must not appear', () {
    test('is not printed by anything the transport does', () async {
      final printed = <String>[];
      final rig = Rig()..answer(headers: {'x-session-token': 'tok_rotated'});
      await rig.pair();

      await runZoned(
        () async {
          await rig.transport.send(
            const TransportRequest(
              method: HttpMethod.post,
              path: '/api/v1/pos/stock',
              headers: {'Authorization': 'Bearer tok_secret_value'},
            ),
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => printed.add(line),
        ),
      );

      final output = printed.join('\n');
      expect(output, isNot(contains('tok_secret_value')));
      expect(output, isNot(contains('refresh_secret_value')));
      expect(output, isNot(contains('tok_rotated')));
    });

    test('is not in the error of a device that is not paired', () async {
      final rig = Rig();

      await expectLater(
        rig.transport.send(stock),
        throwsA(
          isA<NotPairedException>().having(
            (e) => e.toString(),
            'text',
            isNot(contains('tok_')),
          ),
        ),
      );
    });

    test('is not in the text of a session that reaches a log line', () async {
      final rig = Rig();
      await rig.pair();

      expect(
        rig.session.current.toString(),
        isNot(contains('tok_secret_value')),
      );
      expect(
        rig.session.current.toString(),
        isNot(contains('refresh_secret_value')),
      );
    });
  });

  // middleware/auth.go answers 401 for a session token it does not know: expired, revoked, or
  // rotated by another request whose answer this one has not seen yet. A cashier at a till must
  // not be sent to log in again for the last of those, and for the first two there is a refresh
  // token that may still work (auth_service.go `RefreshSession`).
  group('a rejected token (401)', () {
    final renewed = signedIn.copyWith(sessionToken: 'tok_renewed');

    Rig refreshing() => Rig()
      ..withRefresh = true
      ..refreshedTo = renewed;

    test(
      'refreshes the session and sends the request again with the new token',
      () async {
        final rig = refreshing()
          ..answer(status: 401)
          ..answer();
        await rig.pair();

        final response = await rig.transport.send(stock);

        expect(response.status, 200);
        expect(rig.refreshCalls, 1);
        expect(rig.http.calls, hasLength(2));
        expect(
          rig.http.calls[0].request.headers['Authorization'],
          'Bearer tok_secret_value',
        );
        expect(
          rig.http.calls[1].request.headers['Authorization'],
          'Bearer tok_renewed',
        );
        expect(rig.http.calls[1].request.path, stock.path);
      },
    );

    test('gives the 401 back when the refresh does not work', () async {
      final rig = refreshing()
        ..refreshSucceeds = false
        ..answer(status: 401);
      await rig.pair();

      final response = await rig.transport.send(stock);

      expect(response.status, 401);
      expect(rig.http.calls, hasLength(1));
      expect(rig.refreshCalls, 1);
    });

    test('sends the request again only once', () async {
      final rig = refreshing()
        ..answer(status: 401)
        ..answer(status: 401);
      await rig.pair();

      final response = await rig.transport.send(stock);

      expect(response.status, 401);
      expect(rig.http.calls, hasLength(2));
      expect(rig.refreshCalls, 1);
    });

    test('refreshes once for requests that are rejected together', () async {
      final rig = refreshing()
        ..answer(status: 401)
        ..answer(status: 401)
        ..answer()
        ..answer();
      await rig.pair();
      final transport = rig.transport;

      final responses = await Future.wait([
        transport.send(stock),
        transport.send(stock),
      ]);

      expect(responses.map((r) => r.status), [200, 200]);
      expect(rig.refreshCalls, 1);
      expect(rig.http.calls, hasLength(4));
    });

    test(
      'does not refresh when the token was already replaced elsewhere',
      () async {
        final rig = refreshing()
          ..answer(status: 401)
          ..answer();
        await rig.pair();
        // While the request is out, a login or a refresh made elsewhere replaces the token.
        rig.http.whileInFlight = () =>
            rig.session.save(signedIn.copyWith(sessionToken: 'tok_rotated'));

        final response = await rig.transport.send(stock);

        expect(response.status, 200);
        expect(rig.refreshCalls, 0);
        expect(
          rig.http.calls[1].request.headers['Authorization'],
          'Bearer tok_rotated',
        );
      },
    );

    test('leaves a request that carries its own Authorization alone', () async {
      final rig = refreshing()..answer(status: 401);
      await rig.pair();

      final response = await rig.transport.send(
        stock.copyWith(headers: {'Authorization': 'Bearer somebody_elses'}),
      );

      expect(response.status, 401);
      expect(rig.refreshCalls, 0);
      expect(rig.http.calls, hasLength(1));
    });

    test('does not refresh for a device nobody is signed in on', () async {
      final rig = refreshing()..answer(status: 401);
      await rig.pair(
        signedIn.copyWith(sessionToken: '', sessionRefreshToken: null),
      );

      final response = await rig.transport.send(stock);

      expect(response.status, 401);
      expect(rig.refreshCalls, 0);
    });

    for (final status in [400, 403, 404, 429, 500, 503]) {
      test('does not refresh for a $status', () async {
        final rig = refreshing()..answer(status: status);
        await rig.pair();

        final response = await rig.transport.send(stock);

        expect(response.status, status);
        expect(rig.refreshCalls, 0);
      });
    }

    test('gives the 401 back when no refresh was wired', () async {
      final rig = Rig()..answer(status: 401);
      await rig.pair();

      final response = await rig.transport.send(stock);

      expect(response.status, 401);
      expect(rig.http.calls, hasLength(1));
    });
  });

  // The backend does not rotate a bearer session on its own: it lasts as long as it was given,
  // from the login or the last refresh, and only a refresh extends it. A request made close to
  // the end renews first, and does not wait for the 401: an ended session authenticates nothing,
  // so the wait would cost a rejected request at the till. An ended session is renewed too: the
  // backend keeps it refreshable for 14 days.
  group('a session close to its end', () {
    final renewed = signedIn.copyWith(
      sessionToken: 'tok_renewed',
      expiresAt: '2026-09-27T12:00:00Z',
    );
    // 12:00 on the 20th, and the session ends 36 hours later.
    final ending = signedIn.copyWith(expiresAt: '2026-09-22T00:00:00Z');

    Rig renewing() => Rig()
      ..withRefresh = true
      ..refreshWithin = const Duration(hours: 84)
      ..refreshedTo = renewed;

    test(
      'is renewed before the request, which goes out once with the new token',
      () async {
        final rig = renewing()..answer();
        await rig.pair(ending);

        await rig.transport.send(stock);

        expect(rig.refreshCalls, 1);
        expect(rig.http.calls, hasLength(1));
        expect(
          rig.http.calls.single.request.headers['Authorization'],
          'Bearer tok_renewed',
        );
      },
    );

    // Guard, not RED: the behaviour already held.
    test('is renewed before the request after it ended, too', () async {
      final rig = renewing()..answer();
      await rig.pair(signedIn.copyWith(expiresAt: '2026-09-15T00:00:00Z'));

      await rig.transport.send(stock);

      expect(rig.refreshCalls, 1);
      expect(
        rig.http.calls.single.request.headers['Authorization'],
        'Bearer tok_renewed',
      );
    });

    test('is renewed once for requests made together', () async {
      final rig = renewing()
        ..answer()
        ..answer();
      await rig.pair(ending);
      final transport = rig.transport;

      await Future.wait([transport.send(stock), transport.send(stock)]);

      expect(rig.refreshCalls, 1);
      expect(rig.http.calls, hasLength(2));
    });

    test('is left alone when it has more than the window left', () async {
      final rig = renewing()..answer();
      await rig.pair(signedIn.copyWith(expiresAt: '2026-09-25T00:00:00Z'));

      await rig.transport.send(stock);

      expect(rig.refreshCalls, 0);
    });

    test('is left alone when it says nothing about its end', () async {
      final rig = renewing()..answer();
      await rig.pair();

      await rig.transport.send(stock);

      expect(rig.refreshCalls, 0);
    });

    test('is left alone when no window was configured', () async {
      final rig = renewing()
        ..refreshWithin = null
        ..answer();
      await rig.pair(ending);

      await rig.transport.send(stock);

      expect(rig.refreshCalls, 0);
    });

    test(
      'is not renewed for a request that carries its own Authorization',
      () async {
        final rig = renewing()..answer();
        await rig.pair(ending);

        await rig.transport.send(
          stock.copyWith(headers: {'Authorization': 'Bearer somebody_elses'}),
        );

        expect(rig.refreshCalls, 0);
      },
    );

    test('is not renewed for a device nobody is signed in on', () async {
      final rig = renewing()..answer();
      await rig.pair(
        ending.copyWith(sessionToken: '', sessionRefreshToken: null),
      );

      await rig.transport.send(stock);

      expect(rig.refreshCalls, 0);
    });

    test('still sends the request when the renewal fails', () async {
      final rig = renewing()
        ..refreshSucceeds = false
        ..answer();
      await rig.pair(ending);

      final response = await rig.transport.send(stock);

      expect(response.status, 200);
      expect(
        rig.http.calls.single.request.headers['Authorization'],
        'Bearer tok_secret_value',
      );
    });

    // Offline, every request would otherwise open with a refresh that cannot work, and a 401
    // that follows would try the same one again.
    test(
      'is not retried at once after a failure, but is after a minute',
      () async {
        final rig = renewing()
          ..refreshSucceeds = false
          ..answer(status: 401)
          ..answer()
          ..answer();
        await rig.pair(ending);
        final transport = rig.transport;

        final first = await transport.send(
          stock,
        ); // renewal fails; the 401 is not retried
        await transport.send(stock);
        expect(first.status, 401);
        expect(rig.refreshCalls, 1);

        rig.now = rig.now.add(const Duration(minutes: 1));
        await transport.send(stock);

        expect(rig.refreshCalls, 2);
      },
    );
  });

  // The server deletes a device from the dashboard and the tablet has to stop. It finds out
  // here, because every request goes through this one place — and the session has to change,
  // not just the response, because the gate reads the session to decide the screen.
  group('a device the server no longer knows', () {
    TransportResponse unregistered({Map<String, String> headers = const {}}) =>
        TransportResponse(
          status: 401,
          headers: const {'Content-Type': 'application/json'},
          body:
              '{"data":null,"error":{"name":"authorization","code":137,'
              '"key":"pos_device_unregistered","description":"x"}}',
        );

    test('marks the device revoked on the session', () async {
      final rig = Rig()..http.respond(unregistered());
      await rig.pair();

      await rig.transport.send(stock);

      expect(rig.session.current?.deviceRevoked, isTrue);
    });

    test(
      'clears the device token, which the server will not reissue',
      () async {
        final rig = Rig()..http.respond(unregistered());
        await rig.pair();

        await rig.transport.send(stock);

        expect(rig.session.current?.deviceToken, isNull);
      },
    );

    // The response is still returned: the transport reports what the server said. It is the
    // gate, reading the session, that moves the screen.
    test('still returns the response to the caller', () async {
      final rig = Rig()..http.respond(unregistered());
      await rig.pair();

      final response = await rig.transport.send(stock);

      expect(response.status, 401);
    });

    test(
      'does not retry: a deleted device cannot be fixed by asking again',
      () async {
        final rig = Rig()..http.respond(unregistered());
        await rig.pair();

        await rig.transport.send(stock);

        expect(rig.http.calls, hasLength(1));
        expect(rig.refreshCalls, 0);
      },
    );

    // The same detection, without the key: the deployed backend does not send it yet, and
    // 401/137 is the only signal there is. See the `ponytail:` note on the detector.
    test(
      'recognises it from the status and code when there is no key',
      () async {
        final rig = Rig()
          ..http.respond(
            TransportResponse(
              status: 401,
              headers: const {'Content-Type': 'application/json'},
              body:
                  '{"data":null,"error":{"name":"authorization","code":137,'
                  '"description":"x"}}',
            ),
          );
        await rig.pair();

        await rig.transport.send(stock);

        expect(rig.session.current?.deviceRevoked, isTrue);
      },
    );

    // 144 is `UnauthorizedLogin`: the cashier is signed out, the device is fine. Revoking the
    // pairing over that would lose the pairing for no reason and send a healthy tablet to pair
    // again — the expensive direction of getting this wrong.
    test('leaves the device alone for a login 401', () async {
      final rig = Rig()
        ..http.respond(
          TransportResponse(
            status: 401,
            headers: const {'Content-Type': 'application/json'},
            body:
                '{"data":null,"error":{"name":"authorization","code":144,'
                '"description":"You must login to make this request."}}',
          ),
        );
      await rig.pair();

      await rig.transport.send(stock);

      expect(rig.session.current?.deviceRevoked, isFalse);
      expect(rig.session.current?.deviceToken, 'dev_tok_1');
    });

    // A different keyed error is not this one.
    test('leaves the device alone for another keyed 401', () async {
      final rig = Rig()
        ..http.respond(
          TransportResponse(
            status: 401,
            headers: const {'Content-Type': 'application/json'},
            body:
                '{"data":null,"error":{"name":"authorization","code":137,'
                '"key":"some_other_key","description":"x"}}',
          ),
        );
      await rig.pair();

      await rig.transport.send(stock);

      expect(rig.session.current?.deviceRevoked, isFalse);
    });

    // Losing the store is not a reason to pretend the device is fine: the exception reaches
    // the caller rather than being swallowed into a half-applied revocation.
    test('surfaces a storage failure instead of swallowing it', () async {
      final rig = Rig()..http.respond(unregistered());
      await rig.pair();
      rig.store.failNext(StoreException('disk full'));

      await expectLater(
        rig.transport.send(stock),
        throwsA(isA<StoreException>()),
      );
    });
  });
}

/// A [FakePublicHttp] that runs [whileInFlight] while the request is "on the wire": after it was
/// sent and before the answer is handed back.
class _HookedHttp extends FakePublicHttp {
  Future<void> Function()? whileInFlight;

  @override
  Future<TransportResponse> send(
    String baseUrl,
    TransportRequest request,
  ) async {
    final response = await super.send(baseUrl, request);
    await whileInFlight?.call();
    return response;
  }
}
