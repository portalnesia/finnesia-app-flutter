/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/native/push_messaging_port.dart';
import 'package:pos/native/push_messaging/android_firebase_push_messaging.dart';
import 'package:pos/native/push_messaging/unsupported_push_messaging.dart';

PushMessagingPort get pushMessaging => _pushMessaging;
PushMessagingPort _pushMessaging = _createPushMessaging();

PushMessagingPort _createPushMessaging() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidFirebasePushMessaging();
  }
  return UnsupportedPushMessaging();
}

/// Called after Firebase initialization; only Android needs an FCM background callback.
void registerPushBackgroundHandler() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    registerAndroidPushBackgroundHandler();
  }
}

/// Replaces the port in tests; app startup uses the selected platform implementation.
void setPushMessaging(PushMessagingPort implementation) =>
    _pushMessaging = implementation;
