/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/print_queue_fake.dart';
import 'package:pn_types/src/native/print_queue_port.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pos/printer/printer_service.dart';

import 'menu_screen_test.dart' show pumpMenu;

void main() {
  const office = (
    id: 'windows-printer://office',
    name: 'Office Laser',
    isDefault: true,
    isAvailable: false,
  );
  const kitchen = PrinterDevice(address: 'AA:BB', name: 'Dapur');

  void windowsTest(String description, WidgetTesterCallback callback) {
    testWidgets(
      description,
      callback,
      variant: const TargetPlatformVariant({TargetPlatform.windows}),
    );
  }

  group('Windows printer selection', () {
    windowsTest(
      'lists installed queues and remembers selection separately from legacy BLE',
      (tester) async {
        final rig = await pumpMenu(tester);
        rig.printQueue.queues.add(office);
        await rememberPrinter(kitchen, rig.store);

        await tester.ensureVisible(find.text('Printer Windows'));
        await tester.tap(find.text('Printer Windows'));
        await tester.pumpAndSettle();

        expect(find.text('Sambungan printer'), findsOneWidget);
        expect(
          find.text(
            'Printer Windows menerima perintah ESC/POS langsung, atau PDF lewat driver-nya.',
          ),
          findsOneWidget,
        );
        expect(find.text('Pilih printer Windows'), findsOneWidget);
        expect(find.text('Office Laser'), findsOneWidget);
        expect(find.text('Sedang tidak tersedia'), findsOneWidget);

        await tester.tap(find.text('Office Laser'));
        await tester.pumpAndSettle();

        expect(
          await readPrinterMode(rig.store, platform: TargetPlatform.windows),
          PrinterMode.windowsQueue,
        );
        expect((await readSavedWindowsPrinterQueue(rig.store))?.id, office.id);
        expect(await readSavedPrinter(rig.store), kitchen);
        expect(rig.printQueue.operations, [PrintQueueOperation.list]);
        expect(tester.takeException(), isNull);
      },
    );

    windowsTest('shows no installed printer and leaves mode unconfigured', (
      tester,
    ) async {
      final rig = await pumpMenu(tester);

      await tester.ensureVisible(find.text('Printer Windows'));
      await tester.tap(find.text('Printer Windows'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Belum ada printer terpasang di Windows'),
        findsOneWidget,
      );
      expect(
        await readPrinterMode(rig.store, platform: TargetPlatform.windows),
        isNull,
      );
      expect(rig.printQueue.operations, [PrintQueueOperation.list]);
    });

    windowsTest('a legacy saved BLE printer remains selected on Windows', (
      tester,
    ) async {
      final rig = await pumpMenu(tester, savedPrinter: kitchen);

      expect(
        await readPrinterMode(rig.store, platform: TargetPlatform.windows),
        PrinterMode.bluetooth,
      );
      expect(find.text('Bluetooth'), findsOneWidget);
      expect(find.text('Dapur'), findsOneWidget);
      expect(
        find.text(
          'Printer Windows menerima perintah ESC/POS langsung, atau PDF lewat driver-nya.',
        ),
        findsOneWidget,
      );
      expect(rig.printQueue.operations, isEmpty);
    });

    windowsTest(
      'shows a retryable message when Windows queue enumeration fails',
      (tester) async {
        final rig = await pumpMenu(tester);
        rig.printQueue.failNext(
          PrintQueueOperation.list,
          const PrintQueueException(PrintQueueFailure.listFailed),
        );

        await tester.ensureVisible(find.text('Printer Windows'));
        await tester.tap(find.text('Printer Windows'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Belum bisa memuat daftar printer Windows'),
          findsOneWidget,
        );
        expect(find.text('Coba lagi'), findsOneWidget);
        expect(
          await readPrinterMode(rig.store, platform: TargetPlatform.windows),
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
