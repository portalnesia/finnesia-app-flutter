/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:collection';

import 'notification_webview_port.dart';

final class NotificationWebViewOpen {
  const NotificationWebViewOpen({
    required this.destination,
    required this.allowsNavigation,
  });

  final Uri destination;
  final bool Function(Uri uri) allowsNavigation;
}

/// Deterministic fake for tests; records all attempts, including unavailable and failed opens.
final class FakeNotificationWebViewPort implements NotificationWebViewPort {
  final opened = <NotificationWebViewOpen>[];
  final Queue<NotificationWebViewException> _failures = Queue();

  bool available = true;

  void failNext(NotificationWebViewException error) => _failures.add(error);

  @override
  Future<bool> openUrl(
    Uri destination, {
    required bool Function(Uri uri) allowsNavigation,
  }) async {
    opened.add(
      NotificationWebViewOpen(
        destination: destination,
        allowsNavigation: allowsNavigation,
      ),
    );
    if (_failures.isNotEmpty) throw _failures.removeFirst();
    return available;
  }
}
