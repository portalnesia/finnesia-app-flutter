/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/updater_port.dart';
import 'package:pos/native/updater/updater_shorebird.dart';

/// Checks for a Shorebird OTA patch.
UpdaterPort get updater => _updater;
UpdaterPort _updater = ShorebirdUpdaterPort();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setUpdater(UpdaterPort impl) => _updater = impl;
