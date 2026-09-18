/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:convert';

import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/opener_port.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:pos/http/public_envelope.dart';
import 'package:pos/session/session_holder.dart';

/// Where the in-flight login's request id is kept.
///
/// Persisted, not just held in memory: the cashier may background the app to finish the
/// login, and the OS may kill it outright. Without this, coming back would mean walking to the
/// dashboard for a fresh code even though the browser half already succeeded.
const pendingLoginKey = 'pending_login_request';

const _startPath = '/api/auth/mobile/start';
const _pollPath = '/api/auth/mobile/poll';
const _refreshPath = '/api/auth/refresh';

/// Why a login did not finish. The UI translates these rather than showing a message, because
/// the language is not known here.
///
/// `expired` and `timeout` are both "it did not work", but they are not the same advice:
/// `expired` means the request is gone from Redis and a fresh one is the only way forward,
/// `timeout` means the cashier probably just walked away from the browser.
///
/// `cancelled` is not a failure to report at all: the cashier said so, and the screen they
/// came from is still there.
enum LoginFailure { notPaired, unavailable, expired, timeout, cancelled }

class LoginException implements Exception {
  LoginException(this.reason);

  final LoginFailure reason;

  @override
  String toString() => 'LoginException: ${reason.name}';
}

/// The way out of a login that is taking too long, and the way back in.
///
/// A cashier who tapped Masuk by mistake, or whose browser is signed in to the wrong account,
/// otherwise has five minutes of watching a spinner ahead of them, or killing the app
/// (`plan/ui/findings.md` F5). This is what the Batal button on the login screen drives.
///
/// It also carries the wake-up that finishing in the browser produces: coming back to the app
/// means the answer is already waiting, and waiting out the poll interval first would show the
/// cashier a spinner for an answer that is sitting there.
///
/// One control drives one login. The screen owns it for as long as its login runs, and nothing
/// here is shared between two logins.
class LoginControl {
  final _cancelled = Completer<void>();

  /// The wait the poll loop is currently sitting in, when it is sitting in one.
  Completer<void>? _wakeUp;

  /// A [pollNow] that arrived while the loop was polling rather than waiting.
  var _wakeUpMissed = false;

  /// Whether [cancel] has been called. The screen reads it to decide what it is showing.
  bool get isCancelled => _cancelled.isCompleted;

  /// Stops the login with [LoginFailure.cancelled].
  ///
  /// A second call does nothing, so a double tap cannot finish a completer twice.
  ///
  /// A poll that has already collected the session keeps it: the backend hands a session out
  /// once (`TakeMobileLoginResult` uses `GetDel`), so throwing one away would cost the cashier
  /// a second walk through the browser and there is nothing left to collect a second time.
  void cancel() {
    if (isCancelled) return;
    _cancelled.complete();
  }

  /// Asks the poll loop to poll now instead of waiting out the interval.
  ///
  /// The app calls this when it comes back to the foreground, because the cashier left it to
  /// finish in the browser.
  void pollNow() {
    final wakeUp = _wakeUp;
    if (wakeUp != null && !wakeUp.isCompleted) {
      wakeUp.complete();
      return;
    }
    // The loop is between two polls, or inside one right now. Remembered rather than dropped:
    // the answer the cashier came back for would otherwise be waited out one interval late.
    _wakeUpMissed = true;
  }

  /// Stops the login, or waits for [delay] — whichever happens first.
  ///
  /// `false` when the cashier gave up while waiting, which ends the login rather than polling
  /// again. The caller decides what giving up means for what is on disk; this only reports it.
  Future<bool> _waitForNextPoll(Future<void> Function() delay) async {
    if (isCancelled) return false;
    if (_wakeUpMissed) {
      // The app came back while the previous poll was still out.
      _wakeUpMissed = false;
      return true;
    }

    // Held for the length of one wait. A completer left here after that is already completed,
    // and `pollNow` only completes one that is not — so a stale one cannot answer a later
    // wake-up either way.
    final wakeUp = Completer<void>();
    _wakeUp = wakeUp;
    await Future.any([delay(), _cancelled.future, wakeUp.future]);

    // A delay can finish in the same turn as a cancel. Whoever won the race, a login the
    // cashier has given up on does not poll again.
    return !isCancelled;
  }
}

