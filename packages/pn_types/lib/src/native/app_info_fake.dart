/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'app_info_port.dart';

/// An [AppInfoPort] for tests.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). [answer] can be set to `null` to be a platform that
/// cannot say (§4).
class FakeAppInfo implements AppInfoPort {
  FakeAppInfo({this.answer = const (version: '1.4.2', build: '37')});

  /// What [version] answers.
  AppVersion? answer;

  @override
  Future<AppVersion?> version() async => answer;
}
