/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pn_types/src/native/push_messaging_port.dart';
import 'package:pos/notifications/push_debug_log.dart';
import 'package:pos/notifications/windows_push_payload.dart';

const _windowsPushChannel = 'pos/windows_wns';

/// Windows App SDK WNS bridge for the packaged POS application.
///
/// Toasts are displayed by Windows from the server's WNS XML. This adapter only handles the
/// channel URI and the safe launch identifiers used to reopen the authenticated inbox item.
class WindowsWnsPushMessaging implements PushMessagingPort {
  WindowsWnsPushMessaging({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_windowsPushChannel);

  final MethodChannel _channel;
  final _tokenRefreshes = StreamController<String>.broadcast();
  final _foregroundMessages = StreamController<PushMessage>.broadcast();
  final _pendingOpens = <PushMessage>[];
  late final StreamController<PushMessage> _openedMessages =
      StreamController<PushMessage>.broadcast(
        onListen: () {
          for (final message in List<PushMessage>.of(_pendingOpens)) {
            _openedMessages.add(message);
          }
          _pendingOpens.clear();
        },
      );
  bool _initialized = false;
  bool _available = false;
  bool _channelRequestInFlight = false;
  String? _latestToken;
  String? _initialLaunchArguments;

  @override
  Stream<String> get tokenRefreshes => _tokenRefreshes.stream;

  @override
  Stream<PushMessage> get foregroundMessages => _foregroundMessages.stream;

  @override
  Stream<PushMessage> get openedMessages => _openedMessages.stream;

  @override
  Future<bool> initialize() async {
    if (_initialized) return _available;
    _channel.setMethodCallHandler(_handleNativeCall);
    try {
      _available = await _channel.invokeMethod<bool>('initialize') ?? false;
      if (!_available) {
        logPushDebug('Windows WNS unavailable: packaged runtime not ready');
        return false;
      }
      _initialLaunchArguments = await _channel.invokeMethod<String>(
        'initialActivation',
      );
      _initialized = true;
      logPushDebug('Windows WNS messaging initialized');
      return true;
    } on Object catch (error) {
      logPushDebug('Windows WNS initialization failed (${error.runtimeType})');
      return false;
    }
  }

  @override
  Future<PushAuthorizationStatus> authorizationStatus() async => _available
      ? PushAuthorizationStatus.authorized
      : PushAuthorizationStatus.unsupported;

  @override
  Future<PushAuthorizationStatus> requestPermission() async {
    if (!_available) return PushAuthorizationStatus.unsupported;
    _refreshChannel();
    return PushAuthorizationStatus.authorized;
  }

  @override
  Future<String?> getToken() async {
    if (!_available) return null;
    _refreshChannel();
    return _latestToken;
  }

  void _refreshChannel() {
    if (!_available || _channelRequestInFlight) return;
    _channelRequestInFlight = true;
    unawaited(_requestChannel());
  }

  Future<void> _requestChannel() async {
    try {
      final token = await _channel.invokeMethod<String>('createChannel');
      if (token == null || token.isEmpty) return;
      if (token != _latestToken) {
        _latestToken = token;
        _tokenRefreshes.add(token);
      }
    } on Object catch (error) {
      logPushDebug('Windows WNS channel request failed (${error.runtimeType})');
    } finally {
      _channelRequestInFlight = false;
    }
  }

  @override
  Future<PushMessage?> initialMessage() async {
    final arguments = _initialLaunchArguments;
    _initialLaunchArguments = null;
    return parseWindowsPushLaunchArguments(arguments);
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    final arguments = call.arguments;
    if (arguments is! String) return;
    switch (call.method) {
      case 'channelRefreshed':
        if (arguments.isNotEmpty && arguments != _latestToken) {
          _latestToken = arguments;
          _tokenRefreshes.add(arguments);
        }
        break;
      case 'pushReceived':
        final message = parseWindowsPushLaunchArguments(arguments);
        if (message != null) _foregroundMessages.add(message);
        break;
      case 'notificationOpened':
        final message = parseWindowsPushLaunchArguments(arguments);
        if (message != null) {
          if (_openedMessages.hasListener) {
            _openedMessages.add(message);
          } else {
            if (_pendingOpens.length == 10) _pendingOpens.removeAt(0);
            _pendingOpens.add(message);
          }
        }
        break;
    }
  }
}
