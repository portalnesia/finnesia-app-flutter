/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pn_types/src/native/store_port.dart';

/// [StorePort] over `flutter_secure_storage`: values are encrypted with a key held by the
/// Android Keystore, so the session — which holds a bearer token and a refresh token — is not
/// readable from the app's data files, from a backup, or by another app.
///
/// Why this and not `shared_preferences`: that stores plain text, and can be cleared by the
/// system (`.claude/rules/project.md` §5). The token is the credential of a cashier at a till.
///
/// A failing Keystore is a [StoreException], never a missing value. It does happen: a Keystore
/// key does not survive a backup restore or some OEM resets, and the encrypted value then cannot
/// be read. `StorePort` says that is not "the key is absent" — reading it as "not paired" could
/// send a cashier to re-pair a device that is in fact paired. The exception carries the
/// platform's own error only as its cause: the platform's message can hold the key or the value.
class SecureStore implements StorePort {
  SecureStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _guard(
    'the stored value could not be read',
    () => _storage.read(key: key),
  );

  @override
  Future<void> write(String key, String value) => _guard(
    'the value could not be stored',
    () => _storage.write(key: key, value: value),
  );

  @override
  Future<void> remove(String key) => _guard(
    'the stored value could not be removed',
    () => _storage.delete(key: key),
  );

  Future<T> _guard<T>(String message, Future<T> Function() operation) async {
    try {
      return await operation();
    } on PlatformException catch (failure) {
      throw StoreException(message, cause: failure);
    }
  }
}
