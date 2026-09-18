/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Where a Play Store native-update check landed.
///
/// [readyToInstall] is the only state the UI acts on: a new APK/AAB has finished
/// downloading in the background and only needs the cashier's go-ahead to install.
enum NativeUpdateStatus { upToDate, outdated, readyToInstall }

/// Checks Google Play for a genuinely new native release (`docs/distribution.md` §5) —
/// **not** a Shorebird OTA patch. The two can never be confused: this reads the
/// versionCode Play has published, and a Shorebird patch never changes the installed app's
/// versionCode at all, so it is structurally invisible here.
///
/// A port because the real implementation is `package:in_app_update`, which talks to Play
/// Core and only works on a build installed **through** Google Play
/// (`.claude/rules/native-ports.md` §1.2). Any other build — debug, sideloaded, or a release
/// made before Play Console is even set up — answers [NativeUpdateStatus.upToDate]. Never
/// throws.
///
/// Pure types — no plugin import may appear here (§2.1).
abstract interface class NativeUpdatePort {
  /// Checks for a newer native release and starts a background download if one exists. A
  /// second call after the download finishes reports [NativeUpdateStatus.readyToInstall].
  Future<NativeUpdateStatus> checkForUpdate();

  /// Installs a downloaded update. The cashier chooses when — never automatic, since it
  /// restarts the app.
  Future<void> completeUpdate();
}
