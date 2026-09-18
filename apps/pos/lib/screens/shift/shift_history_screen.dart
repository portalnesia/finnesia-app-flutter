/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/common/entry_row.dart';
import 'package:pos/screens/common/paged_list.dart';
import 'package:pos/screens/common/screen_header.dart';
import 'package:pos/screens/shift/shift_screen.dart';
import 'package:pos/shift/shift_history_controller.dart';

/// S16: the shifts of this outlet, newest first, and the way into any of them.
///
/// The web lists every outlet with five filters (`pos-shifts-page.tsx`). Here the outlet is the one
/// pairing locked, and the only filter is the one a cashier reaches for: which are still open, and
/// which are already closed. A row opens the shift screen for *that* shift, so a report can be
/// printed for one that is long closed, without a shift having to be closed first.
class ShiftHistoryScreen extends StatefulWidget {
  const ShiftHistoryScreen({super.key});

  @override
  State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends State<ShiftHistoryScreen> {
  ShiftHistoryController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final services = AppScope.of(context);
    // Not awaited: the controller reports its own state, and a bug it rethrows stays loud.
    _controller = ShiftHistoryController(
      client: services.client,
      outletId: services.session.current?.outletId ?? '',
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
            ScreenHeader(title: l10n.shiftHistoryTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ShiftHistoryFilter>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size(0, PnTouch.min)),
                    ),
                    segments: [
                      ButtonSegment(
                        value: ShiftHistoryFilter.all,
                        label: Text(l10n.shiftHistoryAll),
                      ),
                      ButtonSegment(
                        value: ShiftHistoryFilter.open,
                        label: Text(l10n.shiftDetailOpen),
                      ),
                      ButtonSegment(
                        value: ShiftHistoryFilter.closed,
                        label: Text(l10n.shiftDetailClosed),
                      ),
                    ],
                    selected: {controller.filter},
                    onSelectionChanged: (next) =>
                        controller.setFilter(next.single),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PagedListPane<POSShift>(
                source: controller.shifts,
                failedTitle: l10n.shiftHistoryLoadFailed,
                emptyTitle: l10n.shiftHistoryEmpty,
                moreFailedLabel: l10n.shiftDetailMoreFailed,
                itemBuilder: (context, shift) => _row(context, l10n, shift),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, L10n l10n, POSShift shift) {
    final pn = context.pn;
    final theme = Theme.of(context).textTheme;
    final cashier = shift.cashier?.name;
    final opened = formatDateTime(shift.openedAt);
    return EntryRow(
      title: shift.number,
      lines: [
        Text(
          (cashier != null && cashier.isNotEmpty)
              ? '$cashier · $opened'
              : opened,
          style: theme.bodyMedium!.copyWith(color: pn.inkMuted),
        ),
        // In words: which of them is still open is the first thing this list is read for. Nothing
        // for a status this build cannot read: no claim is better than a wrong one.
        if (shift.status != null)
          Text(
            shift.status == ShiftStatus.open
                ? l10n.shiftDetailOpen
                : l10n.shiftDetailClosed,
            style: theme.bodyMedium,
          ),
      ],
      value: formatCurrency(shift.totalSales),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ShiftScreen(shift: shift)),
      ),
    );
  }
}
