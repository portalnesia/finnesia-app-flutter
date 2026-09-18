/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:pn_types/src/native/crash_report_port.dart';

/// [CrashReportPort] over Firebase Crashlytics.
class FirebaseCrashReport implements CrashReportPort {
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        fatal: fatal,
        // The default already only prints in debug mode; pinned explicitly so a config change
        // upstream cannot start printing exception text (which can carry request ids) in release.
        printDetails: false,
      );
    } on FirebaseException {
      // The port's contract (`crash_report_port.dart`): reporting a crash must never cause one.
      // `firebase_crashlytics` wraps every platform-channel failure as a `FirebaseException`,
      // the same as `firebase_analytics` (`analytics_firebase.dart`).
    } on MissingPluginException {
      // Defensive: see analytics_firebase.dart.
    }
  }

  @override
  Future<void> log(String message) async {
    try {
      await FirebaseCrashlytics.instance.log(message);
    } on FirebaseException {
      // See recordError above.
    } on MissingPluginException {
      // See recordError above.
    }
  }
}
