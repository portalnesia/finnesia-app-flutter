/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';

import 'file_ref.dart';
import 'tenant.dart';

part 'session.freezed.dart';
part 'session.g.dart';

/// Tenant branding from the activation response, so login shows the tenant's identity.
///
/// `custom_domain` is the host the tenant actually uses; it is absent for every tenant that
/// has none, and `PosSession.baseUrl` then stays the canonical host the device paired against.
/// The names are the wire's, because this is `companies.branding_config` as it arrives.
///
/// [logo] is a file reference, not a url string: the response carries the file's `status`,
/// and a `pending`/`detached`/`deleting` file must not be rendered. A backend that still
/// sends the old `logo_url` string is read as no logo at all — the key is ignored, so the
/// login falls back to the Finnesia logo instead of failing the pairing.
@freezed
abstract class PosBranding with _$PosBranding {
  const factory PosBranding({
    @JsonKey(name: 'app_name') String? appName,
    @JsonKey(name: 'logo') FileRef? logo,
    @JsonKey(name: 'custom_domain') String? customDomain,
    @JsonKey(name: 'account_mode') String? accountMode,
  }) = _PosBranding;

  factory PosBranding.fromJson(Map<String, dynamic> json) =>
      _$PosBrandingFromJson(json);
}

/// The cashier who is signed in.
@freezed
abstract class SessionUser with _$SessionUser {
  const SessionUser._();

  const factory SessionUser({required String id, String? name, String? email}) =
      _SessionUser;

  // The generated `toString` would print the name and email. Only the id: enough for a
  // debugger, and it is not personal data.
  @override
  String toString() => 'SessionUser($id)';

  factory SessionUser.fromJson(Map<String, dynamic> json) =>
      _$SessionUserFromJson(json);
}

/// The device's pairing + login state.
///
/// `baseUrl` is the tenant origin locked by pairing, and `sessionToken` stays empty until the
/// cashier logs in — pairing registers the device, login gets the credential.
///
/// Persisted as JSON with these Dart names (camelCase). A device paired with an earlier build
/// does not carry over to this one: the app is a different signing identity and a fresh
/// install.
@freezed
abstract class PosSession with _$PosSession {
  const PosSession._();

  const factory PosSession({
    /// Tenant origin, locked from pairing. Example: https://erp.perusahaan.com
    required String baseUrl,
    required String companyId,
    required String outletId,

    /// Device name, sent at pairing and login (device audit).
    String? deviceName,

    /// The credential that identifies this tablet, sent as `X-Device-Token` on every POS
    /// request. Activation returns it exactly once and no endpoint fetches it again, so it is
    /// persisted with the session rather than kept in memory.
    ///
    /// `null` on a device paired before the registry change: it has no token, and the only way
    /// to get one is to pair again. That is not an error — it is a device that has to re-pair,
    /// and the transport reads it as "send no header" rather than sending an empty one.
    String? deviceToken,

    /// Set when the server said this tablet is no longer registered, and cleared by pairing
    /// again. It is what sends the device back to the pairing screen.
    ///
    /// Deliberately separate from a missing [deviceToken]. A device paired against a backend
    /// that predates the registry also has no token, and treating that as revoked would lock
    /// every tablet out of the till until the backend caught up. Only an explicit rejection
    /// from the server sets this.
    @Default(false) bool deviceRevoked,

    /// Primary credential for the `Authorization: Bearer` header. Empty until login.
    required String sessionToken,

    /// Used by `POST /api/auth/refresh` when the session nears expiry.
    String? sessionRefreshToken,
    String? expiresAt,
    SessionUser? user,

    /// The companies this cashier belongs to, as the login returned them.
    ///
    /// Carried because the till has to answer "may this person take payment?" without a
    /// round trip: the membership holds the role, and the role is what decides. `null` on a
    /// device that is paired but not signed in — an empty list means the login returned no
    /// memberships, which is a different fact.
    List<UserCompany>? companies,

    /// Tenant branding from the activation response.
    PosBranding? branding,
  }) = _PosSession;

  // The generated `toString` prints every field, and three of them are credentials (and
  // `user` is personal data). A session that reaches a log line or a crash report must not
  // carry them (`.claude/rules/security.md` §1) — so this says which pairing it is and
  // whether anyone is signed in, and nothing more.
  @override
  String toString() =>
      'PosSession(baseUrl: $baseUrl, outletId: $outletId, signedIn: ${sessionToken.isNotEmpty})';

  factory PosSession.fromJson(Map<String, dynamic> json) =>
      _$PosSessionFromJson(json);
}

/// Whether two sessions are the same device paired to the same outlet.
///
/// Identity is the pairing, not the object: rotating a token replaces the session object
/// without the device having moved anywhere, and a login in flight for it is still valid.
/// A reset clears the session, and re-pairing changes the outlet (or the host), so both of
/// those are what a caller compares against to notice its work has been invalidated.
bool isSamePairing(PosSession? a, PosSession? b) {
  if (a == null || b == null) return false;
  return a.baseUrl == b.baseUrl &&
      a.companyId == b.companyId &&
      a.outletId == b.outletId;
}
