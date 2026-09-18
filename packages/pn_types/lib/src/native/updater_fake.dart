/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'updater_port.dart';

/// An [UpdaterPort] for tests: reports whatever [status] is set to, and records how many times
/// it was asked.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). No failure path: the port's contract is that it
/// never throws (§4 — a fake needs one only where the port can fail).
class FakeUpdater implements UpdaterPort {
  FakeUpdater({this.status = UpdaterStatus.upToDate});

  UpdaterStatus status;
  var checkCount = 0;

  @override
  Future<UpdaterStatus> checkForUpdate() async {
    checkCount++;
    return status;
  }
}
