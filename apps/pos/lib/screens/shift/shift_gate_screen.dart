/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/shift_gate.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_ui/src/widgets/state_view.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/shift/open_shift_notice_panels.dart';
import 'package:pos/screens/shift/open_shift_panel.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/shift_controller.dart';

/// S4: the screen between a signed-in cashier and the till.
///
/// It reads whether the cashier may sell, and shows the reason when they may not. [till] is what
/// it shows when they may.
///
/// The [ShiftController] belongs to this screen, so signing out (which replaces the screen) also
/// forgets which shift the cashier chose to continue. That is the point: a decision kept past the
/// cashier who made it would silently resume yesterday's shift (`plan/ui/findings.md` F6).
class ShiftGateScreen extends StatefulWidget {
  const ShiftGateScreen({super.key, required this.till});

  /// The shift is the one the cashier is working in, or null when the company runs without
  /// shifts. The preferences come with it: the gate already read them, and the till branches on
  /// them.
  final Widget Function(
    BuildContext context,
    POSShift? shift,
    POSPreferences? preferences,
  )
  till;

  @override
  State<ShiftGateScreen> createState() => _ShiftGateScreenState();
}

class _ShiftGateScreenState extends State<ShiftGateScreen> {
  ShiftController? _controller;
  ValueNotifier<int>? _shiftClosed;
  ValueNotifier<POSShift?>? _activeShift;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final services = AppScope.of(context);
    final session = services.session.current;
    final controller = ShiftController(
      client: services.client,
      outletId: session?.outletId ?? '',
      userId: session?.user?.id,
      analytics: services.analytics,
    );
    _controller = controller;
    // Told every time the controller has something new to report, so the shell above this gate
    // — which cannot see `controller` itself — knows whether there is a shift to show a detail
    // of. Registered before `load()`, so the first answer is reported too.
    _activeShift = services.activeShift;
    controller.addListener(_reportActiveShift);
    controller.load();
    // A shift closed from inside the app: the drawer this gate let the cashier into no longer
    // exists, and the till would keep selling into it. Reading again answers with the open form.
    _shiftClosed = services.shiftClosed..addListener(_onShiftClosed);
  }

  void _onShiftClosed() => _controller?.load();

  void _reportActiveShift() => _activeShift?.value = _controller?.activeShift;

  @override
  void dispose() {
    _shiftClosed?.removeListener(_onShiftClosed);
    _controller?.removeListener(_reportActiveShift);
    // This gate is gone — a sign-out, most likely — so there is no longer a shift to show a
    // detail of, whatever the last one read was.
    _activeShift?.value = null;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = L10n.of(context);
        final state = controller.state;
        if (state is Failed<ShiftContext>) {
          return Scaffold(
            body: StateView(
              // The server's own sentence when it refused, the gate's own when nobody answered.
              // A refusal is the server's to explain: 402 SUBSCRIPTION_EXPIRED is the one a
              // cashier will meet here, and "check the connection and try again" would send them
              // to check a router for something only the owner can fix. The Menu already reads a
              // failed load this way, so this is the gate agreeing with its sibling rather than a
              // rule of its own.
              title: failedReadText(state.error, l10n.shiftLoadFailed),
              actionLabel: l10n.commonRetry,
              onAction: controller.load,
            ),
          );
        }
        // `resolveShiftGate` answers alreadyOpen and heldByOther only for a shift that exists (the
        // first returns shiftRequired when there is none, the second reads its cashier), so the
        // `!` below cannot be null.
        return switch (controller.gate) {
          ShiftGateState.cart => widget.till(
            context,
            controller.activeShift,
            controller.preferences,
          ),
          ShiftGateState.shiftRequired => _Centered(
            child: OpenShiftPanel(controller: controller),
          ),
          ShiftGateState.alreadyOpen => _Centered(
            child: AlreadyOpenPanel(
              shift: controller.activeShift!,
              onContinue: controller.resume,
            ),
          ),
          ShiftGateState.heldByOther => _Centered(
            child: HeldByOtherPanel(shift: controller.activeShift!),
          ),
          ShiftGateState.loading => Scaffold(
            body: StateView.loading(label: l10n.commonLoading),
          ),
        };
      },
    );
  }
}

/// One column in the middle of the screen, the same at every width: each panel here is a title,
/// a sentence and one action, and two columns would be a layout for the sake of a layout.
class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: child,
          ),
        ),
      ),
    ),
  );
}
