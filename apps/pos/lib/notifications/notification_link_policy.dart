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
      _companyOriginKeys = _collectCompanyOriginKeys(session);

  static const _canonicalOrigins = <String>[
    'https://apps.finnesia.com',
    'https://apps-dev.finnesia.com',
  ];
  static final _canonicalOriginKeys = <String>{
    for (final origin in _canonicalOrigins) _originKey(Uri.parse(origin)),
  };
  final Uri? _pairedOrigin;
  final Set<String> _companyOriginKeys;

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
