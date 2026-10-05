/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_ui/src/layout/window_class.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/ledger_row.dart';
import 'package:pn_ui/src/widgets/state_view.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/branding/company_avatar.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/common/amount_entry.dart';
import 'package:pos/screens/common/screen_header.dart';
import 'package:pos/screens/shift/shift_panes.dart';
import 'package:pos/shift/close_shift_controller.dart';
import 'package:pos/shift/submit_problem.dart';
import 'package:pos/state/loadable.dart';

/// S12: counting the drawer, and closing it.
class CloseShiftScreen extends StatefulWidget {
  const CloseShiftScreen({
    super.key,
    required this.shiftId,
    required this.isOverride,
  });

  final String shiftId;

  /// The drawer is another cashier's, closed through `pos.shift.override`.
  final bool isOverride;

  @override
  State<CloseShiftScreen> createState() => _CloseShiftScreenState();
}

class _CloseShiftScreenState extends State<CloseShiftScreen> {
  Loadable<ShiftSummaryResponse>? _summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_summary != null) return;
    final client = AppScope.of(context).client;
    _summary = Loadable(
      () => PosApi.shiftsGetSummary(client, (id: widget.shiftId)),
    )..load();
  }

  @override
  void dispose() {
    _summary?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final summary = _summary!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: l10n.closeShiftTitle,
              trailing: const CompanyAvatar(),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: summary,
                builder: (context, _) => switch (summary.state) {
                  Ready(:final data) => _CloseForm(
                    summary: data,
                    isOverride: widget.isOverride,
                  ),
                  Loading() => StateView.loading(label: l10n.commonLoading),
                  Failed(:final error) => StateView(
                    title: failedReadText(error, l10n.closeShiftLoadFailed),
                    actionLabel: l10n.commonRetry,
                    onAction: summary.load,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The figures, the count, and what the count comes to. Built once the figures are in: the
/// controller counts against them, so it cannot exist before them.
class _CloseForm extends StatefulWidget {
  const _CloseForm({required this.summary, required this.isOverride});

  final ShiftSummaryResponse summary;
  final bool isOverride;

  @override
  State<_CloseForm> createState() => _CloseFormState();
}

class _CloseFormState extends State<_CloseForm> {
  CloseShiftController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= CloseShiftController(
      client: AppScope.of(context).client,
      summary: widget.summary,
      isOverride: widget.isOverride,
      analytics: AppScope.of(context).analytics,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    final controller = _controller!;
    await controller.submit();
    if (!controller.isClosed || !mounted) return;
    final services = AppScope.of(context);
    // A basket held under this drawer must not resurface once the next shift at this outlet opens:
    // the drawer it was rung up against no longer exists. Only this outlet's; another till's are
    // its own.
    await clearHeldOrders(
      services.holdStore,
      services.session.current?.outletId ?? '',
    );
    if (!mounted) return;
    // The gate reads the shift again, and answers with the open form: the drawer it let the
    // cashier into no longer exists.
    services.shiftClosed.value++;
    showTopNotice(context, message: L10n.of(context).closeShiftDone);
    // Back to where the app began, not to the screen that opened this one: that was the shift
    // screen, and it is about a drawer that is shut.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final controller = _controller!;
    final figures = _figures(l10n);
    final counting = _counting(l10n, controller);

    // Side by side when there is room: the figures stay in view while the drawer is counted, which
    // is the point of having them on this screen. One column on a narrow one.
    final sideBySide = context.windowClass != WindowClass.compact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: sideBySide
              ? Row(
                  children: [
                    SizedBox(
                      width: context.windowClass == WindowClass.wide
                          ? 440
                          : 400,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: figures,
                      ),
                    ),
                    VerticalDivider(width: 1, color: context.pn.border),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: counting,
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [...figures, ...counting],
                ),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => _CloseBar(
            enabled: controller.close.canClose && !controller.isClosing,
            isClosing: controller.isClosing,
            problem: controller.problem,
            onClose: _close,
          ),
        ),
      ],
    );
  }

  List<Widget> _figures(L10n l10n) {
    final data = widget.summary;
    final holder = data.cashierName;
    return [
      if (widget.isOverride) ...[
        Text(
          l10n.closeShiftOverrideNotice(
            (holder != null && holder.isNotEmpty)
                ? holder
                : l10n.shiftUnknownCashier,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
      ],
      LedgerRow(
        label: l10n.shiftDetailOpeningCash,
        value: formatCurrency(data.openingCash),
      ),
      LedgerRow(
        label: l10n.shiftDetailTotalSales,
        value: formatCurrency(data.totalSales),
      ),
      LedgerRow(
        label: l10n.shiftDetailCashIn,
        value: formatCurrency(data.cashIn),
      ),
      LedgerRow(
        label: l10n.shiftDetailCashOutAndDrop,
        value: formatCurrency(data.cashOut + data.cashDrop),
      ),
      LedgerRow(
        label: l10n.shiftDetailExpectedCash,
        value: formatCurrency(data.expectedCash),
        emphasized: true,
      ),
    ];
  }

  List<Widget> _counting(L10n l10n, CloseShiftController controller) => [
    AmountEntry(
      label: l10n.shiftDetailCountedCash,
      backspaceLabel: l10n.shiftKeypadBackspace,
      onChanged: controller.setCountedCash,
    ),
    const SizedBox(height: 16),
    ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LedgerRow(
            label: l10n.shiftDetailVarianceLabel,
            value: varianceText(l10n, controller.close.variance),
          ),
          _Notes(controller: controller),
        ],
      ),
    ),
  ];
}

/// The note, with the reason it is needed written beside it: a field the button waits on has to
/// say so, or the cashier is left guessing what is wrong with a drawer they have just counted.
class _Notes extends StatelessWidget {
  const _Notes({required this.controller});

  final CloseShiftController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final state = controller.close;
    final helper = !state.needsNote
        ? l10n.closeShiftNoteOptional
        : (controller.isOverride && state.variance == 0)
        ? l10n.closeShiftNoteNeededOverride
        : l10n.closeShiftNoteNeededVariance;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextField(
        key: const Key('close-notes'),
        minLines: 1,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.closeShiftNotesLabel,
          helperText: helper,
          helperMaxLines: 3,
        ),
        onChanged: controller.setNotes,
      ),
    );
  }
}

/// The action the screen exists for, fixed at the bottom so a long list of figures never pushes it
/// out of reach. Destructive, so it wears the error colour: closing a drawer is not undone.
class _CloseBar extends StatelessWidget {
  const _CloseBar({
    required this.enabled,
    required this.isClosing,
    required this.problem,
    required this.onClose,
  });

  final bool enabled;
  final bool isClosing;
  final SubmitProblem? problem;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pn = context.pn;
    final scheme = Theme.of(context).colorScheme;
    final shown = problem;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: pn.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (shown != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  // Not the server's words for an error or a silence: it may have closed the drawer
                  // anyway, and only a refusal is the server's to explain (F34).
                  shown.mayHaveSucceeded
                      ? l10n.closeShiftUncertain
                      : (shown.message ?? l10n.closeShiftRefused),
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(color: pn.errorText),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: PnTouch.primary,
              child: FilledButton(
                onPressed: enabled ? onClose : null,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                child: Text(
                  isClosing ? l10n.closeShiftClosing : l10n.closeShiftButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
