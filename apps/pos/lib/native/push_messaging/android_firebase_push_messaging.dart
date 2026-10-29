/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pn_types/src/native/push_messaging_port.dart';
import 'package:pos/firebase_options.dart';
import 'package:pos/notifications/push_debug_log.dart';

const _channelId = 'finnesia_pos_notifications';
const _channelName = 'Finnesia POS';
const _channelDescription = 'Notifications from your Finnesia POS account.';
const _androidInitialization = InitializationSettings(
  android: AndroidInitializationSettings('@mipmap/ic_launcher'),
);
const _androidNotificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDescription,
    importance: Importance.high,
    priority: Priority.high,
  ),
);

/// Receives FCM data while Android has the app backgrounded or terminated.
///
/// The backend sends data-only messages, so Android does not display these on its own. We create
/// a local notification only in the background; foreground messages are intentionally silent so
/// an active checkout is never covered by a push banner.
@pragma('vm:entry-point')
Future<void> firebasePushBackgroundMessageHandler(RemoteMessage message) async {
  logPushDebug(
    'background message received; notification present=${message.notification != null}; data field count=${message.data.length}',
  );
  if (message.notification != null) {
    logPushDebug('background message ignored: notification payload present');
    return;
  }
  final payload = _tapPayload(message.data);
  if (payload == null) {
    logPushDebug(
      'background message ignored: notification id present=${message.data.containsKey('notification_id')}',
    );
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logPushDebug('background Firebase initialized');
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(settings: _androidInitialization);
    final title = _stringValue(message.data['title']);
    final body = _stringValue(message.data['body']);
    final titlePresent = title != null && title.isNotEmpty;
    final bodyPresent = body != null && body.isNotEmpty;
    logPushDebug(
      'background display text present; title=$titlePresent; body=$bodyPresent',
    );
    if (!titlePresent && !bodyPresent) {
      logPushDebug('background notification skipped: display text unavailable');
      return;
    }
    await notifications.show(
      id: (message.messageId?.hashCode ?? message.hashCode) & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: _androidNotificationDetails,
      payload: payload,
    );
    logPushDebug('background local notification displayed');
  } on Object catch (error) {
    // Notifications are best-effort; a plugin failure must not crash the POS process.
    logPushDebug(
      'background notification handling failed (${error.runtimeType})',
    );
  }
}

/// Registers the top-level callback from the single Android composition root.
void registerAndroidPushBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebasePushBackgroundMessageHandler);
  logPushDebug('Android background message handler registered');
}

/// Android FCM and local-notification adapter. Other platforms use the unsupported port.
class AndroidFirebasePushMessaging implements PushMessagingPort {
  AndroidFirebasePushMessaging({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notifications;
  final _opened = StreamController<PushMessage>.broadcast();
  bool _initialized = false;
  PushMessage? _initial;

  @override
  Stream<String> get tokenRefreshes =>
      FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<PushMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(_fromRemoteMessage);

  @override
  Stream<PushMessage> get openedMessages => _opened.stream;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      if (!await FirebaseMessaging.instance.isSupported()) {
        logPushDebug('FCM unsupported on Android runtime');
        return false;
      }
      final initialized = await _notifications.initialize(
        settings: _androidInitialization,
        onDidReceiveNotificationResponse: _onLocalNotificationResponse,
      );
      if (initialized != true) {
        logPushDebug('local notification initialization failed');
        return false;
      }

      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _opened.add(_fromRemoteMessage(message)),
        onError: (Object _) {
          // A stream failure must not interfere with login or checkout.
        },
      );

      final localLaunch = await _notifications
          .getNotificationAppLaunchDetails();
      if (localLaunch?.didNotificationLaunchApp == true) {
        _initial = _decodeTapPayload(
          localLaunch?.notificationResponse?.payload,
        );
      }
      final remoteLaunch = await FirebaseMessaging.instance.getInitialMessage();
      if (remoteLaunch != null) _initial = _fromRemoteMessage(remoteLaunch);

      _initialized = true;
      logPushDebug('Android push messaging initialized');
      return true;
    } on Object catch (error) {
      logPushDebug('Android push initialization failed (${error.runtimeType})');
      return false;
    }
  }

  @override
  Future<PushAuthorizationStatus> authorizationStatus() async =>
      _mapAuthorizationStatus(
        (await FirebaseMessaging.instance.getNotificationSettings())
            .authorizationStatus,
      );

  @override
  Future<PushAuthorizationStatus> requestPermission() async =>
      _mapAuthorizationStatus(
        (await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        )).authorizationStatus,
      );

  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  @override
  Future<PushMessage?> initialMessage() async {
    final message = _initial;
    _initial = null;
    return message;
  }

  void _onLocalNotificationResponse(NotificationResponse response) {
    final message = _decodeTapPayload(response.payload);
    if (message != null) _opened.add(message);
  }
}

PushAuthorizationStatus _mapAuthorizationStatus(AuthorizationStatus status) =>
    switch (status) {
      AuthorizationStatus.notDetermined =>
        PushAuthorizationStatus.notDetermined,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently => PushAuthorizationStatus.denied,
      AuthorizationStatus.authorized => PushAuthorizationStatus.authorized,
      AuthorizationStatus.provisional => PushAuthorizationStatus.provisional,
    };

PushMessage _fromRemoteMessage(RemoteMessage message) {
  final data = <String, String>{};
  for (final entry in message.data.entries) {
    final value = _stringValue(entry.value);
    if (value != null) data[entry.key] = value;
  }
  return PushMessage(data: data, messageId: message.messageId);
}

String? _tapPayload(Map<String, dynamic> data) {
  final notificationId = _stringValue(data['notification_id'])?.trim();
  if (notificationId == null || notificationId.isEmpty) return null;
  final safeData = <String, String>{'notification_id': notificationId};
  final companyId = _stringValue(data['company_id'])?.trim();
  if (companyId != null && companyId.isNotEmpty) {
    safeData['company_id'] = companyId;
  }
  return jsonEncode(safeData);
}

PushMessage? _decodeTapPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) return null;
    final notificationId = decoded['notification_id'];
    if (notificationId is! String || notificationId.trim().isEmpty) return null;
    final data = <String, String>{'notification_id': notificationId.trim()};
    final companyId = decoded['company_id'];
    if (companyId is String && companyId.trim().isNotEmpty) {
      data['company_id'] = companyId.trim();
    }
    return PushMessage(data: data);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

String? _stringValue(Object? value) => value is String ? value : null;
