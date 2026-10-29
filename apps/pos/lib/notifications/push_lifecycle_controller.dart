/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/push_token.dart';
import 'package:pn_types/src/native/device_info_port.dart';
import 'package:pn_types/src/native/push_messaging_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/device/device_identity.dart';
import 'package:pos/notifications/push_debug_log.dart';
import 'package:pos/session/session_holder.dart';

/// Coordinates native push delivery with the POS login without making it a login prerequisite.
class PushLifecycleController {
  PushLifecycleController({
    required this.client,
    required this.messaging,
    required this.session,
    required this.store,
    required this.deviceInfo,
    required this.locale,
  });

  final ApiClient client;
  final PushMessagingPort messaging;
  final SessionHolder session;
  final StorePort store;
  final DeviceInfoPort deviceInfo;
  final String Function() locale;

  final authorizationStatus = ValueNotifier(
    PushAuthorizationStatus.notDetermined,
  );
  final _openedMessages = StreamController<PushMessage>.broadcast();
  final _pendingOpens = <PushMessage>[];

  Stream<PushMessage> get openedMessages => _openedMessages.stream;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<PushMessage>? _openedSubscription;
  void Function()? _unsubscribeSession;
  Future<void>? _startTask;
  Future<void> _registrationQueue = Future<void>.value();
  String? _latestToken;
  String? _registeredToken;
  String? _registeredSessionToken;
  bool _available = false;
  bool _unregistering = false;
  bool _disposed = false;

  Future<void> start() {
    final existing = _startTask;
    if (existing != null) return existing;
    final task = _startOnce();
    _startTask = task;
    return task;
  }

  Future<void> _startOnce() async {
    try {
      _available = await messaging.initialize();
      logPushDebug('messaging initialized; available=$_available');
    } on Object catch (error) {
      logPushDebug('messaging initialization failed (${error.runtimeType})');
      _setAuthorizationStatus(PushAuthorizationStatus.unsupported);
      return;
    }
    if (!_available || _disposed) {
      _setAuthorizationStatus(PushAuthorizationStatus.unsupported);
      return;
    }

    _tokenSubscription = messaging.tokenRefreshes.listen(
      _receiveTokenRefresh,
      onError: (Object _) {
        // A refresh-stream failure must not interrupt the POS session.
      },
    );
    _openedSubscription = messaging.openedMessages.listen(
      _receiveOpen,
      onError: (Object _) {
        // Tap delivery is best-effort; a stream error must not close the till.
      },
    );
    _unsubscribeSession = session.subscribe(_sessionChanged);

    await refreshPermissionStatus();
    await _readInitialMessage();
  }

  /// Refreshes permission after returning from device Settings without showing a prompt.
  Future<void> refreshPermissionStatus() async {
    if (!_available || _disposed) return;
    try {
      _setAuthorizationStatus(await messaging.authorizationStatus());
    } on Object catch (error) {
      logPushDebug('permission status check failed (${error.runtimeType})');
      _setAuthorizationStatus(PushAuthorizationStatus.unsupported);
      return;
    }
    if (authorizationStatus.value.canReceivePush) {
      try {
        final token = await messaging.getToken();
        if (token == null || token.isEmpty) {
          logPushDebug('channel refresh returned no token');
          return;
        }
        _latestToken = token;
        await _queueRegistration();
      } on Object catch (error) {
        logPushDebug('channel refresh failed (${error.runtimeType})');
      }
    }
  }

  /// Requests OS permission only after an explicit cashier action.
  Future<PushAuthorizationStatus> requestPermission() async {
    await start();
    if (!_available || _disposed) {
      return PushAuthorizationStatus.unsupported;
    }
    try {
      final status = await messaging.requestPermission();
      _setAuthorizationStatus(status);
      if (status.canReceivePush) await _queueRegistration();
      return status;
    } on Object catch (error) {
      // A permission-sheet failure should leave login and checkout usable.
      logPushDebug('permission request failed (${error.runtimeType})');
      return authorizationStatus.value;
    }
  }

  /// Removes the current token before the caller clears the bearer session.
  Future<void> unregisterCurrentToken() async {
    await start();
    if (!_available || _disposed || !_isSignedIn(session.current)) return;
    _unregistering = true;
    await _registrationQueue;
    try {
      final token =
          _registeredToken ?? _latestToken ?? await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await PushTokenApi.unregister.call(client, (token: token));
    } on Object {
      // Logout must continue when the network is down; the backend also removes tokens on revoke.
    }
  }

