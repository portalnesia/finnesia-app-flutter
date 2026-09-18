/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:collection';
import 'dart:typed_data';

import 'printer_port.dart';

/// Which [PrinterPort] method a queued failure applies to.
enum PrinterOp { scan, connect, write, disconnect }

/// A [PrinterPort] for tests: finds the devices it was given, records what it was asked to
/// do, and can be told to fail.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). Fails on request (§4: a fake with no failure path
/// never exercises what the caller does about one).
class FakePrinter implements PrinterPort {
  /// [devices] is what a scan finds. Copied, so later edits to the list a test passed in do
  /// not leak into the fake.
  FakePrinter([List<PrinterDevice> devices = const []])
    : _devices = List.of(devices);

  final List<PrinterDevice> _devices;

  /// The duration of every scan received, in order.
  final scanDurations = <Duration>[];

  /// Every call received, in order — the ones that failed too.
  final operations = <PrinterOp>[];

  /// What was actually sent: one entry per successful [write], a copy of the bytes.
  final written = <Uint8List>[];

  final _failures = <PrinterOp, Queue<PrinterException>>{};

  /// Makes the next [op] throw [failure]. Per operation: a queued write failure does not
  /// touch a connect.
  ///
  /// Not for [PrinterOp.disconnect]: `PrinterPort.disconnect` cannot fail, and a fake that
  /// could would have callers grow a catch they never need.
  void failNext(PrinterOp op, PrinterException failure) {
    if (op == PrinterOp.disconnect) {
      throw ArgumentError.value(op, 'op', 'disconnect cannot fail');
    }
    (_failures[op] ??= Queue()).add(failure);
  }

  void _failIfQueued(PrinterOp op) {
    final queue = _failures[op];
    if (queue != null && queue.isNotEmpty) throw queue.removeFirst();
  }

  @override
  Future<List<PrinterDevice>> scan({
    Duration duration = defaultPrinterScanDuration,
  }) async {
    operations.add(PrinterOp.scan);
    scanDurations.add(duration);
    _failIfQueued(PrinterOp.scan);
    return List.unmodifiable(_devices);
  }

  /// The address the link is up to, or `null` when there is none.
  String? get connectedAddress => _connectedAddress;
  String? _connectedAddress;

  @override
  Future<PrinterDevice> connect(String address) async {
    operations.add(PrinterOp.connect);
    // Closed before the attempt, as the Android plugin does: a failed connect leaves no link.
    _connectedAddress = null;
    _failIfQueued(PrinterOp.connect);
    _connectedAddress = address;
    // The name falls back to the address, as the plugin's does for a printer that is not
    // advertising one.
    return _devices.firstWhere(
      (device) => device.address == address,
      orElse: () => PrinterDevice(address: address, name: address),
    );
  }

  @override
  Future<void> write(Uint8List bytes) async {
    operations.add(PrinterOp.write);
    _failIfQueued(PrinterOp.write);
    // The Android plugin answers `not_connected`, which the port reports as `printFailed`.
    if (_connectedAddress == null)
      throw PrinterException(PrinterFailure.printFailed);
    written.add(Uint8List.fromList(bytes));
  }

  @override
  Future<void> disconnect() async {
    operations.add(PrinterOp.disconnect);
    _connectedAddress = null;
  }
}
