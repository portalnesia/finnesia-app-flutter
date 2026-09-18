/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/device_info_port.dart';
import 'package:pos/native/device_info/device_info_android.dart';

/// The platform's identifier for this installation.
DeviceInfoPort get deviceInfo => _deviceInfo;
DeviceInfoPort _deviceInfo = AndroidIdInfo();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setDeviceInfo(DeviceInfoPort impl) => _deviceInfo = impl;