/// Everything a login touches, injected so it can be tested without a browser, a network or a
/// clock (`.claude/rules/testing.md` §4).
typedef LoginDeps = ({
  /// Holds the pending request id. The session is persisted through [session]'s own store.
  StorePort store,
  PublicHttpPort http,
  OpenerPort opener,
  SessionHolder session,

  /// Waits between two polls. Injected so a test can drive the loop without real waiting.
  Future<void> Function() delay,
  Duration pollTimeout,

  /// The deadline is measured against this, so a test can move time without sleeping.
  DateTime Function() now,
});

typedef _StartedLogin = ({String requestId, String loginUrl});

/// Signs the cashier in.
///
/// The app never sees the OIDC provider and is never redirected to: it asks the backend to open
/// a login, hands the resulting URL to the system browser, and polls until the session the
/// callback parked in Redis appears. That indirection is what removes the deep link, the second
/// `redirect_uri`, and the dependence on the app being woken up by the OS.
///
/// Pairing must have happened first — it is what supplies the host this talks to.
///
/// [control] is the cashier's way out (and the app's way of saying it is back). Without one the
/// login runs to its own end.
Future<void> loginNative(LoginDeps deps, {LoginControl? control}) async {
  final session = deps.session.current;
  if (session == null || session.baseUrl.isEmpty) {
    throw LoginException(LoginFailure.notPaired);
  }
  // Nothing has happened yet, so there is nothing to undo either.
  if (control?.isCancelled ?? false) {
    throw LoginException(LoginFailure.cancelled);
  }

  final started = await _startLogin(deps, session);

  // Saved before the browser opens. If the OS kills the app while the cashier is signing in,
  // the request is still in Redis and a resume can still collect it.
  await deps.store.write(pendingLoginKey, started.requestId);

  // The cashier can give up while the start call is out, and a browser opened after that would
  // sign them in to an account they just walked away from. The marker goes with it: left
  // behind, the next launch would collect the login they abandoned.
  if (control?.isCancelled ?? false) {
    await deps.store.remove(pendingLoginKey);
    throw LoginException(LoginFailure.cancelled);
  }

  try {
    await deps.opener.openUrl(started.loginUrl);
  } on OpenerException {
    // Nobody is going to finish this login, so nobody should be resumed into it.
    await deps.store.remove(pendingLoginKey);
    throw LoginException(LoginFailure.unavailable);
  }

  await _collect(deps, session, started.requestId, control);
}

/// Picks up a login that was already started, if one was left behind.
///
/// Called at bootstrap: a login the app was killed in the middle of is still waiting in Redis,
/// and finishing it silently is far better than making the cashier start over.
///
/// Two callers can ask at the same time, and a second poll loop for one request id would be
/// pure waste: the backend hands the session out once, so the loser would sit for the full
/// timeout and then fail. Sharing the future makes the second caller wait for the first.
Future<void> resumePendingLogin(LoginDeps deps, {LoginControl? control}) =>
    _resumeInFlight ??= _resume(
      deps,
      control,
    ).whenComplete(() => _resumeInFlight = null);

Future<void>? _resumeInFlight;

Future<void> _resume(LoginDeps deps, LoginControl? control) async {
  final session = deps.session.current;
  if (session == null || session.baseUrl.isEmpty) return;

  final requestId = await deps.store.read(pendingLoginKey);
  // The source tests `if (!requestId)`, so an empty string is not a request id either.
  if (requestId == null || requestId.isEmpty) return;

  await _collect(deps, session, requestId, control);
}

Future<_StartedLogin> _startLogin(LoginDeps deps, PosSession session) async {
  final response = await _send(deps, session.baseUrl, _startPath, {
    'device_name': session.deviceName ?? '',
  });
  if (!response.ok) throw LoginException(LoginFailure.unavailable);

  final data = readEnvelopeData(response.body);
  final requestId = data?['request_id'];
  final loginUrl = data?['login_url'];
  if (requestId is! String || requestId.isEmpty) {
    throw LoginException(LoginFailure.unavailable);
  }
  // Without a URL there is nothing to open, and polling a request the browser can never
  // finish would just burn five minutes before timing out.
  if (loginUrl is! String || loginUrl.isEmpty) {
    throw LoginException(LoginFailure.unavailable);
  }
  // The URL came out of a response and goes to the OS, which opens any scheme it has a handler
  // for (`intent:` starts another app, `file:` reads local storage). Only a web page belongs in
  // the browser. The source hands it over unchecked.
  if (!_isWebUrl(loginUrl)) throw LoginException(LoginFailure.unavailable);
  return (requestId: requestId, loginUrl: loginUrl);
}

