/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pn_types/src/native/native_update_port.dart';
import 'package:pn_types/src/native/updater_port.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/boot_screens.dart';
import 'package:pos/app/gate.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/preferences/app_preferences.dart';
import 'package:pos/preferences/enum_preference.dart';

/// Paints the Android status bar and navigation bar to match the theme in force: the screen's
/// own background behind them, and icons that contrast with that background.
///
/// Nothing else sets this: the engine default leaves white buttons on a white bar in the light
/// theme, and a white bar in the dark one, and the status bar's icons follow the device's
/// setting and not the app's, so they came out black on the dark theme. Reads the resolved
/// [Theme], not the device setting, so the cashier's in-app light/dark choice is what the bars
/// follow.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // Transparent, so the screen's own colour shows behind the clock and icons; only their
        // colour is ours to choose, and it has to contrast with that screen.
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}

/// Tells the cashier a Shorebird patch has finished downloading and only needs a restart —
/// the in-app counterpart of the update notice Play Store or Telegram show, except this one
/// works before the app is even on Play Store (`docs/distribution.md` §4).
///
/// Purely informational: it does not restart the app itself (no cross-platform way to do that
/// without a plugin nobody has asked for), and it does not block anything underneath it — the
/// patch already applies on its own the next time the app happens to restart.
class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.system_update_alt),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  L10n.of(context).updateReadyMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tells the cashier a native (APK/AAB) update has finished downloading in the background,
/// with an action to install it now — Play Store's own in-app update prompt
/// (`docs/distribution.md` §5), not Shorebird's: this only ever fires for a genuinely new
/// versionCode Play has published, which a Shorebird patch can never produce.
///
/// Unlike [_UpdateBanner], this one acts: installing restarts the app, so the cashier
/// chooses when, never automatically.
class _NativeUpdateBanner extends StatelessWidget {
  const _NativeUpdateBanner({required this.onInstall});

  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return SafeArea(
      bottom: false,
      child: Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.system_update_alt),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.nativeUpdateReadyMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: onInstall,
                child: Text(l10n.nativeUpdateAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app: boots, then shows the screen the session decides (`Gate`).
///
/// [language] and [theme] are given here and not read from the booted services because the
/// boot screens themselves are drawn in the cashier's language and theme, and they exist
/// before there are any services.
class PosApp extends StatefulWidget {
  const PosApp({
    super.key,
    required this.boot,
    required this.language,
    required this.theme,
    required this.screens,
    this.updater,
    this.nativeUpdate,
  });

  final Future<BootResult> Function() boot;
  final EnumPreference<AppLanguage> language;
  final EnumPreference<ThemeMode> theme;
  final GateScreens screens;

  /// Checks for a Shorebird OTA patch once the app is up. `null` (most tests, and any platform
  /// with no updater wired) means no check happens and no banner ever shows — same shape as
  /// [PosApp.boot]'s optional `link`, for the same reason: most call sites do not care.
  final UpdaterPort? updater;

  /// Checks Play Store for a native (APK/AAB) update once the app is up. Same optional shape
  /// as [updater], and deliberately a separate port: the two updates are independent, and a
  /// cashier must be able to see either without the other.
  final NativeUpdatePort? nativeUpdate;

  @override
  State<PosApp> createState() => _PosAppState();
}

class _PosAppState extends State<PosApp> with WidgetsBindingObserver {
  BootResult? _result;

  /// Whether a downloaded patch is waiting for the app to restart. Never set outside
  /// production: [UpdaterPort.checkForUpdate] itself answers [UpdaterStatus.upToDate] on any
  /// build not made with `shorebird release` (`updater_shorebird.dart`), so nothing here needs
  /// its own release-mode guard.
  final _restartRequired = ValueNotifier<bool>(false);

  /// Whether Play has a native update downloaded and ready to install. Same production-only
  /// reasoning as [_restartRequired], for the native side: a build the Play Core API does not
  /// recognise (debug, sideloaded, or made before Play Console is set up) answers
  /// [NativeUpdateStatus.upToDate] on its own (`native_update_play.dart`).
  final _nativeUpdateReady = ValueNotifier<bool>(false);

  /// The pairing the services were built for, so a change of identity can be noticed.
  ///
  /// `isSamePairing` rather than `==` on the session object: rotating a token replaces the object
  /// without the device having moved, and a refresh must not tear the app down and rebuild it.
  /// Only the tenant identity — host, company, outlet — is what the services are bound to.
  PosSession? _bootedPairing;

  /// Whether a rebuild is under way, so two session writes in the same frame cannot start two.
  bool _rebinding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _run();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restartRequired.dispose();
    _nativeUpdateReady.dispose();
    final result = _result;
    if (result is BootReady) result.services.dispose();
    super.dispose();
  }

  /// Whether the services in hand were built for the session the app is now on.
  ///
  /// A device that pairs **after** boot is the case that matters: the services were built while
  /// the session was null, so the pending-sale queue inside them is bound to the empty company.
  /// Pairing then saves the real company, and without this the queue stays bound to `''` — the
  /// till's `enqueue` refuses every sale with an `ArgumentError` the pay screen cannot report,
  /// so the button looks dead and the money is never recorded (`tenant_rebind_test.dart`).
  bool get _tenantChanged {
    final result = _result;
    if (result is! BootReady) return false;
    return !isSamePairing(result.services.session.current, _bootedPairing);
  }

  /// Rebuilds what is bound to the tenant, keeping the app running.
  ///
  /// A full re-boot rather than a rebind of the queue alone: the queue is not the only thing
  /// derived from the session. A re-boot is also the only shape that reaches the till, which
  /// captured its `CheckoutService` — and the store inside it — when it was first built
  /// (`till_screen.dart` `didChangeDependencies`), so a swap underneath it would leave the old
  /// store in the cashier's hands. Nothing else is lost: the basket, the shift and the held
  /// orders are not part of the services.
  Future<void> _rebind() async {
    if (_rebinding) return;
    _rebinding = true;
    try {
      final result = await widget.boot();
      if (!mounted) return;
      final previous = _result;
      setState(() => _result = result);
      // After `setState`, so the tree never holds services that are already disposed. Disposing
      // also unsubscribes the old holder's listener, which is what keeps this from accumulating
      // one listener per re-pair.
      if (previous is BootReady) previous.services.dispose();
      if (result is! BootReady) return;
      _bootedPairing = result.services.session.current;
      result.services.session.subscribe((_) => _onSessionChanged());
      await result.services.resumeLogin();
      await result.services.refreshIfExpiring();
      result.services.queueSync.start();
    } finally {
      _rebinding = false;
    }
  }

  /// Rebuilds the services when the tenant the app is paired with changes, so nothing stays
  /// bound to the pairing it was built for.
  void _onSessionChanged() {
    if (!_tenantChanged) return;
    // Fire-and-forget: a rebuild is not something a caller waits for, and a `setState` during a
    // build (pairing saves the session from a button's callback, which is a build-adjacent
    // moment) must not be run synchronously here.
    unawaited(_rebind());
  }

  /// The cashier leaves the app to finish signing in at the browser, so coming back is the
  /// ordinary moment the answer is already waiting. A running poll is told to ask now rather
  /// than sit out the rest of its interval, which is what makes the return feel immediate.
  ///
  /// Here, above the screens: the login outlives whichever screen happens to be showing, and the
  /// services are what own it (`plan/ui/findings.md` F29).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final result = _result;
    if (result is BootReady) result.services.onForeground();
  }

