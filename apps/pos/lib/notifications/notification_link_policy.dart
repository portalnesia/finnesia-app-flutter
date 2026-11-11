/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/session.dart';

/// Resolves notification destinations only to origins the paired company owns.
///
/// The server resolves notification links. This is a second boundary in the POS client: only the
/// paired origin, a server-provided custom domain, and the product's two HTTPS web origins may be
/// initial destinations. After launch, navigation is handled by the user's external browser.
class NotificationLinkPolicy {
  NotificationLinkPolicy(PosSession? session)
    : _pairedOrigin = _trustedOrigin(session?.baseUrl),
      _serverBase = Uri.tryParse(session?.baseUrl.trim() ?? ''),
      _companyOriginKeys = _collectCompanyOriginKeys(session);

  static const _canonicalOrigins = <String>[
    'https://apps.finnesia.com',
    'https://apps-dev.finnesia.com',
  ];
  static final _canonicalOriginKeys = <String>{
    for (final origin in _canonicalOrigins) _originKey(Uri.parse(origin)),
  };
  final Uri? _pairedOrigin;

  /// The paired server as it was entered, HTTP included. Announcement content (image, CTA, body
  /// links) is resolved against it the way the web page resolves `/path` against its own
  /// origin, whatever the scheme; the notification's own `link` keeps the HTTPS-only rule.
  final Uri? _serverBase;
  final Set<String> _companyOriginKeys;

  /// Resolves an announcement image the way an `<img>` on the web page does. The API signs
  /// images as `/static/...`, which the browser loads from the page's own origin; the till
  /// loads them from the server it is paired with. An absolute `http`/`https` URL loads as it
  /// is. Anything else returns null.
  Uri? resolveMedia(String value) {
    final raw = value.trim();
    if (raw.startsWith('/')) return _resolveRootRelative(raw);
    final uri = Uri.tryParse(raw);
    if (uri == null || !_isWebScheme(uri) || uri.host.isEmpty) return null;
    return uri;
  }

  /// `/path` against the paired server. `//host` and `/\host` name another host, which the
  /// web dialog refuses too.
  Uri? _resolveRootRelative(String raw) {
    if (!raw.startsWith('/') || raw.startsWith('//') || raw.contains('\\')) {
      return null;
    }
    final base = _serverBase;
    if (base == null || !_isWebScheme(base) || base.host.isEmpty) return null;
    return base.resolve(raw);
  }

  static bool _isWebScheme(Uri uri) =>
      uri.scheme.toLowerCase() == 'https' || uri.scheme.toLowerCase() == 'http';

  /// Resolves a root-relative or absolute server destination if it belongs to a trusted company
  /// origin. External schemes, protocol-relative references, and untrusted hosts return null.
  Uri? resolveDestination(String value) {
    final raw = value.trim();
    if (raw.isEmpty || raw.contains('\\')) return null;

    final parsed = Uri.tryParse(raw);
    if (parsed == null || parsed.userInfo.isNotEmpty) return null;

    final Uri candidate;
    if (parsed.hasScheme) {
      if (parsed.scheme.toLowerCase() != 'https' || parsed.host.isEmpty) {
        return null;
      }
      candidate = parsed;
    } else {
      // Accept only app-rooted links, never a path relative to the current page or a
      // protocol-relative authority such as //attacker.example.
      final base = _pairedOrigin;
      if (base == null || parsed.hasAuthority || !raw.startsWith('/')) {
        return null;
      }
      candidate = base.resolveUri(parsed);
    }

    if (!_isHttpsOrigin(candidate) ||
        !_companyOriginKeys.contains(_originKey(candidate))) {
      return null;
    }
    return candidate;
  }

  /// Resolves a CTA or a link inside the announcement body by the web app's rules
  /// (`isSafeCtaHref` in `packages/shared/src/utils/notification-cta.ts`): an app-rooted path
  /// stays in the app ([inApp], resolved against the paired origin), and an `http`, `https`,
  /// `mailto` or `tel` link opens as it is. Anything else returns null and does nothing.
  ///
  /// Wider than [resolveDestination] on purpose: these links were typed by an operator and kept
  /// by the server's sanitizer, and the web opens them in a new tab, whereas the notification's
  /// own `link` is where tapping the notification takes the cashier.
  ({Uri uri, bool inApp})? resolveAction(String value) {
    final raw = value.replaceAll(
      RegExp(r'^[\x00-\x20\x7f]+|[\x00-\x20\x7f]+$'),
      '',
    );
    if (raw.isEmpty) return null;

    if (raw.startsWith('/')) {
      final uri = _resolveRootRelative(raw);
      return uri == null ? null : (uri: uri, inApp: true);
    }

    final lower = raw.toLowerCase();
    const schemes = ['http://', 'https://', 'mailto:', 'tel:'];
    if (!schemes.any(lower.startsWith)) return null;
    final uri = Uri.tryParse(raw);
    return uri == null ? null : (uri: uri, inApp: false);
  }

  static Set<String> _collectCompanyOriginKeys(PosSession? session) {
    final origins = <String>{..._canonicalOriginKeys};
    final paired = _trustedOrigin(session?.baseUrl);
    if (paired != null) origins.add(_originKey(paired));
    final custom = _trustedOrigin(
      session?.branding?.customDomain,
      allowBareHost: true,
    );
    if (custom != null) origins.add(_originKey(custom));
    return origins;
  }

  static Uri? _trustedOrigin(String? value, {bool allowBareHost = false}) {
    if (value == null || value.trim().isEmpty) return null;
    var raw = value.trim();
    if (allowBareHost && !raw.contains('://')) raw = 'https://$raw';
    final uri = Uri.tryParse(raw);
    if (uri == null || !_isHttpsOrigin(uri) || uri.userInfo.isNotEmpty) {
      return null;
    }
    if ((uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return Uri(
      scheme: 'https',
      host: uri.host.toLowerCase(),
      port: uri.hasPort ? uri.port : null,
      path: '/',
    );
  }

  static bool _isHttpsOrigin(Uri uri) =>
      uri.scheme.toLowerCase() == 'https' && uri.host.isNotEmpty;

  static String _originKey(Uri uri) =>
      'https://${uri.host.toLowerCase()}:${uri.port}';
}
