/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pn_types/src/native/app_info_port.dart';

/// [AppInfoPort] over `package_info_plus`.
class PackageInfoAppInfo implements AppInfoPort {
  @override
  Future<AppVersion?> version() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return (version: info.version, build: info.buildNumber);
    } on PlatformException {
      // Only shown, never acted on (the port's contract): a blank is the whole cost.
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
