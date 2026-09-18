/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/firebase_options.dart';
import 'package:pos/native/analytics/active.dart';
import 'package:pos/native/app_info/active.dart';
import 'package:pos/native/crash_report/active.dart';
import 'package:pos/native/device_info/active.dart';
import 'package:pos/native/hold/active.dart';
import 'package:pos/native/http/active.dart';
import 'package:pos/native/link/active.dart';
import 'package:pos/native/native_update/active.dart';
import 'package:pos/native/opener/active.dart';
import 'package:pos/native/preferences/active.dart';
import 'package:pos/native/printer/active.dart';
import 'package:pos/native/queue/active.dart';
import 'package:pos/native/scanner/active.dart';
import 'package:pos/native/store/active.dart';
import 'package:pos/native/updater/active.dart';
import 'package:pos/preferences/app_preferences.dart';
import 'package:pos/screens/login/login_screen.dart';
import 'package:pos/screens/pairing/pairing_screen.dart';
import 'package:pos/screens/common/till_shell.dart';
import 'package:pos/screens/shift/shift_gate_screen.dart';
import 'package:pos/screens/till/till_screen.dart';

// The only place the real ports meet the app. Everything below it takes them as arguments, so
// it can be run against fakes; this file is not tested because it has no behaviour of its own.
Future<void> main() async {
  // The preferences are plugin calls, and they need the binding before `runApp`.
  WidgetsFlutterBinding.ensureInitialized();

  // Crashlytics/Analytics only for now — no FCM, so no messaging setup here
  // (`.claude/rules/project.md` §2: this app is a thin client, and the backend cannot send a
  // token yet).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Everything the framework catches on its own — a build error, a gesture callback that
  // throws — still goes to the console (`presentError`) and now also to Crashlytics.
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    defaultOnError?.call(details);
    crashReport.recordError(
      details.exceptionAsString(),
      details.stack,
      reason: details.context?.toStringDeep(),
      fatal: true,
    );
  };
  // Everything outside the framework's own zone — a bare `Future` nobody awaited, a stream
  // listener that threw. Returning `true` tells the engine this was handled, so it does not
  // also print it twice.
  PlatformDispatcher.instance.onError = (error, stack) {
    crashReport.recordError(error, stack, fatal: true);
    return true;
  };

  final language = languagePreference(preferences);
  final theme = themePreference(preferences);
  // Before the first frame, so the boot screen is already in the cashier's language and theme.
  // Neither load throws: a storage that cannot be read leaves the defaults.
  await Future.wait([language.load(), theme.load()]);

  runApp(
    PosApp(
      boot: () => bootstrap(
        store: store,
        http: publicHttp,
        opener: opener,
        link: link,
        deviceInfo: deviceInfo,
        appInfo: appInfo,
        printer: printer,
        scanner: scanner,
        holdStore: holdStore,
        pendingSaleStore: pendingSaleStoreFor,
        analytics: analytics,
        language: language,
        theme: theme,
      ),
      language: language,
      theme: theme,
      screens: (pairing: _pairing, login: _login, till: _till),
      updater: updater,
      nativeUpdate: nativeUpdate,
    ),
  );
}

Widget _pairing(BuildContext context) => const PairingScreen();

Widget _login(BuildContext context) => const LoginScreen();

// The shift gate stands in front of the till, and lets through only a cashier who may sell.
//
// The Menu bar is wrapped around the gate, not put inside the till screen: it has to stand over
// every panel the gate can show, including the ones a cashier sees before they may sell.
Widget _till(BuildContext context) => TillShell(
  child: ShiftGateScreen(
    till: (context, shift, preferences) =>
        TillScreen(shift: shift, preferences: preferences),
  ),
);
