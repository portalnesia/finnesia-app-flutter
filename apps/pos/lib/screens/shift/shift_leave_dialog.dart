/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/l10n/app_localizations.dart';

/// Reminds the cashier that [shift] is still open, and asks whether to leave anyway.
///
/// Answers true for "leave anyway" and false for "back to the till" (or the dialog dismissed).
/// It never blocks: leaving is always one tap away, it only comes second. Staying is the filled
/// button because it is the choice that keeps the drawer reconcilable, so it should be the easier
/// one to hit.
Future<bool> showShiftLeaveReminder(
  BuildContext context,
  POSShift shift,
) async {
  final l10n = L10n.of(context);
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.shiftLeaveTitle),
      content: Text(l10n.shiftLeaveDesc(shift.number)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.shiftLeaveConfirm),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.shiftLeaveStay),
        ),
      ],
    ),
  );
  return leave ?? false;
}
