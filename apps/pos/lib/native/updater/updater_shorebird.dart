/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:pn_types/src/native/updater_port.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;

/// [UpdaterPort] over `package:shorebird_code_push`.
class ShorebirdUpdaterPort implements UpdaterPort {
  final _updater = shorebird.ShorebirdUpdater();

  @override
  Future<UpdaterStatus> checkForUpdate() async {
    try {
      final status = await _updater.checkForUpdate();
      switch (status) {
        case shorebird.UpdateStatus.restartRequired:
          return UpdaterStatus.restartRequired;
        case shorebird.UpdateStatus.outdated:
          // Fire-and-forget: a cashier must not wait on a patch download. A failed download
          // (offline, Shorebird server down) is simply tried again on the next check.
          unawaited(_updater.update());
          return UpdaterStatus.outdated;
        case shorebird.UpdateStatus.upToDate:
        case shorebird.UpdateStatus.unavailable:
          // `unavailable`: not a build made with `shorebird release` (debug, or a plain
          // `flutter build`) — same as up to date, nothing for the cashier to act on. This is
          // what keeps the "update ready" banner production-only without an extra guard.
          return UpdaterStatus.upToDate;
      }
    } catch (_) {
      // Never throws (port contract): a broken OTA check must not take a sale down with it.
      return UpdaterStatus.upToDate;
    }
  }
}
