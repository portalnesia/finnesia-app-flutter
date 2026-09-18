/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/screens/shift/shift_history_screen.dart';
import 'package:pos/shift/shift_history_controller.dart';

import '../../support/boot_rig.dart';
import '../../support/routed_http.dart';
import 'shift_screen_test.dart'
    show
        movementBody,
        movementsPath,
        page,
        saleBody,
        salesPath,
        settingsPathRoute,
        signedIn,
        summaryBody,
        summaryPath,
        useSize;

// S16: the shifts of this outlet, newest first, and the way into any of them: the drawer that is
// open, and the ones already closed, whoever closed them. Behaviour from `pos-shifts-page.tsx`; the
// shape is this app's own (one list, a status filter, one outlet: the one pairing locked).
//
// Opening a row is the shift screen, so what that screen does with the shift (the figures, the
// report) is `shift_screen_test` and `print_shift_report_test`; what is here is that the right
// shift gets there.

const shiftsPath = '/api/v1/pos/shifts';
const kitchen = PrinterDevice(address: 'AA:BB', name: 'Dapur');

Map<String, Object?> row(
  String id, {
  String status = 'CLOSED',
  String cashierId = 'user_1',
  String cashierName = 'Budi',
  num total = 250000,
}) => {
  'id': id,
  'number': 'SH-$id',
  'cashier_id': cashierId,
  'outlet_id': 'out_1',
  'opened_at': '2026-09-20T01:00:00Z',
  'opening_cash': 100000,
  'total_sales': total,
  'total_transactions': 4,
  'status': status,
  'cashier': {'id': cashierId, 'name': cashierName},
};

