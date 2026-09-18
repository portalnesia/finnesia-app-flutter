/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_types/src/api/environment.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/http/pos_transport.dart';
import 'package:pos/login/native_login.dart';
import 'package:pos/pairing/pairing.dart';
import 'package:pos/preferences/app_preferences.dart';
import 'package:pos/session/session_holder.dart';

import 'support/boot_rig.dart';

/// [paired], and a cashier is at the till.
const signedIn = PosSession(
  baseUrl: 'https://erp.perusahaan.com',
  companyId: 'comp_1',
  outletId: 'out_1',
  sessionToken: 'tok_secret_value',
  user: SessionUser(id: 'user_1'),
);

/// A sale Q6's queue sync has to drain: one pending entry, typed by [signedIn]'s cashier.
PendingSale pendingSale() => PendingSale(
  clientRef: 'REF-1',
  companyId: signedIn.companyId,
  outletId: signedIn.outletId,
  cashierId: signedIn.user!.id,
  status: PendingSaleStatus.pending,
  paidAt: '2026-09-22T03:00:00.000Z',
  createdAt: '2026-09-22T03:00:00.000Z',
  payload: const POSCheckoutDTO(
    outletId: 'out_1',
    transactionDate: '2026-09-22',
    items: [
      POSCheckoutItemDTO(
        productId: 'p1',
        unitId: 'u1',
        quantity: 1,
        price: 15000,
      ),
    ],
    payments: [POSTenderDTO(method: POSTenderMethod.cash, amount: 15000)],
  ),
  receipt: const PendingSaleReceipt(
    subtotal: 15000,
    discountAmount: 0,
    taxAmount: 0,
    grandTotal: 15000,
    tenderedAmount: 15000,
    changeAmount: 0,
    items: [],
  ),
);

/// What `/pos/shifts/active` answers when no shift is open.
TransportResponse activeShiftResponse() => TransportResponse(
  status: 200,
  headers: const {'content-type': 'application/json'},
  body: '{"data":null}',
);

/// What `POST /pos/sales/checkout` answers for [pendingSale].
TransportResponse saleResponse() => TransportResponse(
  status: 200,
  headers: const {'content-type': 'application/json'},
  body: jsonEncode({
    'data': {
      'id': 'x1',
      'number': 'POS-0001',
      'shift_id': 's1',
      'outlet_id': 'out_1',
      'cashier_id': 'user_1',
      'transaction_date': '2026-09-22',
      'subtotal': 15000,
      'discount_amount': 0,
      'tax_amount': 0,
      'grand_total': 15000,
      'tendered_amount': 15000,
      'change_amount': 0,
      'status': 'POSTED',
      'created_at': '2026-09-22T03:00:00Z',
    },
  }),
);

