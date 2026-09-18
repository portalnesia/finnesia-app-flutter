/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pos/http/inspector/request_inspector.dart';
import 'package:pos/native/http/public_http_dio.dart';

/// What the debug screen reads (README §14). Only a debug app ever puts anything in it:
/// [DioPublicHttp] installs its interceptor through `installInspector`, which does nothing in
/// a release build.
final requestInspector = RequestInspector();

PublicHttpPort get publicHttp => _publicHttp;
PublicHttpPort _publicHttp = DioPublicHttp(inspector: requestInspector);

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setPublicHttp(PublicHttpPort impl) => _publicHttp = impl;
