/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pos/l10n/app_localizations.dart';

/// Asks what to call a basket about to be held. Resolves to the name (possibly empty, which means
/// "call it by the time"), or null when the cashier changed their mind.
///
/// [initial] is the name a resumed basket already has: holding it again must not ask twice.
Future<String?> showHoldNameDialog(
  BuildContext context, {
  String initial = '',
}) => showDialog<String>(
  context: context,
  builder: (context) => _HoldNameDialog(initial: initial),
);

class _HoldNameDialog extends StatefulWidget {
  const _HoldNameDialog({required this.initial});

  final String initial;

  @override
  State<_HoldNameDialog> createState() => _HoldNameDialogState();
}

class _HoldNameDialogState extends State<_HoldNameDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return AlertDialog(
      title: Text(l10n.tillHoldTitle),
      content: TextField(
        key: const Key('hold-name'),
        controller: _name,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.tillHoldNameLabel,
          hintText: l10n.tillHoldNameHint,
        ),
        onSubmitted: (_) => Navigator.of(context).pop(_name.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('hold-confirm'),
          onPressed: () => Navigator.of(context).pop(_name.text),
          child: Text(l10n.tillHold),
        ),
      ],
    );
  }
}
