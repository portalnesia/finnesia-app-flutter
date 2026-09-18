/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Where a Shorebird OTA check landed.
///
/// [restartRequired] is the only state the UI acts on: a patch finished downloading and takes
/// effect the next time the app restarts — nothing else needs a cashier's attention.
enum UpdaterStatus { upToDate, outdated, restartRequired }

/// Checks for a Shorebird OTA patch (Dart-only, no store review — `docs/distribution.md` §4).
///
/// A port because the real implementation is `package:shorebird_code_push`, which talks to a
/// native updater that only exists in a build made with `shorebird release`
/// (`.claude/rules/native-ports.md` §1.2). A debug build, or a release built without Shorebird,
/// answers [UpdaterStatus.upToDate] — never throws, and never anything for the cashier to act
/// on outside production.
///
/// Pure types — no plugin import may appear here (§2.1).
abstract interface class UpdaterPort {
  /// Checks for a new patch and starts downloading it if one is available. A second call after
  /// the download has finished reports [UpdaterStatus.restartRequired].
  Future<UpdaterStatus> checkForUpdate();
}
