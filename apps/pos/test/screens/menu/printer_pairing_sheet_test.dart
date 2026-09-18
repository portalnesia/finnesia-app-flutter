/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/printer/printer_service.dart';

import '../../support/boot_rig.dart';
import '../../support/held_printer.dart';
import 'menu_screen_test.dart' show pumpMenu;

// S15, opened from the Menu's printer card. The logic is `printer_pairing_controller_test`; what
// is here is what a cashier sees and can press.

const kitchen = PrinterDevice(address: 'AA:BB', name: 'Dapur');
const nameless = PrinterDevice(address: 'CC:DD', name: '');

Finder get pairButton => find.text('Sambungkan printer');
Finder get scanButton => find.widgetWithText(FilledButton, 'Pindai printer');

/// The Menu with a printer to find, and the pairing sheet opened.
Future<Rig> openSheet(
  WidgetTester tester, {
  List<PrinterDevice> nearby = const [kitchen],
  FakePrinter? printer,
  Size size = const Size(1280, 800),
  double textScale = 1,
}) async {
  final rig = await pumpMenu(
    tester,
    size: size,
    textScale: textScale,
    printer: printer ?? FakePrinter(nearby),
  );
  await tester.ensureVisible(pairButton);
  await tester.tap(pairButton);
  await tester.pumpAndSettle();
  return rig;
}

