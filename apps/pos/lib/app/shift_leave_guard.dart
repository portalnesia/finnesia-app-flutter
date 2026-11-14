/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pn_types/src/native/app_exit_port.dart';
import 'package:pn_types/src/native/exit_notice_port.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/native/app_exit/active.dart';
import 'package:pos/native/crash_report/active.dart';
import 'package:pos/native/exit_notice/active.dart';
import 'package:pos/screens/shift/shift_leave_dialog.dart';

/// Reminds the cashier of their open shift on every way out of the app the platform tells the
/// app about, before letting them go. A reminder, never a lock.
///
/// - **Android back at the root.** Held by a [PopScope] while there is a shift to remind of;
///   after "leave anyway" the app does what the back press would have done ([AppExitPort]).
///   Back presses inside a pushed screen are untouched: they only close that screen.
/// - **Closing the window on desktop** (the title-bar close, Alt+F4, the taskbar's "Close
///   window"). The engine asks the framework first, and [AppLifecycleListener.onExitRequested]
///   answers after the cashier has chosen.
///
/// Two more ways out reach the platform but never the Dart side, so the platform is kept told
/// beforehand what to say ([ExitNoticePort]):
///
/// - **Android, swiping the app away from Recents.** `ShiftReminderService` runs while there is
///   a shift to remind of, and posts the reminder as a notification from `onTaskRemoved`.
/// - **Windows shutting down or signing out.** The runner gives Windows the reminder as the
///   reason on its "an app is preventing shutdown" screen, where "shut down anyway" stays.
///
/// Not covered, because nothing hears it: a process killed outright (Task Manager's "End
/// process", `taskkill /F`, Android killing the app from settings or for memory). The shift gate's
/// "already open" panel is what the cashier meets on the next launch instead.
///
/// Mounted under the [Navigator] (as the home route's child), so it can show a dialog, and kept
/// for as long as the gate is: screens pushed on top do not remove it.
class ShiftLeaveGuard extends StatefulWidget {
  const ShiftLeaveGuard({super.key, required this.child});

  final Widget child;

  @override
  State<ShiftLeaveGuard> createState() => _ShiftLeaveGuardState();
}

class _ShiftLeaveGuardState extends State<ShiftLeaveGuard> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onExitRequested: _onExitRequested,
  );
  ValueNotifier<POSShift?>? _reminder;

  /// What the platform was last told, so it is told again only when the text changes.
  ExitNotice? _toldPlatform;

  /// Read in [didChangeDependencies] and kept: the gate clears the reminder from its own
  /// `dispose`, which reaches [_tellPlatform] while this element is already being torn down and
  /// may no longer look anything up.
  L10n? _l10n;

  /// True while the reminder is on screen, so a second close or back press does not stack a
  /// second dialog on the first.
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    // Touched so the listener exists from the start, not from the first exit request.
    _lifecycle;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = L10n.of(context);
    final reminder = AppScope.of(context).shiftLeaveReminder;
    if (!identical(reminder, _reminder)) {
      _reminder?.removeListener(_tellPlatform);
      _reminder = reminder..addListener(_tellPlatform);
    }
    // Here too, not only on a change of shift: a change of language changes the text.
    _tellPlatform();
  }

  @override
  void dispose() {
    _reminder?.removeListener(_tellPlatform);
    _lifecycle.dispose();
    // Gone with the gate (a sign-out, a re-pair): nobody at the till holds a shift to remind of.
    _sendNotice(null);
    super.dispose();
  }

  void _tellPlatform() {
    final shift = _reminder?.value;
    final l10n = _l10n;
    _sendNotice(
      shift == null || l10n == null
          ? null
          : ExitNotice(
              title: l10n.shiftLeaveTitle,
              body: l10n.shiftLeaveNoticeBody(shift.number),
            ),
    );
  }

  void _sendNotice(ExitNotice? notice) {
    if (notice == _toldPlatform) return;
    _toldPlatform = notice;
    exitNotice.setNotice(notice).catchError((Object error, StackTrace stack) {
      // Nothing on screen depends on it, so the cashier is not interrupted; but a till whose
      // platform cannot be told is one whose shutdown reminder silently never shows, so it is
      // reported rather than dropped (`security.md` §5).
      crashReport.recordError(
        error,
        stack,
        reason: 'exit notice not delivered',
      );
    });
  }

  /// Asks the cashier; true means leave. A request that arrives while already asking is answered
  /// "stay": the dialog on screen is the one the cashier is answering.
  Future<bool> _ask(POSShift shift) async {
    if (_asking) return false;
    _asking = true;
    try {
      return await showShiftLeaveReminder(context, shift);
    } finally {
      _asking = false;
    }
  }

  Future<AppExitResponse> _onExitRequested() async {
    final shift = _reminder?.value;
    if (shift == null || !mounted) return AppExitResponse.exit;
    return await _ask(shift) ? AppExitResponse.exit : AppExitResponse.cancel;
  }

  Future<void> _onBackAtRoot() async {
    final shift = _reminder?.value;
    if (shift == null) return;
    if (!await _ask(shift)) return;
    try {
      await appExit.exit();
    } on AppExitException {
      // The app is still here, so the cashier has to be told the tap did nothing
      // (`security.md` §5: no swallow).
      if (mounted) {
        showTopNotice(context, message: L10n.of(context).shiftLeaveExitFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminder = _reminder!;
    return ValueListenableBuilder<POSShift?>(
      valueListenable: reminder,
      builder: (context, shift, child) => PopScope<Object?>(
        // Nothing to remind of: the back press does what it always did.
        canPop: shift == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBackAtRoot();
        },
        child: child!,
      ),
      child: widget.child,
    );
  }
}
