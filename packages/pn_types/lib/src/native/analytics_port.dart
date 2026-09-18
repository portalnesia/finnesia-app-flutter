/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Logs product-usage events (screen views, checkout, shift open/close, ...).
///
/// A port because the real one is a platform plugin (Firebase Analytics), which does not exist
/// under `dart test` (`.claude/rules/native-ports.md` §1.2).
///
/// Never throws: losing an event must never take a sale down with it. A platform that could not
/// log stays silent — the real implementation is where that swallowing happens, not here.
///
/// Pure types — no plugin import may appear here (§2.1).
abstract interface class AnalyticsPort {
  /// Logs [name] with [parameters]. Values follow Firebase Analytics' own restriction: `String`,
  /// `num`, or `bool` — no `null`, no nested maps.
  Future<void> logEvent(String name, {Map<String, Object>? parameters});
}
