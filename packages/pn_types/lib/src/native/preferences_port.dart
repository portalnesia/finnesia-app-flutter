/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Small settings that belong to the tablet, not to a session: the language and the theme.
///
/// A port because the real one is a platform plugin, which does not exist under `dart test`
/// (`.claude/rules/native-ports.md` §1.2).
///
/// Nothing here may be something the cashier cannot afford to lose. The system can clear this
/// storage, which is why the offline queue lives in SQLite and not here
/// (`.claude/rules/project.md` §5).
///
/// Pure types — no plugin import may appear here (`.claude/rules/native-ports.md` §2.1).
abstract interface class PreferencesPort {
  /// The value stored under [key], or `null` when nothing was ever stored there.
  ///
  /// Throws [PreferencesException] when the storage cannot be read.
  Future<String?> read(String key);

  /// Stores [value] under [key], replacing what was there.
  ///
  /// Throws [PreferencesException] when the storage cannot be written.
  Future<void> write(String key, String value);
}

/// The preference storage could not be read or written.
class PreferencesException implements Exception {
  PreferencesException(this.message, {this.cause});

  final String message;

  /// Whatever the platform threw, for a debugger. Never printed.
  final Object? cause;

  @override
  String toString() => 'PreferencesException: $message';
}
