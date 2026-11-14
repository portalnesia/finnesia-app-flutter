/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';

part 'exit_notice_port.freezed.dart';

/// Tells the platform what to say if the app is closed in a way the app itself never hears
/// about.
///
/// Some ways out reach the platform but never the Dart side: Android's swipe from Recents
/// (only a running service's `onTaskRemoved` hears it) and Windows shutting down or signing out
/// (`WM_QUERYENDSESSION`, answered by the runner). The platform cannot ask Dart at that moment,
/// so it has to be told beforehand what to say — this port keeps it told.
///
/// A port because the real one is a platform channel, which does not exist under `dart test`.
/// Pure types — no plugin import may appear here (`.claude/rules/native-ports.md` §2.1).
abstract interface class ExitNoticePort {
  /// Replaces what the platform says on such an exit; null means say nothing.
  ///
  /// Throws [ExitNoticeException] when the platform could not be told.
  Future<void> setNotice(ExitNotice? notice);
}

/// What the platform shows: already in the cashier's language, because the platform has no
/// translations of its own.
@freezed
abstract class ExitNotice with _$ExitNotice {
  const factory ExitNotice({required String title, required String body}) =
      _ExitNotice;
}

/// The platform could not be told.
class ExitNoticeException implements Exception {
  ExitNoticeException(this.message, {this.cause});

  final String message;

  /// Whatever the platform threw, for a debugger. Never printed.
  final Object? cause;

  @override
  String toString() => 'ExitNoticeException: $message';
}
