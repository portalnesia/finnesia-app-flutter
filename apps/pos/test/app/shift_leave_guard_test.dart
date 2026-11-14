/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/app_exit_fake.dart';
import 'package:pn_types/src/native/app_exit_port.dart';
import 'package:pn_types/src/native/crash_report_fake.dart';
import 'package:pn_types/src/native/exit_notice_fake.dart';
import 'package:pn_types/src/native/exit_notice_port.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/gate.dart';
import 'package:pos/native/app_exit/active.dart';
import 'package:pos/native/crash_report/active.dart';
import 'package:pos/native/exit_notice/active.dart';
import 'package:pos/screens/shift/shift_gate_screen.dart';

import '../support/boot_rig.dart';
import '../support/routed_http.dart';

// The open-shift reminder on every way out of the app the platform tells the app about: the
// Android back press at the root, and the window close on Windows. Run inside the real `PosApp`
// with the real shift gate, so what decides the reminder is the same read the till makes. The
// rule itself (`shouldWarnOnLeave`) is tested in `pn_pos`.

Map<String, Object?> shiftBody({String cashierId = 'user_1'}) => {
  'id': 's1',
  'number': 'SH-0001',
  'cashier_id': cashierId,
  'outlet_id': 'out_1',
  'opened_at': '2026-09-20T01:00:00Z',
  'opening_cash': 150000,
  'total_sales': 0,
  'total_transactions': 0,
};

final signedIn = paired.copyWith(
  user: const SessionUser(id: 'user_1', name: 'Budi'),
);

/// What the platform is told to say on an exit the app never hears about (swipe from Recents,
/// Windows shutdown), and where a failure to tell it is reported. Fresh for every [pumpApp].
late FakeExitNotice exitNoticeHost;
late FakeCrashReport crashes;

