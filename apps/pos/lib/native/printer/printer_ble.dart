/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:typed_data';

import 'package:pn_types/src/native/printer_port.dart';
import 'package:pos/native/printer/printer_protocol.dart';
import 'package:universal_ble/universal_ble.dart';

/// The BLE printer, over `universal_ble`. The only class that calls the plugin.
class BlePrinter implements PrinterPort {
  /// The names scans showed, by address. The plugin has no way to ask a device for its name,
  /// and `pairPrinter` saves the name `connect` returns.
  final _names = <String, String>{};

  @override
  Future<List<PrinterDevice>> scan({
    Duration duration = defaultPrinterScanDuration,
  }) async {
    await ensureBluetoothPermission();
    await _ensureBluetoothOn(otherwise: PrinterFailure.scanFailed);

    // By address, in the order first seen. The same printer advertises many times during a
    // scan; writing over an existing key keeps its position and takes the latest name.
    final found = <String, PrinterDevice>{};
    // Listening starts before the scan does: a result that arrives first would be lost.
    final subscription = UniversalBle.scanStream.listen((result) {
      // A device with no name is noise (most beacons), and an advertisement that leaves the
      // name out must not erase one an earlier advertisement gave. A name that is the empty
      // string is still a name: the pairing list labels those.
      final name = result.name;
      if (name == null) return;
      _names[result.deviceId] = name;
      found[result.deviceId] = PrinterDevice(
        address: result.deviceId,
        name: name,
      );
    });
    try {
      // No service filter: many printers do not advertise their service UUID, so filtering
      // would hide the very printer being looked for.
      await UniversalBle.startScan();
      await Future<void>.delayed(duration);
    } catch (error) {
      throw PrinterException(
        failureFromBleError(error, otherwise: PrinterFailure.scanFailed),
      );
    } finally {
      // A scan left running drains the battery until the app is killed, so this runs whether
      // the scan worked or not.
      await _stopScan();
      await subscription.cancel();
    }
    return found.values.toList();
  }

  @override
  Future<PrinterDevice> connect(String address) async {
    await ensureBluetoothPermission();
    await _ensureBluetoothOn(otherwise: PrinterFailure.notConnected);

    // Every print reconnects by address, and Android caps GATT connections at about seven
    // per device, so the printer already held is not connected again.
    final held = _link;
    if (held != null && held.device.address == address) return held.device;

    // One link at a time, closed before the attempt: a failed connect leaves none, not even
    // the earlier one (the Android plugin does the same).
    await _closeLink();

    try {
      await UniversalBle.connect(address);
      final mtu = await _negotiateMtu(address);
      final services = await UniversalBle.discoverServices(address);

      // Connected, but not to anything that takes ESC/POS (`no_writable_characteristic`).
      final target = pickWriteTarget(services);
      if (target == null) throw PrinterException(PrinterFailure.notConnected);

      // A printer paired earlier is reconnected by address with no scan, so no name is
      // known; the address stands in, as the Android plugin's does.
      final device = PrinterDevice(
        address: address,
        name: _names[address] ?? address,
      );
      _link = (device: device, target: target, chunkSize: chunkSizeFor(mtu));
      // The printer can go out of range or off at any time. Without this the held link would
      // be returned as if it were up, and the next print would write into nothing.
      _watch = UniversalBle.connectionStream(address).listen((isUp) {
        if (isUp) return;
        _link = null;
        _watch?.cancel();
        _watch = null;
      });
      return device;
    } catch (error) {
      // A link left open after a failed setup would count against the seven, and the source
      // closes the GATT on every failure path so the next attempt does not inherit it.
      await _disconnect(address);
      if (error is PrinterException) rethrow;
      throw PrinterException(
        failureFromBleError(error, otherwise: PrinterFailure.notConnected),
      );
    }
  }

  @override
  Future<void> disconnect() => _closeLink();

  /// The link that is up: who it is to, where to write, and how much per write.
  _Link? _link;

  StreamSubscription<bool>? _watch;

  Future<void> _closeLink() async {
    final link = _link;
    _link = null;
    // Cancelled first: closing the link makes the plugin report it down, which is ours.
    await _watch?.cancel();
    _watch = null;
    if (link == null) return;
    await _disconnect(link.device.address);
  }

