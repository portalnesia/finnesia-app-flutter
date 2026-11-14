/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:collection';

import 'app_exit_port.dart';

/// An [AppExitPort] for tests: counts every exit and can be told to fail.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). Fails on request (§4: a fake with no failure path
/// never exercises what the caller does about one).
class FakeAppExit implements AppExitPort {
  /// How many exits were asked for, including the ones that failed.
  int exits = 0;

  final _failures = Queue<AppExitException>();

  /// Makes the next call throw [failure].
  void failNext(AppExitException failure) => _failures.add(failure);

  @override
  Future<void> exit() async {
    exits++;
    if (_failures.isNotEmpty) throw _failures.removeFirst();
  }
}
