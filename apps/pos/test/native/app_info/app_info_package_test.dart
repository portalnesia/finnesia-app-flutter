/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus_platform_interface/package_info_data.dart';
import 'package:package_info_plus_platform_interface/package_info_platform_interface.dart';
import 'package:pos/native/app_info/app_info_package.dart';

/// `package_info_plus`'s own seam: the platform interface it asks, with nothing behind it.
class _Platform extends PackageInfoPlatform {
  Object? failure;

  @override
  Future<PackageInfoData> getAll({String? baseUrl}) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return PackageInfoData(
      appName: 'Finnesia POS',
      packageName: 'com.finnesia.pos',
      version: '1.4.2',
      buildNumber: '37',
      buildSignature: '',
    );
  }
}

void main() {
  final platform = _Platform();
  PackageInfoPlatform.instance = platform;

  // The plugin keeps what it read for the life of the process, so a platform that failed can only
  // be shown before one that answered. The order below is the order that can be told apart.
  group('PackageInfoAppInfo', () {
    test(
      'says nothing when the platform cannot be asked, and does not throw',
      () async {
        platform.failure = PlatformException(code: 'unavailable');

        expect(await PackageInfoAppInfo().version(), isNull);
      },
    );

    test(
      'reports the version and the build number the platform gives',
      () async {
        platform.failure = null;

        final info = await PackageInfoAppInfo().version();

        expect(info?.version, '1.4.2');
        expect(info?.build, '37');
      },
    );
  });
}
