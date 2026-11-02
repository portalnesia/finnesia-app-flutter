/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pn_types/src/native/notification_webview_port.dart';

/// Native InAppBrowser adapter. It never receives the POS session or bearer token.
class InAppNotificationWebView implements NotificationWebViewPort {
  _PolicyInAppBrowser? _activeBrowser;

  @override
  Future<bool> openUrl(
    Uri destination, {
    required bool Function(Uri uri) allowsNavigation,
  }) async {
    if (!allowsNavigation(destination)) return false;

    WebViewEnvironment? environment;
    if (defaultTargetPlatform == TargetPlatform.windows) {
      try {
        final version = await WebViewEnvironment.getAvailableVersion();
        if (version == null || version.isEmpty) return false;
        environment = await WebViewEnvironment.create();
      } on PlatformException {
        return false;
      } on MissingPluginException {
        return false;
      }
    } else if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    late final _PolicyInAppBrowser browser;
    browser = _PolicyInAppBrowser(
      environment: environment,
      allowsNavigation: allowsNavigation,
      onClosed: () {
        if (identical(_activeBrowser, browser)) _activeBrowser = null;
        final current = environment;
        if (current != null) unawaited(current.dispose());
      },
    );
    _activeBrowser = browser;

    try {
      // Deliberately send no headers: in particular, never copy the POS Authorization bearer.
      await browser.openUrlRequest(
        urlRequest: URLRequest(url: WebUri.uri(destination)),
        settings: InAppBrowserClassSettings(
          browserSettings: InAppBrowserSettings(
            toolbarTopFixedTitle: 'Finnesia POS',
          ),
          webViewSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: true,
            javaScriptEnabled: true,
            javaScriptCanOpenWindowsAutomatically: false,
            supportMultipleWindows: false,
          ),
        ),
      );
      return true;
    } on PlatformException {
      _activeBrowser = null;
      await _disposeEnvironment(environment);
      return false;
    } on MissingPluginException {
      _activeBrowser = null;
      await _disposeEnvironment(environment);
      return false;
    }
  }

  Future<void> _disposeEnvironment(WebViewEnvironment? environment) async {
    if (environment == null) return;
    try {
      await environment.dispose();
    } on PlatformException {
      // A failed WebView launch should fall back to the system browser regardless of cleanup.
    } on MissingPluginException {
      // The plugin disappeared during cleanup; no POS credential has been sent to it.
    }
  }
}

class _PolicyInAppBrowser extends InAppBrowser {
  _PolicyInAppBrowser({
    required WebViewEnvironment? environment,
    required this.allowsNavigation,
    required this.onClosed,
  }) : super(webViewEnvironment: environment);

  final bool Function(Uri uri) allowsNavigation;
  final VoidCallback onClosed;

  @override
  Future<NavigationActionPolicy?> shouldOverrideUrlLoading(
    NavigationAction navigationAction,
  ) async {
    final destination = navigationAction.request.url?.uriValue;
    if (destination == null || !allowsNavigation(destination)) {
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  @override
  void onExit() => onClosed();
}