Future<({Rig rig, RoutedHttp http})> pumpHistory(
  WidgetTester tester,
  RoutedHttp http, {
  Size size = const Size(1280, 800),
  double textScale = 1,
  bool paired = true,
}) async {
  useSize(tester, size, textScale);
  final rig = Rig({
    ...storedSession(signedIn),
    if (paired)
      printerKey: jsonEncode({
        'address': kitchen.address,
        'name': kitchen.name,
      }),
  });
  rig.printer = FakePrinter([kitchen]);
  await tester.pumpWidget(
    PosApp(
      boot: () => rig.bootWith(http: http),
      language: rig.language,
      theme: rig.theme,
      screens: (
        pairing: (_) => const Text('pairing'),
        login: (_) => const Text('login'),
        till: (_) => const ShiftHistoryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (rig: rig, http: http);
}

/// What opening a shift from the list reads: its figures, its movements and its sales.
void shiftBehind(RoutedHttp http, {String status = 'CLOSED'}) {
  http.respond(
    summaryPath,
    ok(
      summaryBody(
        status: status,
        counted: 275000,
        variance: 0,
        cashierId: 'someone_else',
        cashierName: 'Sari',
      ),
    ),
  );
  http.respond(
    movementsPath,
    ok([movementBody('m1', 'CASH_OUT', 5000, 'Beli galon')]),
  );
  http.respond(salesPath, page([saleBody('a')]));
  http.respond(
    settingsPathRoute,
    ok({'require_shift': true, 'show_product_sales_summary': false}),
  );
}

Finder get filterClosed => find.descendant(
  of: find.byType(SegmentedButton<ShiftHistoryFilter>),
  matching: find.text('Ditutup'),
);
Finder get filterAll => find.text('Semua');

void main() {
  group('the list', () {
    testWidgets(
      'shows each shift with its cashier, its state and what it sold',
      (tester) async {
        final http = RoutedHttp()
          ..respond(
            shiftsPath,
            page([
              row('b', status: 'OPEN', cashierName: 'Budi', total: 99000),
              row('a', cashierName: 'Sari', total: 250000),
            ]),
          );

        await pumpHistory(tester, http);

        expect(find.text('Riwayat Shift'), findsOneWidget);
        expect(find.text('SH-b'), findsOneWidget);
        expect(find.text('SH-a'), findsOneWidget);
        expect(find.textContaining('Sari'), findsOneWidget);
        expect(find.text(formatCurrency(250000)), findsOneWidget);
        expect(find.text(formatCurrency(99000)), findsOneWidget);
        // In words, not only in place: which of them is still open.
        expect(find.text('Terbuka'), findsWidgets);
      },
    );

    testWidgets('asks for the shifts of the paired outlet, a page at a time', (
      tester,
    ) async {
      final http = RoutedHttp()..respond(shiftsPath, page([row('a')]));

      await pumpHistory(tester, http);

      final asked = http.calls.single;
      expect(asked.path, contains('outlet_id=out_1'));
      expect(asked.path, contains('page_size=25'));
      expect(asked.path, isNot(contains('status=')));
    });

    testWidgets('asks for the next page when the end comes near', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(
          shiftsPath,
          page([for (var i = 0; i < 25; i++) row('s$i')], next: 'cur_2'),
        )
        ..respond(shiftsPath, page([row('last')]));

      await pumpHistory(tester, http, size: const Size(1280, 600));
      await tester.drag(find.byType(ListView), const Offset(0, -6000));
      await tester.pumpAndSettle();

      expect(http.calls, hasLength(2));
      expect(http.calls.last.path, contains('next_cursor=cur_2'));
    });

    testWidgets('says so when there are none', (tester) async {
      final http = RoutedHttp()..respond(shiftsPath, page([]));

      await pumpHistory(tester, http);

      expect(find.text('Belum ada shift.'), findsOneWidget);
    });

    testWidgets('a failed read says so, and can be tried again', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(shiftsPath, refused(500, 'Gagal'))
        ..respond(shiftsPath, page([row('a')]));

      await pumpHistory(tester, http);
      expect(find.text('Gagal'), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text('SH-a'), findsOneWidget);
    });

    // Same rule as the shift gate and the Menu: a server that refused explains itself, and its
    // sentence is the one the cashier gets. A 402 SUBSCRIPTION_EXPIRED lands here too — every POS
    // route is refused once the subscription ends — and "check the connection, then try again"
    // sends a cashier to check a router for something only the owner can fix.
    testWidgets('shows the reason the server gave, not a connection hint', (
      tester,
    ) async {
      const reason =
          'Masa berlaku langganan untuk perusahaan ini telah berakhir. '
          'Silakan perbarui langganan Anda';
      final http = RoutedHttp()..respond(shiftsPath, refused(402, reason));

      await pumpHistory(tester, http);

      expect(find.text(reason), findsOneWidget);
      expect(find.textContaining('Periksa koneksi'), findsNothing);
    });

    // A connection that dropped has nobody to speak for it, so the list's own wording is the only
    // advice that fits — and it is the sentence this screen already owned.
    testWidgets('falls back to its own wording when nobody answered', (
      tester,
    ) async {
      final http = RoutedHttp()..fail(shiftsPath);

      await pumpHistory(tester, http);

      expect(
        find.textContaining('Riwayat shift belum bisa dimuat'),
        findsOneWidget,
      );
    });
  });

  group('narrowing it', () {
    testWidgets('a status is asked of the server, and the list is replaced', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(shiftsPath, page([row('b', status: 'OPEN'), row('a')]))
        ..respond(shiftsPath, page([row('a')]));

      await pumpHistory(tester, http);
      await tester.tap(filterClosed);
      await tester.pumpAndSettle();

      expect(http.calls.last.path, contains('status=CLOSED'));
      expect(find.text('SH-b'), findsNothing);
      expect(find.text('SH-a'), findsOneWidget);
    });

    testWidgets('back to all asks for every status again', (tester) async {
      final http = RoutedHttp()
        ..respond(shiftsPath, page([row('a')]))
        ..respond(shiftsPath, page([row('a')]))
        ..respond(shiftsPath, page([row('b'), row('a')]));

      await pumpHistory(tester, http);
      await tester.tap(filterClosed);
      await tester.pumpAndSettle();
      await tester.tap(filterAll);
      await tester.pumpAndSettle();

      expect(http.calls.last.path, isNot(contains('status=')));
      expect(find.text('SH-b'), findsOneWidget);
    });
  });

  group('opening a shift', () {
    testWidgets('shows that shift, without asking which drawer is open', (
      tester,
    ) async {
      final http = RoutedHttp()..respond(shiftsPath, page([row('s1')]));
      shiftBehind(http);
      await pumpHistory(tester, http);

      await tester.tap(find.text('SH-s1'));
      await tester.pumpAndSettle();

      expect(http.count('/api/v1/pos/shifts/active'), 0);
      expect(http.count(summaryPath), greaterThan(0));
      // Its figures are on screen: the counted cash of a shift closed and counted.
      expect(find.text(formatCurrency(275000)), findsWidgets);
    });

    testWidgets('a closed shift of another cashier can be read and printed, '
        'and nothing else is offered', (tester) async {
      final backend = RoutedHttp()
        ..respond(shiftsPath, page([row('s1', cashierId: 'someone_else')]));
      shiftBehind(backend);
      final (:rig, :http) = await pumpHistory(tester, backend);

      await tester.tap(find.text('SH-s1'));
      await tester.pumpAndSettle();
      expect(find.text('Tutup shift'), findsNothing);
      expect(find.text('Catat kas masuk atau keluar'), findsNothing);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cetak Laporan'));
      await tester.pumpAndSettle();

      expect(
        String.fromCharCodes(rig.printer.written.single),
        contains('SH-0001'),
      );
      expect(find.text('Laporan terkirim ke printer'), findsOneWidget);
    });
  });

  group('the layout', () {
    testWidgets('fits a small tablet in portrait, with text at 1.3x', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(
          shiftsPath,
          page([
            row(
              'b',
              status: 'OPEN',
              cashierName: 'Nama kasir yang sangat panjang sekali',
            ),
            row('a'),
          ]),
        );

      await pumpHistory(
        tester,
        http,
        size: const Size(600, 960),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.widgetWithText(InkWell, 'SH-b').first).height,
        greaterThanOrEqualTo(PnTouch.primary),
      );
    });
  });
}
