/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Sends crash and error reports (Firebase Crashlytics).
///
/// A port because the real one is a platform plugin, which does not exist under `dart test`
/// (`.claude/rules/native-ports.md` §1.2).
///
/// Never throws: reporting a crash must never cause a second one.
///
/// Pure types — no plugin import may appear here (§2.1).
abstract interface class CrashReportPort {
  /// Records [error] (and [stack], when there is one) as a non-fatal report, unless [fatal] is
  /// set. [reason] is shown alongside it in the Crashlytics console — never the cashier, never a
  /// token (`.claude/rules/security.md` §1).
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });

  /// Leaves a breadcrumb that is attached to the next report from this session.
  Future<void> log(String message);
}
