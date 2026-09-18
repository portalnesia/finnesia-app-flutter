/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/preferences_port.dart';
import 'package:pos/native/preferences/preferences_shared.dart';

PreferencesPort get preferences => _preferences;
PreferencesPort _preferences = SharedPrefs();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setPreferences(PreferencesPort impl) => _preferences = impl;
