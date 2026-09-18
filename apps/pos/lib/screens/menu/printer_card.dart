/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/screens/menu/printer_pairing_sheet.dart';

/// Which printer this tablet prints to, and the way to change that (S14). The contents of a card;
/// the Menu draws the card around it.
///
/// Named by what was saved, not by what is connected: the link does not survive a restart, and a
/// cashier asking "which printer is this?" wants the configured one.
class PrinterCard extends StatefulWidget {
  const PrinterCard({super.key});

  @override
  State<PrinterCard> createState() => _PrinterCardState();
}

class _PrinterCardState extends State<PrinterCard> {
  Future<PrinterDevice?>? _saved;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _saved ??= readSavedPrinter(AppScope.of(context).store);
  }

  Future<void> _pair() async {
    final paired = await showPrinterPairingSheet(context);
    if (!paired || !mounted) return;
    _reload();
  }

  Future<void> _forget() async {
    final l10n = L10n.of(context);
    final services = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.menuPrinterForgetTitle),
        content: Text(l10n.menuPrinterForgetDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.menuPrinterForgetConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await clearPrinter(printer: services.printer, store: services.store);
    } on StoreException {
      // Nothing was forgotten: the printer is still what is saved, and the card still says so.
      if (mounted) {
        showTopNotice(context, message: l10n.menuPrinterForgetFailed);
      }
      return;
    }
    if (mounted) _reload();
  }

  /// Reads what is saved again, after something changed it.
  void _reload() {
    final read = readSavedPrinter(AppScope.of(context).store);
    setState(() {
      _saved = read;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return FutureBuilder<PrinterDevice?>(
      future: _saved,
      builder: (context, snapshot) {
        // Nothing while it is being read: "no printer" for a frame would be a claim.
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final saved = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.menuPrinterSection,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Text(
              // A store that would not answer is not an empty one: "none" would send a cashier
              // to pair a printer that is in fact paired.
              snapshot.hasError
                  ? l10n.menuPrinterUnreadable
                  : saved?.name ?? l10n.menuPrinterNone,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: PnTouch.min,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _pair,
                child: Text(
                  saved == null ? l10n.menuPrinterPair : l10n.menuPrinterChange,
                ),
              ),
            ),
            if (saved != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: PnTouch.min,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _forget,
                  child: Text(l10n.menuPrinterForget),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
