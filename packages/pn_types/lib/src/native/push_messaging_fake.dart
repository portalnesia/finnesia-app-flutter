/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'push_messaging_port.dart';

/// A [PushMessagingPort] fake that records calls and lets tests drive native events.
class FakePushMessaging implements PushMessagingPort {
  bool initializeResult = true;
  PushAuthorizationStatus status = PushAuthorizationStatus.notDetermined;
  PushAuthorizationStatus permissionResult =
      PushAuthorizationStatus.notDetermined;
  String? token = 'fcm-token-1';
  PushMessage? launchMessage;
  var initializeCalls = 0;
  var permissionStatusCalls = 0;
  var requestPermissionCalls = 0;
  var tokenCalls = 0;
  var initialMessageCalls = 0;

  final _tokenRefreshes = StreamController<String>.broadcast(sync: true);
  final _foregroundMessages = StreamController<PushMessage>.broadcast(
    sync: true,
  );
  final _openedMessages = StreamController<PushMessage>.broadcast(sync: true);

  @override
  Stream<String> get tokenRefreshes => _tokenRefreshes.stream;

  @override
  Stream<PushMessage> get foregroundMessages => _foregroundMessages.stream;

  @override
  Stream<PushMessage> get openedMessages => _openedMessages.stream;

  @override
  Future<bool> initialize() async {
    initializeCalls++;
    return initializeResult;
  }

  @override
  Future<PushAuthorizationStatus> authorizationStatus() async {
    permissionStatusCalls++;
    return status;
  }

  @override
  Future<PushAuthorizationStatus> requestPermission() async {
    requestPermissionCalls++;
    status = permissionResult;
    return status;
  }

  @override
  Future<String?> getToken() async {
    tokenCalls++;
    return token;
  }

  @override
  Future<PushMessage?> initialMessage() async {
    initialMessageCalls++;
    final message = launchMessage;
    launchMessage = null;
    return message;
  }

  void emitTokenRefresh(String value) => _tokenRefreshes.add(value);

  void emitForegroundMessage(PushMessage message) =>
      _foregroundMessages.add(message);

  void emitOpenedMessage(PushMessage message) => _openedMessages.add(message);

  Future<void> dispose() async {
    await Future.wait([
      _tokenRefreshes.close(),
      _foregroundMessages.close(),
      _openedMessages.close(),
    ]);
  }
}