void main() {
  group('starting up', () {
    test('comes up paired when a session was stored', () async {
      final services = await Rig(storedSession(paired)).ready();

      expect(services.session.current, paired);
    });

    test('hands the held-order store it was given to the screens', () async {
      final rig = Rig();

      final services = await rig.ready();

      expect(services.holdStore, same(rig.holdStore));
    });

    // Not `same(rig.pendingSaleStore)`: the store `AppServices` is handed is the one Q6's queue
    // sync drains, so the proof is that the two agree, not that they are one field pointing at
    // another (`bootstrap.dart` builds `queueSync` from `pendingSaleStore` itself).
    test(
      'drains the pending-sale store it was given, in the background',
      () async {
        final rig = Rig(storedSession(signedIn));
        await rig.pendingSaleStore.enqueue(pendingSale());
        rig.http
          ..respond(activeShiftResponse())
          ..respond(saleResponse());

        final services = await rig.ready();
        addTearDown(services.dispose);
        await services.queueSync.sync();

        expect(await rig.pendingSaleStore.readAll(), isEmpty);
      },
    );

    // The formatter throws until it has been asked for its locale data, so a screen that draws
    // a price before this would crash in the cashier's hand. Nothing in a widget test would
    // notice: every one of them calls it in its own setup.
    test('can format money as soon as it is up', () async {
      await Rig().ready();

      expect(formatCurrency(150000), 'Rp 150.000');
    });

    // `timezone` does not know the device's zone (its local is UTC), so the boot hands it the
    // offset the OS reports. Without it a tablet in WIB shows 06:00 as 23:00 the day before.
    test('shows times in the zone of the tablet', () async {
      addTearDown(() => useFixedLocalZone(Duration.zero));
      final rig = Rig()..deviceOffset = const Duration(hours: 7);

      await rig.ready();

      expect(formatDateTime('2026-09-19T23:30:00Z'), contains('20 Sep 2026'));
    });

    test('comes up unpaired when nothing was stored', () async {
      final services = await Rig().ready();

      expect(services.session.current, isNull);
    });
  });

  group('the API client', () {
    test('sends to the host of the session, with its bearer', () async {
      final rig = Rig(storedSession(paired))..http.respond(jsonOk());
      final services = await rig.ready();

      final data = await services.client.request<Object?>(
        method: HttpMethod.get,
        path: '/api/v1/pos/stock',
        parse: (d) => d,
      );

      expect(data, 1);
      final sent = rig.http.calls.single;
      expect(sent.baseUrl, paired.baseUrl);
      expect(sent.request.path, '/api/v1/pos/stock');
      expect(sent.request.headers['Authorization'], 'Bearer tok_secret_value');
      expect(sent.request.headers['X-Company-ID'], 'comp_1');
    });

    test('has no host to send to before pairing', () async {
      final rig = Rig();
      final services = await rig.ready();

      await expectLater(
        services.client.request<Object?>(
          method: HttpMethod.get,
          path: '/api/v1/pos/stock',
          parse: (d) => d,
        ),
        throwsA(isA<NotPairedException>()),
      );
      expect(rig.http.calls, isEmpty);
    });

    test('asks in Indonesian by default', () async {
      final rig = Rig(storedSession(paired))..http.respond(jsonOk());
      final services = await rig.ready();

      await services.client.request<Object?>(
        method: HttpMethod.get,
        path: '/api/v1/pos/stock',
        parse: (d) => d,
      );

      expect(rig.http.calls.single.request.headers['Accept-Language'], 'id');
    });

    test(
      'asks in the language the cashier picks, from the next request on',
      () async {
        final rig = Rig(storedSession(paired))..http.respond(jsonOk());
        final services = await rig.ready();

        await rig.language.select(AppLanguage.en);
        await services.client.request<Object?>(
          method: HttpMethod.get,
          path: '/api/v1/pos/stock',
          parse: (d) => d,
        );

        expect(rig.http.calls.single.request.headers['Accept-Language'], 'en');
      },
    );

    test(
      'hands the language and theme to whatever screen changes them',
      () async {
        final rig = Rig();
        final services = await rig.ready();

        expect(services.language, same(rig.language));
        expect(services.theme, same(rig.theme));
      },
    );
  });

  // Before pairing there is no tenant, so the host comes from the endpoint environment; after
  // it, the session owns the host and the choice is gone (README §13.3, `security.md` §1.1).
  group('the endpoint environment', () {
    test(
      'defaults to staging, the one a debug developer nearly always wants',
      () async {
        final services = await Rig().ready();

        expect(
          services.pairingDeps.canonicalHost,
          canonicalHost(EndpointEnvironment.staging),
        );
      },
    );

    test('can be chosen while the device is not paired', () async {
      final services = await Rig().ready();

      expect(services.canPickEndpoint, isTrue);
      services.chooseEndpoint(EndpointEnvironment.production);

      expect(services.pairingDeps.canonicalHost, productionHost);
      expect(services.endpoint, EndpointEnvironment.production);
    });

    test('cannot be chosen once the device is paired', () async {
      final services = await Rig(storedSession(paired)).ready();

      expect(services.canPickEndpoint, isFalse);
      services.chooseEndpoint(EndpointEnvironment.production);

      expect(
        services.pairingDeps.canonicalHost,
        canonicalHost(EndpointEnvironment.staging),
      );
    });

    test('stops being choosable the moment pairing saves a session', () async {
      final rig = Rig()..http.respond(activatedResponse());
      final services = await rig.ready();
      expect(services.canPickEndpoint, isTrue);

      await pairDevice('AB3K7M', services.pairingDeps);

      expect(services.canPickEndpoint, isFalse);
    });
  });

  // The UI mirrors the session through this: pairing saves it from a screen that does not own
  // the widget tree, and without a notification the app keeps showing "not paired".
  group('telling the UI that something changed', () {
    test('notifies when pairing saves a session', () async {
      final rig = Rig()..http.respond(activatedResponse());
      final services = await rig.ready();
      var notified = 0;
      services.addListener(() => notified++);

      await pairDevice('AB3K7M', services.pairingDeps);

      expect(notified, 1);
    });

    test('notifies when the session is cleared', () async {
      final services = await Rig(storedSession(paired)).ready();
      var notified = 0;
      services.addListener(() => notified++);

      await services.session.clear();

      expect(notified, 1);
    });

    test('notifies when the endpoint is chosen', () async {
      final services = await Rig().ready();
      var notified = 0;
      services.addListener(() => notified++);

      services.chooseEndpoint(EndpointEnvironment.production);

      expect(notified, 1);
    });

    test('does not notify for an endpoint pick that changes nothing', () async {
      final services = await Rig(storedSession(paired)).ready();
      var notified = 0;
      services.addListener(() => notified++);

      services.chooseEndpoint(EndpointEnvironment.production);

      expect(notified, 0);
    });

    test('stops listening to the session once it is disposed', () async {
      final rig = Rig(storedSession(paired));
      final services = await rig.ready();

      services.dispose();

      // Would throw "used after being disposed" if it still notified.
      await services.session.clear();
    });
  });

  group('pairing, then calling the API', () {
    test(
      'pairs against the chosen host, then talks to the session host',
      () async {
        final rig = Rig()
          ..http.respond(activatedResponse())
          ..http.respond(jsonOk());
        final services = await rig.ready();
        services.chooseEndpoint(EndpointEnvironment.production);

        await pairDevice('AB3K7M', services.pairingDeps);
        await services.client.request<Object?>(
          method: HttpMethod.get,
          path: '/api/v1/pos/stock',
          parse: (d) => d,
        );

        expect(rig.http.calls, hasLength(2));
        expect(rig.http.calls[0].baseUrl, productionHost);
        expect(rig.http.calls[0].request.path, '/api/v1/pos/devices/activate');
        expect(
          rig.http.calls[1].baseUrl,
          productionHost,
        ); // no custom_domain: canonical
        expect(rig.http.calls[1].request.path, '/api/v1/pos/stock');
        // Pairing gave the device an identity, and it lives in the same store as the session.
        expect(rig.store.values, contains(sessionKey));
        // The fingerprint is NOT in the store any more: it is the platform's identifier, which
        // is what lets an uninstall find the tablet's existing row instead of adding one.
        expect(rig.store.values, isNot(contains('device_id')));
      },
    );
  });

  group('logging in', () {
    test(
      'starts a login through the same browser and host as pairing',
      () async {
        final rig = Rig(storedSession(paired))
          ..http.respond(
            TransportResponse(
              status: 200,
              body: '{"data":{"request_id":"req_abc","login_url":"$loginUrl"}}',
            ),
          )
          ..http.respond(readyResponse());
        final services = await rig.ready();

        await loginNative(services.loginDeps);

        expect(rig.opener.opened, [loginUrl]);
        expect(rig.http.calls.first.baseUrl, paired.baseUrl);
        expect(services.session.current?.sessionToken, 'sess_tok');
      },
    );
  });

  // A login the app was killed in the middle of is still waiting in Redis; the cashier has not
  // asked for anything yet, so a resume that fails is not worth showing them.
  group('resuming a login left behind', () {
    test('collects it, and the cashier is signed in', () async {
      final rig = Rig({...storedSession(paired), pendingLoginKey: 'req_abc'})
        ..http.respond(readyResponse());
      final services = await rig.ready();

      await services.resumeLogin();

      expect(services.session.current?.sessionToken, 'sess_tok');
    });

    test('does nothing when no login was left behind', () async {
      final rig = Rig(storedSession(paired));
      final services = await rig.ready();

      await services.resumeLogin();

      expect(rig.http.calls, isEmpty);
    });

    test('does not throw when the network is down', () async {
      final rig = Rig({...storedSession(paired), pendingLoginKey: 'req_abc'})
        ..http.fail(TransportException('no connection'))
        // A dropped poll no longer ends the login (`native_login.dart` `_pollOnce`): the request
        // is still alive in Redis, so the loop keeps polling. The deadline is what ends it here,
        // and a resume that fails is swallowed by the controller — which is what this asserts.
        ..pollTimeout = Duration.zero;
      final services = await rig.ready();

      await services.resumeLogin();

      expect(services.session.current?.sessionToken, 'tok_secret_value');
    });

    test('does not throw when the storage cannot be read', () async {
      final rig = Rig({...storedSession(paired), pendingLoginKey: 'req_abc'});
      final services = await rig.ready();
      rig.store.failNext(StoreException('the stored value could not be read'));

      await services.resumeLogin();

      expect(rig.http.calls, isEmpty);
    });
  });

  // D-Q8: the app coming back to the foreground is also a moment to try the offline queue,
  // not only to poll a login.
  group('coming back to the foreground', () {
    test('also wakes the offline queue', () async {
      final rig = Rig(storedSession(signedIn));
      await rig.pendingSaleStore.enqueue(pendingSale());
      rig.http
        ..respond(activeShiftResponse())
        ..respond(saleResponse());
      final services = await rig.ready();
      addTearDown(services.dispose);

      services.onForeground();
      await Future.delayed(const Duration(milliseconds: 80));

      expect(await rig.pendingSaleStore.readAll(), isEmpty);
    });
  });

  // The backend rotates the session token, and a request that loses that race, or one made
  // after the session ended, is answered 401. The cashier should not be sent to log in again
  // for a session a refresh token can still renew.
  group('a rejected token, in the app', () {
    test(
      'is refreshed against the session host, and the request goes again',
      () async {
        final rig = Rig(storedSession(paired))
          ..http.respond(TransportResponse(status: 401))
          ..http.respond(refreshedResponse())
          ..http.respond(jsonOk());
        final services = await rig.ready();

        final data = await services.client.request<Object?>(
          method: HttpMethod.get,
          path: '/api/v1/pos/stock',
          parse: (d) => d,
        );

        expect(data, 1);
        expect(rig.http.calls.map((c) => c.request.path), [
          '/api/v1/pos/stock',
          '/api/auth/refresh',
          '/api/v1/pos/stock',
        ]);
        expect(rig.http.calls[1].baseUrl, paired.baseUrl);
        final body = jsonDecode(rig.http.calls[1].request.body!);
        expect(body['refresh_token'], 'refresh_secret_value');
        expect(
          rig.http.calls[2].request.headers['Authorization'],
          'Bearer tok_new',
        );
        expect(services.session.current?.sessionRefreshToken, 'ref_new');
      },
    );

    test('is an ApiError 401 when the refresh is refused', () async {
      final rig = Rig(storedSession(paired))
        ..http.respond(TransportResponse(status: 401))
        ..http.respond(TransportResponse(status: 401));
      final services = await rig.ready();

      await expectLater(
        services.client.request<Object?>(
          method: HttpMethod.get,
          path: '/api/v1/pos/stock',
          parse: (d) => d,
        ),
        throwsA(isA<ApiError>().having((e) => e.status, 'status', 401)),
      );
    });
  });

  group('a request made close to the end of the session', () {
    test('renews the session first, and goes out with the new token', () async {
      final rig = Rig(storedSession(endingAt(DateTime.utc(2026, 9, 21, 12))))
        ..http.respond(refreshedResponse())
        ..http.respond(jsonOk());
      final services = await rig.ready();

      await services.client.request<Object?>(
        method: HttpMethod.get,
        path: '/api/v1/pos/stock',
        parse: (d) => d,
      );

      expect(rig.http.calls.map((c) => c.request.path), [
        '/api/auth/refresh',
        '/api/v1/pos/stock',
      ]);
      expect(
        rig.http.calls[1].request.headers['Authorization'],
        'Bearer tok_new',
      );
    });
  });

  // A bearer session is renewed only by a refresh, so a launch renews one in the last half of
  // its life. One that has ended is renewed too: the backend keeps it refreshable for 14 days
  // (`sessionRefreshGracePeriod`) while access stays strict. How far past the end it still works
  // is the server's to say, so the client never decides a refresh is pointless.
  group('a session close to its end, at launch', () {
    Future<Rig> launched(PosSession? session, {DateTime? at}) async {
      final rig = Rig(session == null ? const {} : storedSession(session));
      if (at != null) rig.now = at;
      return rig;
    }

    Future<AppServices> refreshLaunch(Rig rig) async {
      final services = await rig.ready();
      await services.refreshIfExpiring();
      return services;
    }

    test('is refreshed when less than half its lifetime is left', () async {
      final rig = await launched(endingAt(DateTime.utc(2026, 9, 21, 12)));
      rig.http.respond(refreshedResponse());

      final services = await refreshLaunch(rig);

      expect(rig.http.calls.single.request.path, '/api/auth/refresh');
      expect(services.session.current?.sessionToken, 'tok_new');
    });

    test('is refreshed one minute inside the 84 hours', () async {
      final rig = await launched(endingAt(DateTime.utc(2026, 9, 23, 23, 59)));
      rig.http.respond(refreshedResponse());

      await refreshLaunch(rig);

      expect(rig.http.calls, hasLength(1));
    });

    test('is left alone at exactly 84 hours and beyond', () async {
      final rig = await launched(endingAt(DateTime.utc(2026, 9, 24)));

      await refreshLaunch(rig);

      expect(rig.http.calls, isEmpty);
    });

    test('is left alone when it has days to go', () async {
      final rig = await launched(endingAt(DateTime.utc(2026, 9, 26, 12)));

      await refreshLaunch(rig);

      expect(rig.http.calls, isEmpty);
    });

    test(
      'is still tried once it has ended: the server decides, not the clock',
      () async {
        final rig = await launched(endingAt(DateTime.utc(2026, 9, 20, 11)));
        rig.http.respond(refreshedResponse());

        await refreshLaunch(rig);

        expect(rig.http.calls, hasLength(1));
      },
    );

    // Guards, not RED: the behaviour already held. They lock the contract, so nobody adds a
    // "too old to bother" shortcut that the backend's 14 days would make wrong.
    test(
      'is refreshed after it ended days ago, inside what the backend keeps',
      () async {
        final rig = await launched(endingAt(DateTime.utc(2026, 9, 10, 12)));
        rig.http.respond(refreshedResponse());

        final services = await refreshLaunch(rig);

        expect(rig.http.calls, hasLength(1));
        expect(services.session.current?.sessionToken, 'tok_new');
      },
    );

    test(
      'is still tried long after that, and a refusal leaves it untouched',
      () async {
        final session = endingAt(DateTime.utc(2026, 8, 20, 12));
        final rig = await launched(session);
        rig.http.respond(TransportResponse(status: 401));

        final services = await refreshLaunch(rig);

        expect(rig.http.calls, hasLength(1));
        expect(services.session.current, session);
      },
    );

    test('is left alone when it says nothing about its end', () async {
      final rig = await launched(endingAt(null));

      await refreshLaunch(rig);

      expect(rig.http.calls, isEmpty);
    });

    test('is left alone when its end cannot be read', () async {
      final rig = await launched(paired.copyWith(expiresAt: 'soon'));

      await refreshLaunch(rig);

      expect(rig.http.calls, isEmpty);
    });

    test('has nothing to refresh when nobody is signed in', () async {
      final rig = await launched(
        endingAt(DateTime.utc(2026, 9, 21, 12))
            .copyWith(sessionToken: '', sessionRefreshToken: null),
      );

      await refreshLaunch(rig);

      expect(rig.http.calls, isEmpty);
    });

    test('has nothing to refresh when the device is not paired', () async {
      final rig = await launched(null);

      await refreshLaunch(rig);

      expect(rig.http.calls, isEmpty);
    });

    test(
      'does not throw when the network is down, and keeps the session',
      () async {
        final session = endingAt(DateTime.utc(2026, 9, 21, 12));
        final rig = await launched(session);
        rig.http.fail(TransportException('no connection'));

        final services = await refreshLaunch(rig);

        expect(services.session.current, session);
      },
    );

    test('does not throw when the new session cannot be stored', () async {
      final rig = await launched(endingAt(DateTime.utc(2026, 9, 21, 12)));
      rig.http.respond(refreshedResponse());
      final services = await rig.ready();
      rig.store.failNext(StoreException('the value could not be stored'));

      await services.refreshIfExpiring();
    });
  });

  // A Keystore that cannot be read is not "not paired": treating it so would send a cashier to
  // re-pair a device that is in fact paired (`SessionHolder.hydrate`, `StorePort`).
  group('when the storage cannot be read', () {
    test('does not come up, and does not say the device is unpaired', () async {
      final rig = Rig(storedSession(paired));
      rig.store.failNext(StoreException('the stored value could not be read'));

      final result = await rig.boot();

      expect(result, isA<BootFailed>());
    });

    test('can be tried again once the storage answers', () async {
      final rig = Rig(storedSession(paired));
      rig.store.failNext(StoreException('the stored value could not be read'));
      await rig.boot();

      final services = await rig.ready();

      expect(services.session.current, paired);
    });

    test('keeps what was stored: nothing is removed to recover', () async {
      final rig = Rig(storedSession(paired));
      rig.store.failNext(StoreException('the stored value could not be read'));

      await rig.boot();

      expect(rig.store.values, storedSession(paired));
      expect(
        rig.store.operations.map((o) => o.op),
        isNot(contains(StoreOp.remove)),
      );
    });
  });
}
