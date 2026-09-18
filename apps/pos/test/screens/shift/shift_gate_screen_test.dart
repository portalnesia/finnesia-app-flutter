/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/screens/shift/shift_gate_screen.dart';

import '../../support/boot_rig.dart';
import '../../support/routed_http.dart';

// S4. Run inside the real `PosApp`, so the gate that sends a signed-in cashier here is the one
// under test too. The rule that decides which panel shows (`resolveShiftGate`) is tested in
// `pn_pos`; what is tested here is that each answer of it becomes the right screen, and that
// every control on it does what it says.

Map<String, Object?> shiftBody({
  String id = 's1',
  String cashierId = 'user_1',
  String? cashierName,
  String openedAt = '2026-09-20T01:00:00Z',
}) => {
  'id': id,
  'number': 'SH-0001',
  'cashier_id': cashierId,
  'outlet_id': 'out_1',
  'opened_at': openedAt,
  'opening_cash': 150000,
  'total_sales': 0,
  'total_transactions': 0,
  if (cashierName != null) 'cashier': {'id': cashierId, 'name': cashierName},
};

/// A paired device with Budi signed in: what the gate sends to the till.
final signedIn = paired.copyWith(
  user: const SessionUser(id: 'user_1', name: 'Budi'),
);

/// The two reads the gate makes when it opens.
void backend(
  RoutedHttp http, {
  Map<String, Object?>? shift,
  bool requireShift = true,
}) {
  http.respond(activePath, ok(shift));
  http.respond(settingsPath, ok({'require_shift': requireShift}));
}

Widget appWith(Rig rig, RoutedHttp http) => PosApp(
  boot: () => rig.bootWith(http: http),
  language: rig.language,
  theme: rig.theme,
  screens: (
    pairing: (_) => const Text('pairing'),
    login: (_) => const Text('login'),
    till: (_) => ShiftGateScreen(till: (_, _, _) => const Text('the till')),
  ),
);

Rig signedInRig() => Rig(storedSession(signedIn));

