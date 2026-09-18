/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/screens/common/till_shell.dart';
import 'package:pos/screens/menu/menu_screen.dart';
import 'package:pos/screens/shift/shift_gate_screen.dart';
import 'package:pos/screens/shift/shift_screen.dart';

import '../../support/routed_http.dart';

import '../../support/boot_rig.dart';
import '../menu/menu_screen_test.dart' show MenuHttp;

// The way out to the Menu, from behind the shift gate.
//
// This is the behaviour `till-bar.tsx` calls out in a comment: "a cashier who cannot sell yet
// still has to be able to change the language or sign out". The bar is wrapped around the gate
// rather than put inside the till screen, so this is what proves it stands over the panels a
// cashier sees *before* they may sell — which is exactly the state a tablet is left in when a
// cashier walks away without signing out.

final signedIn = paired.copyWith(
  user: const SessionUser(id: 'user_1', name: 'Budi'),
  deviceName: 'Tablet Kasir',
);

const shiftForDetail = POSShift(
  id: 's1',
  number: 'SH-0001',
  cashierId: 'user_1',
  outletId: 'out_1',
  openedAt: '2026-09-20T01:00:00Z',
  openingCash: 150000,
  totalSales: 0,
  totalTransactions: 0,
);

PosApp appWith(Rig rig, Widget child) => PosApp(
  boot: () => rig.bootWith(http: MenuHttp()),
  language: rig.language,
  theme: rig.theme,
  screens: (
    pairing: (_) => const Text('pairing'),
    login: (_) => const Text('login'),
    till: (_) => TillShell(child: child),
  ),
);

Future<void> pumpShell(WidgetTester tester, Rig rig, Widget child) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(appWith(rig, child));
  await tester.pumpAndSettle();
}

Map<String, Object?> shiftBody() => {
  'id': 's1',
  'number': 'SH-0001',
  'cashier_id': 'user_1',
  'outlet_id': 'out_1',
  'opened_at': '2026-09-20T01:00:00Z',
  'opening_cash': 150000,
  'total_sales': 0,
  'total_transactions': 0,
};

PosApp appWithGate(Rig rig, RoutedHttp http) => PosApp(
  boot: () => rig.bootWith(http: http),
  language: rig.language,
  theme: rig.theme,
  screens: (
    pairing: (_) => const Text('pairing'),
    login: (_) => const Text('login'),
    till: (_) => TillShell(
      child: ShiftGateScreen(till: (_, _, _) => const Text('the till')),
    ),
  ),
);

void main() {
  group('the shift detail action', () {
    testWidgets('is absent while no shift has ever been opened', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(activePath, ok(null))
        ..respond(settingsPath, ok({'require_shift': true}));

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(appWithGate(Rig(storedSession(signedIn)), http));
      await tester.pumpAndSettle();

      expect(find.text('Buka shift'), findsOneWidget); // the open-shift panel
      expect(find.text('Detail shift'), findsNothing);
    });

    testWidgets('appears once a shift is open', (tester) async {
      final http = RoutedHttp()
        ..respond(activePath, ok(shiftBody()))
        ..respond(settingsPath, ok({'require_shift': true}));

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(appWithGate(Rig(storedSession(signedIn)), http));
      await tester.pumpAndSettle();

      // Not resumed yet, so this is the "already open" panel, not the till — the button has
      // to appear whenever a shift exists, not only once the cashier has consciously
      // continued it. That matches the Menu's own rule (`shift is POSShift`).
      expect(find.text('the till'), findsNothing);
      expect(find.text('Detail shift'), findsOneWidget);
    });
  });

  testWidgets('the bar stands above whatever is behind it', (tester) async {
    final rig = Rig(storedSession(signedIn));
    await pumpShell(tester, rig, const Text('the gate'));

    // Both are on screen: the bar is wrapped around the screen behind it, not replacing it.
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('the gate'), findsOneWidget);
  });

  testWidgets('the bar is above the child, not below it', (tester) async {
    final rig = Rig(storedSession(signedIn));
    await pumpShell(tester, rig, const Text('the gate'));

    // The shift gate's own Scaffold would cover a bar placed underneath it. Order on screen is
    // what makes the bar reachable at all.
    expect(
      tester.getTopLeft(find.text('Menu')).dy,
      lessThan(tester.getTopLeft(find.text('the gate')).dy),
    );
  });

  testWidgets('tapping it opens the Menu, over the screen behind it', (
    tester,
  ) async {
    final rig = Rig(storedSession(signedIn));
    await pumpShell(tester, rig, const Text('the gate'));

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    expect(find.byType(MenuScreen), findsOneWidget);
  });

  testWidgets(
    'once the gate has reported one, the shift detail is one tap away, beside the Menu',
    (tester) async {
      final rig = Rig(storedSession(signedIn));
      await pumpShell(tester, rig, const Text('the gate'));
      // The instance the pumped tree is actually using — not a fresh boot, which would build a
      // second `AppServices` whose `activeShift` nobody below `TillShell` is listening to.
      final services = AppScope.of(tester.element(find.byType(TillShell)));
      services.activeShift.value = shiftForDetail;
      await tester.pump();

      expect(
        tester.getCenter(find.text('Detail shift')).dy,
        tester.getCenter(find.text('Menu')).dy,
      );

      await tester.tap(find.text('Detail shift'));
      await tester.pumpAndSettle();

      expect(find.byType(ShiftScreen), findsOneWidget);
    },
  );

  testWidgets('signing out leaves the Menu and lands on the login screen', (
    tester,
  ) async {
    // Reported from a tablet: signing out did log the cashier out — the session was cleared, and
    // the app knew it — but the screen stayed on the Menu.
    //
    // The Menu is a pushed route, so the gate rebuilds *underneath* it: `home` becomes the login
    // screen while the Menu keeps covering it. The gate cannot fix this by itself, because it has
    // no idea a route is sitting on top of it.
    final rig = Rig(storedSession(signedIn));
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PosApp(
        boot: () => rig.bootWith(http: MenuHttp()),
        language: rig.language,
        theme: rig.theme,
        screens: (
          pairing: (_) => const Text('pairing'),
          login: (_) => const Text('the login screen'),
          till: (_) => TillShell(child: const Text('the gate')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    // Below the fold on an 800 dp tablet since the printer card joined the Menu.
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Keluar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ya, keluar'));
    await tester.pumpAndSettle();

    // The cashier has to be shown the way back in, not the screen they just left.
    expect(find.text('the login screen'), findsOneWidget);
    expect(find.byType(MenuScreen), findsNothing);
  });

  testWidgets('a rotated token does not close the Menu', (tester) async {
    // The transport rewrites the session whenever the server hands back a new token
    // (`X-Session-Token`). That is a session change like any other, and a screen that closed on
    // every change would shut itself mid-shift.
    final rig = Rig(storedSession(signedIn));
    await pumpShell(tester, rig, const Text('the gate'));
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    final session = await rig.ready();
    await session.session.save(signedIn.copyWith(sessionToken: 'tok_rotated'));
    await tester.pumpAndSettle();

    expect(find.byType(MenuScreen), findsOneWidget);
  });
}
