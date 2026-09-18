/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/native_update_port.dart';
import 'package:pos/native/native_update/native_update_play.dart';

/// Checks Play Store for a native (APK/AAB) update.
NativeUpdatePort get nativeUpdate => _nativeUpdate;
NativeUpdatePort _nativeUpdate = PlayNativeUpdatePort();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setNativeUpdate(NativeUpdatePort impl) => _nativeUpdate = impl;
