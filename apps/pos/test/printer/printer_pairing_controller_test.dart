/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pos/printer/printer_pairing_controller.dart';
import 'package:pos/printer/printer_service.dart';

import '../support/held_printer.dart';

// S15's logic: scan, choose, connect, remember. The sheet only draws what this says.

void main() {
  const kitchen = PrinterDevice(address: 'AA:BB', name: 'Kitchen');
  const counter = PrinterDevice(address: 'CC:DD', name: 'Counter');

  late FakePrinter printer;
  late FakeStorePort store;
  late FakeAnalytics analytics;
  late PrinterPairingController controller;

  setUp(() {
    printer = FakePrinter([kitchen, counter]);
    store = FakeStorePort();
    analytics = FakeAnalytics();
    controller = PrinterPairingController(
      printer: printer,
      store: store,
      analytics: analytics,
    );
    addTearDown(controller.dispose);
  });

  group('while it waits', () {
    test(
      'says it is scanning, and a second scan does not start another',
      () async {
        final held = HeldPrinter([kitchen]);
        final busy = PrinterPairingController(
          printer: held,
          store: store,
          analytics: FakeAnalytics(),
        );
        addTearDown(busy.dispose);

        final first = busy.scan();
        expect(busy.state, isA<PairingScanning>());
        await busy.scan();
        held.scanning.complete();
        await first;

        expect(
          held.operations.where((op) => op == PrinterOp.scan),
          hasLength(1),
        );
        expect(busy.state, isA<PairingFound>());
      },
    );

    test('says it is connecting, and a second choice waits its turn', () async {
      final held = HeldPrinter([kitchen, counter]);
      final busy = PrinterPairingController(
        printer: held,
        store: store,
        analytics: FakeAnalytics(),
      );
      addTearDown(busy.dispose);

      final first = busy.pair(kitchen);
      expect((busy.state as PairingConnecting).device, kitchen);
      await busy.pair(counter);
      held.connecting.complete();
      await first;

      expect(held.connectedAddress, kitchen.address);
      expect((busy.state as PairingDone).device, kitchen);
    });
  });

  group('choosing a printer', () {
    test('connects to it and remembers it', () async {
      await controller.scan();
      await controller.pair(counter);

      expect((controller.state as PairingDone).device, counter);
      expect(printer.connectedAddress, counter.address);
      expect(await readSavedPrinter(store), counter);
    });

    test('says why it would not connect, and remembers nothing', () async {
      printer.failNext(
        PrinterOp.connect,
        PrinterException(PrinterFailure.notConnected),
      );

      await controller.pair(kitchen);

      final state = controller.state as PairingFailed;
      expect(state.reason, PrinterFailure.notConnected);
      expect(state.step, PairingStep.connect);
      expect(await readSavedPrinter(store), isNull);
    });

    test('says so when it connected but could not be remembered', () async {
      store.failNext(StoreException('disk'));

      await controller.pair(kitchen);

      expect((controller.state as PairingSaveFailed).device, kitchen);
    });
  });

  group('scanning', () {
    test('starts with nothing asked of the printer', () {
      expect(controller.state, isA<PairingIdle>());
      expect(printer.operations, isEmpty);
    });

    test('shows what the scan found', () async {
      await controller.scan();

      expect(controller.state, isA<PairingFound>());
      expect((controller.state as PairingFound).devices, [kitchen, counter]);
    });

    test('nothing nearby is an answer, not a failure', () async {
      final empty = PrinterPairingController(
        printer: FakePrinter(),
        store: store,
        analytics: FakeAnalytics(),
      );
      addTearDown(empty.dispose);
      await empty.scan();

      expect((empty.state as PairingFound).devices, isEmpty);
    });

    test('says why a scan failed, and offers to try again', () async {
      printer.failNext(
        PrinterOp.scan,
        PrinterException(PrinterFailure.bluetoothOff),
      );

      await controller.scan();

      final state = controller.state as PairingFailed;
      expect(state.reason, PrinterFailure.bluetoothOff);
      expect(state.step, PairingStep.scan);

      await controller.scan();
      expect(controller.state, isA<PairingFound>());
    });
  });

  group('analytics', () {
    test('logs printer_pairing_started then printer_paired', () async {
      await controller.pair(counter);

      expect(analytics.logged.map((e) => e.$1), [
        'printer_pairing_started',
        'printer_paired',
      ]);
    });

    test(
      'logs printer_pairing_failed with the reason when it would not connect',
      () async {
        printer.failNext(
          PrinterOp.connect,
          PrinterException(PrinterFailure.notConnected),
        );

        await controller.pair(kitchen);

        expect(analytics.logged.map((e) => e.$1), [
          'printer_pairing_started',
          'printer_pairing_failed',
        ]);
        expect(analytics.logged.last.$2, {'reason': 'notConnected'});
      },
    );

    test('logs printer_pairing_failed when it connected but could not be remembered', () async {
      store.failNext(StoreException('disk'));

      await controller.pair(kitchen);

      expect(analytics.logged.last.$1, 'printer_pairing_failed');
      expect(analytics.logged.last.$2, {'reason': 'storage'});
    });

    test('logs nothing for scanning alone', () async {
      await controller.scan();

      expect(analytics.logged, isEmpty);
    });
  });
}
