/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pos/native/analytics/analytics_firebase.dart';

/// Where product-usage events go.
AnalyticsPort get analytics => _analytics;
AnalyticsPort _analytics = FirebaseAnalyticsPort();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setAnalytics(AnalyticsPort impl) => _analytics = impl;
