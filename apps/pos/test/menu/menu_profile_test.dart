/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/menu/menu_controller.dart';

// Reported from a tablet: the Menu's account card said "Tidak diketahui" for a cashier who was
// signed in.
//
// The card falls back to that word when the session carries neither a name nor an email. It is
// reached by a real login: `/api/auth/mobile/poll` is registered **without** `RequireAuth`
// (`auth_routes.go`), so the request has no `ctx.User`, and `GetProfile` answers
// `&model.User{ID: userID}` — an id, an empty name and an empty email. The app stores that
// profile, and nothing later fills it in.
//
// So the fallback is not wrong; it is the only thing it can say. What the screen does about it
// is the subject here.

const _json = {'content-type': 'application/json'};

TransportResponse ok(Object? data) => TransportResponse(
  status: 200,
  headers: _json,
  body: jsonEncode({'data': data}),
);

/// A backend whose profile endpoint answers, and whose outlet read is not needed.
({MenuScreenController menu, FakeApiTransport transport}) rigWithMe({
  required bool hasMe,
}) {
  final transport = FakeApiTransport();
  if (hasMe) {
    transport.respond(
      ok({
        'user': {
          'id': 'user_1',
          'name': 'Budi',
          'email': 'budi@perusahaan.com',
        },
        'companies': <Object?>[],
      }),
    );
  }
  final menu = MenuScreenController(
    client: ApiClient(transport: transport, language: () => 'id'),
    // No outlet: this test is about the profile, and an empty outlet asks for nothing.
    outletId: '',
  );
  addTearDown(menu.dispose);
  return (menu: menu, transport: transport);
}

/// A session whose profile is the empty one the poll hands out.
const anonymousProfile = SessionUser(id: 'user_1');

void main() {
  group('a cashier whose profile has no name', () {
    test('is fetched from the server rather than left as "unknown"', () async {
      final (:menu, :transport) = rigWithMe(hasMe: true);

      await menu.loadProfile(anonymousProfile);

      // The id is known and the endpoint takes no parameters: the profile is one request, and it
      // is what turns "Tidak diketahui" back into a name.
      expect(
        transport.requests.map((r) => r.path.split('?').first),
        contains('/api/auth/me'),
      );
      expect(menu.profile?.name, 'Budi');
    });

    test('is not fetched again when the session already has a name', () async {
      final (:menu, :transport) = rigWithMe(hasMe: false);

      await menu.loadProfile(const SessionUser(id: 'user_1', name: 'Budi'));

      // The session is the fast path: no request, and it is the app's own record of the login.
      expect(transport.requests, isEmpty);
      expect(menu.profile?.name, 'Budi');
    });

    test(
      'is not fetched again when the session already has an email',
      () async {
        final (:menu, :transport) = rigWithMe(hasMe: false);

        await menu.loadProfile(
          const SessionUser(id: 'user_1', email: 'budi@perusahaan.com'),
        );

        // Either one answers "which account is this?", which is the only question the card asks.
        expect(transport.requests, isEmpty);
      },
    );

    test('still shows what it has when the server cannot answer', () async {
      final transport = FakeApiTransport();
      transport.fail(TransportException('offline'));
      final menu = MenuScreenController(
        client: ApiClient(transport: transport, language: () => 'id'),
        outletId: '',
      );
      addTearDown(menu.dispose);

      await menu.loadProfile(anonymousProfile);

      // A profile that could not be read must not take the screen down: the cashier can still see
      // their shift and can still sign out (`menu_controller.dart`).
      expect(menu.profile?.id, 'user_1');
    });

    test('with no profile at all, asks for nothing', () async {
      final (:menu, :transport) = rigWithMe(hasMe: true);

      await menu.loadProfile(null);

      // A session with nobody signed in has no profile to complete, and `/auth/me` would be a
      // request the server answers 401.
      expect(transport.requests, isEmpty);
    });
  });
}