  Future<void> _run() async {
    final result = await widget.boot();
    if (!mounted) return;
    setState(() => _result = result);
    if (result is! BootReady) return;
    _bootedPairing = result.services.session.current;
    // The rebuild above runs when the pairing identity changes, and it is the only listener the
    // app adds: the holder notifies on every save, and `_tenantChanged` filters out the ones that
    // are not a new tenant (a token rotation, a sign-in, a sign-out).
    result.services.session.subscribe((_) => _onSessionChanged());

    // A login the app was killed in the middle of, then a session close to its end. Neither
    // throws, and the screen follows because the session is what the gate reads. In this
    // order: a login just collected is a fresh session, and needs no refresh.
    await result.services.resumeLogin();
    await result.services.refreshIfExpiring();
    // D-Q8: coming up is also a moment to try the offline queue, and starts the periodic pass
    // that keeps trying every interval for the rest of the app's life.
    result.services.queueSync.start();

    // Fire-and-forget: neither update check must ever hold up the till coming up.
    final updater = widget.updater;
    if (updater != null) unawaited(_checkForUpdate(updater));
    final nativeUpdate = widget.nativeUpdate;
    if (nativeUpdate != null) unawaited(_checkForNativeUpdate(nativeUpdate));
  }

  Future<void> _checkForUpdate(UpdaterPort updater) async {
    final status = await updater.checkForUpdate();
    if (!mounted) return;
    if (status == UpdaterStatus.restartRequired) _restartRequired.value = true;
  }

  Future<void> _checkForNativeUpdate(NativeUpdatePort nativeUpdate) async {
    final status = await nativeUpdate.checkForUpdate();
    if (!mounted) return;
    if (status == NativeUpdateStatus.readyToInstall) {
      _nativeUpdateReady.value = true;
    }
  }

  void _installNativeUpdate() {
    final nativeUpdate = widget.nativeUpdate;
    if (nativeUpdate == null) return;
    // The install itself restarts the app; nothing here needs to react to its result.
    unawaited(nativeUpdate.completeUpdate());
  }

  void _retry() {
    setState(() => _result = null);
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    // Rebuilt when the cashier picks another language or theme, so it applies at once and
    // nothing needs a restart.
    return ListenableBuilder(
      listenable: Listenable.merge([widget.language, widget.theme]),
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => L10n.of(context).appName,
        theme: pnTheme(Brightness.light),
        darkTheme: pnTheme(Brightness.dark),
        themeMode: widget.theme.value,
        locale: widget.language.value.locale,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        // Above the Navigator, so a route pushed later sees the services too.
        builder: (context, child) => _SystemBars(
          child: Stack(
            children: [
              result is BootReady
                  ? AppScope(services: result.services, child: child!)
                  : child!,
              // Above every screen, like the banner's Telegram/Play Store counterpart: a
              // cashier mid-sale is never interrupted by it, but it is never hidden either.
              // A Column, not a single slot: the Shorebird and native checks are independent
              // (`native_update_port.dart`), so both can have something to say at once.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _nativeUpdateReady,
                    builder: (context, ready, _) => ready
                        ? _NativeUpdateBanner(onInstall: _installNativeUpdate)
                        : const SizedBox.shrink(),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _restartRequired,
                    builder: (context, needsRestart, _) => needsRestart
                        ? const _UpdateBanner()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
        home: switch (result) {
          null => const BootScreen(),
          BootFailed() => BootFailedScreen(onRetry: _retry),
          BootReady() => Gate(screens: widget.screens),
        },
      ),
    );
  }
}
