/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';

/// The notice currently on screen, so a new one replaces it rather than stacking under it.
OverlayEntry? _current;

/// Tells the cashier something happened, at the **top** of the screen, and takes it away again.
///
/// ## Why not a `SnackBar`
///
/// Two measured reasons, both from the till screen:
///
/// 1. **It sits on the Pay button.** A default SnackBar at 800x600 occupied
///    `Rect.fromLTRB(0.0, 552.0, 800.0, 600.0)`: the last 48 px, which is where Pay is. A cashier
///    who removes a line and then wants to pay has to wait out or dismiss a message they did not
///    ask for.
/// 2. **A SnackBar with an action never leaves.** Measured: with a `SnackBarAction` the bar was
///    still on screen after 12 seconds against a 4-second duration, while the same bar without an
///    action was gone. Flutter keeps that timer alive while the action can take focus
///    (flutter#111874). The undo affordance is the entire reason this notice exists, so dropping
///    the action is not an option.
///
/// A bar that is closed by the framework's clock, on top of the button the screen exists for, is
/// the wrong tool. This draws its own, in the one place that covers nothing.
///
/// ## Lifetime
///
/// The notice removes itself after [duration], or when its action is used. The timer belongs to
/// the widget and is cancelled when that widget goes away, so a screen disposed mid-wait cannot
/// have a stale callback run against a dead overlay.
///
/// ## What it is for
///
/// Short facts about something that already happened: a line was removed, a sign-out failed, a
/// scan found nothing. **Not** for anything the cashier must act on — an unconfirmed sale belongs
/// on the payment screen, where it stays until it is dealt with (`plan/ui/findings.md` F34).
void showTopNotice(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  // The root overlay, so a notice shown from a pushed route is not clipped by it.
  final overlay = Overlay.of(context, rootOverlay: true);

  // One at a time: two stacked notices cover the catalogue, and the older one is about something
  // that has already happened.
  _current?.remove();
  _current = null;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TopNotice(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      onGone: () {
        if (identical(_current, entry)) _current = null;
        entry.remove();
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

/// Removes whatever notice is on screen, if any. For a screen that is going away and does not
/// want its message left behind on the next one.
void dismissTopNotice() {
  _current?.remove();
  _current = null;
}

class _TopNotice extends StatefulWidget {
  const _TopNotice({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onGone,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;

  /// Called once, when the notice is finished with: its own timer ran out, its action was used,
  /// or it was dismissed.
  final VoidCallback onGone;

  @override
  State<_TopNotice> createState() => _TopNoticeState();
}

class _TopNoticeState extends State<_TopNotice> {
  Timer? _timer;
  var _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _leave);
  }

  @override
  void dispose() {
    // The reason this is a widget and not a bare `Future.delayed`: a screen that goes away
    // mid-wait must not leave a callback that runs against a dead overlay.
    _timer?.cancel();
    super.dispose();
  }

  /// Fades out, then removes itself. Guarded, so an action tapped as the clock runs out cannot
  /// start this twice.
  void _leave() {
    if (_isLeaving || !mounted) return;
    _isLeaving = true;
    _timer?.cancel();
    setState(() {});
    // The removal waits for the fade, so the notice does not vanish mid-frame.
    _timer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) widget.onGone();
    });
  }

  /// How far up a drag has to go before letting go dismisses the notice.
  ///
  /// A tenth of the screen would be too little on a tablet: this is a bar at the top, and the
  /// gesture has to be deliberate. A drag that stops short springs back rather than dismissing,
  /// so a thumb brushing the screen cannot throw away the undo a cashier was reaching for.
  static const _dismissAfter = 40.0;

  double _drag = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    // Only upwards counts. A sideways or downward drag leaves the notice where it is, because
    // those are not the gesture: the notice is pinned to the top, and down is where the
    // catalogue is.
    final next = _drag + details.delta.dy;
    setState(() => _drag = next < 0 ? next : 0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_drag <= -_dismissAfter) {
      _leave();
      return;
    }
    // Not far enough, or a fling that did not travel: back it goes.
    setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    final pn = context.pn;
    final theme = Theme.of(context).textTheme;

    return Positioned(
      // At the top, and only as wide as it needs: the till's action is at the bottom, and the
      // catalogue is under everything else.
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedOpacity(
              opacity: _isLeaving ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                // A swipe up takes it away, the way the platform dismisses this kind of bar.
                // The button is not the only way out: a cashier who has read the message should
                // not have to wait out the timer with it covering the catalogue.
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                child: Transform.translate(
                  offset: Offset(0, _drag),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Material(
                      color: pn.ink,
                      borderRadius: BorderRadius.circular(PnRadius.surface),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.message,
                                style: theme.bodyMedium?.copyWith(
                                  color: pn.background,
                                ),
                              ),
                            ),
                            if (widget.actionLabel != null &&
                                widget.onAction != null) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  widget.onAction!();
                                  _leave();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: pn.accent,
                                  // A full tap target, not just the word: this is the undo
                                  // button, and a mis-tap on it costs a rescan.
                                  minimumSize: const Size(0, PnTouch.min),
                                ),
                                child: Text(widget.actionLabel!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
