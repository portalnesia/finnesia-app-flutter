/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/gate.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/pairing/pairing.dart';

import '../support/boot_rig.dart';

// Which screen the device is on comes from one thing, the session: none means not paired, a
// session without a token means paired but nobody signed in, a token means the till.

const signedOut = PosSession(
  baseUrl: 'https://erp.perusahaan.com',
  companyId: 'comp_1',
  outletId: 'out_1',
  sessionToken: '',
);

/// What a device looks like after the server said it is no longer registered: still paired in
/// the store, still signed in, but cut off until it pairs again.
const revoked = PosSession(
  baseUrl: 'https://erp.perusahaan.com',
  companyId: 'comp_1',
  outletId: 'out_1',
  sessionToken: 'tok_1',
  deviceRevoked: true,
);

void main() {
  group('the destination', () {
    test('is pairing when there is no session', () {
      expect(gateDestination(null), GateDestination.pairing);
    });

    test('is login when the device is paired and nobody is signed in', () {
      expect(gateDestination(signedOut), GateDestination.login);
    });

    test('is the till when a cashier is signed in', () {
      expect(gateDestination(paired), GateDestination.till);
    });

    // The server deleted this tablet. It cannot transact any more, and no screen it can reach
    // would fix that — the only way back is pairing again.
    test('is pairing when the server unregistered the device', () {
      expect(gateDestination(revoked), GateDestination.pairing);
    });

    // A device paired against a backend that predates the registry has no token either, and
    // must still reach the till: the flag, not the missing token, is what means "revoked".
    test('is the till for a paired device that simply has no token', () {
      expect(
        gateDestination(paired.copyWith(deviceToken: null)),
        GateDestination.till,
      );
    });
  });

  group('the gate', () {
    Widget over(AppServices services) => MaterialApp(
      home: AppScope(
        services: services,
        child: Gate(
          screens: (
            pairing: (_) => const Text('pairing screen'),
            login: (_) => const Text('login screen'),
            till: (_) => const Text('till screen'),
          ),
        ),
      ),
    );

    testWidgets('shows the pairing screen for a device that is not paired', (
      tester,
    ) async {
      await tester.pumpWidget(over(await Rig().ready()));

      expect(find.text('pairing screen'), findsOneWidget);
    });

    testWidgets('shows the login screen once the cashier is signed out', (
      tester,
    ) async {
      final services = await Rig(storedSession(signedOut)).ready();
      await tester.pumpWidget(over(services));

      expect(find.text('login screen'), findsOneWidget);
    });

    testWidgets('shows the till for a signed-in cashier', (tester) async {
      await tester.pumpWidget(over(await Rig(storedSession(paired)).ready()));

      expect(find.text('till screen'), findsOneWidget);
    });

    testWidgets('moves on by itself the moment pairing saves a session', (
      tester,
    ) async {
      final rig = Rig()..http.respond(activatedResponse());
      final services = await rig.ready();
      await tester.pumpWidget(over(services));

      await pairDevice('AB3K7M', services.pairingDeps);
      await tester.pump();

      expect(find.text('pairing screen'), findsNothing);
      expect(find.text('login screen'), findsOneWidget);
    });

    testWidgets('goes back to login when the cashier signs out', (
      tester,
    ) async {
      final services = await Rig(storedSession(paired)).ready();
      await tester.pumpWidget(over(services));

      await services.session.clearToken();
      await tester.pump();

      expect(find.text('login screen'), findsOneWidget);
    });

    // The whole point of the revocation: the moment the server says the tablet is gone, the
    // till is unreachable. Without this the tablet keeps selling against a registry entry that
    // no longer exists.
    testWidgets('goes back to pairing when the server unregisters the device', (
      tester,
    ) async {
      final services = await Rig(storedSession(paired)).ready();
      await tester.pumpWidget(over(services));

      await services.session.unregisterDevice();
      await tester.pump();

      expect(find.text('pairing screen'), findsOneWidget);
      expect(find.text('till screen'), findsNothing);
    });

    // Pairing again is the way out, and it has to work from the revoked state — otherwise the
    // tablet is bricked. The flag is not a blacklist.
    testWidgets('reaches the till again after pairing following a revocation', (
      tester,
    ) async {
      final rig = Rig(storedSession(paired));
      final services = await rig.ready();
      await tester.pumpWidget(over(services));
      await services.session.unregisterDevice();
      await tester.pump();
      expect(find.text('pairing screen'), findsOneWidget);

      rig.http.respond(activatedResponse());
      await pairDevice('AB3K7M', services.pairingDeps);
      await tester.pump();

      expect(find.text('login screen'), findsOneWidget);
    });
  });
}
