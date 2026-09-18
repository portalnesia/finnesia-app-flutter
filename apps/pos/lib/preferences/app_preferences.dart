/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_types/src/native/preferences_port.dart';
import 'package:pos/preferences/enum_preference.dart';

/// The interface languages. The [name] is what is stored and what the API receives as
/// `Accept-Language`, so a name is never changed once a build has written it.
enum AppLanguage {
  id,
  en;

  Locale get locale => Locale(name);
}

/// Indonesian unless the cashier picks another (owner decision D9).
EnumPreference<AppLanguage> languagePreference(PreferencesPort port) =>
    EnumPreference(
      port: port,
      key: 'language',
      values: AppLanguage.values,
      fallback: AppLanguage.id,
    );

/// The system's choice until the cashier makes their own (README §2.1).
EnumPreference<ThemeMode> themePreference(PreferencesPort port) =>
    EnumPreference(
      port: port,
      key: 'theme',
      values: ThemeMode.values,
      fallback: ThemeMode.system,
    );
