/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/notification_webview_port.dart';
import 'package:pos/native/notification_webview/in_app_notification_webview.dart';

NotificationWebViewPort get notificationWebView => _notificationWebView;
NotificationWebViewPort _notificationWebView = InAppNotificationWebView();

/// Replaces the implementation in tests; app startup uses the native implementation above.
void setNotificationWebView(NotificationWebViewPort impl) =>
    _notificationWebView = impl;
