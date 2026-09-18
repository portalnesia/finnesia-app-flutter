/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/environment.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/app/finnesia_logo.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/native/scanner/scanner_port.dart';
import 'package:pos/preferences/app_preferences.dart';
import 'package:pos/screens/pairing/pairing_screen.dart';

import '../../support/boot_rig.dart';

// S2. The screen is run inside the real `PosApp`, so what is tested is what the cashier gets:
// the boot, the gate deciding a device with no session belongs here, the theme and the language.

Widget _elsewhere(BuildContext _) => const Text('elsewhere');

PosApp appWith(Rig rig, Future<BootResult> Function() boot) => PosApp(
  boot: boot,
  language: rig.language,
  theme: rig.theme,
  screens: (
    pairing: (_) => const PairingScreen(),
    login: _elsewhere,
    till: _elsewhere,
  ),
);

void useSize(WidgetTester tester, Size size, double textScale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> pumpScreen(
  WidgetTester tester,
  Rig rig, {
  Size size = const Size(1280, 800),
  double textScale = 1,
}) async {
  useSize(tester, size, textScale);
  await tester.pumpWidget(appWith(rig, rig.boot));
  await tester.pumpAndSettle();
}

Finder get codeField => find.byType(TextField).last;
Finder get nameField => find.byType(TextField).first;
Finder get submit => find.byType(FilledButton);

/// A [PublicHttpPort] that answers when the test says so, to look at the screen while a
/// request is out.
class HeldHttp implements PublicHttpPort {
  final completer = Completer<TransportResponse>();
  int calls = 0;

  @override
  Future<TransportResponse> send(String baseUrl, TransportRequest request) {
    calls++;
    return completer.future;
  }
}

void main() {
  group('what the cashier sees', () {
    testWidgets('is the logo, what to do, and the two fields', (tester) async {
      await pumpScreen(tester, Rig());

      expect(find.byType(FinnesiaLogo), findsOneWidget);
      expect(find.text('Pasangkan tablet ini'), findsOneWidget);
      expect(
        find.text(
          'Masukkan kode dari dashboard Finnesia untuk menghubungkan tablet ini ke outlet Anda.',
        ),
        findsOneWidget,
      );
      expect(find.text('Nama tablet'), findsOneWidget);
      expect(find.text('Kode pairing'), findsWidgets);
      expect(find.widgetWithText(FilledButton, 'Pasangkan'), findsOneWidget);
    });

    testWidgets('says how the fields are used', (tester) async {
      await pumpScreen(tester, Rig());

      expect(
        find.text('Tampil di dashboard agar setiap tablet mudah dikenali.'),
        findsOneWidget,
      );
      // "menu Outlet": the code is generated from the activate button on the dashboard's
      // Outlets page (`apps/web/src/pages/outlets-page.tsx`), and the dashboard's own copy says
      // "di menu Outlet". A hint that sends the cashier to a menu that does not exist is worse
      // than no hint.
      expect(
        find.text('Kode ada di dashboard Finnesia, menu Outlet.'),
        findsOneWidget,
      );
    });

    testWidgets('speaks English when the cashier chose English', (
      tester,
    ) async {
      final rig = Rig();
      await rig.language.select(AppLanguage.en);

      await pumpScreen(tester, rig);

      expect(find.text('Pair this tablet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Pair'), findsOneWidget);
    });
  });

  group('the language, before there is a menu to pick it in', () {
    testWidgets('can be changed here, and applies at once', (tester) async {
      final rig = Rig();
      await pumpScreen(tester, rig);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('Pair this tablet'), findsOneWidget);
      expect(rig.language.value, AppLanguage.en);
    });

    testWidgets('can be changed back', (tester) async {
      final rig = Rig();
      await rig.language.select(AppLanguage.en);
      await pumpScreen(tester, rig);

      await tester.tap(find.text('Indonesia'));
      await tester.pumpAndSettle();

      expect(find.text('Pasangkan tablet ini'), findsOneWidget);
    });
  });

  group('typing', () {
    testWidgets('puts the code in capitals in its cells', (tester) async {
      await pumpScreen(tester, Rig());

      await tester.enterText(codeField, 'ab3-k7m');
      await tester.pump();

      for (final c in ['A', 'B', '3', 'K', '7', 'M']) {
        expect(find.text(c), findsOneWidget, reason: c);
      }
    });

    testWidgets('does not let a seventh character in', (tester) async {
      await pumpScreen(tester, Rig());

      await tester.enterText(codeField, 'AB3K7MX');
      await tester.pump();

      expect(find.text('X'), findsNothing);
    });
  });

  group('pairing', () {
    testWidgets('sends the name and the code, and the gate moves on', (
      tester,
    ) async {
      final rig = Rig()..http.respond(activatedResponse());
      await pumpScreen(tester, rig);

      await tester.enterText(nameField, 'Kasir Depan');
      await tester.enterText(codeField, 'ab3k7m');
      await tester.tap(submit);
      await tester.pumpAndSettle();

      final body = jsonDecode(
        rig.http.calls.single.request.body!,
      ) as Map<String, dynamic>;
      expect(body['device_name'], 'Kasir Depan');
      expect(body['code'], 'AB3K7M');
      expect(find.text('elsewhere'), findsOneWidget);
    });

    testWidgets('sends when the keyboard says Done, too', (tester) async {
      final rig = Rig()..http.respond(activatedResponse());
      await pumpScreen(tester, rig);
      await tester.enterText(codeField, 'AB3K7M');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(rig.http.calls, hasLength(1));
    });

    testWidgets('says it is pairing, and cannot be tapped again, meanwhile', (
      tester,
    ) async {
      final rig = Rig();
      final held = HeldHttp();
      useSize(tester, const Size(1280, 800), 1);
      await tester.pumpWidget(appWith(rig, () => rig.bootWith(http: held)));
      await tester.pumpAndSettle();
      await tester.enterText(codeField, 'AB3K7M');

      await tester.tap(submit);
      await tester.pump();
      await tester.tap(submit, warnIfMissed: false);
      await tester.pump();

      expect(find.text('Memasangkan…'), findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(held.calls, 1);
      held.completer.complete(activatedResponse());
      await tester.pumpAndSettle();
    });
  });

  group('scanning the QR from the dashboard', () {
    Finder scanButton() => find.widgetWithText(OutlinedButton, 'Pindai QR');

    Future<void> openCamera(WidgetTester tester) async {
      await tester.tap(scanButton());
      await tester.pumpAndSettle();
    }

    testWidgets('is offered next to the code, and opens the camera', (
      tester,
    ) async {
      final rig = Rig();
      await pumpScreen(tester, rig);
      expect(rig.scanner.isShowing, isFalse);

      await openCamera(tester);

      expect(rig.scanner.isShowing, isTrue);
      expect(find.text('Pindai QR pairing'), findsOneWidget);
      expect(
        find.text('Arahkan kamera ke QR di dashboard Finnesia.'),
        findsOneWidget,
      );
    });

    testWidgets('is not offered where the platform has no scanner', (
      tester,
    ) async {
      final rig = Rig();
      rig.scanner.isAvailable = false;

      await pumpScreen(tester, rig);

      expect(scanButton(), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('pairs with the code it reads, and puts the camera away', (
      tester,
    ) async {
      final rig = Rig()..http.respond(activatedResponse());
      await pumpScreen(tester, rig);
      await openCamera(tester);

      rig.scanner.read('ab3k7m');
      await tester.pumpAndSettle();

      final body = jsonDecode(
        rig.http.calls.single.request.body!,
      ) as Map<String, dynamic>;
      expect(body['code'], 'AB3K7M');
      expect(rig.scanner.isShowing, isFalse);
      expect(find.text('elsewhere'), findsOneWidget);
    });

    testWidgets('closes the camera at once, not when the request is done', (
      tester,
    ) async {
      final rig = Rig();
      final held = HeldHttp();
      useSize(tester, const Size(1280, 800), 1);
      await tester.pumpWidget(appWith(rig, () => rig.bootWith(http: held)));
      await tester.pumpAndSettle();
      await openCamera(tester);

      rig.scanner.read('AB3K7M');
      // `pump`, not `pumpAndSettle`: the spinner of a request that is out never settles.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(rig.scanner.isShowing, isFalse);
      expect(find.text('Memasangkan…'), findsOneWidget);
      held.completer.complete(activatedResponse());
      await tester.pumpAndSettle();
    });

    testWidgets('cannot be started while a request is out', (tester) async {
      final rig = Rig();
      final held = HeldHttp();
      useSize(tester, const Size(1280, 800), 1);
      await tester.pumpWidget(appWith(rig, () => rig.bootWith(http: held)));
      await tester.pumpAndSettle();
      await tester.enterText(codeField, 'AB3K7M');
      await tester.tap(submit);
      await tester.pump();

      expect(
        tester
            .widget<OutlinedButton>(find.byType(OutlinedButton).last)
            .onPressed,
        isNull,
      );
      held.completer.complete(activatedResponse());
      await tester.pumpAndSettle();
    });

    testWidgets('keeps looking when the QR is not a pairing code', (
      tester,
    ) async {
      final rig = Rig();
      await pumpScreen(tester, rig);
      await openCamera(tester);

      rig.scanner.read('https://example.com/menu');
      await tester.pumpAndSettle();

      expect(rig.scanner.isShowing, isTrue);
      expect(rig.http.calls, isEmpty);
    });

    testWidgets('says the camera is not allowed, and what to do', (
      tester,
    ) async {
      final rig = Rig();
      await pumpScreen(tester, rig);
      await openCamera(tester);

      rig.scanner.fail(ScannerFailure.permissionDenied);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Kamera belum diizinkan. Izinkan akses kamera untuk aplikasi ini di Pengaturan, atau ketik kodenya.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('says the camera cannot be used, when it cannot', (
      tester,
    ) async {
      final rig = Rig();
      await pumpScreen(tester, rig);
      await openCamera(tester);

      rig.scanner.fail(ScannerFailure.unavailable);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Kamera tidak bisa dipakai. Ketik kode pairing secara manual.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('can be cancelled, and sends nothing', (tester) async {
      final rig = Rig();
      await pumpScreen(tester, rig);
      await openCamera(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Batal'));
      await tester.pumpAndSettle();

      expect(rig.scanner.isShowing, isFalse);
      expect(rig.http.calls, isEmpty);
    });

    testWidgets('speaks English when the cashier chose English', (
      tester,
    ) async {
      final rig = Rig();
      await rig.language.select(AppLanguage.en);
      await pumpScreen(tester, rig);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Scan QR'));
      await tester.pumpAndSettle();

      expect(find.text('Scan pairing QR'), findsOneWidget);
    });
  });

  group('when pairing does not work', () {
    Future<void> tryWith(WidgetTester tester, Rig rig, String code) async {
      await pumpScreen(tester, rig);
      await tester.enterText(codeField, code);
      await tester.tap(submit);
      await tester.pumpAndSettle();
    }

    testWidgets('says a short code cannot be a code, and sends nothing', (
      tester,
    ) async {
      final rig = Rig();
      await tryWith(tester, rig, 'AB3');

      expect(
        find.text('Kode terdiri dari 6 huruf atau angka.'),
        findsOneWidget,
      );
      expect(rig.http.calls, isEmpty);
    });

    testWidgets('says the server did not accept the code', (tester) async {
      final rig = Rig()
        ..http.respond(TransportResponse(status: 401, body: '{}'));
      await tryWith(tester, rig, 'AB3K7M');

      expect(
        find.text(
          'Kode ini tidak dikenali, sudah dipakai, atau sudah kedaluwarsa. Buat kode baru di dashboard.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('says the server could not be reached', (tester) async {
      final rig = Rig()..http.fail(TransportException('down'));
      await tryWith(tester, rig, 'AB3K7M');

      expect(
        find.text(
          'Tidak bisa terhubung ke server. Periksa koneksi internet, lalu coba lagi.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('says the device storage failed', (tester) async {
      final rig = Rig();
      await pumpScreen(tester, rig);
      rig.store.failNext(StoreException('the value could not be read'));
      await tester.enterText(codeField, 'AB3K7M');
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(
        find.text('Data tablet belum bisa disimpan. Coba lagi.'),
        findsOneWidget,
      );
    });

    // The only failure whose fix is on the dashboard rather than on this screen. Saying
    // "the code did not work" would send the cashier back to ask for another code that cannot
    // help, so the message has to name the real problem.
    testWidgets('names the outlet limit, with the number the server sent', (
      tester,
    ) async {
      final rig = Rig()
        ..http.respond(
          TransportResponse(
            status: 422,
            headers: const {'Content-Type': 'application/json'},
            body:
                '{"data":null,"error":{"code":720,'
                '"key":"pos_device_limit_reached","params":{"limit":10}}}',
          ),
        );
      await tryWith(tester, rig, 'AB3K7M');

      expect(
        find.text(
          'Outlet ini sudah mencapai batas 10 tablet kasir. '
          'Hapus salah satu tablet di dashboard, lalu coba lagi.',
        ),
        findsOneWidget,
      );
    });

    // The number is optional, so its absence must not print a placeholder or a null.
    testWidgets('names the outlet limit without a number when none was sent', (
      tester,
    ) async {
      final rig = Rig()
        ..http.respond(
          TransportResponse(
            status: 422,
            headers: const {'Content-Type': 'application/json'},
            body:
                '{"data":null,"error":{"code":720,'
                '"key":"pos_device_limit_reached"}}',
          ),
        );
      await tryWith(tester, rig, 'AB3K7M');

      expect(
        find.text(
          'Outlet ini sudah mencapai batas tablet kasir. '
          'Hapus salah satu tablet di dashboard, lalu coba lagi.',
        ),
        findsOneWidget,
      );
    });

    // 422 with code 720 is also a duplicate fingerprint. Claiming the outlet is full would send
    // the cashier to the dashboard to delete a tablet for nothing.
    testWidgets('does not claim the outlet is full for a 422 without the key', (
      tester,
    ) async {
      final rig = Rig()
        ..http.respond(
          TransportResponse(
            status: 422,
            headers: const {'Content-Type': 'application/json'},
            body:
                '{"data":null,"error":{"code":720,"description":"duplicate"}}',
          ),
        );
      await tryWith(tester, rig, 'AB3K7M');

      expect(find.textContaining('batas'), findsNothing);
      expect(
        find.text(
          'Tidak bisa terhubung ke server. Periksa koneksi internet, lalu coba lagi.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('lets the cashier try again with the same button', (
      tester,
    ) async {
      final rig = Rig()..http.fail(TransportException('down'));
      await tryWith(tester, rig, 'AB3K7M');

      rig.http.respond(activatedResponse());
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('elsewhere'), findsOneWidget);
    });

    testWidgets('takes the message away as soon as the code is edited', (
      tester,
    ) async {
      final rig = Rig()
        ..http.respond(TransportResponse(status: 401, body: '{}'));
      await tryWith(tester, rig, 'AB3K7M');

      await tester.enterText(codeField, 'AB3K7');
      await tester.pump();

      expect(find.textContaining('tidak dikenali'), findsNothing);
    });

    testWidgets('is announced to a screen reader when it appears', (
      tester,
    ) async {
      final rig = Rig()
        ..http.respond(TransportResponse(status: 401, body: '{}'));
      await tryWith(tester, rig, 'AB3K7M');

      final data = tester
          .getSemantics(find.textContaining('tidak dikenali'))
          .getSemanticsData();
      expect(data.flagsCollection.isLiveRegion, isTrue);
    });
  });

  group('the endpoint, in a debug build', () {
    testWidgets('can be picked before pairing, and the host follows', (
      tester,
    ) async {
      await pumpScreen(tester, Rig());

      expect(
        find.text(canonicalHost(EndpointEnvironment.staging)),
        findsOneWidget,
      );
      await tester.tap(find.text(EndpointEnvironment.production.name));
      await tester.pumpAndSettle();

      expect(find.text(productionHost), findsOneWidget);
    });

    testWidgets('is the one the pairing request goes to', (tester) async {
      final rig = Rig()..http.respond(activatedResponse());
      await pumpScreen(tester, rig);
      await tester.tap(find.text(EndpointEnvironment.production.name));
      await tester.enterText(codeField, 'AB3K7M');
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(rig.http.calls.single.baseUrl, productionHost);
    });
  });

  group('the layout', () {
    testWidgets('puts the logo beside the form on a wide screen', (
      tester,
    ) async {
      await pumpScreen(tester, Rig(), size: const Size(1280, 800));

      final logo = tester.getRect(find.byType(FinnesiaLogo));
      final field = tester.getRect(codeField);
      expect(logo.right, lessThan(field.left));
    });

    testWidgets('puts the logo above the form on a narrow one', (tester) async {
      await pumpScreen(tester, Rig(), size: const Size(800, 1280));

      final logo = tester.getRect(find.byType(FinnesiaLogo));
      final field = tester.getRect(codeField);
      expect(logo.bottom, lessThan(field.top));
    });

    testWidgets('has a main button big enough to hit', (tester) async {
      await pumpScreen(tester, Rig());

      expect(
        tester.getSize(submit).height,
        greaterThanOrEqualTo(PnTouch.primary),
      );
    });

    testWidgets('moves from the name to the code with Tab', (tester) async {
      await pumpScreen(tester, Rig());
      await tester.tap(nameField);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(tester.widget<TextField>(codeField).focusNode!.hasFocus, isTrue);
    });

    const shapes = {
      '360 dp phone': Size(360, 800),
      '600 dp tablet': Size(600, 960),
      '800 dp tablet, portrait': Size(800, 1280),
      '1024 dp tablet': Size(1024, 768),
      '1280 dp tablet, landscape': Size(1280, 800),
    };
    for (final MapEntry(key: name, value: size) in shapes.entries) {
      for (final scale in [1.0, 1.3]) {
        for (final brightness in Brightness.values) {
          testWidgets(
            'fits a $name at text ${scale}x in the ${brightness.name} theme, with a message showing',
            (tester) async {
              final rig = Rig()
                ..http.respond(TransportResponse(status: 401, body: '{}'));
              await rig.theme.select(
                brightness == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
              );
              await pumpScreen(tester, rig, size: size, textScale: scale);
              await tester.enterText(codeField, 'AB3K7M');
              // On a small screen at a large text size the button is below the fold, and the
              // cashier scrolls to it.
              await tester.ensureVisible(submit);
              await tester.tap(submit);
              await tester.pumpAndSettle();

              expect(tester.takeException(), isNull);
              expect(find.textContaining('tidak dikenali'), findsOneWidget);
            },
          );
        }
      }
    }
  });
}
