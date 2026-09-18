/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:in_app_update/in_app_update.dart' as play;
import 'package:pn_types/src/native/native_update_port.dart';

/// [NativeUpdatePort] over `package:in_app_update` (Play Core).
class PlayNativeUpdatePort implements NativeUpdatePort {
  @override
  Future<NativeUpdateStatus> checkForUpdate() async {
    try {
      final info = await play.InAppUpdate.checkForUpdate();
      if (info.installStatus == play.InstallStatus.downloaded) {
        return NativeUpdateStatus.readyToInstall;
      }
      if (info.updateAvailability == play.UpdateAvailability.updateAvailable &&
          info.flexibleUpdateAllowed) {
        // Fire-and-forget: a cashier must not wait on a download that can take minutes.
        // Play shows its own system consent prompt before it starts.
        unawaited(play.InAppUpdate.startFlexibleUpdate());
        return NativeUpdateStatus.outdated;
      }
      return NativeUpdateStatus.upToDate;
    } catch (_) {
      // Never throws (port contract). Includes every build the Play Core API rejects
      // outright: debug, sideloaded, iOS/Windows, or a release made before Play Console is
      // even set up (`docs/distribution.md` §0).
      return NativeUpdateStatus.upToDate;
    }
  }

  @override
  Future<void> completeUpdate() => play.InAppUpdate.completeFlexibleUpdate();
}
