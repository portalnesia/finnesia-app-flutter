/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pn_types/src/native/device_info_port.dart';

/// [DeviceInfoPort] over `android_id`.
///
/// Not `device_info_plus`: that package **removed** its `androidId` getter in 4.0.0 "to avoid
/// Google Play policies violations" and points at this package instead (its own CHANGELOG,
/// §4.0.0/4.1.0). The `fingerprint` field it still exposes is `Build.FINGERPRINT` — the OS build
/// fingerprint, identical on every tablet of the same model and ROM — so using it would collide
/// every tablet in an outlet onto one device row.
///
/// The identifier is stable across reinstalls and app updates. It is **not** stable across a
/// factory reset, which is the honest limit of what Android offers.
///
/// The value is a credential to the server, so it never reaches a log, a crash report, or an
/// exception message.
class AndroidIdInfo implements DeviceInfoPort {
  AndroidIdInfo({
    this._androidId = const AndroidId(),
    DeviceInfoPlugin? plugin,
    TargetPlatform? platform,
  }) : _plugin = plugin ?? DeviceInfoPlugin(),
       _platform = platform ?? defaultTargetPlatform;

  /// The channel the plugin invokes. Named here so a test can stand in for the platform: the
  /// plugin exposes no platform-interface class to swap.
  static const channel = MethodChannel('android_id');

  final AndroidId _androidId;
  final DeviceInfoPlugin _plugin;
  final TargetPlatform _platform;

  @override
  Future<String?> androidId() async {
    final String? id;
    try {
      id = await _androidId.getId();
    } on PlatformException catch (failure) {
      // The platform was asked and failed. Reported as an exception rather than as `null`,
      // because the two lead to different behaviour in the caller: `null` falls back to a
      // fingerprint the app mints itself, while a failure must not, or a tablet whose platform
      // hiccuped once would register a second device row.
      throw DeviceInfoException(
        'the platform could not be asked',
        cause: failure,
      );
    } on MissingPluginException {
      // Not Android, or a build without the plugin: no identifier is the truthful answer. The
      // exception is not kept — it says nothing the caller can act on, and its text names the
      // channel rather than the device.
      return null;
    }
    // The plugin can answer with an empty string on a device that refuses to report one; that is
    // no identifier, not an identifier of "".
    if (id == null || id.isEmpty) return null;
    return id;
  }

  /// Never throws: this only fills the admin's device list, and a tablet that cannot say what it
  /// is must still be able to pair. The platform name comes from the build, not from the plugin,
  /// so it is there even when everything else is not.
  ///
  /// Windows has no model to give: `productName` is a product, not hardware, and the computer name
  /// is whatever its owner typed. The OS version is the build (`10.0.26220`), because Windows 11
  /// still reports major version 10.
  @override
  Future<DeviceDescription> describe() async {
    final platform = _platform.name;
    try {
      switch (_platform) {
        case TargetPlatform.android:
          final info = await _plugin.androidInfo;
          return (
            platform: platform,
            osVersion: info.version.release,
            deviceModel: '${info.manufacturer} ${info.model}',
          );
        case TargetPlatform.windows:
          final info = await _plugin.windowsInfo;
          return (
            platform: platform,
            osVersion:
                '${info.majorVersion}.${info.minorVersion}.${info.buildNumber}',
            deviceModel: null,
          );
        default:
          return (platform: platform, osVersion: null, deviceModel: null);
      }
    } on Exception {
      // Display-only, see above. A failing platform (`PlatformException`) and a missing plugin
      // (`MissingPluginException`) both mean the same thing here: nothing more to say.
      return (platform: platform, osVersion: null, deviceModel: null);
    }
  }
}
