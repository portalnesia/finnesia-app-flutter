/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/common/amount_entry.dart';
import 'package:pos/screens/shift/account_picker_dialog.dart';
import 'package:pos/screens/till/pos_sheet.dart';
import 'package:pos/shift/cash_movement_controller.dart';
import 'package:pos/shift/submit_problem.dart';
import 'package:pos/state/loadable.dart';

/// S13: money that enters or leaves the drawer without a sale.
///
/// Resolves to true when a movement was recorded, so the screen that opened it reads its figures
/// again: the expected cash moved with it.
Future<bool> showCashMovementSheet(
  BuildContext context, {
  required String shiftId,
}) async {
  final recorded = await showPosSheet<bool>(
    context,
    heightFactor: 0.92,
    builder: (context) => CashMovementSheet(shiftId: shiftId),
  );
  return recorded ?? false;
}

class CashMovementSheet extends StatefulWidget {
  const CashMovementSheet({super.key, required this.shiftId});

  final String shiftId;

  @override
  State<CashMovementSheet> createState() => _CashMovementSheetState();
}

class _CashMovementSheetState extends State<CashMovementSheet> {
  CashMovementController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    // Not awaited: the controller reports its own state, and a bug it rethrows stays loud.
    _controller = CashMovementController(
      client: AppScope.of(context).client,
      shiftId: widget.shiftId,
      analytics: AppScope.of(context).analytics,
    )..open();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final controller = _controller!;
    await controller.submit();
    if (!controller.isRecorded || !mounted) return;
    showTopNotice(context, message: L10n.of(context).cashMovementDone);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final controller = _controller!;
    // A modal sheet does not move for the tablet's keyboard by itself, and the reason is a text
    // field: without this the keyboard sits over the save button.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PosSheetHeader(title: l10n.cashMovementTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListenableBuilder(
                  listenable: controller.settings,
                  builder: (context, _) => switch (controller.settings.state) {
                    Failed(:final error) => _SettingsFailed(
                      error: error,
                      onRetry: controller.settings.load,
                    ),
                    // Nothing while it loads or once it is read: this is a note under a form that
                    // is already drawn, not a screen of its own.
                    _ => const SizedBox.shrink(),
                  },
                ),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => SegmentedButton<CashMovementType>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size(0, PnTouch.min)),
                    ),
                    segments: [
                      ButtonSegment(
                        value: CashMovementType.cashIn,
                        label: Text(l10n.shiftDetailCashIn),
                      ),
                      ButtonSegment(
                        value: CashMovementType.cashOut,
                        label: Text(l10n.shiftDetailCashOut),
                      ),
                      ButtonSegment(
                        value: CashMovementType.drop,
                        label: Text(l10n.shiftDetailCashDrop),
                      ),
                    ],
                    selected: {controller.type},
                    onSelectionChanged: (next) =>
                        controller.setType(next.single),
                  ),
                ),
                const SizedBox(height: 24),
                AmountEntry(
                  label: l10n.cashMovementAmount,
                  backspaceLabel: l10n.shiftKeypadBackspace,
                  onChanged: controller.setAmount,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('movement-reason'),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.cashMovementReasonRequired,
                    hintText: l10n.cashMovementReasonHint,
                  ),
                  onChanged: controller.setReason,
                ),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) =>
                      _AccountField(controller: controller),
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => _SaveBar(
              enabled: controller.canSubmit && !controller.isSubmitting,
              isSaving: controller.isSubmitting,
              problem: controller.problem,
              onSave: _save,
            ),
          ),
        ],
      ),
    );
  }
}

/// The account as a row that looks like a field and opens the picker. Always one row high, picked
/// or not, so nothing under it moves.
class _AccountField extends StatelessWidget {
  const _AccountField({required this.controller});

  final CashMovementController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final picked = controller.account;
    return InkWell(
      key: const Key('movement-account'),
      borderRadius: BorderRadius.circular(PnRadius.control),
      onTap: () => showAccountPickerDialog(context, controller: controller),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PnTouch.primary),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: controller.requireAccount
                ? l10n.cashMovementAccountRequired
                : l10n.cashMovementAccount,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            picked == null
                ? l10n.cashMovementAccountNone
                : '${picked.code} - ${picked.name}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Why the form cannot be saved yet, when the reason is that the settings could not be read: a
/// button that stays grey for no visible reason leaves the cashier guessing what is wrong.
///
/// The server's own sentence when it refused — a 402 SUBSCRIPTION_EXPIRED blocks this read like
/// every other POS read, and "check the connection" would send a cashier after a problem only the
/// owner can fix. This screen's wording is for a failure with nobody to speak for it.
class _SettingsFailed extends StatelessWidget {
  const _SettingsFailed({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            failedReadText(error, l10n.cashMovementSettingsFailed),
            style: Theme.of(context).textTheme.bodyMedium!
                .copyWith(color: context.pn.errorText),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}

/// The action the sheet exists for, fixed at the bottom so the keypad above it never pushes it out
/// of reach.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.enabled,
    required this.isSaving,
    required this.problem,
    required this.onSave,
  });

  final bool enabled;
  final bool isSaving;
  final SubmitProblem? problem;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pn = context.pn;
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
                  // Not the server's words for an error or a silence: it may have recorded the
                  // movement anyway, and only a refusal is the server's to explain (F34).
                  shown.mayHaveSucceeded
                      ? l10n.cashMovementUncertain
                      : (shown.message ?? l10n.cashMovementRefused),
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(color: pn.errorText),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: PnTouch.primary,
              child: FilledButton(
                onPressed: enabled ? onSave : null,
                child: Text(isSaving ? l10n.commonSaving : l10n.commonSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
