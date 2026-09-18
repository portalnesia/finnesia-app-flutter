/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/crash_report_port.dart';
import 'package:pos/native/crash_report/crash_report_firebase.dart';

/// Where crash and error reports go.
CrashReportPort get crashReport => _crashReport;
CrashReportPort _crashReport = FirebaseCrashReport();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setCrashReport(CrashReportPort impl) => _crashReport = impl;
