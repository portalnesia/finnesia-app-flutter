/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pos/printer/printer_service.dart';

/// Where pairing a printer has got to (S15).
sealed class PairingState {
  const PairingState();
}

/// Nothing asked yet: a scan draws power, so it starts when the cashier says, not on open.
final class PairingIdle extends PairingState {
  const PairingIdle();
}

final class PairingScanning extends PairingState {
  const PairingScanning();
}

/// The link to [device] is being opened. Slow enough to see: a printer that is off takes seconds
/// to give up.
final class PairingConnecting extends PairingState {
  const PairingConnecting(this.device);

  final PrinterDevice device;
}

/// The scan is over. An empty list is an answer, not a failure.
final class PairingFound extends PairingState {
  const PairingFound(this.devices);

  final List<PrinterDevice> devices;
}

/// Which part of pairing went wrong: the sheet words the same [PrinterFailure] differently for
/// each ("could not scan" is no help to someone whose printer refused to connect).
enum PairingStep { scan, connect }

final class PairingFailed extends PairingState {
  const PairingFailed(this.reason, this.step);

  final PrinterFailure reason;
  final PairingStep step;
}

/// Connected and remembered. [device] is what the connection reported, which is what was saved.
final class PairingDone extends PairingState {
  const PairingDone(this.device);

  final PrinterDevice device;
}

/// The printer answered but the tablet could not write it down, so the next launch would not
/// know it. Not [PairingFailed]: telling a cashier the printer "would not connect" when it did
/// sends them to check a printer that is fine.
final class PairingSaveFailed extends PairingState {
  const PairingSaveFailed(this.device);

  final PrinterDevice device;
}

/// Runs the pairing of one printer: find, choose, connect, remember.
///
/// Holds the state and nothing of how it looks: the sheet draws it.
class PrinterPairingController extends ChangeNotifier {
  PrinterPairingController({
    required this.printer,
    required this.store,
    required this._analytics,
  });

  final PrinterPort printer;
  final StorePort store;
  final AnalyticsPort _analytics;

  PairingState _state = const PairingIdle();
  PairingState get state => _state;

  var _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _set(PairingState next) {
    // A scan or a connect outlives the sheet that asked for it, and cannot be called off: a
    // cashier who closes the sheet while it runs must not get a notification into a screen that
    // is gone.
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  /// Whether a scan or a connect is running. The sheet leaves its buttons alone until it is not.
  bool get isBusy => _state is PairingScanning || _state is PairingConnecting;

  Future<void> scan() async {
    // A second tap while the first is still running would start a second radio scan, or a
    // second connect against a printer that is already being connected to.
    if (isBusy) return;
    _set(const PairingScanning());
    try {
      _set(PairingFound(await printer.scan()));
    } on PrinterException catch (failure) {
      _set(PairingFailed(failure.reason, PairingStep.scan));
    }
  }

  Future<void> pair(PrinterDevice device) async {
    if (isBusy) return;
    _set(PairingConnecting(device));
    await _analytics.logEvent('printer_pairing_started');
    try {
      final connected = await printer.connect(device.address);
      if (_disposed) {
        // The cashier closed the sheet while it connected: they walked away from this printer, so
        // it is not remembered, and the link is not left open to a printer nobody has chosen.
        await printer.disconnect();
        return;
      }
      await rememberPrinter(connected, store);
      _set(PairingDone(connected));
      await _analytics.logEvent('printer_paired');
    } on PrinterException catch (failure) {
      _set(PairingFailed(failure.reason, PairingStep.connect));
      await _analytics.logEvent(
        'printer_pairing_failed',
        parameters: {'reason': failure.reason.name},
      );
    } on StoreException {
      _set(PairingSaveFailed(device));
      await _analytics.logEvent(
        'printer_pairing_failed',
        parameters: {'reason': 'storage'},
      );
    }
  }
}
