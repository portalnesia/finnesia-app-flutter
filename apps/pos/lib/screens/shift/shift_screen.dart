/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/permission_viewer.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_ui/src/layout/window_class.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/state_view.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/print_shift_report.dart';
import 'package:pos/screens/common/print_flow.dart';
import 'package:pos/screens/common/screen_header.dart';
import 'package:pos/screens/queue/pending_sales_screen.dart';
import 'package:pos/screens/shift/cash_movement_sheet.dart';
import 'package:pos/screens/shift/close_shift_screen.dart';
import 'package:pos/screens/shift/sale_detail_sheet.dart';
import 'package:pos/screens/shift/shift_panes.dart';
import 'package:pos/shift/shift_detail_controller.dart';
import 'package:pos/state/loadable.dart';

enum _Tab { figures, sales, movements }

/// S10: the open drawer, in full.
///
/// A whole screen and not a dialog (`shift-page.tsx`): the figures are read before anything is
/// done with them, and a cashier who has to explain a variance needs the sales and the cash
/// movements behind it in front of them, not behind a dialog they have to close first.
///
/// The way to work the drawer is at the bottom: record cash in or out, and close it. Both are
/// absent unless the drawer is known to be open and this cashier may work it (their own, or
/// another's with the override); a button they may not press has no place on the screen.
///
/// The figures stand beside the lists on a wide tablet, and take turns with them (behind three
/// tabs) on a narrow one: one column at a time, because two would each be too narrow to read a
/// row of amounts.
class ShiftScreen extends StatefulWidget {
  /// [shift] is one the history picked: this shows that shift, and not the drawer that is open now.
  const ShiftScreen({super.key, this.shift});

