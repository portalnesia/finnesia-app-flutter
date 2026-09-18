/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/app_info_port.dart';
import 'package:pos/native/app_info/app_info_package.dart';

/// Which build this is.
AppInfoPort get appInfo => _appInfo;
AppInfoPort _appInfo = PackageInfoAppInfo();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setAppInfo(AppInfoPort impl) => _appInfo = impl;
