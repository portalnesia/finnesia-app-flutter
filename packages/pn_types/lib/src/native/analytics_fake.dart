/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'analytics_port.dart';

/// An [AnalyticsPort] for tests: records every event it is asked to log.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). No failure path: the port's contract is that it never
/// throws (§4 — a fake needs one only where the port can fail).
class FakeAnalytics implements AnalyticsPort {
  /// Every `(name, parameters)` pair received, in order.
  final logged = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    logged.add((name, parameters));
  }
}
