/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';

/// Where the paired printer lives in the local store.
const printerKey = 'printer_device';

/// The printer this tablet has been paired with, or `null` when there is none.
///
/// Only the address and the name: the address is the identity a reconnect needs, and the name
/// is what the Menu shows so a cashier can tell which printer is configured without walking
/// over to read its label.
///
/// What is stored but no longer a printer — not JSON, the wrong shape, an address that is not
/// a non-empty string — reads as no printer and does not throw: the Menu asks at startup, and
/// one that dies here shows nothing, worse than an unconfigured printer that at least says so.
/// A name that is missing or not a string reads as `''`; it is only a label.
///
/// A failing *store* is different and is not swallowed: [StoreException] passes through.
/// Reading a transient failure as "no printer" would send a cashier to pair one that is in
/// fact paired.
Future<PrinterDevice?> readSavedPrinter(StorePort store) async {
  final raw = await store.read(printerKey);
  return raw == null ? null : _decode(raw);
}

PrinterDevice? _decode(String raw) {
  try {
    final json = jsonDecode(raw);
    if (json case {'address': final String address} when address.isNotEmpty) {
      final name = json['name'];
      return PrinterDevice(address: address, name: name is String ? name : '');
    }
    return null;
  } on FormatException {
    return null;
  }
}

/// Pairs a printer and remembers it, so the next print has nothing to pick.
///
/// What is saved is what the connection reported, not what was passed in: the name a scan
/// showed can differ, and the Menu shows what was saved. A printer that would not connect is
/// not remembered — the failure goes to the caller as it is, before anything is written.
Future<PrinterDevice> pairPrinter(
  PrinterDevice device, {
  required PrinterPort printer,
  required StorePort store,
}) async {
  final connected = await printer.connect(device.address);
  await rememberPrinter(connected, store);
  return connected;
}

/// Writes [device] as the paired printer. Split out of [pairPrinter] for a caller that has to
/// decide, between connecting and remembering, that the pairing is no longer wanted.
Future<void> rememberPrinter(PrinterDevice device, StorePort store) =>
    store.write(
      printerKey,
      jsonEncode({'address': device.address, 'name': device.name}),
    );

/// Forgets the paired printer and drops the link to it.
///
/// The link goes too, as the web's `forgetPrinter` does: forgetting a printer while staying
/// connected to it would leave a link nothing can reach and a GATT slot taken.
Future<void> clearPrinter({
  required PrinterPort printer,
  required StorePort store,
}) async {
  await printer.disconnect();
  await store.remove(printerKey);
}

/// Prints a document, connecting first: the BLE link does not survive a restart, and
/// re-pairing on every print would make the button useless, so the saved address is
/// reconnected on its own.
///
/// Throws [PrinterException] with the reason the port gave. `notConnected` also when no
/// printer is saved, which the UI turns into an offer to pair (the web signals that with
/// `false` so its caller can fall back to CSS; a tablet has no such fallback).
///
/// The source wrapped the connect in `catch { throw PrinterError('notConnected') }`, which
/// threw away the reason its own port had worked out: a cashier with Bluetooth off read
/// "switch the printer on", advice that cannot help, when `printer.bluetoothOff` had been
/// written for exactly that. Nothing is caught here. The port promises a [PrinterException],
/// and anything else is a bug that should not be dressed up as "not connected".
Future<void> printDocument(
  Uint8List bytes, {
  required PrinterPort printer,
  required StorePort store,
}) async {
  final saved = await readSavedPrinter(store);
  if (saved == null) throw PrinterException(PrinterFailure.notConnected);

  await printer.connect(saved.address);
  await printer.write(bytes);
}
