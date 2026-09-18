/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/app_info_port.dart';
import 'package:pn_types/src/native/device_info_port.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/pairing_code.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/device/device_identity.dart';
import 'package:pos/http/public_envelope.dart';
import 'package:pos/session/session_holder.dart';

const _activatePath = '/api/v1/pos/devices/activate';

/// Everything pairing touches, injected so it can be tested without a platform plugin or a
/// network (`.claude/rules/testing.md` §4).
typedef PairingDeps = ({
  /// Holds the device fingerprint. The session is persisted through [session]'s own store.
  StorePort store,
  PublicHttpPort http,
  SessionHolder session,

  /// The platform's identifier for this installation, used as the device fingerprint so a
  /// reinstall does not register a second tablet.
  DeviceInfoPort deviceInfo,

  /// Which build this is, reported to the server with the rest of the device's description.
  AppInfoPort appInfo,

  /// The host the activate call goes to — the host before any tenant is known.
  String canonicalHost,
});

/// The body `POST /api/v1/pos/devices/activate` expects — see `dto.ActivateDeviceDTO`.
typedef ActivatePayload = ({
  String code,
  String deviceName,
  String deviceFingerprint,
  String? platform,
  String? osVersion,
  String? appVersion,
  String? deviceModel,
});

enum PairingFailure {
  invalidCode,
  codeRejected,
  unavailable,
  deviceLimitReached,
}

/// Why pairing failed, as a reason the UI translates rather than a message.
///
/// The UI language is not known here, and the reason also lets the screen tell "you typed it
/// wrong" apart from "the server is unreachable".
///
/// [PairingFailure.invalidCode] and [PairingFailure.codeRejected] are both about the code but
/// are not the same advice: the first means it could never have been a code (wrong length, or
/// a character outside 0-9 and A-Z), the second means it was well-formed and the server still
/// said no — unknown, already redeemed, or past its five minutes. Only the second needs a
/// fresh code from the dashboard.
///
/// [PairingFailure.deviceLimitReached] is the one failure the cashier can act on without a new
/// code: the outlet is full, and the fix is on the dashboard. It carries [deviceLimit] because
/// the message is more useful with the number in it.
class PairingException implements Exception {
  PairingException(this.reason, {this.deviceLimit});

  final PairingFailure reason;

  /// How many tablets the outlet allows, when the server said so.
  ///
  /// `null` when the error carried no params, so the screen leaves the number out rather than
  /// printing a placeholder.
  final int? deviceLimit;

  @override
  String toString() => 'PairingException: ${reason.name}';
}

/// Builds the activate body, or returns `null` when [code] is not a valid pairing code.
///
/// Split out from `pairDevice` so it can be tested without a host: pairing happens before any
/// session exists, but the payload the backend requires (all three fields are `required` in
/// the DTO) can still be built and asserted.
///
/// The code is validated *before* the identity is built, so a code that could never be sent
/// does not leave a fingerprint behind. A [StoreException] from the identity is not
/// swallowed: pairing without a fingerprint that will survive the next launch registers a
/// device the app can no longer recognise.
Future<ActivatePayload?> buildActivatePayload(
  String code,
  StorePort store,
  DeviceInfoPort deviceInfo, {
  AppInfoPort? appInfo,
  String? deviceName,
}) async {
  final normalized = normalizePairingCode(code);
  if (!isValidPairingCode(normalized)) return null;

  final identity = await buildDeviceIdentity(
    store,
    deviceInfo,
    requestedName: deviceName,
  );
  final description = await deviceInfo.describe();
  final app = await appInfo?.version();
  return (
    code: normalized,
    deviceName: identity.deviceName,
    deviceFingerprint: identity.deviceFingerprint,
    platform: _reported(description.platform, 32),
    osVersion: _reported(description.osVersion, 64),
    appVersion: app == null ? null : _reported(_versionWithBuild(app), 32),
    deviceModel: _reported(description.deviceModel, 128),
  );
}

/// What the device said about itself, or `null` when it said nothing worth sending, cut to the
/// [max] characters the server accepts (`dto.ActivateDeviceDTO`, `validate:"max=..."`).
///
/// Cut and not refused: an over-long model name must not turn into a 400 that keeps the tablet
/// from pairing at all. The server counts characters, not UTF-16 units, so this does too.
String? _reported(String? value, int max) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return String.fromCharCodes(trimmed.runes.take(max));
}

/// `1.4.2+37`: the version says what a person would call it, the build tells two APKs of it apart.
String _versionWithBuild(AppVersion app) =>
    app.build.isEmpty ? app.version : '${app.version}+${app.build}';

/// Pairs this device with the tenant that owns [code].
///
/// The activate endpoint is public and lives on the *canonical* host, not on the tenant's:
/// nothing in the pairing code carries a host, because the code resolves to company/outlet
/// out of Redis rather than to an origin.
Future<void> pairDevice(
  String code,
  PairingDeps deps, {
  String? deviceName,
}) async {
  final payload = await buildActivatePayload(
    code,
    deps.store,
    deps.deviceInfo,
    appInfo: deps.appInfo,
    deviceName: deviceName,
  );
  if (payload == null) throw PairingException(PairingFailure.invalidCode);

  final activation = await _activate(deps, payload);
  await deps.session.save(
    PosSession(
      baseUrl: _resolveBaseUrl(activation.branding, deps.canonicalHost),
      companyId: activation.companyId,
      outletId: activation.outletId,
      deviceName: activation.deviceName,
      // Pairing registers the device; it returns no user credential. Login is a separate step.
      sessionToken: '',
      // The device's own credential, and the only time the server hands it over: it stores a
      // hash, so a lost token can only be replaced by pairing again. Absent against a backend
      // that predates the registry — the tablet still works, it just has no device identity.
      deviceToken: activation.deviceToken,
      branding: activation.branding,
    ),
  );
}