  Future<void> _readInitialMessage() async {
    try {
      final message = await messaging.initialMessage();
      if (message != null) _receiveOpen(message);
    } on Object {
      // Cold-start routing is best-effort; the notification remains available in the inbox.
    }
  }

  void _receiveTokenRefresh(String token) {
    logPushDebug('token refresh received; token present=${token.isNotEmpty}');
    if (token.isEmpty || _disposed) return;
    _latestToken = token;
    unawaited(_queueRegistration());
  }

  void _receiveOpen(PushMessage message) {
    final notificationId = message.data['notification_id']?.trim();
    if (notificationId == null || notificationId.isEmpty || _disposed) return;

    final safeData = <String, String>{'notification_id': notificationId};
    final companyId = message.data['company_id']?.trim();
    if (companyId != null && companyId.isNotEmpty) {
      safeData['company_id'] = companyId;
    }
    final safeMessage = PushMessage(
      data: safeData,
      messageId: message.messageId,
    );

    if (_isSignedIn(session.current)) {
      _openedMessages.add(safeMessage);
      return;
    }
    if (_pendingOpens.length == 10) _pendingOpens.removeAt(0);
    _pendingOpens.add(safeMessage);
  }

  void _sessionChanged(PosSession? next) {
    if (!_isSignedIn(next)) {
      _registeredToken = null;
      _registeredSessionToken = null;
      _unregistering = false;
      return;
    }
    if (_unregistering) return;
    _flushPendingOpens();
    unawaited(_queueRegistration());
  }

  void _flushPendingOpens() {
    if (!_isSignedIn(session.current)) return;
    final pending = List<PushMessage>.of(_pendingOpens);
    _pendingOpens.clear();
    for (final message in pending) {
      _openedMessages.add(message);
    }
  }

  Future<void> _queueRegistration() {
    final next = _registrationQueue.then((_) => _registerCurrentToken());
    _registrationQueue = next;
    return next;
  }

  Future<void> _registerCurrentToken() async {
    if (_disposed) {
      logPushDebug('token registration skipped: controller disposed');
      return;
    }
    if (!_available) {
      logPushDebug('token registration skipped: messaging unavailable');
      return;
    }
    if (_unregistering) {
      logPushDebug('token registration skipped: unregister in progress');
      return;
    }
    if (!authorizationStatus.value.canReceivePush) {
      logPushDebug('token registration skipped: permission not granted');
      return;
    }
    final current = session.current;
    if (current == null || !_isSignedIn(current)) {
      logPushDebug('token registration skipped: no signed-in session');
      return;
    }

    try {
      final token = _latestToken ?? await messaging.getToken();
      if (token == null || token.isEmpty) {
        logPushDebug('token registration skipped: token unavailable');
        return;
      }
      if (token == _registeredToken &&
          current.sessionToken == _registeredSessionToken) {
        logPushDebug('token registration skipped: token already registered');
        return;
      }
      final deviceId = (await buildDeviceIdentity(
        store,
        deviceInfo,
      )).deviceFingerprint;
      final platform = (await deviceInfo.describe()).platform;
      logPushDebug('registering token; platform=$platform; app=pos');
      await PushTokenApi.register.call(client, (
        token: token,
        platform: platform,
        app: 'pos',
        deviceId: deviceId,
        locale: locale(),
      ));
      _latestToken = token;
      _registeredToken = token;
      _registeredSessionToken = current.sessionToken;
      logPushDebug('token registration request completed');
    } on Object catch (error) {
      // Registration is retried on token refresh or session change, never at the cost of a sale.
      final failure = error is ApiError
          ? 'HTTP ${error.status}'
          : error.runtimeType.toString();
      logPushDebug('token registration failed ($failure)');
    }
  }

  void _setAuthorizationStatus(PushAuthorizationStatus value) {
    if (_disposed || authorizationStatus.value == value) return;
    authorizationStatus.value = value;
    logPushDebug('permission status=${value.name}');
  }

  bool _isSignedIn(PosSession? value) =>
      value != null && value.sessionToken.isNotEmpty;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _unsubscribeSession?.call();
    unawaited(_tokenSubscription?.cancel() ?? Future<void>.value());
    unawaited(_openedSubscription?.cancel() ?? Future<void>.value());
    unawaited(_openedMessages.close());
    authorizationStatus.dispose();
  }
}
