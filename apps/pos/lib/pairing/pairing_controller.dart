/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/pairing_code.dart';
import 'package:pos/pairing/pairing.dart';
import 'package:pos/state/loadable.dart';

/// Why the last attempt to pair did not work, as something the screen can put in a sentence.
enum PairingProblem {
  invalidCode,
  codeRejected,
  unavailable,
  storage,
  deviceLimitReached,
}

/// The state behind the pairing screen: what was typed, whether a request is out, and why the
/// last one failed.
class PairingController extends ChangeNotifier with RequestGuard {
  PairingController(this._deps, {required this._analytics});

  // A function, not the value: the host follows the endpoint the developer picks on this very
  // screen, so it is read when the request is made.
  final PairingDeps Function() _deps;

  final AnalyticsPort _analytics;

  String _deviceName = '';
  String _code = '';
  bool _isSubmitting = false;
  PairingProblem? _problem;
  int? _deviceLimit;

  String get deviceName => _deviceName;
  String get code => _code;
  bool get isSubmitting => _isSubmitting;
  PairingProblem? get problem => _problem;

  /// How many tablets the outlet allows, when the last failure was the outlet limit. `null`
  /// otherwise, and when the server did not send the number.
  int? get deviceLimit => _deviceLimit;

  void setDeviceName(String value) {
    _deviceName = value;
    _problem = null;
    _deviceLimit = null;
    notifyListeners();
  }

  /// Takes the next value of the code field: capitals, no separators, never over six.
  void setCode(String raw) {
    _code = applyPairingCodeInput(raw, _code);
    // An edit answers the message: the cashier is already fixing what it said.
    _problem = null;
    _deviceLimit = null;
    notifyListeners();
  }

  /// Pairs with a code the camera read, and says whether it was one.
  ///
  /// The dashboard's QR encodes the code and nothing else (`qr_string`), so anything that does
  /// not have a code's shape is some other QR in front of the camera: it is refused without a
  /// word, and the field keeps what the cashier had typed. Ignored while a request is out, for
  /// the same reason a second tap on Pasangkan is.
  ///
  /// Answers at once and pairs in the background, so the camera can be closed the moment a code
  /// is taken rather than after the request: how it went shows on this screen, like a tap.
  bool useScannedCode(String raw) {
    final code = normalizePairingCode(raw);
    if (_isSubmitting || !isValidPairingCode(code)) return false;
    setCode(code);
    unawaited(submit());
    return true;
  }

  /// Pairs the device. Success saves the session, and the gate moves on by itself.
  ///
  /// Asked again while a request is out, it does nothing: a second tap must not register the
  /// tablet twice.
  Future<void> submit() async {
    if (_isSubmitting) return;
    final request = startRequest();
    _isSubmitting = true;
    _problem = null;
    _deviceLimit = null;
    notifyListeners();
    await _analytics.logEvent('pairing_started');

    try {
      await pairDevice(_code, _deps(), deviceName: _deviceName);
      await _analytics.logEvent('pairing_succeeded');
    } on PairingException catch (failure) {
      if (isCurrent(request)) {
        _problem = _problemOf(failure.reason);
        _deviceLimit = failure.deviceLimit;
      }
      // The category (`invalidCode`, `codeRejected`, ...), never the server's sentence —
      // `plan/firebase/README.md` §2.
      await _analytics.logEvent(
        'pairing_failed',
        parameters: {'reason': _problemOf(failure.reason).name},
      );
    } on StoreException {
      // The device could not keep what pairing needed to keep. Not the server's fault, and
      // "check the connection" would send the cashier the wrong way.
      if (isCurrent(request)) _problem = PairingProblem.storage;
      await _analytics.logEvent(
        'pairing_failed',
        parameters: {'reason': 'storage'},
      );
    } finally {
      // After a success the screen is usually gone already (the session changed under it), and
      // a disposed notifier must not be told anything.
      if (isCurrent(request)) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  PairingProblem _problemOf(PairingFailure reason) => switch (reason) {
    PairingFailure.invalidCode => PairingProblem.invalidCode,
    PairingFailure.codeRejected => PairingProblem.codeRejected,
    PairingFailure.unavailable => PairingProblem.unavailable,
    PairingFailure.deviceLimitReached => PairingProblem.deviceLimitReached,
  };
}
