/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pos/native/printer/printer_protocol.dart';
import 'package:universal_ble/universal_ble.dart';

// The two services the source tries, in the source's order.
const _printerService = '000018f0-0000-1000-8000-00805f9b34fb';
const _uartService = '49535343-fe7d-4ae5-8fa9-9fafd205e455';

BleCharacteristic _char(String uuid, List<CharacteristicProperty> properties) =>
    BleCharacteristic(uuid, properties, []);

BleService _service(String uuid, List<BleCharacteristic> characteristics) =>
    BleService(uuid, characteristics);

void main() {
  group('candidateServiceUuids', () {
    // Thermal printers share no single standard: some expose a dedicated printer service,
    // others an ISSC/HM-10 style "transparent UART". Web and the Android plugin both try
    // these two, in this order, and a third one is added here and nowhere else.
    test('are the two services the source tries, in order', () {
      expect(candidateServiceUuids, [_printerService, _uartService]);
    });
  });

  group('chunkSizeFor', () {
    // 20 is what the BLE spec guarantees with the default MTU of 23 (23 minus 3 bytes of
    // header). An MTU the plugin could not negotiate, or never reported, gets exactly that.
    test('is 20 when the MTU is unknown or too small to be useful', () {
      expect(chunkSizeFor(null), 20);
      expect(chunkSizeFor(23), 20);
      expect(chunkSizeFor(0), 20);
    });

    test('is the MTU less its 3 bytes of header', () {
      expect(chunkSizeFor(24), 21);
      expect(chunkSizeFor(100), 97);
      expect(chunkSizeFor(183), 180);
    });

    // The source caps it at 180 whatever was negotiated: its comment says cheap printers
    // stall around 185 bytes, and Android can negotiate up to 517. Web caps at 180 too.
    test('never exceeds 180, however large the MTU', () {
      expect(chunkSizeFor(184), 180);
      expect(chunkSizeFor(247), 180);
      expect(chunkSizeFor(517), 180);
    });
  });

  group('splitChunks', () {
    Uint8List bytesOf(int length) =>
        Uint8List.fromList(List.generate(length, (i) => i % 256));

    // Nothing to send is nothing to write; not one empty write.
    test('gives no chunks for no bytes', () {
      expect(splitChunks(Uint8List(0), 180), isEmpty);
    });

    test('gives one chunk for a document that fits', () {
      expect(splitChunks(bytesOf(100), 180), [bytesOf(100)]);
      expect(splitChunks(bytesOf(180), 180), [bytesOf(180)]);
    });

    // The last chunk is whatever is left, not padded.
    test('leaves the remainder in a shorter last chunk', () {
      final chunks = splitChunks(bytesOf(400), 180);

      expect(chunks.map((c) => c.length), [180, 180, 40]);
    });

    test('splits an exact multiple with no empty chunk at the end', () {
      expect(splitChunks(bytesOf(360), 180).map((c) => c.length), [180, 180]);
    });

    // The whole point: what goes out is the document, in order, and no piece is larger than
    // the printer takes. 1000 bytes at 180 is 5 full chunks and a remainder of 100.
    test('puts the document out unchanged, in chunks no larger than asked', () {
      final document = bytesOf(1000);
      final chunks = splitChunks(document, 180);

      expect(chunks.length, 6);
      expect(chunks.every((c) => c.length <= 180), isTrue);
      expect(chunks.expand((c) => c).toList(), document);
    });

    // A zero size would never advance.
    test('refuses a chunk size that cannot make progress', () {
      expect(() => splitChunks(bytesOf(10), 0), throwsArgumentError);
      expect(() => splitChunks(bytesOf(10), -1), throwsArgumentError);
    });
  });

  group('failureForAvailability', () {
    test('finds nothing wrong when Bluetooth is on', () {
      expect(failureForAvailability(AvailabilityState.poweredOn), isNull);
    });

    test('says the radio is off when it is off', () {
      expect(
        failureForAvailability(AvailabilityState.poweredOff),
        PrinterFailure.bluetoothOff,
      );
    });

    // Android reports `resetting` while the adapter is turning on or off. The cashier's
    // move is the same as for "off": switch it on, wait, try again. Not "unsupported".
    test('says the radio is off while it is switching', () {
      expect(
        failureForAvailability(AvailabilityState.resetting),
        PrinterFailure.bluetoothOff,
      );
    });

    test(
      'says the device cannot do Bluetooth when it reports it unsupported',
      () {
        expect(
          failureForAvailability(AvailabilityState.unsupported),
          PrinterFailure.unsupported,
        );
      },
    );

    // Android answers `unknown` when there is no adapter at all (the plugin's `adapter?.state
    // ?: UNKNOWN`), which the source reported as `bluetooth_unavailable` → `unsupported`.
    // Reading it as "off" would tell a cashier to switch on a radio the tablet does not have.
    test('says the device cannot do Bluetooth when it reports no adapter', () {
      expect(
        failureForAvailability(AvailabilityState.unknown),
        PrinterFailure.unsupported,
      );
    });

    test('says access was refused when it is unauthorized', () {
      expect(
        failureForAvailability(AvailabilityState.unauthorized),
        PrinterFailure.permissionDenied,
      );
    });
  });

  group('failureFromBleError', () {
    UniversalBleException error(UniversalBleErrorCode code) =>
        UniversalBleException(code: code, message: 'x');

    // The three the cashier can act on, each with its own advice, must survive whatever the
    // caller falls back to: the source's `readScanFailure` and `readConnectFailure` differ
    // only in that fallback.
    test('reads "Bluetooth is off" for a scan and for a connect alike', () {
      final off = error(UniversalBleErrorCode.bluetoothNotEnabled);

      expect(
        failureFromBleError(off, otherwise: PrinterFailure.scanFailed),
        PrinterFailure.bluetoothOff,
      );
      expect(
        failureFromBleError(off, otherwise: PrinterFailure.notConnected),
        PrinterFailure.bluetoothOff,
      );
    });

    test('reads "no Bluetooth on this device" as unsupported', () {
      expect(
        failureFromBleError(
          error(UniversalBleErrorCode.bluetoothNotAvailable),
          otherwise: PrinterFailure.scanFailed,
        ),
        PrinterFailure.unsupported,
      );
    });

    test('reads a refused permission as permissionDenied, whichever way it is reported', () {
      for (final code in [
        UniversalBleErrorCode.bluetoothNotAllowed,
        UniversalBleErrorCode.bluetoothUnauthorized,
      ]) {
        expect(
          failureFromBleError(
            error(code),
            otherwise: PrinterFailure.scanFailed,
          ),
          PrinterFailure.permissionDenied,
        );
      }
    });

    // A printer that is off, out of range, or already claimed by another app all arrive as
    // some connection code, and the cashier's next move is the same in every case.
    test('gives the caller\'s fallback for a failure it cannot name', () {
      final timeout = error(UniversalBleErrorCode.connectionTimeout);

      expect(
        failureFromBleError(timeout, otherwise: PrinterFailure.notConnected),
        PrinterFailure.notConnected,
      );
      expect(
        failureFromBleError(timeout, otherwise: PrinterFailure.scanFailed),
        PrinterFailure.scanFailed,
      );
    });

    // Not everything thrown is the plugin's: a bug elsewhere must not read as "Bluetooth is
    // off".
    test('gives the fallback for an error that is not the plugin\'s', () {
      expect(
        failureFromBleError(
          StateError('x'),
          otherwise: PrinterFailure.scanFailed,
        ),
        PrinterFailure.scanFailed,
      );
    });

    // `UniversalBle.connect` wraps whatever the platform threw in a `ConnectionException`,
    // parsing the code from a `PlatformException` whose code is the enum's index.
    test(
      'reads the code out of the ConnectionException a failed connect throws',
      () {
        final thrown = ConnectionException(
          PlatformException(
            code: UniversalBleErrorCode.bluetoothNotEnabled.index.toString(),
          ),
        );

        expect(
          failureFromBleError(thrown, otherwise: PrinterFailure.notConnected),
          PrinterFailure.bluetoothOff,
        );
      },
    );
  });

  group('pickWriteTarget', () {
    test('takes a writable characteristic of the printer service', () {
      final target = pickWriteTarget([
        _service(_printerService, [
          _char('2af1', [CharacteristicProperty.write]),
        ]),
      ]);

      expect(target?.service, _printerService);
      expect(target?.characteristic, BleUuidParser.string('2af1'));
      expect(target?.withoutResponse, isFalse);
    });

    test(
      'falls back to the UART service when the printer service is absent',
      () {
        final target = pickWriteTarget([
          _service(_uartService, [
            _char('ffe1', [CharacteristicProperty.write]),
          ]),
        ]);

        expect(target?.service, _uartService);
      },
    );

    // A service can be offered without anything to write to; that is not a printer.
    test('moves on when a candidate service has nothing writable', () {
      final target = pickWriteTarget([
        _service(_printerService, [
          _char('2a00', [CharacteristicProperty.read]),
        ]),
        _service(_uartService, [
          _char('ffe1', [CharacteristicProperty.write]),
        ]),
      ]);

      expect(target?.service, _uartService);
    });

    // The order is the source's, not the device's: a device that lists the UART first must
    // still be written through the printer service if it has one.
    test('prefers the earlier candidate however the device lists them', () {
      final target = pickWriteTarget([
        _service(_uartService, [
          _char('ffe1', [CharacteristicProperty.write]),
        ]),
        _service(_printerService, [
          _char('2af1', [CharacteristicProperty.write]),
        ]),
      ]);

      expect(target?.service, _printerService);
    });

    test('takes the first writable characteristic, skipping the others', () {
      final target = pickWriteTarget([
        _service(_printerService, [
          _char('2a00', [
            CharacteristicProperty.read,
            CharacteristicProperty.notify,
          ]),
          _char('2af1', [CharacteristicProperty.write]),
          _char('2af2', [CharacteristicProperty.write]),
        ]),
      ]);

      expect(target?.characteristic, BleUuidParser.string('2af1'));
    });

    // A write with no response is only for a characteristic that offers nothing better: the
    // next chunk goes out when the write completes, and without an acknowledgement that is
    // too early and the printer's buffer overflows.
    test(
      'writes without response only when that is all the characteristic offers',
      () {
        final only = pickWriteTarget([
          _service(_uartService, [
            _char('ffe1', [CharacteristicProperty.writeWithoutResponse]),
          ]),
        ]);
        final both = pickWriteTarget([
          _service(_uartService, [
            _char('ffe1', [
              CharacteristicProperty.writeWithoutResponse,
              CharacteristicProperty.write,
            ]),
          ]),
        ]);

        expect(only?.withoutResponse, isTrue);
        expect(both?.withoutResponse, isFalse);
      },
    );

    // The plugin normalises the UUIDs it reports, so a 16-bit one still matches.
    test('matches a candidate reported in its short form', () {
      final target = pickWriteTarget([
        _service('18f0', [
          _char('2af1', [CharacteristicProperty.write]),
        ]),
      ]);

      expect(target?.service, _printerService);
    });

    test(
      'finds nothing when no candidate service has a writable characteristic',
      () {
        expect(pickWriteTarget([]), isNull);
        expect(
          pickWriteTarget([
            // Writable, but not a service the source knows to be a printer.
            _service('1800', [
              _char('2a00', [CharacteristicProperty.write]),
            ]),
          ]),
          isNull,
        );
      },
    );
  });
}
