/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:math';
import 'dart:typed_data';

import 'package:pn_types/src/native/printer_port.dart';
import 'package:universal_ble/universal_ble.dart';

/// Candidate services for ESC/POS BLE printers, in the order they are tried.
///
/// No single standard is honoured by every cheap thermal printer: some expose the usual
/// "printer" service, others are ISSC/Microchip/HM-10 style serial modules with a
/// "transparent UART". These are the two the web app uses
/// (`apps/web/src/lib/pos-bluetooth-printer.ts`). A printer that uses a third
/// UUID is added here and nowhere else.
const candidateServiceUuids = [
  '000018f0-0000-1000-8000-00805f9b34fb',
  '49535343-fe7d-4ae5-8fa9-9fafd205e455',
];

/// The smallest chunk: the BLE default MTU of 23 less 3 bytes of header.
const minChunkBytes = 20;

/// The largest chunk, whatever was negotiated. Cheap printers stall around 185 bytes; the web
/// app (`MAX_CHUNK_BYTES`) stops at 180. The BLE library would happily offer up to 509, so
/// this cap is ours to enforce.
const maxChunkBytes = 180;

/// How many bytes of a document go into one write, given the negotiated [mtu].
///
/// The MTU less its 3 bytes of header, kept between [minChunkBytes] and [maxChunkBytes]. An
/// MTU that is unknown (`null`, or the negotiation failed) gets the smallest chunk.
int chunkSizeFor(int? mtu) {
  if (mtu == null) return minChunkBytes;
  return min(max(mtu - 3, minChunkBytes), maxChunkBytes);
}

/// [bytes] in pieces of at most [size], in order; the last holds whatever is left.
///
/// No bytes give no chunks, so nothing is written for nothing. The BLE library offers no
/// chunking of its own (its README shows a `splitWrite` snippet to copy), so this is ours.
List<Uint8List> splitChunks(Uint8List bytes, int size) {
  // A size that cannot advance would loop forever.
  if (size < 1) throw ArgumentError.value(size, 'size', 'must be at least 1');

  return [
    for (var start = 0; start < bytes.length; start += size)
      Uint8List.sublistView(bytes, start, min(start + size, bytes.length)),
  ];
}

/// What is wrong with Bluetooth as [state] reports it, or `null` when nothing is.
///
/// Exhaustive on purpose: a state the plugin adds later must be decided here, not fall
/// through to "fine".
PrinterFailure? failureForAvailability(AvailabilityState state) =>
    switch (state) {
      AvailabilityState.poweredOn => null,
      AvailabilityState.poweredOff => PrinterFailure.bluetoothOff,
      // Android reports `resetting` while the adapter turns on or off. The cashier's move is
      // the same as for "off": switch it on, wait, try again.
      AvailabilityState.resetting => PrinterFailure.bluetoothOff,
      AvailabilityState.unsupported => PrinterFailure.unsupported,
      // Android answers `unknown` when there is no adapter at all, which the source reported
      // as `bluetooth_unavailable` → `unsupported`. Reading it as "off" would tell a cashier
      // to switch on a radio the tablet does not have.
      AvailabilityState.unknown => PrinterFailure.unsupported,
      AvailabilityState.unauthorized => PrinterFailure.permissionDenied,
    };

/// Why a scan or connect failed, as the UI can translate it.
///
/// [otherwise] is what a failure this cannot name becomes: `scanFailed` for a scan,
/// `notConnected` for a connect. The three failures a cashier can act on keep their own
/// advice either way.
PrinterFailure failureFromBleError(
  Object error, {
  required PrinterFailure otherwise,
}) {
  // Not everything thrown is the plugin's; a bug elsewhere must not read as "Bluetooth is
  // off". `ConnectionException` is a `UniversalBleException`, so a failed connect is read
  // through the same `code`.
  if (error is! UniversalBleException) return otherwise;

  return switch (error.code) {
    UniversalBleErrorCode.bluetoothNotEnabled => PrinterFailure.bluetoothOff,
    UniversalBleErrorCode.bluetoothNotAvailable => PrinterFailure.unsupported,
    UniversalBleErrorCode.bluetoothNotAllowed ||
    UniversalBleErrorCode.bluetoothUnauthorized =>
      PrinterFailure.permissionDenied,
    _ => otherwise,
  };
}

/// Where to write, and how.
typedef WriteTarget = ({
  String service,
  String characteristic,
  bool withoutResponse,
});

/// The characteristic to write a document to, or `null` when the device is not a printer
/// this app knows how to talk to.
///
/// For each candidate service in order, the first characteristic that can be written to. The
/// order is the source's, not the device's. A write **with** response is chosen whenever the
/// characteristic offers one: the next chunk is sent when the write completes, and without an
/// acknowledgement that comes too early and the printer's buffer overflows.
WriteTarget? pickWriteTarget(List<BleService> services) {
  for (final candidate in candidateServiceUuids) {
    for (final service in services) {
      if (!BleUuidParser.compareStrings(service.uuid, candidate)) continue;

      for (final characteristic in service.characteristics) {
        final properties = characteristic.properties;
        final withResponse = properties.contains(CharacteristicProperty.write);
        final withoutResponse = properties.contains(
          CharacteristicProperty.writeWithoutResponse,
        );
        if (!withResponse && !withoutResponse) continue;

        return (
          service: candidate,
          characteristic: characteristic.uuid,
          withoutResponse: !withResponse,
        );
      }
    }
  }
  return null;
}