void useSize(WidgetTester tester, Size size, double textScale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> pumpGate(
  WidgetTester tester,
  Rig rig,
  RoutedHttp http, {
  Size size = const Size(1280, 800),
  double textScale = 1,
}) async {
  useSize(tester, size, textScale);
  await tester.pumpWidget(appWith(rig, http));
  await tester.pumpAndSettle();
}

Finder get openButton => find.widgetWithText(FilledButton, 'Buka shift');

void main() {
  group('while it finds out', () {
    testWidgets('says it is loading, and shows no till yet', (tester) async {
      final http = RoutedHttp()..hold(activePath);
      http.respond(settingsPath, ok({'require_shift': true}));

      useSize(tester, const Size(1280, 800), 1);
      await tester.pumpWidget(appWith(signedInRig(), http));
      await tester.pump();
      await tester.pump();

      expect(find.text('Memuat…'), findsOneWidget);
      expect(find.text('the till'), findsNothing);

      // Let the answer land so no request outlives the test.
      http.release(activePath, ok(null));
      await tester.pump();
      await tester.pump();
    });

    testWidgets('says it could not read, and reads again on Coba lagi', (
      tester,
    ) async {
      final http = RoutedHttp();
      // A server that refused explains itself, so the screen quotes it — the same rule the Menu
      // has always followed. The gate's own "check the connection" wording is for a failure with
      // nobody to speak for it, which the next test covers.
      http.respond(activePath, refused(500, 'boom'));
      http.respond(settingsPath, ok({'require_shift': false}));

      await pumpGate(tester, signedInRig(), http);

      // Not "no shift is open": that would offer to open one the server may already have.
      expect(find.text('boom'), findsOneWidget);
      expect(find.text('the till'), findsNothing);

      backend(http, requireShift: false);
      await tester.tap(find.widgetWithText(FilledButton, 'Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text('the till'), findsOneWidget);
    });

    testWidgets('falls back to its own wording when nobody answered', (
      tester,
    ) async {
      final http = RoutedHttp();
      http.fail(activePath);
      http.respond(settingsPath, ok({'require_shift': false}));

      await pumpGate(tester, signedInRig(), http);

      // A dropped connection has no speaker, so "check the connection" is the only advice that
      // fits — and it is the sentence the gate already owned.
      expect(find.textContaining('Belum bisa membaca'), findsOneWidget);
      expect(find.text('the till'), findsNothing);
    });

    // The backend refuses every POS route with 402 SUBSCRIPTION_EXPIRED once the company's
    // subscription ends (`finnesia-monorepo` `middleware/tenant.go`), and it sends the reason
    // translated into the cashier's language. The gate reads the shift and the settings in
    // parallel, so both reads are refused and the gate is showing its failed state.
    //
    // "Check the connection and try again" is the wrong advice here: retrying cannot work, and
    // it sends a cashier to check a router for a problem only the owner can fix. The Menu
    // already shows the server's own sentence for a failed read (`_failedText`), so this is the
    // gate agreeing with its sibling, not a new behaviour.
    testWidgets('shows the reason the server gave, not a connection hint', (
      tester,
    ) async {
      final http = RoutedHttp();
      const reason =
          'Masa berlaku langganan untuk perusahaan ini telah berakhir. '
          'Silakan perbarui langganan Anda';
      http.respond(activePath, refused(402, reason));
      http.respond(settingsPath, refused(402, reason));

      await pumpGate(tester, signedInRig(), http);

      expect(find.text(reason), findsOneWidget);
      expect(find.textContaining('Periksa koneksi'), findsNothing);
      expect(find.text('the till'), findsNothing);
    });
  });

  group('when a shift is required', () {
    testWidgets('asks for the cash in the drawer, starting at nothing', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);

      await pumpGate(tester, signedInRig(), http);

      expect(find.text('Buka shift dulu'), findsOneWidget);
      expect(find.text('Rp 0'), findsOneWidget);
      expect(openButton, findsOneWidget);
      expect(find.text('the till'), findsNothing);
    });

    // Written after the panel, not before it: these had no RED of their own.
    group('the amount', () {
      Future<void> typed(WidgetTester tester, List<String> keys) async {
        for (final key in keys) {
          await tester.tap(find.widgetWithText(OutlinedButton, key).first);
        }
        await tester.pump();
      }

      testWidgets('follows the keypad, in thousands', (tester) async {
        final http = RoutedHttp();
        backend(http);
        await pumpGate(tester, signedInRig(), http);

        await typed(tester, ['1', '5', '00']);

        expect(find.text('Rp 1.500'), findsOneWidget);
      });

      testWidgets('drops the last digit on delete', (tester) async {
        final http = RoutedHttp();
        backend(http);
        await pumpGate(tester, signedInRig(), http);
        await typed(tester, ['1', '5']);

        await tester.tap(find.bySemanticsLabel('Hapus angka'));
        await tester.pump();

        expect(find.text('Rp 1'), findsOneWidget);
      });

      testWidgets('ignores zeros in front of nothing', (tester) async {
        final http = RoutedHttp();
        backend(http);
        await pumpGate(tester, signedInRig(), http);

        await typed(tester, ['0', '00', '7']);

        expect(find.text('Rp 7'), findsOneWidget);
      });

      testWidgets('stops at twelve digits, past which it is a slip', (
        tester,
      ) async {
        final http = RoutedHttp();
        backend(http);
        await pumpGate(tester, signedInRig(), http);

        await typed(tester, List.filled(13, '9'));

        expect(find.text('Rp 999.999.999.999'), findsOneWidget);
      });

      testWidgets('takes digits from a physical keyboard too', (tester) async {
        final http = RoutedHttp();
        backend(http);
        await pumpGate(tester, signedInRig(), http);

        await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
        await tester.sendKeyEvent(LogicalKeyboardKey.numpad2);
        await tester.pump();

        expect(find.text('Rp 42'), findsOneWidget);
      });
    });

    testWidgets('opens the shift with that amount, and the till follows', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      await pumpGate(tester, signedInRig(), http);
      await tester.tap(find.widgetWithText(OutlinedButton, '5').first);
      await tester.tap(find.widgetWithText(OutlinedButton, '00').first);
      await tester.pump();

      http.respond(openPath, ok(shiftBody()));
      backend(http, shift: shiftBody());
      await tester.tap(openButton);
      await tester.pumpAndSettle();

      final sent = http.calls.singleWhere((c) => c.path == openPath);
      expect(jsonDecode(sent.body!), {
        'outlet_id': 'out_1',
        'opening_cash': 500,
      });
      // The cashier just opened it, so there is no "continue this shift?" to answer.
      expect(find.text('the till'), findsOneWidget);
    });

    group('when it does not open', () {
      testWidgets('says what the server said, and stays on the panel', (
        tester,
      ) async {
        final http = RoutedHttp();
        backend(http);
        await pumpGate(tester, signedInRig(), http);

        http.respond(
          openPath,
          refused(409, 'Shift sudah terbuka di outlet ini'),
        );
        await tester.tap(openButton);
        await tester.pumpAndSettle();

        expect(find.text('Shift sudah terbuka di outlet ini'), findsOneWidget);
        expect(find.text('Buka shift dulu'), findsOneWidget);
        expect(find.text('the till'), findsNothing);
        final data = tester
            .getSemantics(find.text('Shift sudah terbuka di outlet ini'))
            .getSemanticsData();
        expect(data.flagsCollection.isLiveRegion, isTrue);
      });

      testWidgets('says there was no answer, in words of its own', (
        tester,
      ) async {
        final http = RoutedHttp();
        backend(http);
        await pumpGate(tester, signedInRig(), http);

        http.fail(openPath);
        await tester.tap(openButton);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Belum bisa menghubungi server. Periksa koneksi lalu coba lagi.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('takes the message away when the cashier tries again', (
        tester,
      ) async {
        final http = RoutedHttp();
        backend(http);
        await pumpGate(tester, signedInRig(), http);
        http.respond(
          openPath,
          refused(409, 'Shift sudah terbuka di outlet ini'),
        );
        await tester.tap(openButton);
        await tester.pumpAndSettle();

        http.respond(openPath, ok(shiftBody()));
        backend(http, shift: shiftBody());
        await tester.tap(openButton);
        await tester.pumpAndSettle();

        expect(find.text('Shift sudah terbuka di outlet ini'), findsNothing);
        expect(find.text('the till'), findsOneWidget);
      });
    });

    testWidgets('says it is opening, and cannot be tapped twice', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      await pumpGate(tester, signedInRig(), http);

      http.hold(openPath);
      await tester.tap(openButton);
      await tester.pump();
      await tester.pump();

      expect(find.text('Membuka shift…'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Membuka shift…'),
      );
      expect(button.onPressed, isNull);

      backend(http, shift: shiftBody());
      http.release(openPath, ok(shiftBody()));
      await tester.pumpAndSettle();
      expect(find.text('the till'), findsOneWidget);
    });
  });

  group('when a shift is already open', () {
    // "Now", so the shift was opened today whatever day the tests run on.
    String today() => DateTime.now().toUtc().toIso8601String();

    testWidgets('shows which shift it is before the till can be used', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http, shift: shiftBody(openedAt: today()));

      await pumpGate(tester, signedInRig(), http);

      expect(find.text('Shift masih terbuka'), findsOneWidget);
      expect(find.text('SH-0001'), findsOneWidget);
      expect(find.text('Rp 150.000'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Lanjutkan shift SH-0001'),
        findsOneWidget,
      );
      expect(find.text('the till'), findsNothing);
    });

    testWidgets('does not name the cashier: it is the one reading', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(
        http,
        shift: shiftBody(openedAt: today(), cashierName: 'Budi'),
      );

      await pumpGate(tester, signedInRig(), http);

      expect(find.text('Kasir'), findsNothing);
    });

    testWidgets('says so when it was opened on an earlier day', (tester) async {
      final http = RoutedHttp();
      backend(http, shift: shiftBody(openedAt: '2026-01-05T01:00:00Z'));

      await pumpGate(tester, signedInRig(), http);

      // The wording was shortened on 2026-09-20 (owner): "dibuka pada hari sebelumnya" is the
      // panel's own title and the date is already a row in it, so the sentence repeated both.
      // The distinction it carried is kept — a shift from an earlier day is told to check the
      // figures — and this is what says so.
      expect(find.textContaining('Periksa dulu angka'), findsOneWidget);
    });

    testWidgets('is not called old when it was opened today', (tester) async {
      final http = RoutedHttp();
      backend(http, shift: shiftBody(openedAt: today()));

      await pumpGate(tester, signedInRig(), http);

      expect(find.textContaining('Periksa dulu angka'), findsNothing);
    });

    testWidgets('continuing it opens the till', (tester) async {
      final http = RoutedHttp();
      backend(http, shift: shiftBody(openedAt: today()));
      await pumpGate(tester, signedInRig(), http);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Lanjutkan shift SH-0001'),
      );
      await tester.pumpAndSettle();

      expect(find.text('the till'), findsOneWidget);
      // Nothing was sent: continuing is the cashier's decision, not a request.
      expect(http.calls, hasLength(2));
    });
  });

  group('when another cashier holds the shift', () {
    testWidgets('says whose it is, and offers no way to sell into it', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(
        http,
        shift: shiftBody(cashierId: 'user_9', cashierName: 'Andi'),
      );

      await pumpGate(tester, signedInRig(), http);

      expect(find.text('Shift dipegang kasir lain'), findsOneWidget);
      expect(find.textContaining('SH-0001 dibuka oleh Andi'), findsOneWidget);
      expect(find.text('Kasir'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Lanjutkan shift SH-0001'),
        findsNothing,
      );
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('the till'), findsNothing);
    });

    testWidgets('does not print an empty name when the server sent none', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http, shift: shiftBody(cashierId: 'user_9'));

      await pumpGate(tester, signedInRig(), http);

      expect(find.textContaining('dibuka oleh kasir lain'), findsOneWidget);
    });
  });

  group('the layout', () {
    testWidgets('has main buttons big enough to hit', (tester) async {
      final http = RoutedHttp();
      backend(http);
      await pumpGate(tester, signedInRig(), http);

      expect(
        tester.getSize(openButton).height,
        greaterThanOrEqualTo(PnTouch.primary),
      );
    });

    const shapes = {
      '360 dp phone': Size(360, 800),
      '600 dp tablet': Size(600, 960),
      '800 dp tablet, portrait': Size(800, 1280),
      '1024 dp tablet': Size(1024, 768),
      '1280 dp tablet, landscape': Size(1280, 800),
    };
    // What each panel needs the backend to say, and something on it that must be showing.
    final panels = <String, ({Map<String, Object?>? shift, String shows})>{
      'the open form': (shift: null, shows: 'Buka shift dulu'),
      'a shift of the cashier': (
        shift: shiftBody(openedAt: '2026-01-05T01:00:00Z'),
        shows: 'Shift masih terbuka',
      ),
      'a shift of another': (
        shift: shiftBody(cashierId: 'user_9', cashierName: 'Andi'),
        shows: 'Shift dipegang kasir lain',
      ),
    };
    for (final MapEntry(key: panel, value: config) in panels.entries) {
      for (final MapEntry(key: name, value: size) in shapes.entries) {
        for (final scale in [1.0, 1.3]) {
          for (final brightness in Brightness.values) {
            testWidgets(
              '$panel fits a $name at text ${scale}x in the ${brightness.name} theme',
              (tester) async {
                final rig = signedInRig();
                await rig.theme.select(
                  brightness == Brightness.dark
                      ? ThemeMode.dark
                      : ThemeMode.light,
                );
                final http = RoutedHttp();
                backend(http, shift: config.shift);

                await pumpGate(tester, rig, http, size: size, textScale: scale);

                expect(tester.takeException(), isNull);
                expect(find.text(config.shows), findsOneWidget);
              },
            );
          }
        }
      }
    }
  });

  group('when the shift is closed from inside the app', () {
    String today() => DateTime.now().toUtc().toIso8601String();

    testWidgets('reads the shift again, and the till gives way to the open '
        'form', (tester) async {
      final http = RoutedHttp();
      backend(http, shift: shiftBody(openedAt: today()));
      await pumpGate(tester, signedInRig(), http);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Lanjutkan shift SH-0001'),
      );
      await tester.pumpAndSettle();
      expect(find.text('the till'), findsOneWidget);

      // What the close screen announces once the server has closed the drawer.
      backend(http, shift: null);
      AppScope.of(tester.element(find.text('the till'))).shiftClosed.value++;
      await tester.pumpAndSettle();

      expect(find.text('the till'), findsNothing);
      expect(find.text('Buka shift dulu'), findsOneWidget);
    });
  });
}
