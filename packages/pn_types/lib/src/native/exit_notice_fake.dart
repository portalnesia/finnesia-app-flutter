/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:collection';

import 'exit_notice_port.dart';

/// An [ExitNoticePort] for tests: records every change and can be told to fail.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). Fails on request (§4).
class FakeExitNotice implements ExitNoticePort {
  /// Every notice received, in order, including the ones that failed. Null is "say nothing".
  final changes = <ExitNotice?>[];

  /// What the platform would say now: the last notice that went through.
  ExitNotice? current;

  final _failures = Queue<ExitNoticeException>();

  /// Makes the next call throw [failure].
  void failNext(ExitNoticeException failure) => _failures.add(failure);

  @override
  Future<void> setNotice(ExitNotice? notice) async {
    changes.add(notice);
    if (_failures.isNotEmpty) throw _failures.removeFirst();
    current = notice;
  }
}
