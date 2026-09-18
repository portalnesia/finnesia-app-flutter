/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/datetime.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/state_view.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/queue/pending_sales_controller.dart';
import 'package:pos/screens/common/screen_header.dart';
import 'package:pos/state/loadable.dart';

/// S17: every sale this tablet has taken money for and not yet had confirmed
/// (`plan/offline-queue/README.md` §7).
///
/// Reached from the Menu card and the status strip item, both of which push this — there is no
/// list to scroll to it, only ever this one screen.
class PendingSalesScreen extends StatefulWidget {
  const PendingSalesScreen({super.key});

  @override
  State<PendingSalesScreen> createState() => _PendingSalesScreenState();
}

class _PendingSalesScreenState extends State<PendingSalesScreen> {
  PendingSalesController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final services = AppScope.of(context);
    _controller = PendingSalesController(
      store: services.pendingSaleStore,
      sync: services.queueSync,
      analytics: services.analytics,
    )..load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Throwing a queued sale away leaves the drawer short of money it actually took, so it asks
  /// first. The safe answer is the quiet one and the destructive one is the filled one, so it is
  /// not the easier one to hit (`held_orders_sheet.dart`).
  Future<void> _confirmDiscard(String clientRef) async {
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.queueDiscardTitle),
        content: Text(l10n.queueDiscardDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.queueDiscard),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller!.discard(clientRef);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final l10n = L10n.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: l10n.queueTitle,
              trailing: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => TextButton(
                  onPressed: controller.isSending ? null : controller.sendNow,
                  child: Text(l10n.queueSendNow),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => switch (controller.state) {
                  Loading() => StateView.loading(label: l10n.commonLoading),
                  Failed() => StateView(
                    title: l10n.queueLoadFailed,
                    actionLabel: l10n.commonRetry,
                    onAction: controller.load,
                  ),
                  Ready(data: []) => StateView(title: l10n.queueEmpty),
                  Ready(:final data) => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: data.length,
                    itemBuilder: (context, i) => _PendingSaleRow(
                      entry: data[i],
                      onRetry: () => controller.retry(data[i].clientRef),
                      onDiscard: () => _confirmDiscard(data[i].clientRef),
                    ),
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

class _PendingSaleRow extends StatelessWidget {
  const _PendingSaleRow({
    required this.entry,
    required this.onRetry,
    required this.onDiscard,
  });

  final PendingSale entry;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final failed = entry.status == PendingSaleStatus.failed;
    final error = entry.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: pn.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatDateTime(entry.paidAt),
                    style: theme.bodyLarge,
                  ),
                ),
                Text(
                  formatCurrency(entry.receipt.grandTotal),
                  style: theme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              failed ? l10n.queueStatusFailed : l10n.queueStatusPending,
              style: theme.bodyMedium!.copyWith(
                color: failed ? pn.errorText : pn.inkMuted,
              ),
            ),
            // The server's own sentence, unchanged: what to fix is often something only it
            // knows (F14). Shown for a `pending` sale as well as a `failed` one: a sale the
            // server **blocks** (402, or 403 `outlet_inactive`) stays `pending` while the drain
            // loop retries it, so this is the only place the cashier can see why it is not
            // going through (`queue_sync.dart`, spec §3a 5).
            if (error != null && error.isNotEmpty)
              Text(
                error,
                style: theme.bodyMedium!.copyWith(color: pn.errorText),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  SizedBox(
                    height: PnTouch.min,
                    child: TextButton(
                      onPressed: onDiscard,
                      child: Text(l10n.queueDiscard),
                    ),
                  ),
                  // Only a failed sale can be retried verbatim: a pending one is already going
                  // to be tried again by the drain loop, and pressing this on it would send
                  // nothing that is not already going to be sent (`isFinalError`, `pn_pos`).
                  if (failed)
                    SizedBox(
                      height: PnTouch.min,
                      child: FilledButton(
                        onPressed: onRetry,
                        child: Text(l10n.queueRetry),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
