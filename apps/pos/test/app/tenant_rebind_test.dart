/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/pos_app.dart';

import '../support/boot_rig.dart';

/// The pending-sale store is bound to a tenant at construction, and the tenant is only known
/// once the device is paired. This file pins the consequence: **the services have to be rebuilt
/// when the pairing changes**, or the store the till uses stays bound to whatever the session
/// said at boot.
///
/// The bug this exists to catch, seen in Crashlytics on the first sale after pairing:
///
///   Invalid argument (sale.companyId): belongs to another company than this store ():
///     "01M38J2KRJQ4V5FAQ8PSGYW281"
///
/// The store's company was the **empty string** — `bootstrap` ran before pairing, so
/// `session.current?.companyId ?? ''` bound it to `''`, and nothing rebuilt the services once
/// pairing saved the real company. `enqueue` refused (correctly), the sale never went out, and
/// because it threw an `ArgumentError` rather than a `PendingSaleStoreException` the pay screen
/// showed nothing at all — the button simply looked dead.
///
/// A restart hid it: the next boot reads the stored company, so the second attempt worked. That
/// is why this is a widget test over the real `PosApp` and not a unit test of the store.

/// Pairs the device the way the pairing screen does, from inside the widget tree.
Widget _pairing(BuildContext context) => Builder(
  builder: (context) => TextButton(
    onPressed: () => AppScope.of(context).session.save(paired),
    child: const Text('pair'),
  ),
);

/// Reports the tenant the **till's** queue is bound to, read through `AppScope` — the same
/// object `TillScreen` hands to `CheckoutService`.
Widget _till(BuildContext context) => Builder(
  builder: (context) =>
      Text('queue=${AppScope.of(context).pendingSaleStore.companyId}'),
);

Widget _login(BuildContext context) => const Text('login');

const _screens = (pairing: _pairing, login: _login, till: _till);

PosApp appOver(Rig rig) => PosApp(
  boot: rig.boot,
  language: rig.language,
  theme: rig.theme,
  screens: _screens,
);

void main() {
  testWidgets(
    'a device that pairs after boot gets a queue for the paired tenant',
    (tester) async {
      // Booted unpaired: `session.current` is null, so the queue starts bound to the empty
      // company. This is the state every fresh install is in.
      final rig = Rig();

      await tester.pumpWidget(appOver(rig));
      await tester.pumpAndSettle();

      expect(
        find.text('pair'),
        findsOneWidget,
        reason: 'an unpaired device should be on the pairing screen',
      );

      // Pairing saves the session, which is the moment the tenant becomes known.
      await tester.tap(find.text('pair'));
      await tester.pumpAndSettle();

      // The till must be wired to the company the session now names. Before the fix this read
      // `queue=` (empty): the services were built once, before pairing, and never rebuilt.
      expect(
        find.text('queue=${paired.companyId}'),
        findsOneWidget,
        reason:
            'the queue the till sells into must be bound to the paired company, not to the '
            'empty one bootstrap saw before pairing',
      );
    },
  );

  testWidgets(
    'a device that was already paired boots with a queue for its tenant',
    (tester) async {
      // The control: this is the case a restart produces, and it worked all along. If this ever
      // fails, the failure above is not the one being reported.
      final rig = Rig(storedSession(paired));

      await tester.pumpWidget(appOver(rig));
      await tester.pumpAndSettle();

      expect(find.text('queue=${paired.companyId}'), findsOneWidget);
    },
  );

  test('the queue a paired boot is given is bound to the session, not to a default', () async {
    // Pins the wiring at the seam the widget tests cannot reach: whatever `bootstrap` hands
    // `AppServices` has to carry the session's company, because that store is what the till
    // and the drain loop both use.
    final services = await Rig(storedSession(paired)).ready();
    addTearDown(services.dispose);

    expect(services.pendingSaleStore.companyId, paired.companyId);
  });

  test('the queue an unpaired boot is given is empty, which is what the rebuild corrects', () async {
    // Documents the pre-pairing state deliberately: it is not a bug on its own, it is the
    // reason the services have to be rebuilt when pairing lands.
    final services = await Rig().ready();
    addTearDown(services.dispose);

    expect(services.pendingSaleStore.companyId, '');
  });
}
