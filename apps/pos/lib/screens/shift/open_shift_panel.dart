/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/common/amount_entry.dart';
import 'package:pos/state/shift_controller.dart';

/// Where a shift is opened: the cash in the drawer, entered on the on-screen keypad so the
/// tablet's keyboard never has to open over it.
class OpenShiftPanel extends StatefulWidget {
  const OpenShiftPanel({super.key, required this.controller});

  final ShiftController controller;

  @override
  State<OpenShiftPanel> createState() => _OpenShiftPanelState();
}

class _OpenShiftPanelState extends State<OpenShiftPanel> {
  var _amount = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isOpening = widget.controller.isOpening;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.shiftRequiredTitle, style: theme.headlineMedium),
            ),
            const SizedBox(height: 8),
            Text(l10n.shiftRequiredDesc, style: theme.bodyMedium),
            const SizedBox(height: 24),
            AmountEntry(
              label: l10n.shiftOpeningCashLabel,
              onChanged: (next) => _amount = next,
              backspaceLabel: l10n.shiftKeypadBackspace,
              enabled: !isOpening,
            ),
            const SizedBox(height: 16),
            _Problem(widget.controller.openProblem),
            SizedBox(
              height: PnTouch.primary,
              child: FilledButton(
                onPressed: isOpening
                    ? null
                    : () => widget.controller.open(_amount),
                child: Text(
                  isOpening ? l10n.shiftOpening : l10n.shiftOpenButton,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Why the last attempt did not open a shift. Nothing when there is nothing to say.
class _Problem extends StatelessWidget {
  const _Problem(this.problem);

  final OpenShiftProblem? problem;

  @override
  Widget build(BuildContext context) {
    final shown = problem;
    if (shown == null) return const SizedBox.shrink();
    // The server's own sentence when it refused; ours only when there was no answer to quote.
    final message = shown.message ?? L10n.of(context).shiftOpenUnavailable;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(color: context.pn.errorText),
        ),
      ),
    );
  }
}
