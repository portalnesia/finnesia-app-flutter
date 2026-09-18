/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pos/login/native_login.dart';

/// Why the last sign-in did not finish, as something the screen can put in a sentence.
///
/// There is no member for the cashier giving up: they decided, so there is nothing to explain.
enum LoginProblem { notPaired, unavailable, expired, timeout }

/// The state behind the login screen: whether a login is running, and why the last one failed.
///
/// It lives in `AppServices` and not in the screen, because two of the three things that drive
/// it are not the screen: the boot resumes a login the app was killed in the middle of, and the
/// app coming back to the foreground asks for a poll now. A controller owned by the screen would
/// be built after the resume had already started, and would offer a second Masuk button for a
/// login that is already running (`plan/ui/findings.md` F29).
///
/// Ported from the `login`/`isLoggingIn`/`failure` half of `auth-context.tsx`. The source keeps
/// it in a React context, which is the same place in the tree as `AppServices` here.
class LoginController extends ChangeNotifier {
  LoginController(this._deps, {required this._analytics});

  // A function, not the value: `bootstrap` builds the services that carry these deps, so the
  // controller cannot be handed them at construction without a cycle.
  final LoginDeps Function() _deps;

  final AnalyticsPort _analytics;

  /// The login that is running, when one is. What the Batal button and the app's return to the
  /// foreground drive.
  LoginControl? _control;

  LoginProblem? _problem;
  bool _disposed = false;

  /// Whether a login is running: a sign-in the cashier started, or a resume the boot started.
  ///
  /// One flag for both, because from the cashier's seat they are the same login: the screen
  /// shows the same waiting state, and Batal gets out of either.
  bool get isSigningIn => _control != null;

  LoginProblem? get problem => _problem;

  /// Signs the cashier in: opens the browser, then polls until it finishes.
  ///
  /// Asked again while a login is running, it does nothing. The source guards this in the button
  /// alone; here the state guards it too, so no caller can start a second poll loop for one
  /// request id. The backend hands the session out once, and the loser of that race would sit
  /// for the full timeout and then fail.
  Future<void> signIn() async {
    if (isSigningIn) return;
    await _run(
      (control) => loginNative(_deps(), control: control),
      reportAnalytics: true,
    );
  }

  /// Picks up a login the app was killed in the middle of, if one was left behind.
  ///
  /// The same state as [signIn], and deliberately so: the poll can run for minutes, and a
  /// cashier who does not want it must be able to stop it (F5).
  ///
  /// A failure is not shown. Nobody asked for this — it runs on its own at launch — so there is
  /// nobody to tell, and the Masuk button is still there. That is the source's contract
  /// (`auth-context.tsx`, `resumePendingLogin().catch`), narrowed to the failures this can have.
  ///
  /// Logs no analytics event, unlike [signIn]. `resumePendingLogin` completes the same way
  /// whether it recovered a login or found nothing to resume — every ordinary boot calls this —
  /// so there is no signal here to tell "recovered a login" from "nothing was pending" without a
  /// bigger change to `native_login.dart` (`plan/firebase/progress.md`).
  Future<void> resume() async {
    if (isSigningIn) return;
    await _run((control) => resumePendingLogin(_deps(), control: control));
  }

  /// Stops a login that is running. Does nothing when none is.
  void cancel() => _control?.cancel();

  /// The app is back in the foreground, so a running poll should not wait out its interval.
  void pollNow() => _control?.pollNow();

  /// [reportAnalytics] is only ever `true` for [signIn]: see [resume] for why it opts out.
  Future<void> _run(
    Future<void> Function(LoginControl control) login, {
    bool reportAnalytics = false,
  }) async {
    final control = LoginControl();
    _control = control;
    _problem = null;
    notifyListeners();
    if (reportAnalytics) await _analytics.logEvent('login_started');

    try {
      await login(control);
      if (reportAnalytics && !control.isCancelled) {
        await _analytics.logEvent('login_succeeded');
      }
    } on LoginException catch (failure) {
      // A login the cashier gave up on has nothing to explain, and neither has a resume that
      // failed: nobody asked for the second one.
      if (!control.isCancelled) {
        _problem = _problemOf(failure.reason);
        if (reportAnalytics && _problem != null) {
          await _analytics.logEvent(
            'login_failed',
            parameters: {'reason': _problem!.name},
          );
        }
      }
    } on StoreException {
      // The device could not keep the pending marker, or could not drop it. Not the server's
      // fault, and "check the connection" would send the cashier the wrong way. Trying again is
      // the one thing they can act on, and it is the button they are looking at.
      _problem = LoginProblem.unavailable;
      if (reportAnalytics) {
        await _analytics.logEvent(
          'login_failed',
          parameters: {'reason': 'unavailable'},
        );
      }
    } finally {
      // After a success the screen is usually gone already — the session changed under it and
      // the gate moved on — so this must not notify a disposed controller.
      _control = null;
      if (!_disposed) notifyListeners();
    }
  }

  LoginProblem? _problemOf(LoginFailure reason) => switch (reason) {
    LoginFailure.notPaired => LoginProblem.notPaired,
    LoginFailure.unavailable => LoginProblem.unavailable,
    LoginFailure.expired => LoginProblem.expired,
    LoginFailure.timeout => LoginProblem.timeout,
    // Not a failure to report: the cashier tapped Batal, so the screen goes back to the button
    // they started from with nothing said. `_run` checks `isCancelled` before it reaches here,
    // and this member keeps the switch exhaustive so a new failure cannot be added unnoticed.
    LoginFailure.cancelled => null,
  };

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
