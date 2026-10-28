/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Permission states the POS needs to decide whether it should register an FCM token.
enum PushAuthorizationStatus {
  notDetermined,
  denied,
  authorized,
  provisional,
  unsupported,
}

extension PushAuthorizationStatusPermission on PushAuthorizationStatus {
  bool get canReceivePush =>
      this == PushAuthorizationStatus.authorized ||
      this == PushAuthorizationStatus.provisional;
}

/// FCM data used by the POS. The server remains the authority for notification destinations.
final class PushMessage {
  PushMessage({required Map<String, String> data, this.messageId})
    : data = Map.unmodifiable(data);

  final Map<String, String> data;
  final String? messageId;
}

/// Platform boundary for FCM, foreground delivery, and local-notification tap handling.
///
/// Implementations report unsupported or unavailable platform state as values rather than
/// making push setup a prerequisite for signing in or taking a sale.
abstract interface class PushMessagingPort {
  /// Installs background handling and local-notification callbacks. Returns false when unavailable.
  Future<bool> initialize();

  Future<PushAuthorizationStatus> authorizationStatus();

  /// Called only after a cashier explicitly chooses to enable notifications.
  Future<PushAuthorizationStatus> requestPermission();

  Future<String?> getToken();

  Stream<String> get tokenRefreshes;
  Stream<PushMessage> get foregroundMessages;
  Stream<PushMessage> get openedMessages;

  /// Returns a notification tap that launched the process, whether from FCM or a local notification.
  Future<PushMessage?> initialMessage();
}
