/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pos/native/push_messaging/android_firebase_push_messaging.dart';

void main() {
  test('uses the POS monochrome drawable for Android notification icon', () {
    expect(
      androidPushNotificationInitializationSettings.android?.defaultIcon,
      'ic_launcher_monochrome',
    );
  });
}
