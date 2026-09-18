/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/screens/payment/done_screen.dart';

import '../../support/boot_rig.dart';
import '../../support/routed_http.dart';

// D2: the receipt, from the screen that says the sale went through. What is on paper is
// `receipt_test`; what is here is what the button needs, and what happens when it cannot.

const kitchen = PrinterDevice(address: 'AA:BB', name: 'Dapur');
const salePath = '/api/v1/pos/sales/sale_1';
const outletPath = '/api/v1/outlets/out_1';

final signedIn = paired.copyWith(
  user: const SessionUser(id: 'user_1', name: 'Budi'),
);

Map<String, Object?> saleJson({bool full = true}) => {
  'id': 'sale_1',
  'number': 'POS-0007',
  'shift_id': 's1',
  'outlet_id': 'out_1',
  'cashier_id': 'user_1',
  'transaction_date': '2026-09-20',
  'subtotal': 50000,
  'discount_amount': 0,
  'tax_amount': 0,
  'grand_total': 50000,
  'tendered_amount': 100000,
  'change_amount': 50000,
  'status': 'POSTED',
  'created_at': '2026-09-20T03:00:00Z',
  'cashier': {'id': 'user_1', 'name': 'Budi'},
  if (full) ...{
    'payments': [
      {'id': 'p1', 'method': 'CASH', 'amount': 100000},
    ],
    'invoice': {
      'items': [
        {
          'id': 'i1',
          'quantity': 2,
          'price': 25000,
          'line_subtotal': 50000,
          'line_total': 50000,
          'product': {'id': 'p', 'name': 'Kopi Susu'},
        },
      ],
    },
  },
};

POSSale sale({bool full = true}) => POSSale.fromJson(saleJson(full: full));

/// A sale the server has not confirmed yet — what the done screen shows while it is queued.
PendingSale pendingSale() => const PendingSale(
  clientRef: 'REF-1',
  companyId: 'comp_1',
  outletId: 'out_1',
  cashierId: 'user_1',
  status: PendingSaleStatus.pending,
  paidAt: '2026-09-20T03:00:00.000Z',
  createdAt: '2026-09-20T03:00:00.000Z',
  payload: POSCheckoutDTO(
    outletId: 'out_1',
    transactionDate: '2026-09-20',
    items: [
      POSCheckoutItemDTO(
        productId: 'p',
        unitId: 'u1',
        quantity: 2,
        price: 25000,
      ),
    ],
    payments: [POSTenderDTO(method: POSTenderMethod.cash, amount: 100000)],
  ),
  receipt: PendingSaleReceipt(
    subtotal: 50000,
    discountAmount: 0,
    taxAmount: 0,
    grandTotal: 50000,
    tenderedAmount: 100000,
    changeAmount: 50000,
    items: [],
  ),
);

Finder get printButton => find.widgetWithText(OutlinedButton, 'Cetak struk');

/// What the receipt reads besides the sale: the outlet name and the footer of the tenant. Read on
/// every press, so a test that presses more than once needs an answer for each.
void backend(
  RoutedHttp http, {
  bool settingsReadable = true,
  bool outletReadable = true,
  bool saleReadable = true,
}) {
  for (var i = 0; i < 4; i++) {
    if (settingsReadable) {
      http.respond(
        settingsPath,
        ok({'require_shift': true, 'receipt_footer_text': 'Terima kasih'}),
      );
    } else {
      http.fail(settingsPath);
    }
    if (outletReadable) {
      http.respond(outletPath, ok({'id': 'out_1', 'name': 'Outlet Pusat'}));
    } else {
      http.fail(outletPath);
    }
    if (saleReadable) {
      http.respond(salePath, ok(saleJson()));
    } else {
      http.fail(salePath);
    }
  }
}