  @override
  Future<void> write(Uint8List bytes) async {
    // The Android plugin answers `not_connected`, which the port reports as `printFailed`.
    final link = _link;
    if (link == null) throw PrinterException(PrinterFailure.printFailed);

    // One document at a time (`write_in_progress` in the source). A double tap must not print
    // the receipt twice, and two documents must not interleave their chunks on the wire; the
    // library would queue the second, so it is refused here instead. Set before the first
    // `await`, so a call that starts while this one runs already sees it.
    if (_writing) throw PrinterException(PrinterFailure.printFailed);
    _writing = true;

    // Each chunk is awaited before the next goes out: `UniversalBle.write` finishes when the
    // characteristic write completes, which is the only correct moment to send more.
    try {
      for (final chunk in splitChunks(bytes, link.chunkSize)) {
        await UniversalBle.write(
          link.device.address,
          link.target.service,
          link.target.characteristic,
          chunk,
          withoutResponse: link.target.withoutResponse,
        );
      }
    } catch (_) {
      // Whatever the plugin says, the source turns it into `printFailed`, and the cashier's
      // move is the same: check the printer and try again. The exception stops the loop, so
      // no chunk goes out after the one that failed and the receipt has no hole in it.
      throw PrinterException(PrinterFailure.printFailed);
    } finally {
      _writing = false;
    }
  }

  bool _writing = false;
}

typedef _Link = ({PrinterDevice device, WriteTarget target, int chunkSize});

Future<void> _disconnect(String address) async {
  try {
    await UniversalBle.disconnect(address);
  } catch (_) {
    // `PrinterPort.disconnect` cannot fail, and having nothing to tear down is not a failure
    // the caller can act on. The link is forgotten either way.
  }
}

/// The MTU asked for right after connecting, before service discovery: on some devices it
/// must be settled first. A request, not a demand; the printer may answer with less.
const _requestedMtu = 512;

/// The MTU the printer agreed to, or `null` when it would not say. Whatever the outcome the
/// source moves on to discovery: a printer that will not negotiate can still print, in
/// smaller pieces.
Future<int?> _negotiateMtu(String address) async {
  try {
    return await UniversalBle.requestMtu(address, _requestedMtu);
  } catch (_) {
    return null;
  }
}

/// Throws [PrinterException] unless Bluetooth is on and usable.
///
/// [otherwise] is what a failure to even ask becomes: `scanFailed` for a scan, `notConnected`
/// for a connect.
Future<void> _ensureBluetoothOn({required PrinterFailure otherwise}) async {
  final AvailabilityState state;
  try {
    state = await UniversalBle.getBluetoothAvailabilityState();
  } catch (error) {
    throw PrinterException(failureFromBleError(error, otherwise: otherwise));
  }

  final failure = failureForAvailability(state);
  if (failure != null) throw PrinterException(failure);
}

Future<void> _stopScan() async {
  try {
    await UniversalBle.stopScan();
  } catch (_) {
    // What was found is the answer; failing to stop the radio afterwards is not a reason to
    // throw it away, and nothing a cashier could do about it.
  }
}

/// Makes sure Android's runtime Bluetooth permissions are held, asking when they are not.
///
/// Declaring them in the manifest is not enough from Android 12: a scan without the grant
/// fails, which the source once reported as "this runtime has no Bluetooth". Asking is cheap
/// when the grant is already held, but the check comes first so nothing crosses the platform
/// channel twice and no request is made without an Activity to show it.
///
/// Throws [PrinterException]: `permissionDenied` when the cashier refuses, `unsupported` when
/// the permissions cannot be checked at all.
Future<void> ensureBluetoothPermission() async {
  if (await _holdsBluetoothPermission()) return;

  try {
    await UniversalBle.requestPermissions();
  } catch (_) {
    // Not evidence of a refusal: the plugin reports one as code `failed` with a message,
    // the same code as any other failure, and a request racing another throws while the
    // grant lands. The check below is what decides.
  }

  if (!await _holdsBluetoothPermission()) {
    throw PrinterException(PrinterFailure.permissionDenied);
  }
}

/// Whether both Bluetooth permissions are held. The plugin reports "held" only when
/// BLUETOOTH_SCAN and BLUETOOTH_CONNECT both are, and neither alone can find a printer and
/// print to it, so anything short of both is a refusal.
///
/// A check that itself fails means the plugin is missing or the manifest does not declare
/// what it needs: nothing a cashier can fix, so `unsupported`.
Future<bool> _holdsBluetoothPermission() async {
  try {
    return await UniversalBle.hasPermissions();
  } catch (_) {
    throw PrinterException(PrinterFailure.unsupported);
  }
}
