/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Reads the platform's identifier for this installation.
///
/// A port because the real one is a platform plugin, which does not exist under `dart test`
/// (`.claude/rules/native-ports.md` §1.2, where it is listed as `DeviceInfoPort`).
///
/// It exists for exactly one purpose: the device fingerprint the backend upserts on. A value the
/// app invents itself lives in the app's own storage, so an uninstall takes it with it and the
/// same physical tablet comes back as a new device — which is what the fingerprint must not do
/// (`plan/pos-device-registry/01-kontrak-aplikasi-android.md` §3.5).
///
/// Pure types — no plugin import may appear here (§2.1).
abstract interface class DeviceInfoPort {
  /// The platform's stable identifier for this installation, or `null` when the platform has
  /// none (a desktop build, or a device that refuses to report one).
  ///
  /// `null` is an ordinary answer, not an error: the caller falls back to an identifier it mints
  /// and stores itself, which is worse across reinstalls but still a working device.
  ///
  /// Throws [DeviceInfoException] when the platform call itself fails. That is **not** the same
  /// as `null`: a failing platform may have a perfectly good identifier behind it, and treating
  /// the failure as "no identifier" would quietly mint a throwaway fingerprint and register a
  /// duplicate device row.
  Future<String?> androidId();

  /// What this device is, for the admin who reads the device list. Display-only: nothing
  /// depends on it, so it never throws. A platform that cannot say leaves the parts it cannot
  /// name as `null`.
  Future<DeviceDescription> describe();
}

/// `platform` is lower-case and always known (`android`, `windows`); the rest is whatever the
/// platform would say.
typedef DeviceDescription = ({
  String platform,
  String? osVersion,
  String? deviceModel,
});

/// The platform could not be asked for its identifier.
///
/// The message never carries the identifier: it identifies the tablet to the server, and
/// exception text ends up in logs and crash reports.
class DeviceInfoException implements Exception {
  DeviceInfoException(this.message, {this.cause});

  final String message;

  /// Whatever the platform threw, for a debugger. Never printed.
  final Object? cause;

  @override
  String toString() => 'DeviceInfoException: $message';
}
