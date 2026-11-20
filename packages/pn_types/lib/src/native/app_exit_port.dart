/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Leaves the app, the way the platform's own back or close would have.
///
/// A port because the real one goes through a platform channel, which does not exist under
/// `dart test`. It exists for the one exit the app has to finish itself: on Android, the back
/// press at the root is held so the cashier can first be reminded of an open shift, and once
/// they confirm, the app has to do what the back press would have done.
///
/// Pure types — no plugin import may appear here (`.claude/rules/native-ports.md` §2.1).
abstract interface class AppExitPort {
  /// Asks the platform to leave the app.
  ///
  /// Throws [AppExitException] when the platform refused or could not be reached.
  Future<void> exit();
}

/// The platform did not leave the app.
class AppExitException implements Exception {
  AppExitException(this.message, {this.cause});

  final String message;

  /// Whatever the platform threw, for a debugger. Never printed.
  final Object? cause;

  @override
  String toString() => 'AppExitException: $message';
}
