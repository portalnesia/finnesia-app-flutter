/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_hold_store.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/environment.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/native/app_info_port.dart';
import 'package:pn_types/src/native/device_info_port.dart';
import 'package:pn_types/src/native/link_port.dart';
import 'package:pn_types/src/native/opener_port.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/device/device_reset.dart';
import 'package:pos/http/pos_transport.dart';
import 'package:pos/login/login_controller.dart';
import 'package:pos/login/native_login.dart';
import 'package:pos/native/scanner/scanner_port.dart';
import 'package:pos/pairing/pairing.dart';
import 'package:pos/queue/queue_sync.dart';
import 'package:pos/preferences/app_preferences.dart';
import 'package:pos/preferences/enum_preference.dart';
import 'package:pos/session/session_holder.dart';

/// What the app is made of once it is up: the pieces this layer wires together.
///
/// A [ChangeNotifier] so the UI can rebuild when the session or the endpoint pick changes: the
/// session is written from places that do not own the widget tree (pairing saves it from its
/// screen), and `SessionHolder` is read synchronously by the transport, so it cannot be a
/// widget's state itself.
class AppServices extends ChangeNotifier {
  AppServices({
    required this.session,
    required this.client,
    required this.loginDeps,
    required this.deviceInfo,
    required this.appInfo,
    required this.printer,
    required this.scanner,
    required this.holdStore,
    required PendingSaleStore Function(String companyId) pendingSaleStore,
    required this.analytics,
    required this.language,
    required this.theme,
    LinkPort? link,
  }) : pendingSaleStore = pendingSaleStore(session.current?.companyId ?? '') {
    queueSync = QueueSync(
      client: client,
      queue: this.pendingSaleStore,
      session: session,
      analytics: analytics,
    );
    _unsubscribe = session.subscribe((_) => notifyListeners());
    // An incoming App Link is the browser's way of saying the login is done: wake the poll now
    // instead of letting it sit out its two-second interval.
    //
    // Injected, like every other port — deliberately NOT read from the `activeLink` global. A
    // global lookup here meant every boot on Windows (including every `flutter test`) constructed
    // the real plugin, which opens a platform channel that needs a Flutter binding and fails
    // asynchronously from inside the plugin's own `onListen`. Nothing a `try` here could catch,
    // and not something a login should ever depend on. `main.dart` is the one place the real
    // ports meet the app, so the app passes it and a test passes nothing.
    //
    // A `null` link means "this platform has no link listener", not "the listener is idle":
    // Android passes none because the lifecycle observer already covers the wake-up
    // (`native/link/active.dart`, `link_port.dart`).
    //
    // The poll is the real path and the link only speeds it up, so a listener that fails is
    // swallowed rather than taken as a login failure.
    _linkSubscription = link?.links.listen(
      (_) => login.pollNow(),
      onError: (_) {},
    );
  }

  late final StreamSubscription<Uri>? _linkSubscription;

  late final void Function() _unsubscribe;

  final SessionHolder session;

  /// The platform's identifier for this installation. Read at pairing to build the device
  /// fingerprint, so a reinstall does not register a second tablet.
  final DeviceInfoPort deviceInfo;

  /// Which build this is: the Menu shows it.
  final AppInfoPort appInfo;

  /// The thermal printer: paired from the Menu, written to by the reports.
  final PrinterPort printer;

  /// The camera that reads the pairing QR.
  final ScannerPort scanner;

  /// Where baskets the cashier parked are kept (`.claude/rules/project.md` §5: SQLite, not
  /// something the system can clear).
  final HoldOrderStore holdStore;

  /// Where sales that have not reached the server are kept.
  ///
  /// The **same** contract reason as [holdStore] and a stronger one: the money has already been
  /// taken, so this may not be something the system can clear (`project.md` §5, `security.md`
  /// §5). Bound to the tenant, which is why it is built from the session and not a global — and
  /// built **once**, because a device that pairs after boot gets a whole new [AppServices]
  /// rather than a new store under this one (`pos_app.dart` `_rebind`).
  final PendingSaleStore pendingSaleStore;

  /// Drains [pendingSaleStore] in the background (`plan/offline-queue/README.md` §5.2, step Q6).
  late final QueueSync queueSync;

  /// Where product-usage events go (`plan/firebase/README.md`).
  final AnalyticsPort analytics;

  /// Every call to the tenant's API goes through this: the host and the bearer come from
  /// [session] on each request (`PosTransport`), never from the caller.
  final ApiClient client;

  /// What `loginNative` and `refreshSession` take. Its store, HTTP and session are the ones
  /// pairing uses too, so a device paired here is logged in against the same storage.
  final LoginDeps loginDeps;

