/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Opens a URL in the system browser.
///
/// A port because the real one is a platform plugin, which does not exist under `dart test`.
///
/// It is the system browser on purpose, never an in-app view: login depends on the OIDC session
/// living in the browser's cookie jar and never in the app's.
///
/// Pure types — no plugin import may appear here (`.claude/rules/native-ports.md` §2.1).
abstract interface class OpenerPort {
  /// Asks the OS to show [url] in the browser.
  ///
  /// Throws [OpenerException] when nothing could be opened: no browser is installed, or the
  /// platform refused the URL. Returning normally means the OS accepted the request, not that
  /// the page loaded.
  Future<void> openUrl(String url);
}

/// The URL could not be opened.
///
/// The message never carries the URL: a login URL holds a request id, and exception text ends
/// up in logs and crash reports.
class OpenerException implements Exception {
  OpenerException(this.message, {this.cause});

  final String message;

  /// Whatever the platform threw, for a debugger. Never printed.
  final Object? cause;

  @override
  String toString() => 'OpenerException: $message';
}