Future<({Rig rig, RoutedHttp http})> pumpDone(
  WidgetTester tester, {
  POSSale? completed,
  PendingSale? pending,
  bool paired = true,
  List<PrinterDevice> nearby = const [],
  bool settingsReadable = true,
  bool outletReadable = true,
  bool saleReadable = true,
  Size size = const Size(1280, 800),
  double textScale = 1,
  VoidCallback? onNewSale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final http = RoutedHttp();
  backend(
    http,
    settingsReadable: settingsReadable,
    outletReadable: outletReadable,
    saleReadable: saleReadable,
  );
  final rig = Rig({
    ...storedSession(signedIn),
    if (paired)
      printerKey: jsonEncode({
        'address': kitchen.address,
        'name': kitchen.name,
      }),
  });
  rig.printer = FakePrinter(nearby);
  final done = pending == null ? completed ?? sale() : null;
  await tester.pumpWidget(
    PosApp(
      boot: () => rig.bootWith(http: http),
      language: rig.language,
      theme: rig.theme,
      screens: (
        pairing: (_) => const Text('pairing'),
        login: (_) => const Text('login'),
        till: (_) => DoneScreen(
          sale: done,
          pending: pending,
          onNewSale: onNewSale ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (rig: rig, http: http);
}

String paper(Rig rig) => String.fromCharCodes(rig.printer.written.single);

int asked(RoutedHttp http, String path) =>
    http.calls.where((c) => c.path.split('?').first == path).length;

void main() {
  group('printing it', () {
    testWidgets('sends the receipt to the printer that is paired', (
      tester,
    ) async {
      final (:rig, :http) = await pumpDone(tester);

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(rig.printer.connectedAddress, kitchen.address);
      final text = paper(rig);
      expect(text, contains('POS-0007'));
      expect(text, contains('Kopi Susu'));
      // The words of the shop, read for it: the name of the outlet and the footer.
      expect(text, contains('Outlet Pusat'));
      expect(text, contains('Terima kasih'));
      expect(find.text('Struk terkirim ke printer'), findsOneWidget);
    });

    testWidgets(
      'does not ask the server for a sale that already has its goods',
      (tester) async {
        final (:rig, :http) = await pumpDone(tester);

        await tester.tap(printButton);
        await tester.pumpAndSettle();

        expect(asked(http, salePath), 0);
      },
    );

    testWidgets('reads the sale first when it came without its goods', (
      tester,
    ) async {
      final (:rig, :http) = await pumpDone(
        tester,
        completed: sale(full: false),
      );

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(asked(http, salePath), 1);
      expect(paper(rig), contains('Kopi Susu'));
    });

    testWidgets('the name of the shop and the footer are optional', (
      tester,
    ) async {
      final (:rig, :http) = await pumpDone(
        tester,
        settingsReadable: false,
        outletReadable: false,
      );

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      final text = paper(rig);
      expect(text, contains('Kopi Susu'));
      expect(text, isNot(contains('Outlet Pusat')));
      expect(find.text('Struk terkirim ke printer'), findsOneWidget);
    });

    testWidgets('logs receipt_printed', (tester) async {
      final (:rig, :http) = await pumpDone(tester);

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(rig.analytics.logged.map((e) => e.$1), ['receipt_printed']);
    });

    testWidgets('logs pending_receipt_printed for a queued sale', (
      tester,
    ) async {
      final (:rig, :http) = await pumpDone(tester, pending: pendingSale());

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(rig.analytics.logged.map((e) => e.$1), [
        'pending_receipt_printed',
      ]);
    });
  });

  group('when it does not come out', () {
    testWidgets('a sale that could not be read says so, and prints nothing', (
      tester,
    ) async {
      final (:rig, :http) = await pumpDone(
        tester,
        completed: sale(full: false),
        saleReadable: false,
      );

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(find.text('Struk belum bisa dimuat. Coba lagi.'), findsOneWidget);
      expect(rig.printer.written, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the reason is said in words, and the sale is left alone', (
      tester,
    ) async {
      var newSales = 0;
      final (:rig, :http) = await pumpDone(tester, onNewSale: () => newSales++);
      rig.printer.failNext(
        PrinterOp.connect,
        PrinterException(PrinterFailure.bluetoothOff),
      );

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Bluetooth tablet sedang mati'),
        findsOneWidget,
      );
      // The change is still on screen, and so is the way on to the next customer.
      expect(find.byKey(const Key('change-amount')), findsOneWidget);
      await tester.tap(find.text('Transaksi Baru'));
      expect(newSales, 1);
    });

    testWidgets('with no printer paired it offers one, and prints once it is', (
      tester,
    ) async {
      final (:rig, :http) = await pumpDone(
        tester,
        paired: false,
        nearby: [kitchen],
      );

      await tester.tap(printButton);
      await tester.pumpAndSettle();
      expect(find.text('Sambungkan Printer'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Pindai printer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dapur'));
      await tester.pumpAndSettle();

      expect(paper(rig), contains('POS-0007'));
    });
  });

  group('the layout', () {
    testWidgets('fits a phone-sized screen at text 1.3x, with both buttons', (
      tester,
    ) async {
      await pumpDone(tester, size: const Size(360, 640), textScale: 1.3);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(printButton).height,
        greaterThanOrEqualTo(PnTouch.min),
      );
      expect(find.text('Transaksi Baru'), findsOneWidget);
    });
  });
}
