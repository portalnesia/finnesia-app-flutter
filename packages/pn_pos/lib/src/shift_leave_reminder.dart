/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Whether leaving the app should first remind the cashier that their shift is still open.
///
/// A reminder, not a lock: a cashier who walks away with the drawer still open leaves a shift
/// nobody reconciles, and the next person at the outlet finds a drawer they cannot use. Leaving
/// stays allowed; the cashier only sees the reminder first.
///
/// Only the cashier holding the shift is reminded. A shift someone else holds is not theirs to
/// close, and with shifts switched off the open shift is bookkeeping the server maintains, not a
/// session anyone holds. An unknown state (a read that failed) reminds nobody: a reminder about a
/// shift the till cannot vouch for is noise.
///
/// Same rule as `shouldWarnOnLeave` in `apps/web/src/lib/pos-leave-guard.ts` of the source repo.
bool shouldWarnOnLeave({
  required bool requireShift,
  required bool shiftStateKnown,
  required String? shiftId,
  required String? shiftOwnerId,
  required String? currentUserId,
}) {
  if (!requireShift || !shiftStateKnown) return false;
  // `!input.shiftId` and `!!input.currentUserId` in the source: `''` counts as missing.
  if (shiftId == null || shiftId.isEmpty) return false;
  if (currentUserId == null || currentUserId.isEmpty) return false;
  return shiftOwnerId == currentUserId;
}