final _scheme = RegExp('^(https?)://', caseSensitive: false);
final _trailingSlashes = RegExp(r'/+$');

// What a host may contain. `Uri` is lenient — a space in the host comes back percent-encoded
// rather than as an error — so "did it parse" would accept `erp perusahaan.com`.
final _hostChars = RegExp(r'^[A-Za-z0-9._:-]+$');

// The host the session locks to: the tenant's own when the response carries one, otherwise the
// canonical host the device paired against — which is also all that is left when the domain is
// not one, rather than a session that points at a host nobody controls.
//
// The scheme is honoured when there is one and is `https` only when there is none. The source
// forces `https://` in front of everything, which locks a tenant reachable only over http (a
// dev tenant with a domain of its own, `http://localhost:4000`) to a URL that fails TLS.
String _resolveBaseUrl(PosBranding branding, String canonicalHost) {
  final domain = branding.customDomain?.trim() ?? '';
  final match = _scheme.firstMatch(domain);
  final scheme = match?.group(1)?.toLowerCase() ?? 'https';
  final host = domain
      .substring(match?.end ?? 0)
      .replaceFirst(_trailingSlashes, '');

  final origin = '$scheme://$host';
  final parsed = Uri.tryParse(origin)?.host ?? '';
  return _hostChars.hasMatch(parsed) ? origin : canonicalHost;
}

Future<_Activation> _activate(PairingDeps deps, ActivatePayload payload) async {
  final TransportResponse response;
  try {
    response = await deps.http.send(
      deps.canonicalHost,
      TransportRequest(
        method: HttpMethod.post,
        path: _activatePath,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'code': payload.code,
          'device_name': payload.deviceName,
          'device_fingerprint': payload.deviceFingerprint,
          if (payload.platform != null) 'platform': payload.platform,
          if (payload.osVersion != null) 'os_version': payload.osVersion,
          if (payload.appVersion != null) 'app_version': payload.appVersion,
          if (payload.deviceModel != null) 'device_model': payload.deviceModel,
        }),
      ),
    );
  } on TransportException {
    throw PairingException(PairingFailure.unavailable);
  }

  // `invalidPairingCode()` answers 401 for unknown, already-redeemed and expired codes alike,
  // and the backend deliberately will not say which. Every other failure reports
  // `unavailable`: the app cannot honestly tell the cashier more than "that did not work".
  if (response.status == 401) {
    throw PairingException(PairingFailure.codeRejected);
  }

  // The one failure worth reading the body for: the outlet is full, and the cashier's remedy is
  // on the dashboard rather than in a new code. Detected by `key`, never by status — a 422 with
  // code 720 is also what a duplicate fingerprint and a truncated name return, and calling those
  // "outlet penuh" would send the cashier to delete a tablet for nothing.
  final error = errorObjectOf(response.body);
  if (isDeviceLimitReachedError(error)) {
    throw PairingException(
      PairingFailure.deviceLimitReached,
      deviceLimit: deviceLimitFrom(error),
    );
  }

  if (!response.ok) throw PairingException(PairingFailure.unavailable);

  // A 200 whose body is not the shape the API promises is not a successful pairing, and
  // storing a half-read session would leave the device pointing at no tenant at all.
  final activation = _readActivation(response.body);
  if (activation == null) throw PairingException(PairingFailure.unavailable);
  return activation;
}

typedef _Activation = ({
  String companyId,
  String outletId,
  String deviceName,
  String? deviceToken,
  PosBranding branding,
});

_Activation? _readActivation(String? body) {
  final data = readEnvelopeData(body);
  if (data == null) return null;
  final device = data['device'];
  final branding = data['branding'];
  if (device is! Map<String, dynamic> || branding is! Map<String, dynamic>) {
    return null;
  }

  final companyId = device['company_id'];
  final outletId = device['outlet_id'];
  if (companyId is! String || companyId.isEmpty) return null;
  if (outletId is! String || outletId.isEmpty) return null;

  // The source casts branding without looking; here a field of the wrong type is a body the
  // API did not promise, and it must not escape as a `TypeError` in the pairing screen.
  final PosBranding parsedBranding;
  try {
    parsedBranding = PosBranding.fromJson(branding);
  } on TypeError {
    return null;
  }

  final name = device['name'];
  final token = data['device_token'];
  return (
    companyId: companyId,
    outletId: outletId,
    deviceName: name is String ? name : '',
    // An empty string and a non-string are both "no token": the transport treats an empty one
    // as absence anyway, and a number would otherwise become the string "7" and be sent as a
    // credential on every request from then on.
    deviceToken: token is String && token.isNotEmpty ? token : null,
    branding: parsedBranding,
  );
}
