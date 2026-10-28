/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/push_token.dart';
import 'package:pn_types/src/native/device_info_port.dart';
import 'package:pn_types/src/native/push_messaging_port.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/session/session_holder.dart';

/// Coordinates FCM with the current POS login without making push a login prerequisite.
class PushLifecycleController {
  PushLifecycleController({
    required this.client,
    required this.messaging,
    required this.session,
    required this.deviceInfo,
    required this.locale,
  });

  final ApiClient client;
  final PushMessagingPort messaging;
  final SessionHolder session;
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
    } on Object {
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
    } on Object {
      _setAuthorizationStatus(PushAuthorizationStatus.unsupported);
      return;
    }
    if (authorizationStatus.value.canReceivePush) {
      await _queueRegistration();
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
    } on Object {
      // A permission-sheet failure should leave login and checkout usable.
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
      final token = await messaging.getToken() ?? _latestToken;
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
    if (_disposed || !_available || _unregistering) return;
    if (!authorizationStatus.value.canReceivePush) return;
    final current = session.current;
    if (current == null || !_isSignedIn(current)) return;

    try {
      final token = _latestToken ?? await messaging.getToken();
      if (token == null || token.isEmpty) return;
      if (token == _registeredToken &&
          current.sessionToken == _registeredSessionToken) {
        return;
      }
      final deviceId = await deviceInfo.androidId();
      await PushTokenApi.register.call(client, (
        token: token,
        platform: 'android',
        app: 'pos',
        deviceId: deviceId,
        locale: locale(),
      ));
      _latestToken = token;
      _registeredToken = token;
      _registeredSessionToken = current.sessionToken;
    } on Object {
      // Registration is retried on token refresh or session change, never at the cost of a sale.
    }
  }

  void _setAuthorizationStatus(PushAuthorizationStatus value) {
    if (_disposed || authorizationStatus.value == value) return;
    authorizationStatus.value = value;
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
