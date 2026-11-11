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
import 'package:pn_types/src/native/print_queue_fake.dart';
import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/printer/printer_service.dart';

import '../../support/boot_rig.dart';
import '../../support/routed_http.dart';
import 'shift_screen_test.dart'
    show
        appWith,
        backend,
        l10n,
        settingsPathRoute,
        signedIn,
        summaryBody,
        useSize;

// The closing report, printed from the shift screen. What is on paper is `shift_report_test`;
// what is here is who can ask for it, what it needs, and what happens when the printer will not.

const kitchen = PrinterDevice(address: 'AA:BB', name: 'Dapur');
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

Future<void> settleAsyncPrint(
  WidgetTester tester,
  FakePrintQueuePort queue, {
  required int expectedOperations,
}) async {
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

Finder get printButton => find.widgetWithText(OutlinedButton, 'Cetak Laporan');

/// The shift screen of an open drawer, on a tablet that already has [kitchen] paired.
Future<({Rig rig, RoutedHttp http})> pumpReport(
  WidgetTester tester, {
  Map<String, Object?>? summary,
  bool paired = true,
  List<PrinterDevice> nearby = const [],
  bool showProducts = false,
  bool settingsReadable = true,
  Size size = const Size(1280, 800),
  double textScale = 1,
}) async {
  useSize(tester, size, textScale);
  final http = RoutedHttp();
  backend(http, summary: summary);
  // Read on every press, so a test that presses more than once needs an answer for each.
  for (var i = 0; i < 6; i++) {
    if (settingsReadable) {
      http.respond(
        settingsPathRoute,
        ok({'require_shift': true, 'show_product_sales_summary': showProducts}),
      );
    } else {
      http.fail(settingsPathRoute);
    }
  }
  final rig = Rig({
    ...storedSession(signedIn),
    if (paired)
      printerKey: jsonEncode({
        'address': kitchen.address,
        'name': kitchen.name,
      }),
  });
  rig.printer = FakePrinter(nearby);
  await tester.pumpWidget(appWith(rig, http));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open shift screen'));
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

void main() {
  // The cashier is standing at a drawer they are counting: a report that did not come out has to
  // say why in words they can act on, and never take the screen down.
  group('when it does not come out', () {
    testWidgets('each reason has its own sentence, and nothing is sent', (
      tester,
    ) async {
      final sentences = {
        (PrinterOp.connect, PrinterFailure.bluetoothOff):
            'Bluetooth tablet sedang mati',
        (PrinterOp.connect, PrinterFailure.permissionDenied):
            'Akses Bluetooth ditolak',
        (PrinterOp.connect, PrinterFailure.notConnected):
            'Printer belum tersambung',
        (PrinterOp.write, PrinterFailure.printFailed):
            'Gagal mengirim ke printer.',
      };
      final (:rig, :http) = await pumpReport(tester);

      for (final MapEntry(key: (op, reason), :value) in sentences.entries) {
        rig.printer.failNext(op, PrinterException(reason));
        await tester.tap(printButton);
        await tester.pumpAndSettle();

        expect(find.textContaining(value), findsOneWidget, reason: '$reason');
        expect(tester.takeException(), isNull);
      }
      expect(rig.printer.written, isEmpty);
    });
  });

  group('with no printer paired yet', () {
    Finder scan() => find.widgetWithText(FilledButton, 'Pindai printer');

    testWidgets('offers to pair one, and prints once it is', (tester) async {
      final (:rig, :http) = await pumpReport(
        tester,
        paired: false,
        nearby: [kitchen],
      );

      await tester.tap(printButton);
      await tester.pumpAndSettle();
      expect(find.text('Sambungkan Printer'), findsOneWidget);
      expect(rig.printer.written, isEmpty);

      await tester.tap(scan());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dapur'));
      await tester.pumpAndSettle();

      expect(paper(rig), contains('SH-0001'));
      expect(find.text('Laporan terkirim ke printer'), findsOneWidget);
    });

    testWidgets('closing the offer prints nothing', (tester) async {
      final (:rig, :http) = await pumpReport(tester, paired: false);

      await tester.tap(printButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();

      expect(rig.printer.written, isEmpty);
      expect(find.text('Sambungkan Printer'), findsNothing);
    });
  });

  group('when the saved printer cannot be read', () {
    testWidgets('says so, and does not offer to pair another', (tester) async {
      final (:rig, :http) = await pumpReport(tester);
      rig.store.failNext(StoreException('keystore'));

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(find.text('Printer tersimpan tidak bisa dibaca'), findsOneWidget);
      expect(find.text('Sambungkan Printer'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('what it depends on', () {
    final withProducts = {
      ...summaryBody(),
      'product_sales': [
        {
          'product_id': 'p1',
          'product_name': 'Kopi Susu',
          'quantity': 2,
          'unit_price': 25000,
          'total': 50000,
        },
      ],
    };

    testWidgets('the product breakdown follows the settings of the tenant', (
      tester,
    ) async {
      final (:rig, :http) = await pumpReport(
        tester,
        summary: withProducts,
        showProducts: true,
      );

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(paper(rig), contains('Kopi Susu'));
    });

    testWidgets('settings that cannot be read do not stop the report', (
      tester,
    ) async {
      final (:rig, :http) = await pumpReport(
        tester,
        summary: withProducts,
        settingsReadable: false,
      );

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      // The part a drawer is counted against is all there; only the optional breakdown is not.
      expect(paper(rig), contains('SH-0001'));
      expect(paper(rig), isNot(contains('Kopi Susu')));
      expect(find.text('Laporan terkirim ke printer'), findsOneWidget);
    });

    testWidgets('a closed shift can be printed, and offers nothing else', (
      tester,
    ) async {
      await pumpReport(
        tester,
        summary: summaryBody(status: 'CLOSED', counted: 275000, variance: 0),
      );

      expect(printButton, findsOneWidget);
      expect(find.text(l10n.cashMovementTitle), findsNothing);
      expect(find.text(l10n.closeShiftButton), findsNothing);
    });
  });

  group('the layout', () {
    testWidgets('fits a small tablet in portrait, with text at 1.3x', (
      tester,
    ) async {
      await pumpReport(tester, size: const Size(600, 960), textScale: 1.3);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(printButton).height,
        greaterThanOrEqualTo(PnTouch.min),
      );
    });
  });

  group('printing it', () {
    testWidgets('sends the report to the printer that is paired', (
      tester,
    ) async {
      final (:rig, :http) = await pumpReport(tester);

      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(rig.printer.connectedAddress, kitchen.address);
      expect(paper(rig), contains('SH-0001'));
      expect(find.text('Laporan terkirim ke printer'), findsOneWidget);
    });

    windowsTest('sends a PDF shift report to the selected Windows queue', (
      tester,
    ) async {
      final rig = (await pumpReport(tester)).rig;
      rig.printQueue.queues.add(office);
      await rememberWindowsPrinterQueue(office, rig.store);
      await saveWindowsQueueFormat(WindowsQueueFormat.pdf, rig.store);

      await tester.tap(printButton);
      await settleAsyncPrint(tester, rig.printQueue, expectedOperations: 2);

      final bytes = rig.printQueue.printed.single.bytes;
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(pdfPageWidth(bytes), closeTo(PdfPageFormat.roll80.width, 0.01));
      expect(bytes.length, greaterThan(1000));
      expect(rig.printQueue.printed.single.queueId, office.id);
      expect(rig.printer.operations, isEmpty);
      expect(find.text('Laporan terkirim ke printer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    windowsTest('can send another PDF in a later Windows print flow', (
      tester,
    ) async {
      final rig = (await pumpReport(tester)).rig;
      rig.printQueue.queues.add(office);
      await rememberWindowsPrinterQueue(office, rig.store);
      await saveWindowsQueueFormat(WindowsQueueFormat.pdf, rig.store);

      await tester.tap(printButton);
      await settleAsyncPrint(tester, rig.printQueue, expectedOperations: 2);

      expect(rig.printQueue.printed, hasLength(1));
      expect(
        String.fromCharCodes(rig.printQueue.printed.single.bytes.take(5)),
        '%PDF-',
      );
      expect(rig.printer.operations, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
