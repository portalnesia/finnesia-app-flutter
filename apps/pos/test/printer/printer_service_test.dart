/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pos/printer/printer_service.dart';

void main() {
  const printer1 = PrinterDevice(address: 'AA:BB:CC:DD:EE:FF', name: 'Kitchen');

  String saved(PrinterDevice device) =>
      jsonEncode({'address': device.address, 'name': device.name});

  Matcher throwsPrinter(PrinterFailure reason) => throwsA(
    isA<PrinterException>().having((e) => e.reason, 'reason', reason),
  );

  group('readSavedPrinter', () {
    // Web `getPairedPrinterInfo returns null when nothing was ever paired`.
    test('finds nothing when no printer was ever paired', () async {
      expect(await readSavedPrinter(FakeStorePort()), isNull);
    });

    test('finds the printer that was saved, with its name', () async {
      final store = FakeStorePort({printerKey: saved(printer1)});

      expect(await readSavedPrinter(store), printer1);
    });

    // The store hands back a string, and what is in it can be anything a previous build, a
    // half-finished write or a hand edit left. The Menu asks at startup: throwing here would
    // take it down, and an unconfigured printer at least says so.
    test(
      'reads what is stored but no longer a printer as no printer',
      () async {
        for (final raw in [
          'not json at all',
          '[1, 2]',
          '"just a string"',
          'null',
          '{}',
          '{"name": "Kitchen"}',
          '{"address": "", "name": "Kitchen"}',
          '{"address": 5, "name": "Kitchen"}',
          '{"address": null}',
        ]) {
          expect(
            await readSavedPrinter(FakeStorePort({printerKey: raw})),
            isNull,
            reason: raw,
          );
        }
      },
    );

    // The address is the identity a reconnect needs; the name is only what the Menu shows.
    test(
      'keeps the address when the name is missing or not a string',
      () async {
        for (final raw in [
          '{"address": "AA"}',
          '{"address": "AA", "name": 7}',
          '{"address": "AA", "name": null}',
        ]) {
          expect(
            await readSavedPrinter(FakeStorePort({printerKey: raw})),
            const PrinterDevice(address: 'AA', name: ''),
            reason: raw,
          );
        }
      },
    );

    // A failing store is not "no printer": reading a transient failure that way would send a
    // cashier to pair a printer that is in fact paired.
    test('lets a failing store through, not as "no printer"', () async {
      final store = FakeStorePort()..failNext(StoreException('disk full'));

      await expectLater(
        readSavedPrinter(store),
        throwsA(isA<StoreException>()),
      );
    });
  });

  group('pairPrinter', () {
    // Web `pairPrinter connects, caches the characteristic, and persists the device info`.
    test('connects to the printer and remembers it', () async {
      final printer = FakePrinter([printer1]);
      final store = FakeStorePort();

      final paired = await pairPrinter(
        printer1,
        printer: printer,
        store: store,
      );

      expect(paired, printer1);
      expect(printer.connectedAddress, printer1.address);
      expect(await readSavedPrinter(store), printer1);
    });

    // The name a scan showed can differ from what the connection reports; the Menu shows what
    // was saved, so it is the connected device that is saved.
    test('saves what the connection reported, not what it was given', () async {
      final printer = FakePrinter([
        const PrinterDevice(
          address: 'AA:BB:CC:DD:EE:FF',
          name: 'Reported name',
        ),
      ]);
      final store = FakeStorePort();

      final paired = await pairPrinter(
        const PrinterDevice(address: 'AA:BB:CC:DD:EE:FF', name: 'Scanned name'),
        printer: printer,
        store: store,
      );

      expect(paired.name, 'Reported name');
      expect((await readSavedPrinter(store))?.name, 'Reported name');
    });

    // A printer that would not connect must not become "the configured printer".
    test('remembers nothing when the connection fails, and says why', () async {
      final printer = FakePrinter([printer1])
        ..failNext(
          PrinterOp.connect,
          PrinterException(PrinterFailure.notConnected),
        );
      final store = FakeStorePort();

      await expectLater(
        pairPrinter(printer1, printer: printer, store: store),
        throwsPrinter(PrinterFailure.notConnected),
      );
      expect(store.values, isEmpty);
    });

    test('replaces the printer that was remembered before', () async {
      const other = PrinterDevice(address: '11:22:33:44:55:66', name: 'Bar');
      final printer = FakePrinter([printer1, other]);
      final store = FakeStorePort();

      await pairPrinter(printer1, printer: printer, store: store);
      await pairPrinter(other, printer: printer, store: store);

      expect(await readSavedPrinter(store), other);
    });
  });

  group('clearPrinter', () {
    // Web `forgetPrinter clears the in-memory connection and the persisted info`.
    test('forgets the printer, and drops the link to it', () async {
      final printer = FakePrinter([printer1]);
      final store = FakeStorePort();
      await pairPrinter(printer1, printer: printer, store: store);

      await clearPrinter(printer: printer, store: store);

      expect(await readSavedPrinter(store), isNull);
      expect(printer.connectedAddress, isNull);
    });

    test('is not a failure when no printer was paired', () async {
      await clearPrinter(printer: FakePrinter(), store: FakeStorePort());
    });
  });

  group('printDocument', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    // Web `printBytes returns false when no printer is connected` and
    // `tryReconnectPrinter returns false when nothing was ever paired`: the web signals it
    // with `false` so the caller can fall back to CSS. A tablet has no such fallback, so it
    // is the `notConnected` the UI turns into an offer to pair.
    test(
      'says notConnected, and does nothing else, when no printer is saved',
      () async {
        final printer = FakePrinter();

        await expectLater(
          printDocument(bytes, printer: printer, store: FakeStorePort()),
          throwsPrinter(PrinterFailure.notConnected),
        );
        expect(printer.operations, isEmpty);
      },
    );

    test('treats a saved printer it cannot read as no printer', () async {
      final printer = FakePrinter();

      await expectLater(
        printDocument(
          bytes,
          printer: printer,
          store: FakeStorePort({printerKey: 'garbage'}),
        ),
        throwsPrinter(PrinterFailure.notConnected),
      );
      expect(printer.operations, isEmpty);
    });

    // Web `tryReconnectPrinter silently reconnects to a previously-paired device with no
    // picker`. The BLE link does not survive a restart, and re-pairing on every print would
    // make the button useless, so the saved address is reconnected on its own.
    test('reconnects to the saved printer, then writes to it', () async {
      final printer = FakePrinter();
      final store = FakeStorePort({printerKey: saved(printer1)});

      await printDocument(bytes, printer: printer, store: store);

      // Connect before write is what the order is for: a write with no link fails.
      expect(printer.operations, [PrinterOp.connect, PrinterOp.write]);
      expect(printer.written, [bytes]);
    });

    test('connects to the address that was saved', () async {
      final printer = FakePrinter();
      final store = FakeStorePort({printerKey: saved(printer1)});

      await printDocument(bytes, printer: printer, store: store);

      expect(printer.connectedAddress, printer1.address);
    });

    // Web `tryReconnectPrinter returns false, without throwing, when the previously-paired
    // device is out of range or off` — here it throws, for the same reason as above.
    test(
      'says notConnected, and writes nothing, when the printer is out of range',
      () async {
        final printer = FakePrinter()
          ..failNext(
            PrinterOp.connect,
            PrinterException(PrinterFailure.notConnected),
          );
        final store = FakeStorePort({printerKey: saved(printer1)});

        await expectLater(
          printDocument(bytes, printer: printer, store: store),
          throwsPrinter(PrinterFailure.notConnected),
        );
        expect(printer.written, isEmpty);
      },
    );

    // The source turned every failure to connect into `notConnected`, discarding the reason
    // its own port had worked out. A cashier with Bluetooth off then read "switch the printer
    // on" — advice that cannot help — when `printer.bluetoothOff` had been written for exactly
    // this. The reason goes through as it was.
    test(
      'passes on why the connection failed, not a blanket notConnected',
      () async {
        for (final failure in [
          PrinterFailure.bluetoothOff,
          PrinterFailure.permissionDenied,
          PrinterFailure.unsupported,
        ]) {
          final printer = FakePrinter()
            ..failNext(PrinterOp.connect, PrinterException(failure));
          final store = FakeStorePort({printerKey: saved(printer1)});

          await expectLater(
            printDocument(bytes, printer: printer, store: store),
            throwsPrinter(failure),
            reason: failure.name,
          );
          expect(printer.written, isEmpty);
        }
      },
    );

    test('passes on a failed write', () async {
      final printer = FakePrinter()
        ..failNext(
          PrinterOp.write,
          PrinterException(PrinterFailure.printFailed),
        );
      final store = FakeStorePort({printerKey: saved(printer1)});

      await expectLater(
        printDocument(bytes, printer: printer, store: store),
        throwsPrinter(PrinterFailure.printFailed),
      );
    });

    test(
      'lets a failing store through, and never touches the printer',
      () async {
        final printer = FakePrinter();
        final store = FakeStorePort()..failNext(StoreException('disk full'));

        await expectLater(
          printDocument(bytes, printer: printer, store: store),
          throwsA(isA<StoreException>()),
        );
        expect(printer.operations, isEmpty);
      },
    );

    // A double connect per print would be the source's habit; the plugin side is idempotent
    // (`BlePrinter`), and here each print asks once.
    test('asks the printer to connect once per print', () async {
      final printer = FakePrinter();
      final store = FakeStorePort({printerKey: saved(printer1)});

      await printDocument(bytes, printer: printer, store: store);
      await printDocument(bytes, printer: printer, store: store);

      expect(
        printer.operations.where((op) => op == PrinterOp.connect),
        hasLength(2),
      );
      expect(printer.written, hasLength(2));
    });
  });
}
