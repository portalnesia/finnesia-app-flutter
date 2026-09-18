/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'printer_port.freezed.dart';

/// How long a scan runs unless the caller says otherwise. Scanning draws power, so it is
/// bounded rather than left as a background poll.
///
/// One constant for the port and every implementation: two defaults would drift.
const defaultPrinterScanDuration = Duration(seconds: 6);

/// Thermal printer port (BLE/GATT).
///
/// The tablet prints over Bluetooth Low Energy, not SPP: the printers this shop uses expose a
/// GATT service.
///
/// It carries **bytes**, not documents. ESC/POS is built by the formatters in `pn_pos`, so the
/// tablet and the web app put the same bytes on paper. Only the way those bytes travel
/// differs.
///
/// Every method reports failure as a [PrinterException], never a plugin's own exception.
///
/// Pure types — no plugin import may appear here (`.claude/rules/native-ports.md` §2.1).
abstract interface class PrinterPort {
  /// Devices advertising nearby, after a scan of [duration].
  ///
  /// An empty list is a real answer ("no printers nearby"), not a failure.
  Future<List<PrinterDevice>> scan({
    Duration duration = defaultPrinterScanDuration,
  });

  /// Opens the link to the printer at [address] and holds it until [disconnect].
  Future<PrinterDevice> connect(String address);

  /// Writes a complete byte stream.
  ///
  /// Chunking is the transport's job, not the caller's. `Uint8List`, not `List<int>`: ESC/POS
  /// is bytes, and `Uint8List` keeps every value inside 0–255.
  Future<void> write(Uint8List bytes);

  /// Tears the link down. Having nothing to tear down is not a failure.
  Future<void> disconnect();
}

/// A thermal printer, as a scan finds it and as the tablet remembers it.
@freezed
abstract class PrinterDevice with _$PrinterDevice {
  const factory PrinterDevice({
    /// The printer's stable identity: its MAC address on Android. This is what gets saved, so
    /// a reconnect after a restart does not depend on the printer still advertising a name.
    required String address,

    /// What the Menu shows, so a cashier can tell which printer is configured without
    /// walking over to read its label. May be empty.
    required String name,
  }) = _PrinterDevice;
}

/// Why printing could not happen, as something the UI can translate.
///
/// Ported from `PrinterFailureReason` in the same `port.ts`. Every name has a matching
/// `printer.<name>` translation key, so the UI renders it without a lookup table that drifts.
enum PrinterFailure {
  /// The device has no usable BLE adapter. Nothing a cashier can fix.
  unsupported,

  /// The ordinary tablet case: no printer paired yet, or it went out of range or off.
  notConnected,

  /// The link was up but the bytes did not go out.
  printFailed,

  /// The scan itself failed, for a reason that is none of the more specific ones below.
  scanFailed,

  /// Bluetooth access was refused. Fixable: grant it in Settings.
  permissionDenied,

  /// The radio is off. Fixable: switch it on. Needs different advice from [permissionDenied].
  bluetoothOff,
}

/// Printing could not happen. [reason] is what the UI translates.
///
/// Carries nothing else on purpose: exception text ends up in logs and crash reports, and a
/// printer's address is not something to put there.
class PrinterException implements Exception {
  PrinterException(this.reason);

  final PrinterFailure reason;

  @override
  String toString() => 'PrinterException: ${reason.name}';
}
