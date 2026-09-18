/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/session/session_holder.dart';

final _trailingSlashes = RegExp(r'/+$');

/// The token goes to `baseUrl + path`, and the port joins the two. A path that is really a URL
/// (`https://…`, or `//host/…`, which a browser-style resolver reads as one) would send the
/// bearer token to a host the device never paired with. Callers build paths from the registry,
/// so this guards against a bug rather than an attacker — but it is the one check that makes
/// "the token only goes to the locked host" true whatever a caller does
/// (`.claude/rules/security.md` §1.1).
///
/// Only the path proper is looked at: a query may legitimately hold `//` or a URL. The error does
/// not say what the path was, because a path can carry a search term.
void _requireRelativePath(String path) {
  final end = path.indexOf(RegExp('[?#]'));
  final proper = end < 0 ? path : path.substring(0, end);
  final startsAtRoot = proper.startsWith('/');
  final leavesTheHost = proper.startsWith('//') || proper.startsWith(r'/\');
  if (!startsAtRoot || leavesTheHost) {
    throw ArgumentError('a request path must be relative to the paired host');
  }
}

bool _hasHeader(Map<String, String> headers, String lowerCaseName) =>
    headers.keys.any((name) => name.toLowerCase() == lowerCaseName);

/// A request was made while the device holds no host to send it to.
///
/// Not a [TransportException]: that one means "no response, try again later", and waiting does
/// not pair a device. The caller is a screen that outlived the pairing (a reset while a request
/// was being built), and it has to send the cashier to the pairing screen instead of retrying.
class NotPairedException implements Exception {
  @override
  String toString() => 'NotPairedException: the device is not paired';
}

/// The [ApiTransport] the POS app runs on: it sends to the host pairing locked and speaks with
/// the session's bearer token.
///
/// The seam is split into `resolveUrl`, `authHeaders` and `send`; here it is the one [send]
/// (README §5), and the client never holds a host or a token — this class is the only place
/// either is read.
///
/// The host and the token are read from [session] on every call, never cached: a reset or a
/// login between two requests must take effect on the very next one.
class PosTransport implements ApiTransport {
  PosTransport({
    required this.session,
    required this.http,
    this.refresh,
    this.refreshWithin,
    this._now = DateTime.now,
  });

  final SessionHolder session;
  final PublicHttpPort http;

  /// Renews the session, and says whether it did. Must not throw: a refresh that fails is
  /// `false`, and the request carries on with what it has.
  ///
  /// Optional so this class does not know about login: the app wires `refreshSession` here.
  final Future<bool> Function()? refresh;

  /// How close to its end a session has to be for a request to renew it first. `null` renews
  /// only after a 401.
  ///
  /// The backend does not rotate a bearer session by itself, so this is what keeps a device that
  /// is used for days signed in. Renewing before the end, and not after the 401, keeps access
  /// unbroken: an ended session authenticates nothing, so waiting costs a rejected request (a
  /// sale at the till), and the backend honours a refresh token only for 14 days past the end.
  final Duration? refreshWithin;

  final DateTime Function() _now;

  // One refresh for every request that needs one while it runs. The backend rotates the refresh
  // token on use, so a second refresh with the token the first one spent would fail and log the
  // cashier out over a request that was only unlucky.
  Future<bool>? _refreshing;

  // Offline, every request would open with a refresh that cannot work, and the 401 that may
  // follow would try the same one again. After a failure the next attempt waits.
  DateTime? _refreshFailedAt;
  static const _retryRefreshAfter = Duration(minutes: 1);

  @override
  Future<TransportResponse> send(TransportRequest request) async {
    _requireRelativePath(request.path);

    await _renewIfEnding(request);
    final first = await _sendOnce(request);
    // Before any retry: a device the server no longer knows cannot be fixed by asking again,
    // and the second request would go out with a token that is already dead.
    if (await _revokeIfUnregistered(first.response)) return first.response;
    if (first.response.status != 401) return first.response;
    if (!await _canSendAgain(first.sentAs, request)) return first.response;

    // Once. A 401 means the server did not run the request, so sending it again cannot
    // repeat a sale; and a second 401 is an answer, not a reason to refresh again.
    return (await _sendOnce(request)).response;
  }

  /// Records that the server has deleted this tablet, and says whether it did.
  ///
  /// Here rather than in each caller because every POS request goes through this one method,
  /// and the contract is explicit that it must be handled in one place: a caller that forgot
  /// would leave a deleted tablet transacting against a registry entry that no longer exists.
  ///
  /// The session is changed, not the response: the gate reads the session to decide the screen,
  /// and the response is still handed back so the caller reports what the server actually said.
  ///
  /// A [StoreException] from the write is not swallowed. A revocation that could not be stored
  /// would be forgotten at the next launch, which is the failure this exists to prevent.
  Future<bool> _revokeIfUnregistered(TransportResponse response) async {
    if (!isDeviceUnregisteredError(
      status: response.status,
      error: errorObjectOf(response.body),
    )) {
      return false;
    }
    await session.unregisterDevice();
    return true;
  }

  // Only a request that goes out with the session's own token is ours to renew for: a caller's
  // own Authorization is not, and a device nobody is signed in on has nothing to refresh (the
  // accurate answer is the 401, and the login screen).
  bool _usesSessionToken(PosSession current, TransportRequest request) =>
      current.sessionToken.isNotEmpty &&
      !_hasHeader(request.headers, 'authorization');

  Future<void> _renewIfEnding(TransportRequest request) async {
    final window = refreshWithin;
    final current = session.current;
    if (window == null || current == null) return;
    if (!_usesSessionToken(current, request)) return;
    if (!endsWithin(current, window, _now())) return;

    await _renew();
  }

  Future<bool> _renew() {
    final renew = refresh;
    if (renew == null) return Future.value(false);

    final running = _refreshing;
    if (running != null) return running;

    final failedAt = _refreshFailedAt;
    if (failedAt != null && _now().difference(failedAt) < _retryRefreshAfter) {
      return Future.value(false);
    }

    return _refreshing = renew()
        .then((renewed) {
          _refreshFailedAt = renewed ? null : _now();
          return renewed;
        })
        .whenComplete(() => _refreshing = null);
  }

  Future<({TransportResponse response, PosSession sentAs})> _sendOnce(
    TransportRequest request,
  ) async {
    final current = session.current;
    if (current == null || current.baseUrl.isEmpty) throw NotPairedException();

    // The port takes a host with no trailing slash and joins the path itself.
    final response = await http.send(
      current.baseUrl.replaceFirst(_trailingSlashes, ''),
      request.copyWith(headers: _withIdentity(current, request.headers)),
    );

    return (response: response, sentAs: current);
  }

  // Whether a request rejected with 401 is worth sending again, renewing the session first if
  // that is what it takes.
  Future<bool> _canSendAgain(
    PosSession sentAs,
    TransportRequest request,
  ) async {
    if (refresh == null) return false;
    if (!_usesSessionToken(sentAs, request)) return false;

    final now = session.current;
    if (now == null) return false; // reset while the request was out
    // The token this request used was replaced meanwhile (a login, or a refresh made elsewhere in
    // the app). The new one is already stored; there is nothing to refresh, only to send again.
    if (now.sessionToken != sentAs.sessionToken) {
      return now.sessionToken.isNotEmpty;
    }

    return _renew();
  }

  // CSRF is intentionally absent: the backend sets `IsWeb` only for a cookie session, so a
  // bearer request is never CSRF-checked.
  //
  // A header the caller already set wins, in whatever case it wrote it: HTTP names are not
  // case-sensitive, and the source's exact-case lookup would send a second copy next to
  // `x-company-id`. Both are also left out when there is nothing to say — no token yet means
  // no header (the accurate 401, not a malformed `Bearer `), and a session without a company
  // sends none.
  //
  // The device token is read here for the same reason the company is: this is the one place a
  // request is built, so no call site can forget it. It is deliberately NOT required to send a
  // request — a device paired before the registry change has none, and the server answers such
  // a tablet the same way it answers the web dashboard (no presence, request allowed).
  Map<String, String> _withIdentity(
    PosSession current,
    Map<String, String> headers,
  ) {
    final deviceToken = current.deviceToken ?? '';
    return {
      ...headers,
      if (current.sessionToken.isNotEmpty &&
          !_hasHeader(headers, 'authorization'))
        'Authorization': 'Bearer ${current.sessionToken}',
      if (current.companyId.isNotEmpty && !_hasHeader(headers, 'x-company-id'))
        'X-Company-ID': current.companyId,
      if (deviceToken.isNotEmpty && !_hasHeader(headers, 'x-device-token'))
        'X-Device-Token': deviceToken,
    };
  }
}
