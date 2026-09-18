/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Which build of the app this is, as the platform reports it.
///
/// A port because the real one is a platform plugin, which does not exist under `dart test`
/// (`.claude/rules/native-ports.md` §1.2).
///
/// Pure types — no plugin import may appear here (§2.1).
abstract interface class AppInfoPort {
  /// The version and build number, or `null` when the platform could not say.
  ///
  /// `null` and not an exception: the version is only ever shown, so a platform that cannot name
  /// it leaves a blank where it would be, and nothing a caller could do about it.
  Future<AppVersion?> version();
}

/// `version` is what a person reads (`1.4.2`); `build` is what tells two APKs of it apart.
typedef AppVersion = ({String version, String build});
