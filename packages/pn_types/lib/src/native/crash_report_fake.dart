/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'crash_report_port.dart';

/// A [CrashReportPort] for tests: records every error and every breadcrumb it is asked to report.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). No failure path: the port's contract is that it never
/// throws (§4 — a fake needs one only where the port can fail).
class FakeCrashReport implements CrashReportPort {
  /// Every error received, in order.
  final recorded =
      <({Object error, StackTrace? stack, String? reason, bool fatal})>[];

  /// Every breadcrumb received, in order.
  final logged = <String>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    recorded.add((error: error, stack: stack, reason: reason, fatal: fatal));
  }

  @override
  Future<void> log(String message) async {
    logged.add(message);
  }
}
