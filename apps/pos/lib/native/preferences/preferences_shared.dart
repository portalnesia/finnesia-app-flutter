/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:pn_types/src/native/preferences_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [PreferencesPort] over `shared_preferences`.
///
/// The async API, not the cached one: a value written elsewhere is read as it is, and there is
/// no cache to preload before the first read.
///
/// A platform that cannot open its storage throws [PlatformException]; that becomes a
/// [PreferencesException], the one failure the callers know how to handle.
class SharedPrefs implements PreferencesPort {
  // Lazy: building it asks the plugin for its platform, and this object is created when
  // `active.dart` loads, before anything has needed a setting.
  late final _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read(String key) async {
    try {
      return await _prefs.getString(key);
    } on PlatformException catch (failure) {
      throw PreferencesException(
        'the setting could not be read',
        cause: failure,
      );
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } on PlatformException catch (failure) {
      throw PreferencesException(
        'the setting could not be saved',
        cause: failure,
      );
    }
  }
}