  final POSShift? shift;

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  ShiftDetailController? _controller;
  _Tab _tab = _Tab.figures;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final session = AppScope.of(context).session.current;
    // Not awaited: the controller reports its own state, and a bug it rethrows stays loud.
    _controller = ShiftDetailController(
      client: AppScope.of(context).client,
      outletId: session?.outletId ?? '',
      userId: session?.user?.id,
      membership: resolvePermissionViewer(session).activeUserCompany,
      shift: widget.shift,
    )..load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final l10n = L10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ListenableBuilder(
              listenable: controller.summary,
              builder: (context, _) => ScreenHeader(
                title: l10n.shiftDetailTitle,
                trailing: _statusBadge(controller, l10n),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: controller.shift,
                builder: (context, _) => _body(context, controller, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Whether the shift is open, in words. Nothing while the figures are not in, or for a status
  /// this build cannot read: no claim is better than a wrong one.
  Widget? _statusBadge(ShiftDetailController controller, L10n l10n) {
    final status = switch (controller.summary.state) {
      Ready(:final data) => data.status,
      _ => null,
    };
    if (status == null) return null;
    return _Badge(
      text: status == ShiftStatus.open
          ? l10n.shiftDetailOpen
          : l10n.shiftDetailClosed,
    );
  }

  Widget _body(
    BuildContext context,
    ShiftDetailController controller,
    L10n l10n,
  ) {
    return switch (controller.shift.state) {
      Loading() => StateView.loading(label: l10n.commonLoading),
      // A failed read is not "no shift is open": that would tell a cashier their drawer is shut
      // while it may not be. The server's own sentence when it refused, this screen's when nobody
      // answered — a 402 SUBSCRIPTION_EXPIRED is refused on every POS read, and "check the
      // connection" would send a cashier after a problem only the owner can fix.
      Failed(:final error) => StateView(
        title: failedReadText(error, l10n.shiftDetailLoadFailed),
        actionLabel: l10n.commonRetry,
        onAction: controller.load,
      ),
      Ready(:final data) when data == null => StateView(
        title: l10n.shiftDetailNone,
      ),
      Ready(:final data)
          when controller.isHeldByOther && !controller.canOverride =>
        StateView(
          title: l10n.shiftHeldTitle,
          description: l10n.shiftDetailHeldDesc(
            data!.number,
            _name(data.cashier?.name) ?? l10n.shiftUnknownCashier,
          ),
        ),
      Ready() => Column(
        children: [
          Expanded(child: _detail(context, controller, l10n)),
          ListenableBuilder(
            listenable: controller.summary,
            builder: (context, _) => _actions(controller, l10n),
          ),
        ],
      ),
    };
  }

  /// What can be done with the drawer. The report can be printed for any shift whose figures were
  /// read; recording cash and closing are only for a drawer known to be open (a closed one has
  /// nothing to work on, and one whose figures could not be read has an unknown status), and only
  /// where the cashier may work it: this is reached for their own drawer, or for another's only
  /// with the override.
  ///
  /// Absent, not disabled: a button the cashier may not press has no place on the screen (R-26).
  Widget _actions(ShiftDetailController controller, L10n l10n) {
    final summary = switch (controller.summary.state) {
      Ready(:final data) => data,
      _ => null,
    };
    if (summary == null) return const SizedBox.shrink();
    final shiftId = switch (controller.shift.state) {
      Ready(:final data) => data?.id,
      _ => null,
    };
    final canWork = summary.status == ShiftStatus.open && shiftId != null;
    final services = AppScope.of(context);
    // README §6, D-Q7: closing reconciles the drawer against what the server has recorded, and
    // a sale still sitting in this tablet's queue — for this outlet — is invisible to that
    // reconciliation. `QueueSync`'s counts are already scoped to the paired outlet.
    return ListenableBuilder(
      listenable: services.queueSync,
      builder: (context, _) {
        final queued =
            services.queueSync.pendingCount + services.queueSync.failedCount;
        final closeBlocked = canWork && queued > 0;
        return _ActionBar(
          printLabel: l10n.printerPrintShiftReport,
          onPrint: () => _print(summary),
          cashLabel: l10n.cashMovementTitle,
          closeLabel: l10n.closeShiftButton,
          onCash: !canWork
              ? null
              : () async {
                  final recorded = await showCashMovementSheet(
                    context,
                    shiftId: shiftId,
                  );
                  // The expected cash, the movements and the sales all moved with it.
                  if (recorded) await controller.load();
                },
          onClose: !canWork
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CloseShiftScreen(
                      shiftId: shiftId,
                      // The drawer is another cashier's, and this cashier holds the override:
                      // the close needs a note whatever the count comes to.
                      isOverride: controller.isHeldByOther,
                    ),
                  ),
                ),
          queueNotice: !closeBlocked
              ? null
              : (
                  message: l10n.shiftCloseBlockedByQueue(queued),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PendingSalesScreen(),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _print(ShiftSummaryResponse summary) {
    final services = AppScope.of(context);
    final l10n = L10n.of(context);
    return runPrint(
      context,
      successMessage: l10n.printerPrintSuccess,
      analyticsEvent: 'shift_report_printed',
      print: () => printShiftReport(
        summary,
        client: services.client,
        printer: services.printer,
        store: services.store,
        l10n: l10n,
        now: DateTime.now(),
      ),
    );
  }

  Widget _detail(
    BuildContext context,
    ShiftDetailController controller,
    L10n l10n,
  ) {
    final windowClass = context.windowClass;
    final sideBySide = windowClass != WindowClass.compact;
    // The figures have a column of their own when side by side, so there is no tab for them; a
    // screen turned from narrow to wide while they were showing lands on the sales.
    final tab = sideBySide && _tab == _Tab.figures ? _Tab.sales : _tab;

    final figures = FiguresPane(summary: controller.summary);
    final list = switch (tab) {
      _Tab.movements => MovementsPane(movements: controller.movements),
      _ => SalesPane(
        sales: controller.sales,
        onOpen: (sale) => showSaleDetailSheet(context, saleId: sale.id),
      ),
    };

    if (!sideBySide) {
      return Column(
        children: [
          _Tabs(
            selected: tab,
            tabs: _Tab.values,
            onSelected: (next) => setState(() => _tab = next),
          ),
          Expanded(child: tab == _Tab.figures ? figures : list),
        ],
      );
    }
    return Row(
      children: [
        SizedBox(
          width: windowClass == WindowClass.wide ? 440 : 400,
          child: figures,
        ),
        VerticalDivider(width: 1, color: context.pn.border),
        Expanded(
          child: Column(
            children: [
              _Tabs(
                selected: tab,
                tabs: const [_Tab.sales, _Tab.movements],
                onSelected: (next) => setState(() => _tab = next),
              ),
              Expanded(child: list),
            ],
          ),
        ),
      ],
    );
  }
}

/// What can be done with the drawer, fixed at the bottom so a long day's list never pushes it out
/// of reach. Closing is the one the screen is for, so it is the large, destructive one; recording
/// cash is the quieter outline beside it, and the report sits above both.
///
/// [onCash] and [onClose] are null for a drawer that is not open, and their buttons are then not
/// drawn.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.printLabel,
    required this.onPrint,
    required this.cashLabel,
    required this.closeLabel,
    required this.onCash,
    required this.onClose,
    this.queueNotice,
  });

  final String printLabel;
  final VoidCallback onPrint;
  final String cashLabel;
  final String closeLabel;
  final VoidCallback? onCash;
  final VoidCallback? onClose;

  /// Set when the offline queue is blocking Close: the sentence and the tap target that opens
  /// S17 (`plan/offline-queue/README.md` §6). [onClose] stays non-null in this state — it is
  /// what the cashier is being blocked *from* — so this is what actually disables the button.
  final ({String message, VoidCallback onTap})? queueNotice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pn = context.pn;
    final onCash = this.onCash;
    final onClose = this.onClose;
    final notice = queueNotice;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.pn.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: PnTouch.min,
              child: OutlinedButton(
                onPressed: onPrint,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.print_outlined),
                    const SizedBox(width: 8),
                    Flexible(child: Text(printLabel)),
                  ],
                ),
              ),
            ),
            if (onCash != null && onClose != null) ...[
              const SizedBox(height: 12),
              if (notice != null) ...[
                InkWell(
                  onTap: notice.onTap,
                  child: Text(
                    notice.message,
                    style: Theme.of(context).textTheme.bodySmall!
                        .copyWith(color: pn.errorText),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: PnTouch.primary,
                      child: OutlinedButton(
                        onPressed: onCash,
                        child: Text(cashLabel),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: PnTouch.primary,
                      child: FilledButton(
                        onPressed: notice == null ? onClose : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                        ),
                        child: Text(closeLabel),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The name, or null when there is none worth printing.
String? _name(String? name) => (name == null || name.isEmpty) ? null : name;

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.selected,
    required this.tabs,
    required this.onSelected,
  });

  final _Tab selected;
  final List<_Tab> tabs;
  final ValueChanged<_Tab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    String label(_Tab tab) => switch (tab) {
      _Tab.figures => l10n.shiftDetailTabFigures,
      _Tab.sales => l10n.shiftDetailTabSales,
      _Tab.movements => l10n.shiftDetailTabMovements,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_Tab>(
          showSelectedIcon: false,
          style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, PnTouch.min)),
          ),
          segments: [
            for (final tab in tabs)
              ButtonSegment(value: tab, label: Text(label(tab))),
          ],
          selected: {selected},
          onSelectionChanged: (next) => onSelected(next.single),
        ),
      ),
    );
  }
}

/// A short word in a box: the state of the shift. A control radius, not a pill (`DESIGN.md`).
class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final pn = context.pn;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PnRadius.control),
        border: Border.all(color: pn.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}
