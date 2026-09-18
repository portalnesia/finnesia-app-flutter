/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:collection';

import 'opener_port.dart';

/// An [OpenerPort] for tests: records every URL and can be told to fail.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). Fails on request (§4: a fake with no failure path
/// never exercises what the caller does about one).
class FakeOpener implements OpenerPort {
  /// Every URL received, in order — including the ones that failed.
  final opened = <String>[];

  final _failures = Queue<OpenerException>();

  /// Makes the next call throw [failure].
  void failNext(OpenerException failure) => _failures.add(failure);

  @override
  Future<void> openUrl(String url) async {
    opened.add(url);
    if (_failures.isNotEmpty) throw _failures.removeFirst();
  }
}