void main() {
  group('scanning', () {
    testWidgets('lists the printers found, by name', (tester) async {
      final rig = await openSheet(tester, nearby: [kitchen]);

      await tester.tap(scanButton);
      await tester.pumpAndSettle();

      expect(find.text('Dapur'), findsOneWidget);
      expect(rig.printer.scanDurations, hasLength(1));
    });

    testWidgets('a printer with no name is still one you can choose', (
      tester,
    ) async {
      await openSheet(tester, nearby: [nameless]);

      await tester.tap(scanButton);
      await tester.pumpAndSettle();

      // The address is what identifies it, so the row exists; the words say it has no name.
      expect(find.text('Tanpa nama'), findsOneWidget);
    });

    testWidgets('finding none says so, and lets you scan again', (
      tester,
    ) async {
      await openSheet(tester, nearby: const []);

      await tester.tap(scanButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Tidak ada printer ditemukan'),
        findsOneWidget,
      );
      expect(scanButton, findsOneWidget);
    });
  });

  group('choosing a printer', () {
    testWidgets('connects, remembers, and the Menu names it', (tester) async {
      final rig = await openSheet(tester, nearby: [kitchen]);
      await tester.tap(scanButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dapur'));
      await tester.pumpAndSettle();

      expect(rig.printer.connectedAddress, kitchen.address);
      expect(await readSavedPrinter(rig.store), kitchen);
      // The sheet is gone, and what the Menu says has changed with it.
      expect(find.text('Sambungkan Printer'), findsNothing);
      expect(find.text('Dapur'), findsOneWidget);
      expect(find.text('Belum ada printer'), findsNothing);
      expect(find.text('Ganti printer'), findsOneWidget);
    });
  });

  // A cashier can act on a sentence, not on a code: "switch Bluetooth on" and "allow Bluetooth in
  // Settings" are different jobs, and "could not scan" helps with neither.
  group('when it does not work', () {
    testWidgets('each reason a scan fails has its own sentence', (
      tester,
    ) async {
      final sentences = {
        PrinterFailure.bluetoothOff: 'Bluetooth tablet sedang mati',
        PrinterFailure.permissionDenied: 'Akses Bluetooth ditolak',
        PrinterFailure.unsupported: 'tidak punya Bluetooth',
        PrinterFailure.scanFailed: 'Gagal memindai printer.',
      };
      final rig = await openSheet(tester);

      for (final MapEntry(:key, :value) in sentences.entries) {
        rig.printer.failNext(PrinterOp.scan, PrinterException(key));
        await tester.tap(scanButton);
        await tester.pumpAndSettle();

        expect(find.textContaining(value), findsOneWidget, reason: '$key');
      }
    });

    testWidgets('a printer that will not connect is not remembered', (
      tester,
    ) async {
      final rig = await openSheet(tester);
      await tester.tap(scanButton);
      await tester.pumpAndSettle();
      rig.printer.failNext(
        PrinterOp.connect,
        PrinterException(PrinterFailure.notConnected),
      );

      await tester.tap(find.text('Dapur'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal menyambungkan ke printer.'), findsOneWidget);
      expect(await readSavedPrinter(rig.store), isNull);
      // Still open, with the scan to run again: the cashier can try it again or pick another.
      expect(find.text('Sambungkan Printer'), findsOneWidget);
      expect(scanButton, findsOneWidget);
    });

    testWidgets('one that connected but could not be saved says that', (
      tester,
    ) async {
      final rig = await openSheet(tester);
      await tester.tap(scanButton);
      await tester.pumpAndSettle();
      rig.store.failNext(StoreException('disk'));

      await tester.tap(find.text('Dapur'));
      await tester.pumpAndSettle();

      expect(find.textContaining('gagal mengingatnya'), findsOneWidget);
      expect(find.text('Sambungkan Printer'), findsOneWidget);
    });
  });

  group('while it waits', () {
    testWidgets('says it is scanning, and the scan cannot be pressed twice', (
      tester,
    ) async {
      final held = HeldPrinter([kitchen]);
      await openSheet(tester, printer: held);

      await tester.tap(scanButton);
      await tester.pump();

      expect(find.text('Memindai…'), findsOneWidget);
      expect(tester.widget<FilledButton>(scanButton).onPressed, isNull);

      held.scanning.complete();
      await tester.pumpAndSettle();
      expect(find.text('Memindai…'), findsNothing);
      expect(tester.widget<FilledButton>(scanButton).onPressed, isNotNull);
    });

    testWidgets('says it is connecting', (tester) async {
      final held = HeldPrinter([kitchen]);
      await openSheet(tester, printer: held);
      held.scanning.complete();
      await tester.tap(scanButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dapur'));
      await tester.pump();

      expect(find.text('Menyambungkan…'), findsOneWidget);
      held.connecting.complete();
      await tester.pumpAndSettle();
    });
  });

  group('closing it while it waits', () {
    testWidgets('during a scan leaves nothing broken when the scan ends', (
      tester,
    ) async {
      final held = HeldPrinter([kitchen]);
      await openSheet(tester, printer: held);
      await tester.tap(scanButton);
      await tester.pump();

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();
      held.scanning.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sambungkan Printer'), findsNothing);
    });

    testWidgets('during a connect leaves nothing broken when it ends', (
      tester,
    ) async {
      final held = HeldPrinter([kitchen]);
      final rig = await openSheet(tester, printer: held);
      held.scanning.complete();
      await tester.tap(scanButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dapur'));
      await tester.pump();

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();
      held.connecting.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The cashier walked away from it: it must not turn up as the printer, nor leave the
      // link open with nothing saved to say who it is to.
      expect(await readSavedPrinter(rig.store), isNull);
      expect(held.connectedAddress, isNull);
    });
  });

  group('the layout', () {
    testWidgets('fits a small tablet in portrait, with text at 1.3x', (
      tester,
    ) async {
      await openSheet(
        tester,
        nearby: [kitchen, nameless],
        size: const Size(600, 960),
        textScale: 1.3,
      );
      await tester.tap(scanButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dapur'), findsOneWidget);
      // A row you have to hit is a control: at least a touch target tall.
      expect(
        tester.getSize(find.widgetWithText(ListTile, 'Dapur')).height,
        greaterThanOrEqualTo(PnTouch.min),
      );
    });
  });

  group('opening the sheet', () {
    testWidgets('says what to do, and does not scan by itself', (tester) async {
      final rig = await openSheet(tester);

      expect(find.text('Sambungkan Printer'), findsOneWidget);
      expect(scanButton, findsOneWidget);
      // A scan draws power, so it waits for the cashier.
      expect(rig.printer.operations, isEmpty);
    });
  });
}
