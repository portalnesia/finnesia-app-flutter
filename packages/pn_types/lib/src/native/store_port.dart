/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Durable local key/value storage.
///
/// A port because storage is native: the real one writes through a platform plugin, which
/// does not exist under `dart test`. The session and the device identity both persist through
/// this one contract rather than each growing its own copy of the storage plumbing.
///
/// Values are strings. Dart has no `JSON.parse` that infers a type, and the caller knows the
/// shape best, so each caller encodes and decodes its own value — and decides what a value
/// that no longer decodes means. That decision lives with the caller, not the store: reading
/// corrupt data as absent is the convention, because throwing at startup would leave the app
/// with nothing rendered — worse than an unpaired device that at least says so.
///
/// Pure types — no plugin import may appear here (`.claude/rules/native-ports.md` §2.1).
abstract interface class StorePort {
  /// The value under [key], or `null` when there is none. The empty string is a value.
  ///
  /// Throws [StoreException] when the storage itself fails.
  Future<String?> read(String key);

  /// Stores [value] under [key], replacing any previous value.
  ///
  /// Throws [StoreException] when the storage itself fails; a failed write leaves the
  /// previous value in place.
  Future<void> write(String key, String value);

  /// Removes [key]. Removing a key that is not there is not an error.
  ///
  /// Throws [StoreException] when the storage itself fails.
  Future<void> remove(String key);
}

/// The storage failed: the disk is full, the platform plugin errored, the file is locked.
///
/// Not "the key is absent" (that is `null`) and not "the value is malformed" (that is the
/// caller's to decide). The source let these escape as untyped errors; a typed one lets the
/// caller tell a failing disk from a missing value — which matters, because treating a
/// transient read failure as "not paired" could send a cashier to re-pair a device that is
/// in fact paired.
class StoreException implements Exception {
  StoreException(this.message, {this.cause});

  final String message;

  /// Whatever the platform threw, for a debugger. Never printed.
  final Object? cause;

  @override
  String toString() => 'StoreException: $message';
}
