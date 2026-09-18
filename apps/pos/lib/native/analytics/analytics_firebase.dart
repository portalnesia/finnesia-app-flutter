/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:pn_types/src/native/analytics_port.dart';

/// [AnalyticsPort] over Firebase Analytics.
class FirebaseAnalyticsPort implements AnalyticsPort {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } on FirebaseException {
      // The port's contract (`analytics_port.dart`): losing an event must never take a sale
      // down with it.
    } on PlatformException {
      // `MethodChannelFirebaseAnalytics.logEvent` wraps the Pigeon call in `try { return
      // _api.logEvent(...); } catch (e, s) { convertPlatformException(e, s); }` with no
      // `await` — so it only converts a *synchronous* throw to `FirebaseException`. A platform
      // failure, which arrives asynchronously once the returned future completes, comes
      // straight through as the raw `PlatformException`. Verified by running a test against
      // that failure, not by reading the wrapping code alone — it looks like it always
      // converts, and does not.
    } on MissingPluginException {
      // Same asymmetry as above, for the platform (Windows) that has no Firebase plugin at all.
    }
  }
}