bool _isWebUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
}

Future<TransportResponse> _send(
  LoginDeps deps,
  String baseUrl,
  String path,
  Map<String, Object?> body,
) async {
  try {
    return await deps.http.send(
      baseUrl,
      TransportRequest(
        method: HttpMethod.post,
        path: path,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );
  } on TransportException {
    throw LoginException(LoginFailure.unavailable);
  }
}

/// Polls until the login finishes, the request is gone, or the wait runs out.
///
/// `pending` is the ordinary answer, not a failure — the cashier is still in the browser.
Future<void> _collect(
  LoginDeps deps,
  PosSession session,
  String requestId,
  LoginControl? control,
) async {
  // A login nobody can cancel still waits through a control, so there is one wait path rather
  // than two: a branch here would leave the ordinary case (no button, no wake-up) running code
  // that only ever executes when a control is missing.
  final waits = control ?? LoginControl();
  final deadline = deps.now().add(deps.pollTimeout);

  for (;;) {
    // The device can be reset (or paired elsewhere) while the browser is open. Completing the
    // login would write the session back and silently undo that reset, so a login that no
    // longer belongs to the current pairing gives up instead of finishing.
    if (!isSamePairing(deps.session.current, session)) {
      await deps.store.remove(pendingLoginKey);
      return;
    }

    final collected = await _pollOnce(deps, session, requestId);
    // Before the cashier's cancel is read: the answer to that poll may be the session itself,
    // and the backend hands it out once. Dropping it would leave the cashier signed out with
    // nothing left to collect, and no way back except the whole browser walk again.
    if (collected) return;

    if (waits.isCancelled) break;

    if (!deps.now().isBefore(deadline)) {
      throw LoginException(LoginFailure.timeout);
    }
    if (!await waits._waitForNextPoll(deps.delay)) break;
  }

  // Given up on, so nothing may pick it up later either: the next launch reads this marker and
  // would collect a session the cashier walked away from.
  await deps.store.remove(pendingLoginKey);
  throw LoginException(LoginFailure.cancelled);
}

/// One poll: `true` when the login finished, `false` while the cashier is still in the browser.
///
/// Throws for the answers that end the login instead: a request id the backend no longer knows
/// ([LoginFailure.expired]), a server that answers with something unusable
/// ([LoginFailure.unavailable]), or a finished login that cannot be used
/// ([LoginFailure.unavailable]).
///
/// **A dropped connection is not one of those.** It says nothing about the request, which lives
/// in Redis for its full TTL, so it is reported as "not ready yet" like any other non-answer.
///
/// Measured on a tablet (2026-09-20): three `200 pending` polls, then one dropped connection
/// while the browser was still open, and the cashier was told "Belum bisa menghubungi server"
/// over a login that was sitting in Redis waiting to be collected. Ending the login there throws
/// away work the cashier already did, and the only way back is a fresh code from the dashboard.
Future<bool> _pollOnce(
  LoginDeps deps,
  PosSession session,
  String requestId,
) async {
  final TransportResponse response;
  try {
    response = await _send(deps, session.baseUrl, _pollPath, {
      'request_id': requestId,
    });
  } on LoginException catch (failure) {
    // Only the transport's own failure is swallowed: `_send` maps a [TransportException] to
    // `unavailable`, and anything else it can throw is a bug that must stay loud.
    if (failure.reason != LoginFailure.unavailable) rethrow;
    return false;
  }

  if (response.status == 404) {
    // Redis no longer knows this request: expired, already collected, or never existed.
    await deps.store.remove(pendingLoginKey);
    throw LoginException(LoginFailure.expired);
  }

  if (response.ok) {
    final data = readEnvelopeData(response.body);
    if (data?['status'] == 'ready') {
      await _finish(deps, session, data!);
      return true;
    }
  } else if (response.status != 429) {
    // A throttled poll is worth retrying; anything else is not.
    throw LoginException(LoginFailure.unavailable);
  }

  return false;
}

Future<void> _finish(
  LoginDeps deps,
  PosSession session,
  Map<String, dynamic> data,
) async {
  final merged = _merge(session, data);
  if (merged == null) {
    // The backend hands the session out once, so there is nothing to poll again.
    await deps.store.remove(pendingLoginKey);
    throw LoginException(LoginFailure.unavailable);
  }
  await deps.session.save(merged);
  await deps.store.remove(pendingLoginKey);
}

/// Login adds the credential; it must not undo what pairing established.
///
/// The host, outlet and branding came from the activation response and are what the rest of the
/// app is built on — overwriting them from the login response would silently re-point a device
/// that was paired to one tenant. `null` when [data] carries no usable token pair.
PosSession? _merge(PosSession session, Map<String, dynamic> data) {
  final token = data['session_token'];
  final refresh = data['session_refresh_token'];
  if (token is! String || token.isEmpty) return null;
  if (refresh is! String || refresh.isEmpty) return null;

  final expiresAt = data['expires_at'];
  return session.copyWith(
    sessionToken: token,
    sessionRefreshToken: refresh,
    expiresAt: expiresAt is String ? expiresAt : session.expiresAt,
    user: _readUser(data['user']) ?? session.user,
    companies: _readCompanies(data['companies']) ?? session.companies,
  );
}

/// A trimmed, non-empty string, or nothing at all.
///
/// `users.name` is NOT NULL but not non-empty, so a profile provisioned from an OIDC account
/// can arrive as `""`. Stored as-is, every display site's `name || email` check treats it as
/// present and shows a blank where the email should have been.
String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

// Email as well as name: the backend's user always carries one, and the Menu has to be able to
// say which cashier is signed in even when the profile has no name.
SessionUser? _readUser(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final id = value['id'];
  if (id is! String) return null;
  return SessionUser(
    id: id,
    name: _text(value['name']),
    email: _text(value['email']),
  );
}

/// The memberships a login returned, when the payload actually carried a list of them.
///
/// A refresh answers with tokens only, and the memberships are persisted and read back by later
/// builds — so a payload that is not a list is treated as "nothing to say", never as "no
/// memberships". Dropping them on a shape this build does not know would strip a signed-in
/// cashier's permissions mid-shift.
///
/// An entry that is not a membership is dropped alone. The source keeps anything with a string
/// `company_id`; here the entry must also parse as a [UserCompany], because a session holding
/// half a membership cannot be saved and read back.
List<UserCompany>? _readCompanies(Object? value) {
  if (value is! List) return null;
  return [for (final entry in value) ?_readCompany(entry)];
}

UserCompany? _readCompany(Object? entry) {
  if (entry is! Map<String, dynamic> || entry['company_id'] is! String) {
    return null;
  }
  try {
    return UserCompany.fromJson(entry);
  } on TypeError {
    return null;
  }
}

/// Renews the session without the cashier noticing.
///
/// Returns `false` when the refresh token no longer resolves — logged out, revoked, or expired —
/// which is the caller's signal to send the cashier through a full login. The stored session is
/// deliberately left untouched on failure, so a transient network problem does not throw away a
/// token that still works.
Future<bool> refreshSession(LoginDeps deps) async {
  final session = deps.session.current;
  final refreshToken = session?.sessionRefreshToken;
  if (session == null || session.baseUrl.isEmpty) return false;
  if (refreshToken == null || refreshToken.isEmpty) return false;

  final TransportResponse response;
  try {
    response = await _send(deps, session.baseUrl, _refreshPath, {
      'refresh_token': refreshToken,
    });
  } on LoginException {
    return false;
  }
  if (!response.ok) return false;

  // The cashier can reset the device while the call is out. Saving what comes back would write
  // the whole session back and silently re-pair a device that was just reset — the same hazard
  // the login poll guards against, which the source leaves open here.
  if (!isSamePairing(deps.session.current, session)) return false;

  final merged = _merge(session, readEnvelopeData(response.body) ?? const {});
  if (merged == null) return false;

  await deps.session.save(merged);
  return true;
}