Future<FakeAppExit> pumpApp(
  WidgetTester tester, {
  Map<String, Object?>? shift,
  bool requireShift = true,
}) async {
  final appExit = FakeAppExit();
  setAppExit(appExit);
  exitNoticeHost = FakeExitNotice();
  setExitNotice(exitNoticeHost);
  crashes = FakeCrashReport();
  setCrashReport(crashes);
  final http = RoutedHttp()
    ..respond(activePath, ok(shift))
    ..respond(settingsPath, ok({'require_shift': requireShift}));
  final rig = Rig(storedSession(signedIn));
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    PosApp(
      boot: () => rig.bootWith(http: http),
      language: rig.language,
      theme: rig.theme,
      screens: (
        pairing: (_) => const Text('pairing'),
        login: (_) => const Text('login'),
        till: (_) => ShiftGateScreen(till: (_, _, _) => const Text('the till')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return appExit;
}

Finder get reminder => find.text('Shift masih aktif');

Future<void> pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  group('Android back at the root', () {
    testWidgets('reminds the cashier holding the open shift', (tester) async {
      final appExit = await pumpApp(tester, shift: shiftBody());

      await pressBack(tester);

      expect(reminder, findsOneWidget);
      expect(find.textContaining('SH-0001'), findsWidgets);
      expect(appExit.exits, 0);
    });

    testWidgets('leaves the app on Tetap keluar', (tester) async {
      final appExit = await pumpApp(tester, shift: shiftBody());

      await pressBack(tester);
      await tester.tap(find.text('Tetap keluar'));
      await tester.pumpAndSettle();

      expect(appExit.exits, 1);
      expect(reminder, findsNothing);
    });

    testWidgets('stays on Kembali ke kasir', (tester) async {
      final appExit = await pumpApp(tester, shift: shiftBody());

      await pressBack(tester);
      await tester.tap(find.text('Kembali ke kasir'));
      await tester.pumpAndSettle();

      expect(appExit.exits, 0);
      expect(reminder, findsNothing);
      // Still at the gate: the "already open" panel the shift answered with.
      expect(find.textContaining('SH-0001'), findsWidgets);
    });

    testWidgets('says so when the platform refuses to leave', (tester) async {
      final appExit = await pumpApp(tester, shift: shiftBody());
      appExit.failNext(AppExitException('refused'));

      await pressBack(tester);
      await tester.tap(find.text('Tetap keluar'));
      await tester.pumpAndSettle();

      expect(appExit.exits, 1);
      expect(
        find.text('Aplikasi tidak bisa ditutup. Coba lagi.'),
        findsOneWidget,
      );
    });

    testWidgets('stays quiet without an open shift', (tester) async {
      await pumpApp(tester);

      await pressBack(tester);

      expect(reminder, findsNothing);
    });

    testWidgets('stays quiet when another cashier holds the shift', (
      tester,
    ) async {
      await pumpApp(tester, shift: shiftBody(cashierId: 'user_2'));

      await pressBack(tester);

      expect(reminder, findsNothing);
    });

    testWidgets('stays quiet when the company runs without shifts', (
      tester,
    ) async {
      await pumpApp(tester, shift: shiftBody(), requireShift: false);

      await pressBack(tester);

      expect(reminder, findsNothing);
    });
  });

  group('window close on desktop', () {
    testWidgets('asks first, and closes on Tetap keluar', (tester) async {
      await pumpApp(tester, shift: shiftBody());

      final response = tester.binding.handleRequestAppExit();
      await tester.pumpAndSettle();
      expect(reminder, findsOneWidget);

      await tester.tap(find.text('Tetap keluar'));
      await tester.pumpAndSettle();

      expect(await response, AppExitResponse.exit);
    });

    testWidgets('keeps the window open on Kembali ke kasir', (tester) async {
      await pumpApp(tester, shift: shiftBody());

      final response = tester.binding.handleRequestAppExit();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kembali ke kasir'));
      await tester.pumpAndSettle();

      expect(await response, AppExitResponse.cancel);
      expect(reminder, findsNothing);
    });

    testWidgets('closes straight away without an open shift', (tester) async {
      await pumpApp(tester);

      final response = tester.binding.handleRequestAppExit();
      await tester.pumpAndSettle();

      expect(reminder, findsNothing);
      expect(await response, AppExitResponse.exit);
    });
  });

  group('exits the app never hears about', () {
    const notice = ExitNotice(
      title: 'Shift masih aktif',
      body:
          'Shift SH-0001 belum ditutup. Tutup shift di akhir jam kerja agar kas laci cocok '
          'dengan laporan.',
    );

    testWidgets('tells the platform what to say while the shift is open', (
      tester,
    ) async {
      await pumpApp(tester, shift: shiftBody());

      expect(exitNoticeHost.current, notice);
    });

    testWidgets('tells it nothing without a shift to remind of', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(exitNoticeHost.current, isNull);
      expect(exitNoticeHost.changes.whereType<ExitNotice>(), isEmpty);
    });

    testWidgets('takes it back once there is nothing to remind of', (
      tester,
    ) async {
      await pumpApp(tester, shift: shiftBody());

      AppScope.of(tester.element(find.byType(Gate))).shiftLeaveReminder.value =
          null;
      await tester.pumpAndSettle();

      expect(exitNoticeHost.current, isNull);
    });

    testWidgets('reports a platform that could not be told, and carries on', (
      tester,
    ) async {
      final host = FakeExitNotice()..failNext(ExitNoticeException('no host'));
      setExitNotice(host);
      exitNoticeHost = host;
      crashes = FakeCrashReport();
      setCrashReport(crashes);
      setAppExit(FakeAppExit());
      final http = RoutedHttp()
        ..respond(activePath, ok(shiftBody()))
        ..respond(settingsPath, ok({'require_shift': true}));
      final rig = Rig(storedSession(signedIn));
      await tester.pumpWidget(
        PosApp(
          boot: () => rig.bootWith(http: http),
          language: rig.language,
          theme: rig.theme,
          screens: (
            pairing: (_) => const Text('pairing'),
            login: (_) => const Text('login'),
            till: (_) =>
                ShiftGateScreen(till: (_, _, _) => const Text('the till')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(crashes.recorded, isNotEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
