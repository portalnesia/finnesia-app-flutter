/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_types/src/master_data.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/state_view.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/shift/cash_movement_controller.dart';
import 'package:pos/state/loadable.dart';

/// Picks the account on the other side of a cash movement, from a list the server searches.
///
/// A dialog of its own and not a list drawn in the sheet, for the reason the customer picker is
/// one: every account it listed would push the fields below it further down, and a chart of
/// accounts is long. Choosing a row is the whole interaction, and it closes the dialog.
Future<void> showAccountPickerDialog(
  BuildContext context, {
  required CashMovementController controller,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AccountPickerDialog(controller: controller),
  );
  // The next opening lists the first page, not whatever the last one searched for.
  controller.setAccountSearch('');
}

class AccountPickerDialog extends StatelessWidget {
  const AccountPickerDialog({super.key, required this.controller});

  final CashMovementController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pn = context.pn;
    return Dialog(
      key: const Key('account-picker'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                key: const Key('account-search'),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.cashMovementAccountSearch,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: controller.setAccountSearch,
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: controller.accounts,
                builder: (context, _) => switch (controller.accounts.state) {
                  Loading() => StateView.loading(label: l10n.commonLoading),
                  Failed(:final error) => StateView(
                    title: failedReadText(
                      error,
                      l10n.cashMovementAccountFailed,
                    ),
                    actionLabel: l10n.commonRetry,
                    onAction: controller.accounts.load,
                  ),
                  Ready(:final data) when data.isEmpty => StateView(
                    title: l10n.cashMovementAccountEmpty,
                  ),
                  Ready(:final data) => ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) => _Row(
                      account: data[i],
                      onPick: () {
                        controller.pickAccount(data[i]);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                },
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: pn.border)),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.account, required this.onPick});

  final ChartOfAccount account;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPick,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: PnTouch.primary),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            '${account.code} - ${account.name}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    ),
  );
}
