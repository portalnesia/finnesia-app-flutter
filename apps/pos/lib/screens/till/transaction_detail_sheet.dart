/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_pos/src/pos_transaction_detail.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/till/customer_picker_dialog.dart';
import 'package:pos/screens/till/pos_sheet.dart';
import 'package:pos/till/transaction_detail_controller.dart';

/// S8: who the sale is for, and what the floor or the kitchen needs to know about it.
///
/// A sheet from the bottom, not a centred dialog. A browser has no other shape for this; here
/// the cart sits in a column on a wide tablet, and a sheet leaves the basket readable while the
/// cashier fills the detail in. The fields are the same four the checkout payload takes, and so
/// are the rules about them (`plan/ui/README.md` §6).
///
/// The panel is deliberately **not** a form with a Save button. Every field writes to the
/// controller as it is typed, so closing the sheet at any moment keeps what was filled in. A
/// Save button would mean a cashier who typed a table number and tapped outside had lost it.
///
/// The customer is one row, and the list it is chosen from is a dialog of its own
/// (`customer_picker_dialog.dart`): a list drawn here would push every field below it off the
/// screen, more of them with every customer the shop has.
Future<void> showTransactionDetailSheet(
  BuildContext context, {
  required TransactionDetailController controller,
}) => showPosSheet<void>(
  context,
  heightFactor: 0.9,
  builder: (context) => TransactionDetailSheet(controller: controller),
);

class TransactionDetailSheet extends StatefulWidget {
  const TransactionDetailSheet({super.key, required this.controller});

  final TransactionDetailController controller;

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  final _memo = TextEditingController();
  final _table = TextEditingController();
  final _queue = TextEditingController();

  @override
  void initState() {
    super.initState();
    final detail = widget.controller.detail;
    _memo.text = detail.customerMemo;
    _table.text = detail.tableNumber;
    _queue.text = detail.queueNumber;
    // Not awaited: the picker draws its own loading state, and a bug it rethrows stays loud.
    widget.controller.open();
  }

  @override
  void dispose() {
    _memo.dispose();
    _table.dispose();
    _queue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pn = context.pn;
    final controller = widget.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final detail = controller.detail;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PosSheetHeader(title: l10n.posTransactionDetail),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _SectionLabel(l10n.posCustomer),
                  const SizedBox(height: 8),
                  _CustomerField(
                    detail: detail,
                    onOpen: () => showCustomerPickerDialog(
                      context,
                      controller: controller,
                    ),
                    onClear: () =>
                        controller.pickCustomer(TransactionDetail.empty),
                  ),
                  const SizedBox(height: 20),
                  _Field(
                    label: l10n.posCustomerMemo,
                    hint: l10n.posCustomerMemoPlaceholder,
                    controller: _memo,
                    onChanged: controller.setMemo,
                  ),
                  // Only drawn when the outlet asks for them. The value is still carried either
                  // way: the preference decides what is shown, not what the sale may hold.
                  if (controller.showTableNumber) ...[
                    const SizedBox(height: 16),
                    _Field(
                      label: l10n.posTableNumber,
                      hint: l10n.posTableNumberPlaceholder,
                      controller: _table,
                      onChanged: controller.setTableNumber,
                    ),
                  ],
                  if (controller.showQueueNumber) ...[
                    const SizedBox(height: 16),
                    _Field(
                      label: l10n.posQueueNumber,
                      hint:
                          controller.queuePlaceholder ??
                          l10n.posQueueNumberPlaceholder,
                      controller: _queue,
                      onChanged: controller.setQueueNumber,
                    ),
                  ],
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: pn.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: PnTouch.primary,
                  child: FilledButton(
                    key: const Key('detail-done'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.tillDetailDone),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The sheet's title bar, with the way out on it.
///
/// A close button as well as the drag handle and the barrier: the cashier may have opened this by
/// mistake, and one tap should undo that.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelLarge);
}

/// The customer on the sale as one row that looks like a field and opens the picker.
///
/// Always one row high, whether a customer is attached or not, so nothing under it moves.
class _CustomerField extends StatelessWidget {
  const _CustomerField({
    required this.detail,
    required this.onOpen,
    required this.onClear,
  });

  final TransactionDetail detail;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final hasCustomer = detail.customerId.isNotEmpty;
    // A customer whose name is not known yet is not the same as no customer, so an empty name
    // still says a customer is attached. The name fills in as soon as the picker's list has it.
    final name = detail.shownCustomerName ?? '';

    return Material(
      color: pn.surfaceMuted,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PnRadius.control),
        side: BorderSide(color: pn.border),
      ),
      child: InkWell(
        key: const Key('customer-field'),
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: PnTouch.primary),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasCustomer
                      ? (name.isEmpty ? l10n.posCustomer : name)
                      : l10n.tillDetailSelectCustomer,
                  style: hasCustomer
                      ? theme.titleSmall
                      : theme.bodyMedium!.copyWith(color: pn.inkMuted),
                ),
              ),
              if (hasCustomer)
                IconButton(
                  key: const Key('customer-clear'),
                  onPressed: onClear,
                  tooltip: l10n.tillDetailClearCustomer,
                  icon: const Icon(Icons.close),
                ),
              Icon(Icons.arrow_drop_down, color: pn.inkMuted),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// One labelled field. The tablet's own keyboard is what opens here: these are names and numbers
