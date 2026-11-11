/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_types/src/native/print_queue_fake.dart';
import 'package:pn_types/src/native/print_queue_port.dart';
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

double pdfPageWidth(List<int> bytes) {
  final match = RegExp(
    r'/MediaBox\s*\[\s*0(?:\.0)?\s+0(?:\.0)?\s+([0-9.]+)\s+([0-9.]+)\s*\]',
  ).firstMatch(String.fromCharCodes(bytes));
  if (match == null) throw StateError('PDF page has no MediaBox');
  return double.parse(match.group(1)!);
}

int asked(RoutedHttp http, String path) =>
    http.calls.where((c) => c.path.split('?').first == path).length;

Future<void> settleAsyncPrint(
  WidgetTester tester,
  FakePrintQueuePort queue, {
  required int expectedOperations,
}) async {
  // Advance both the widget-test clock and real async time for PDF font asset reads.
  for (
    var i = 0;
    i < 200 && queue.operations.length < expectedOperations;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 10));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 10));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  const office = (
    id: 'windows-printer://office',
    name: 'Office Laser',
    isDefault: true,
    isAvailable: true,
  );
  void windowsTest(String description, WidgetTesterCallback callback) {
    testWidgets(
      description,
      callback,
      variant: const TargetPlatformVariant({TargetPlatform.windows}),
    );
  }

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
      expect(
        text,
        contains('Terima kasih\n\nFinnesia.com\nAplikasi Kasir Otomatis\n'),
      );
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

      expect(rig.analytics.logged.map((e) => e.$1), ['tenant_receipt_printed']);
    });

    testWidgets('logs pending_receipt_printed for a queued sale', (
      tester,
    ) async {
      final (:rig, :http) = await pumpDone(tester, pending: pendingSale());

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(paper(rig), contains('Finnesia.com\nAplikasi Kasir Otomatis\n'));
      expect(rig.analytics.logged.map((e) => e.$1), [
        'tenant_pending_receipt_printed',
      ]);
    });

    windowsTest(
      'first Windows print asks for a printer type and an installed queue',
      (tester) async {
        final rig = (await pumpDone(tester, paired: false)).rig;
        rig.printQueue.queues.add(office);

        await tester.tap(printButton);
        await tester.pumpAndSettle();
        expect(find.text('Pilih jenis printer'), findsOneWidget);

        await tester.tap(find.text('Printer Windows'));
        await tester.pumpAndSettle();
        expect(find.text('Pilih printer Windows'), findsOneWidget);
        await tester.tap(find.text('Office Laser'));
        await settleAsyncPrint(tester, rig.printQueue, expectedOperations: 3);

        expect(
          await readPrinterMode(rig.store, platform: TargetPlatform.windows),
          PrinterMode.windowsQueue,
        );
        expect(
          String.fromCharCodes(rig.printQueue.printed.single.bytes.take(5)),
          '%PDF-',
        );
        expect(rig.printer.operations, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    windowsTest('sends a recorded receipt PDF to the selected Windows queue', (
      tester,
    ) async {
      final (:rig, :http) = await pumpDone(tester);
      rig.printQueue.queues.add(office);
      await rememberWindowsPrinterQueue(office, rig.store);
      expect(
        await readPrinterMode(rig.store, platform: TargetPlatform.windows),
        PrinterMode.windowsQueue,
      );
      expect((await readSavedWindowsPrinterQueue(rig.store))?.id, office.id);

      await tester.tap(printButton);
      await settleAsyncPrint(tester, rig.printQueue, expectedOperations: 2);

      final visibleText = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .toList();
      expect(
        tester.takeException(),
        isNull,
        reason: 'visible text: $visibleText',
      );
      expect(
        rig.printQueue.operations,
        [PrintQueueOperation.list, PrintQueueOperation.print],
        reason:
            'BLE operations: ${rig.printer.operations}; visible: $visibleText',
      );
      final bytes = rig.printQueue.printed.single.bytes;
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(pdfPageWidth(bytes), closeTo(PdfPageFormat.roll80.width, 0.01));
      expect(rig.printQueue.printed.single.queueId, office.id);
      expect(rig.printer.operations, isEmpty);
      expect(find.text('Struk terkirim ke printer'), findsOneWidget);
      expect(asked(http, salePath), 0);
      expect(tester.takeException(), isNull);
    });

    windowsTest('sends a pending receipt PDF without reading the server sale', (
      tester,
    ) async {
      final (:rig, :http) = await pumpDone(tester, pending: pendingSale());
      rig.printQueue.queues.add(office);
      await rememberWindowsPrinterQueue(office, rig.store);

      await tester.tap(printButton);
      await settleAsyncPrint(tester, rig.printQueue, expectedOperations: 2);

      expect(
        String.fromCharCodes(rig.printQueue.printed.single.bytes.take(5)),
        '%PDF-',
      );
      expect(rig.printer.operations, isEmpty);
      expect(asked(http, salePath), 0);
      expect(rig.analytics.logged.map((event) => event.$1), [
        'tenant_pending_receipt_printed',
      ]);
      expect(tester.takeException(), isNull);
    });

    windowsTest('reports a queue submission error in the cashier language', (
      tester,
    ) async {
      final rig = (await pumpDone(tester)).rig;
      rig.printQueue.queues.add(office);
      await rememberWindowsPrinterQueue(office, rig.store);
      rig.printQueue.failNext(
        PrintQueueOperation.print,
        const PrintQueueException(PrintQueueFailure.printFailed),
      );

      await tester.tap(printButton);
      await settleAsyncPrint(tester, rig.printQueue, expectedOperations: 2);

      expect(
        find.text('PDF belum bisa dikirim ke printer Windows.'),
        findsOneWidget,
      );
      expect(rig.printQueue.printed, isEmpty);
      expect(rig.printer.operations, isEmpty);
      expect(tester.takeException(), isNull);
    });

    windowsTest('reports a Windows queue that was removed after selection', (
      tester,
    ) async {
      final (:rig, :http) = await pumpDone(tester);
      await rememberWindowsPrinterQueue(office, rig.store);

      await tester.tap(printButton);
      await settleAsyncPrint(tester, rig.printQueue, expectedOperations: 1);

      expect(
        find.text(
          'Printer Windows yang dipilih sudah tidak tersedia. Pilih lagi.',
        ),
        findsOneWidget,
      );
      expect(rig.printQueue.printed, isEmpty);
      expect(rig.printer.operations, isEmpty);
      expect(tester.takeException(), isNull);
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
