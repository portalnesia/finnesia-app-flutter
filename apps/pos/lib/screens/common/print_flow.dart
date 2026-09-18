/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/printer_failure_text.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/screens/menu/printer_pairing_sheet.dart';

/// What a print button does once it is pressed: [print], with the tablet's printer in the way.
///
/// With no printer paired yet the cashier is offered the pairing sheet first and the document
/// prints once it is paired: a tablet has no fallback the way the web has (`printDocument`), and
/// "not connected" is no help to someone who has never connected one.
///
/// Every way it can go wrong ends as a sentence, never as an exception into the screen: the
/// printer's own reasons (`printerFailureText`), a saved printer that cannot be read ("none" would
/// send a cashier to pair one that is in fact paired), and, when [print] reads something from the
/// server first, [loadFailedMessage] for an answer that did not come. A [print] that reads from the
/// server must pass it: without one those failures are not this function's to swallow.
///
/// [successMessage] says what was sent, because that is the only sign a cashier gets that
/// anything happened.
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
    if (await readSavedPrinter(store) == null) {
      if (!context.mounted) return;
      final paired = await showPrinterPairingSheet(context);
      if (!paired || !context.mounted) return;
    }
    await print();
    message = successMessage;
    if (context.mounted) {
      await AppScope.of(context).analytics.logEvent(analyticsEvent);
    }
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
