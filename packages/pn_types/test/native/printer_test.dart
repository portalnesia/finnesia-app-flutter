/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:typed_data';

import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:test/test.dart';

void main() {
  group('PrinterDevice', () {
    // Scan results are compared in tests, and a paired printer is compared with the one a
    // fresh scan returns: the address is its identity, the name is what the Menu shows.
    test('is equal to another with the same address and name', () {
      expect(
        const PrinterDevice(address: 'AA:BB:CC:DD:EE:FF', name: 'Printer'),
        const PrinterDevice(address: 'AA:BB:CC:DD:EE:FF', name: 'Printer'),
      );
    });

    test('differs when the address differs, even with the same name', () {
      expect(
        const PrinterDevice(address: 'AA:BB:CC:DD:EE:FF', name: 'Printer'),
        isNot(
          const PrinterDevice(address: '11:22:33:44:55:66', name: 'Printer'),
        ),
      );
    });
  });

  group('PrinterFailure', () {
    // Each name is the tail of a translation key (`printer.<reason>`), and the UI renders
    // `t('printer', reason.name)` with no lookup table in between. Renaming one here would
    // make a cashier read a raw key instead of advice, and no compiler would notice.
    test('has exactly the names the translation keys use', () {
      expect(
        PrinterFailure.values.map((failure) => failure.name),
        unorderedEquals([
          'unsupported',
          'notConnected',
          'printFailed',
          'scanFailed',
          'permissionDenied',
          'bluetoothOff',
        ]),
      );
    });
  });

  group('PrinterException', () {
    test('carries the reason the UI translates', () {
      expect(
        PrinterException(PrinterFailure.bluetoothOff).reason,
        PrinterFailure.bluetoothOff,
      );
    });

    // Exception text ends up in logs and crash reports; a printer's MAC address does not
    // belong there. The exception carries a reason and nothing else, so it cannot.
    test('names only the reason in its text', () {
      expect(
        PrinterException(PrinterFailure.notConnected).toString(),
        'PrinterException: notConnected',
      );
    });
  });

  group('FakePrinter — scan', () {
    const printer1 = PrinterDevice(
      address: 'AA:BB:CC:DD:EE:FF',
      name: 'Printer 1',
    );
    const printer2 = PrinterDevice(
      address: '11:22:33:44:55:66',
      name: 'Printer 2',
    );

    test('finds the devices it was given, in order', () async {
      final printer = FakePrinter([printer1, printer2]);

      expect(await printer.scan(), [printer1, printer2]);
    });

    // "No printers nearby" is an answer, not a failure (`PrinterPort.scan`).
    test('finds nothing when it was given nothing', () async {
      expect(await FakePrinter().scan(), isEmpty);
    });

    // A scan is bounded because it drains the battery. The fake records the bound so a test
    // can assert the caller did not ask for an unbounded one.
    test('records the duration it was asked for', () async {
      final printer = FakePrinter();

      await printer.scan(duration: const Duration(seconds: 2));
      await printer.scan();

      expect(printer.scanDurations, [
        const Duration(seconds: 2),
        defaultPrinterScanDuration,
      ]);
    });

    // The failure path the port rules require: a test that cannot make the scan fail never
    // exercises what the dialog does about it.
    test('throws a queued failure, once, then works again', () async {
      final printer = FakePrinter([printer1])
        ..failNext(
          PrinterOp.scan,
          PrinterException(PrinterFailure.bluetoothOff),
        );

      await expectLater(
        printer.scan(),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.reason,
            'reason',
            PrinterFailure.bluetoothOff,
          ),
        ),
      );
      expect(await printer.scan(), [printer1]);
    });
  });

  group('FakePrinter — connect', () {
    const printer1 = PrinterDevice(
      address: 'AA:BB:CC:DD:EE:FF',
      name: 'Printer 1',
    );
    const printer2 = PrinterDevice(
      address: '11:22:33:44:55:66',
      name: 'Printer 2',
    );

    test('is not connected to anything to begin with', () {
      expect(FakePrinter([printer1]).connectedAddress, isNull);
    });

    // `pairPrinter` saves what `connect` returns, so the name the cashier sees in the Menu
    // is the one the scan showed.
    test(
      'returns the scanned device with that address, and holds the link',
      () async {
        final printer = FakePrinter([printer1, printer2]);

        expect(await printer.connect(printer2.address), printer2);
        expect(printer.connectedAddress, printer2.address);
      },
    );

    // A printer paired earlier may not be advertising now; the address is still enough to
    // connect. The name falls back to the address, as the Android plugin does.
    test('names a device it never scanned by its address', () async {
      final printer = FakePrinter();

      expect(
        await printer.connect('AA:BB:CC:DD:EE:FF'),
        const PrinterDevice(
          address: 'AA:BB:CC:DD:EE:FF',
          name: 'AA:BB:CC:DD:EE:FF',
        ),
      );
    });

    // One link at a time: connecting elsewhere closes the old one first.
    test('holds only the latest link', () async {
      final printer = FakePrinter([printer1, printer2]);

      await printer.connect(printer1.address);
      await printer.connect(printer2.address);

      expect(printer.connectedAddress, printer2.address);
    });

    // The Android plugin closes the old link before trying the new one, so a failed connect
    // leaves the tablet connected to nothing, not to the printer it had before.
    test(
      'throws a queued failure and leaves no link, even the earlier one',
      () async {
        final printer = FakePrinter([printer1, printer2]);
        await printer.connect(printer1.address);
        printer.failNext(
          PrinterOp.connect,
          PrinterException(PrinterFailure.notConnected),
        );

        await expectLater(
          printer.connect(printer2.address),
          throwsA(isA<PrinterException>()),
        );
        expect(printer.connectedAddress, isNull);
      },
    );
  });

  group('FakePrinter — write', () {
    Future<FakePrinter> connected() async {
      final printer = FakePrinter();
      await printer.connect('AA:BB:CC:DD:EE:FF');
      return printer;
    }

    test('records each document as one write, in order', () async {
      final printer = await connected();

      await printer.write(Uint8List.fromList([1, 2, 3]));
      await printer.write(Uint8List.fromList([4]));

      expect(printer.written, [
        [1, 2, 3],
        [4],
      ]);
    });

    // A caller may reuse its buffer for the next receipt. What the printer was sent must not
    // change afterwards.
    test('keeps a copy, not the caller\'s buffer', () async {
      final printer = await connected();
      final bytes = Uint8List.fromList([1, 2, 3]);

      await printer.write(bytes);
      bytes[0] = 99;

      expect(printer.written.single, [1, 2, 3]);
    });

    // The Android plugin answers `not_connected`, which the port maps to `printFailed`.
    test('throws printFailed, and records nothing, with no link', () async {
      final printer = FakePrinter();

      await expectLater(
        printer.write(Uint8List.fromList([1])),
        throwsA(
          isA<PrinterException>().having(
            (e) => e.reason,
            'reason',
            PrinterFailure.printFailed,
          ),
        ),
      );
      expect(printer.written, isEmpty);
    });

    // A write that failed put nothing on paper, so it is not "written".
    test('throws a queued failure and records nothing, once', () async {
      final printer = await connected()
        ..failNext(
          PrinterOp.write,
          PrinterException(PrinterFailure.printFailed),
        );

      await expectLater(
        printer.write(Uint8List.fromList([1])),
        throwsA(isA<PrinterException>()),
      );
      expect(printer.written, isEmpty);

      await printer.write(Uint8List.fromList([2]));
      expect(printer.written, [
        [2],
      ]);
    });

    // Queued per operation: a failure meant for the write must not be spent on the connect.
    test(
      'leaves a queued write failure alone when something else is called',
      () async {
        final printer = FakePrinter()
          ..failNext(
            PrinterOp.write,
            PrinterException(PrinterFailure.printFailed),
          );

        await printer.connect('AA:BB:CC:DD:EE:FF');
        await printer.scan();

        await expectLater(
          printer.write(Uint8List.fromList([1])),
          throwsA(isA<PrinterException>()),
        );
      },
    );
  });

  group('FakePrinter — disconnect', () {
    test('drops the link', () async {
      final printer = FakePrinter();
      await printer.connect('AA:BB:CC:DD:EE:FF');

      await printer.disconnect();

      expect(printer.connectedAddress, isNull);
    });

    // `PrinterPort.disconnect`: having nothing to tear down is not a failure.
    test('is not a failure with nothing to tear down', () async {
      await FakePrinter().disconnect();
    });

    // The contract says it cannot fail, so a fake that could would model an implementation
    // that breaks it, and a caller tested against that would grow a catch it never needs.
    test('refuses a queued failure, because the port says it cannot fail', () {
      expect(
        () => FakePrinter().failNext(
          PrinterOp.disconnect,
          PrinterException(PrinterFailure.printFailed),
        ),
        throwsArgumentError,
      );
    });

    // A write after a disconnect has no link, as on the tablet.
    test('leaves later writes without a link', () async {
      final printer = FakePrinter();
      await printer.connect('AA:BB:CC:DD:EE:FF');
      await printer.disconnect();

      await expectLater(
        printer.write(Uint8List.fromList([1])),
        throwsA(isA<PrinterException>()),
      );
    });
  });

  group('FakePrinter — operations', () {
    // `printDocument` must connect before it writes; the order is what a service test asserts.
    test('records every call in order', () async {
      final printer = FakePrinter();

      await printer.scan();
      await printer.connect('AA:BB:CC:DD:EE:FF');
      await printer.write(Uint8List.fromList([1]));
      await printer.disconnect();

      expect(printer.operations, [
        PrinterOp.scan,
        PrinterOp.connect,
        PrinterOp.write,
        PrinterOp.disconnect,
      ]);
    });

    test('records the calls that failed too', () async {
      final printer = FakePrinter()
        ..failNext(
          PrinterOp.connect,
          PrinterException(PrinterFailure.notConnected),
        );

      await expectLater(
        printer.connect('AA:BB:CC:DD:EE:FF'),
        throwsA(isA<PrinterException>()),
      );

      expect(printer.operations, [PrinterOp.connect]);
    });
  });
}
