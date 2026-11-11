/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/print_queue_port.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/printer_failure_text.dart';
import 'package:pos/printer/printer_queue_failure_text.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/screens/menu/printer_pairing_sheet.dart';
import 'package:pos/screens/menu/windows_printer_queue_sheet.dart';

/// What a print button does once it is pressed: configure the selected transport if needed, then
/// [print]. Windows can choose a BLE printer or an installed system queue; all other platforms
/// keep the original BLE pairing flow.
///
/// Every expected failure ends as a cashier-facing sentence. When [print] reads from the server,
/// the caller supplies [loadFailedMessage] so API failures keep their existing meaning.
Future<void> runPrint(
  BuildContext context, {
  required Future<void> Function() print,
  required String successMessage,
  required String analyticsEvent,
  String? loadFailedMessage,
}) async {
  final l10n = L10n.of(context);
  final store = AppScope.of(context).store;
  String message;
  try {
    final platform = defaultTargetPlatform;
    var mode = await readPrinterMode(store, platform: platform);
    if (platform == TargetPlatform.windows) {
      if (mode == null) {
        if (!context.mounted) return;
        final chosen = await _chooseWindowsPrinterMode(context);
        if (chosen == null || !context.mounted) return;
        if (chosen == PrinterMode.windowsQueue) {
          if (!await showWindowsPrinterQueueSheet(context) ||
              !context.mounted) {
            return;
          }
          mode = PrinterMode.windowsQueue;
        } else {
          try {
            await savePrinterMode(chosen, store);
          } on StoreException {
            if (context.mounted) {
              showTopNotice(context, message: l10n.printerOutputSaveFailed);
            }
            return;
          }
          mode = chosen;
        }
      }

      if (mode == PrinterMode.windowsQueue) {
        if (await readSavedWindowsPrinterQueue(store) == null) {
          if (!context.mounted ||
              !await showWindowsPrinterQueueSheet(context) ||
              !context.mounted) {
            return;
          }
        }
      } else if (await readSavedPrinter(store) == null) {
        if (!context.mounted) return;
        final paired = await showPrinterPairingSheet(context);
        if (!paired || !context.mounted) return;
      }
    } else if (await readSavedPrinter(store) == null) {
      if (!context.mounted) return;
      final paired = await showPrinterPairingSheet(context);
      if (!paired || !context.mounted) return;
    }

    await print();
    message = successMessage;
    if (context.mounted) {
      await AppScope.of(context).analytics.logEvent(analyticsEvent);
    }
  } on PrintQueueException catch (error) {
    message = printerQueueFailureText(l10n, error.reason);
  } on PrinterException catch (error) {
    message = printerFailureText(
      l10n,
      error.reason,
      fallback: error.reason == PrinterFailure.notConnected
          ? l10n.printerNotConnected
          : l10n.printerPrintFailed,
    );
  } on StoreException {
    message = l10n.menuPrinterUnreadable;
  } on ApiError {
    if (loadFailedMessage == null) rethrow;
    message = loadFailedMessage;
  } on TransportException {
    if (loadFailedMessage == null) rethrow;
    message = loadFailedMessage;
  }
  if (context.mounted) showTopNotice(context, message: message);
}

Future<PrinterMode?> _chooseWindowsPrinterMode(BuildContext context) =>
    showDialog<PrinterMode>(
      context: context,
      builder: (context) {
        final l10n = L10n.of(context);
        return AlertDialog(
          title: Text(l10n.printerOutputChooseTitle),
          content: Text(l10n.printerOutputChooseDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(l10n.commonCancel),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(PrinterMode.bluetooth),
              child: Text(l10n.printerOutputBluetooth),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(PrinterMode.windowsQueue),
              child: Text(l10n.printerOutputWindowsQueue),
            ),
          ],
        );
      },
    );
