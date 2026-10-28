/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Opens an already-validated notification destination in a native in-app browser.
///
/// Returns `false` when the platform cannot provide an embedded browser (for example, when the
/// Windows WebView2 runtime is not installed). Implementations must apply [allowsNavigation] to
/// every top-level navigation and must not forward POS credentials to the web page.
abstract interface class NotificationWebViewPort {
  Future<bool> openUrl(
    Uri destination, {
    required bool Function(Uri uri) allowsNavigation,
  });
}

/// A user-safe failure when the in-app browser cannot be opened.
final class NotificationWebViewException implements Exception {
  const NotificationWebViewException(this.message);

  final String message;

  @override
  String toString() => message;
}