/// a cashier reads off a slip, not an amount they count out, so the keypad-in-the-screen the
/// payment screen uses would be the wrong tool.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: InputDecoration(labelText: label, hintText: hint),
    onChanged: onChanged,
  );
}

/// The customer on the sale, or an invitation to add one, as one tappable row.
///
/// Always the same height whether or not anything is filled in, which is the point of keeping the
/// detail out of the basket: the cashier can see that a customer is attached without four fields
/// pushing the goods off the screen (`cart-panel.tsx`).
class TransactionDetailRow extends StatelessWidget {
  const TransactionDetailRow({
    super.key,
    required this.detail,
    required this.isDefaultCustomer,
    required this.onOpen,
    this.showTableNumber = false,
    this.showQueueNumber = false,
  });

  final TransactionDetail detail;

  /// What the outlet asks for, from `POSPreferences`. A field that is asked for and still empty
  /// is drawn as an empty slot, so the cashier can see where it goes; without this the row named
  /// only what was filled in and gave no hint that a table number existed at all.
  final bool showTableNumber;
  final bool showQueueNumber;

  /// Whether the customer on the sale is the company's nominated walk-in. The note is folded into
  /// its parentheses for that one, and stands on its own row for any other
  /// (`TransactionDetail.summaryTexts`).
  final bool isDefaultCustomer;

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;
    final pn = context.pn;
    final shown = detail.summaryTexts(isDefaultCustomer: isDefaultCustomer);

    final parts = <String>[
      if (shown.customer != null)
        l10n.tillDetailCustomer(
          shown.customer!.isEmpty ? l10n.posCustomer : shown.customer!,
        ),
      if (detail.shownTableNumber != null)
        l10n.tillDetailTable(detail.shownTableNumber!),
      if (detail.shownQueueNumber != null)
        l10n.tillDetailQueue(detail.shownQueueNumber!),
      if (shown.memo != null) l10n.tillDetailMemo(shown.memo!),
    ];
    // Asked for by the outlet and still empty. Kept apart from [parts] so it can be drawn muted:
    // it says where something goes, not that something is there.
    final slots = <String>[
      if (showTableNumber && detail.shownTableNumber == null)
        l10n.tillDetailTable('-'),
      if (showQueueNumber && detail.shownQueueNumber == null)
        l10n.tillDetailQueue('-'),
    ];

    final muted = theme.bodyMedium!.copyWith(color: pn.inkMuted);
    final spans = <InlineSpan>[
      for (final part in parts) TextSpan(text: part),
      for (final slot in slots) TextSpan(text: slot, style: muted),
    ];
    const separator = '  ·  ';

    return Material(
      color: pn.surface,
      child: InkWell(
        key: const Key('transaction-detail-row'),
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: PnTouch.min),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: spans.isEmpty
                      ? Text(l10n.tillDetailAdd, style: muted)
                      : Text.rich(
                          TextSpan(
                            style: theme.bodyMedium!.copyWith(color: pn.ink),
                            children: [
                              for (final (i, span) in spans.indexed) ...[
                                if (i > 0) const TextSpan(text: separator),
                                span,
                              ],
                            ],
                          ),
                        ),
                ),
                Icon(Icons.chevron_right, size: 20, color: pn.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
