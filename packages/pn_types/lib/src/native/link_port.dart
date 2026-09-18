/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

/// An incoming App Link, delivered to a running or newly-started app.
///
/// Windows-only consumer today: the Android side deliberately has no link listener — the
/// lifecycle observer already covers the wake-up (`plan/api-client/findings.md` §Kenapa tidak
/// ada LinkPort). The port exists because the Windows intake is a plugin, and plugins do not
/// exist under `dart test` (`.claude/rules/native-ports.md` §1).
///
/// The link carries **no data** by design (`plan/pos-deeplink/README.md` §D1): it is a
/// "poll now" signal, nothing more. Nothing here parses or trusts its contents.
///
/// Pure types — no plugin import may appear here (`.claude/rules/native-ports.md` §2.1).
abstract interface class LinkPort {
  /// The link the app was started with, if any. Fires once per stream subscription.
  ///
  /// Windows delivers it as `argv[1]`; a normal launch (no link) yields nothing. Implementations
  /// merge this with [links] so a subscriber cannot miss a link that raced its subscription.
  Stream<Uri> get links;
}

/// The link listener could not be set up.
///
/// The message never carries the URL: it is not a secret, but exception text ends up in logs
/// and there is nothing in a link worth logging anyway.
class LinkException implements Exception {
  LinkException(this.message, {this.cause});

  final String message;

  /// Whatever the platform threw, for a debugger. Never printed.
  final Object? cause;

  @override
  String toString() => 'LinkException: $message';
}
