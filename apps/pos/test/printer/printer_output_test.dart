/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/print_queue_fake.dart';
import 'package:pn_types/src/native/print_queue_port.dart';
import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pos/printer/printer_output.dart';
import 'package:pos/printer/printer_service.dart';

void main() {
  const office = (
    id: 'windows-printer://office',
    name: 'Office Laser',
    isDefault: false,
    isAvailable: false,
  );
  final escPos = Uint8List.fromList([0x1b, 0x40, 0x41]);
  final pdf = Uint8List.fromList([37, 80, 68, 70, 45, 49]);

  FakeStorePort windowsStore() => FakeStorePort({
    printerKey: jsonEncode({'address': 'AA:BB', 'name': 'Kitchen BLE'}),
    printerOutputModeKey: 'windows_queue',
    windowsPrinterQueueKey: jsonEncode({'id': office.id, 'name': office.name}),
  });

  group('Windows print queue output', () {
    test(
      'submits generated PDF to the saved queue, not the BLE port',
      () async {
        final bluetooth = FakePrinter();
        final printQueue = FakePrintQueuePort([office]);
        final store = windowsStore();
        var pdfBuilds = 0;
        WindowsPrintPageSize? builtForPageSize;

        await printSelectedDocument(
          bluetoothBytes: escPos,
          buildWindowsPdf: (pageSize) async {
            pdfBuilds++;
            builtForPageSize = pageSize;
            return pdf;
          },
          documentName: 'Receipt',
          bluetooth: bluetooth,
          printQueue: printQueue,
          store: store,
          platform: TargetPlatform.windows,
        );

        expect(pdfBuilds, 1);
        expect(builtForPageSize, printQueue.pageSize);
        expect(bluetooth.operations, isEmpty);
        expect(printQueue.operations, [
          PrintQueueOperation.list,
          PrintQueueOperation.print,
        ]);
        expect(printQueue.printed.single.queueId, office.id);
        expect(printQueue.printed.single.name, 'Receipt');
        expect(printQueue.printed.single.bytes, pdf);
      },
    );

    test('does not print if no Windows queue has been configured', () async {
      final printQueue = FakePrintQueuePort([office]);
      var pdfBuilds = 0;

      await expectLater(
        printSelectedDocument(
          bluetoothBytes: escPos,
          buildWindowsPdf: (_) async {
            pdfBuilds++;
            return pdf;
          },
          documentName: 'Receipt',
          bluetooth: FakePrinter(),
          printQueue: printQueue,
          store: FakeStorePort({printerOutputModeKey: 'windows_queue'}),
          platform: TargetPlatform.windows,
        ),
        throwsA(
          isA<PrintQueueException>().having(
            (error) => error.reason,
            'reason',
            PrintQueueFailure.notConfigured,
          ),
        ),
      );
      expect(pdfBuilds, 0);
      expect(printQueue.operations, isEmpty);
    });

    test('reports a saved queue that disappeared from Windows', () async {
      final printQueue = FakePrintQueuePort();
      var pdfBuilds = 0;

      await expectLater(
        printSelectedDocument(
          bluetoothBytes: escPos,
          buildWindowsPdf: (_) async {
            pdfBuilds++;
            return pdf;
          },
          documentName: 'Receipt',
          bluetooth: FakePrinter(),
          printQueue: printQueue,
          store: windowsStore(),
          platform: TargetPlatform.windows,
        ),
        throwsA(
          isA<PrintQueueException>().having(
            (error) => error.reason,
            'reason',
            PrintQueueFailure.notFound,
          ),
        ),
      );
      expect(pdfBuilds, 0);
      expect(printQueue.operations, [PrintQueueOperation.list]);
    });

    test('surfaces a Windows spooler submission error unchanged', () async {
      final printQueue = FakePrintQueuePort([office])
        ..failNext(
          PrintQueueOperation.print,
          const PrintQueueException(PrintQueueFailure.printFailed),
        );

      await expectLater(
        printSelectedDocument(
          bluetoothBytes: escPos,
          buildWindowsPdf: (_) async => pdf,
          documentName: 'Receipt',
          bluetooth: FakePrinter(),
          printQueue: printQueue,
          store: windowsStore(),
          platform: TargetPlatform.windows,
        ),
        throwsA(
          isA<PrintQueueException>().having(
            (error) => error.reason,
            'reason',
            PrintQueueFailure.printFailed,
          ),
        ),
      );
      expect(printQueue.operations, [
        PrintQueueOperation.list,
        PrintQueueOperation.print,
      ]);
    });
  });

  test(
    'Android stays on its current BLE bytes regardless of saved Windows mode',
    () async {
      final bluetooth = FakePrinter();
      final printQueue = FakePrintQueuePort([office]);
      var pdfBuilds = 0;
      final store = windowsStore();
      await store.write(
        printerKey,
        jsonEncode({'address': 'AA:BB', 'name': 'Kitchen BLE'}),
      );

      await printSelectedDocument(
        bluetoothBytes: escPos,
        buildWindowsPdf: (_) async {
          pdfBuilds++;
          return pdf;
        },
        documentName: 'Receipt',
        bluetooth: bluetooth,
        printQueue: printQueue,
        store: store,
        platform: TargetPlatform.android,
      );

      expect(bluetooth.operations, [PrinterOp.connect, PrinterOp.write]);
      expect(bluetooth.written, [escPos]);
      expect(printQueue.operations, isEmpty);
      expect(pdfBuilds, 0);
    },
  );
}
