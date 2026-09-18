/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'native_update_port.dart';

/// A [NativeUpdatePort] for tests: reports whatever [status] is set to, and records how many
/// times each method was called.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). No failure path: the port's contract is that it
/// never throws (§4 — a fake needs one only where the port can fail).
class FakeNativeUpdate implements NativeUpdatePort {
  FakeNativeUpdate({this.status = NativeUpdateStatus.upToDate});

  NativeUpdateStatus status;
  var checkCount = 0;
  var completeCount = 0;

  @override
  Future<NativeUpdateStatus> checkForUpdate() async {
    checkCount++;
    return status;
  }

  @override
  Future<void> completeUpdate() async {
    completeCount++;
  }
}