  /// The tablet's local store: the session, and which printer is paired.
  StorePort get store => loginDeps.store;

  /// The login the sign-in screen drives, and the app's way of telling it it is back.
  ///
  /// Here rather than in the screen because the boot resumes a login by itself, and the app's
  /// return to the foreground happens above any screen (`plan/ui/findings.md` F29).
  late final login = LoginController(() => loginDeps, analytics: analytics);

  /// Counts the shifts closed from inside the app. The shift gate reads the shift again when it
  /// moves: the drawer it let the cashier into no longer exists, and the till it is showing is
  /// selling into it.
  ///
  /// Not a stream of shifts: the gate re-reads the server rather than trusting a payload, so all it
  /// needs to be told is that something changed.
  final shiftClosed = ValueNotifier<int>(0);

  /// The drawer open at the till, as the shift gate last read it — null before it has read
  /// anything, and when no shift is open. The gate keeps this current; the shell above it reads
  /// it to decide whether the shift detail action has anything to show.
  final activeShift = ValueNotifier<POSShift?>(null);

  /// The language and theme the cashier picked. The root reads them to build the app, the menu
  /// changes them, and the API client asks in the language on every request.
  final EnumPreference<AppLanguage> language;
  final EnumPreference<ThemeMode> theme;

  // Not persisted: a pick before pairing lasts one launch (README §13.2).
  var _endpoint = EndpointEnvironment.staging;

  /// The endpoint environment pairing will use. Meaningful only while [canPickEndpoint]:
  /// after pairing the host is the session's.
  EndpointEnvironment get endpoint => _endpoint;

  /// Whether the pairing screen may offer a choice of endpoint. Read from the session every
  /// time: the moment pairing saves one, the choice is gone.
  bool get canPickEndpoint =>
      canChooseEndpoint(isPaired: session.current != null);

  /// Picks the endpoint environment pairing will talk to. Does nothing when
  /// [canPickEndpoint] is false: once paired the host belongs to the session, and a release
  /// build has only one (`canonicalHost` ignores the choice there too).
  void chooseEndpoint(EndpointEnvironment choice) {
    if (!canPickEndpoint || choice == _endpoint) return;
    _endpoint = choice;
    notifyListeners();
  }

  @override
  void dispose() {
    _unsubscribe();
    _linkSubscription?.cancel();
    login.dispose();
    queueSync.dispose();
    shiftClosed.dispose();
    activeShift.dispose();
    super.dispose();
  }

  PairingDeps get pairingDeps => (
    store: loginDeps.store,
    http: loginDeps.http,
    session: session,
    deviceInfo: deviceInfo,
    appInfo: appInfo,
    canonicalHost: canonicalHost(_endpoint),
  );

  /// What `resetDevice` takes. The same HTTP port and session the rest of the app uses, so the
  /// device token the request needs is the one pairing stored.
  DeviceResetDeps get deviceResetDeps => (
    http: loginDeps.http,
    session: session,
    holdStore: holdStore,
    pendingSaleStore: pendingSaleStore,
    analytics: analytics,
  );

  /// Renews the session at launch if it is in the last half of its life, or past its end.
  /// Never throws.
  ///
  /// A bearer session is not extended by use: only a refresh does that. A device that was off for
  /// days comes back here, and this is where it renews.
  ///
  /// A session that has ended is tried too, and that is deliberate. The backend keeps an ended
  /// session refreshable for 14 days after its end (`sessionRefreshGracePeriod`), while access
  /// stays strict, so a tablet that sat idle for ten days recovers here without a login. How far
  /// past the end is still refreshable is the server's to say, not this clock's: a wrong clock
  /// here must not decide that a good session is gone. A session with no readable end is left to
  /// the 401 path.
  Future<void> refreshIfExpiring() async {
    final current = session.current;
    if (current == null || current.sessionToken.isEmpty) return;
    if (!endsWithin(current, refreshWithin, loginDeps.now())) return;

    await _refreshSafely(loginDeps);
  }

  /// Picks up a login the app was killed in the middle of, if one was left behind.
  ///
  /// Never throws. Nobody has asked for this — it runs on its own at launch — so a failure has
  /// nobody to be shown to, and the sign-in button is still there. That is the source's
  /// contract (`auth-context.tsx`, `resumePendingLogin().catch`), narrowed to the two failures
  /// this can actually have: anything else is a bug and should stay loud.
  ///
  /// Through [login] rather than straight to `resumePendingLogin`, so a cashier who does not
  /// want to wait out a login they were killed in the middle of can stop it: the screen shows
  /// the same waiting state and the same Batal button.
  Future<void> resumeLogin() => login.resume();

