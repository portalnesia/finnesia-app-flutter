/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'device_info_port.dart';

/// A [DeviceInfoPort] for tests.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). Fails on request: a fake that can only succeed never
/// exercises what the caller does about a failing platform (§4).
class FakeDeviceInfo implements DeviceInfoPort {
  FakeDeviceInfo({this.id = 'fake_android_id'});

  /// What [androidId] answers. `null` is a platform with no identifier — an ordinary answer.
  String? id;

  /// What [describe] answers.
  DeviceDescription description = (
    platform: 'android',
    osVersion: '14',
    deviceModel: 'samsung SM-X110',
  );

  /// When set, [androidId] throws it instead of answering.
  DeviceInfoException? failure;

  /// Every call received.
  var calls = 0;

  @override
  Future<String?> androidId() async {
    calls++;
    final failure = this.failure;
    if (failure != null) throw failure;
    return id;
  }

  @override
  Future<DeviceDescription> describe() async => description;
}