  /// Tells a running login that the app is back in the foreground, so it polls now instead of
  /// waiting out the interval it is in.
  ///
  /// The cashier leaves the app to finish signing in at the browser, so coming back is the
  /// ordinary moment the answer is already waiting, and sitting out two more seconds of interval
  /// is two seconds of spinner over an answer that is already there.
  ///
  /// It is also a moment to try the offline queue (D-Q8): a tablet that spent the afternoon out
  /// of coverage gets its pending sales sent the moment a cashier picks it back up, rather than
  /// waiting out whatever is left of the periodic interval.
  void onForeground() {
    login.pollNow();
    queueSync.sync();
  }
}

sealed class BootResult {
  const BootResult();
}

class BootReady extends BootResult {
  const BootReady(this.services);

  final AppServices services;
}

class BootFailed extends BootResult {
  const BootFailed(this.cause);

  final StoreException cause;
}

/// Half of the backend's seven-day session (`SessionTTL`). Our own policy, not a backend
/// threshold: a bearer session is renewed only by a refresh, and renewing with half of it left
/// leaves three and a half days for a refresh that fails (no network, the server down) before
/// access ends, and then the 14 days the backend keeps it refreshable. If `SessionTTL` changes,
/// revisit this.
const refreshWithin = Duration(hours: 84);

/// `refreshSession`, made safe to hand to the transport: it says `false` for every way it can
/// fail, including a store that cannot take the new session.
Future<bool> _refreshSafely(LoginDeps deps) async {
  try {
    return await refreshSession(deps);
  } on StoreException {
    // The old session is still what is stored, and the request that asked gets its 401.
    return false;
  }
}

// Same as the source (`native-login.ts`): a poll every two seconds, for five minutes.
Future<void> _pollEvery2Seconds() => Future.delayed(const Duration(seconds: 2));
const _pollFor = Duration(minutes: 5);

Duration _osOffset() => DateTime.now().timeZoneOffset;

/// Wires the app together and reads the persisted session.
Future<BootResult> bootstrap({
  required StorePort store,
  required PublicHttpPort http,
  required OpenerPort opener,
  required DeviceInfoPort deviceInfo,
  required AppInfoPort appInfo,
  required PrinterPort printer,
  required ScannerPort scanner,
  required HoldOrderStore holdStore,

  /// Builds the queue for a tenant. A factory, not a store: the store is bound to a company, and
  /// the company is only known once the session has been read (`plan/offline-queue/README.md`
  /// §4.1). `main.dart` passes the SQLite one; a test passes a fake and never touches a disk.
  required PendingSaleStore Function(String companyId) pendingSaleStore,
  required AnalyticsPort analytics,
  required EnumPreference<AppLanguage> language,
  required EnumPreference<ThemeMode> theme,
  LinkPort? link,
  Future<void> Function() delay = _pollEvery2Seconds,
  Duration pollTimeout = _pollFor,
  DateTime Function() now = DateTime.now,
  Duration Function() deviceOffset = _osOffset,
}) async {
  // The money formatter throws until it has its locale data. Here, before any screen exists, so
  // no screen has to remember to; it is idempotent and needs no I/O.
  initializePosNumberFormat();
  // The date formatters throw until the zone database is loaded, and fall back to UTC until they
  // are told the tablet's zone (`useFixedLocalZone`).
  await initializePosDateTime();
  useFixedLocalZone(deviceOffset());
  final session = SessionHolder(store);
  try {
    await session.hydrate();
  } on StoreException catch (failure) {
    // Not "unpaired" and not wiped: the session may well be there, and only the Keystore
    // cannot open it right now. Clearing storage to recover would unpair a paired device,
    // so recovery is left to the caller — try again, or a decision the owner has not made.
    return BootFailed(failure);
  }
  final loginDeps = (
    store: store,
    http: http,
    opener: opener,
    session: session,
    delay: delay,
    pollTimeout: pollTimeout,
    now: now,
  );
  final transport = PosTransport(
    session: session,
    http: http,
    refresh: () => _refreshSafely(loginDeps),
    refreshWithin: refreshWithin,
    now: now,
  );
  return BootReady(
    AppServices(
      session: session,
      client: ApiClient(
        transport: transport,
        language: () => language.value.name,
      ),
      loginDeps: loginDeps,
      deviceInfo: deviceInfo,
      appInfo: appInfo,
      printer: printer,
      scanner: scanner,
      holdStore: holdStore,
      pendingSaleStore: pendingSaleStore,
      analytics: analytics,
      language: language,
      theme: theme,
      link: link,
    ),
  );
}
