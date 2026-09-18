/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/print_settings.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/printer/shift_report.dart';

/// Prints the closing report of [summary] to the paired printer.
///
/// Throws [PrinterException], for the caller to put in words: with no printer saved that is
/// `notConnected`, which the screen turns into an offer to pair.
///
/// The tenant's settings decide two optional parts of the paper (the product breakdown and the
/// footer): see [readPrintSettings], which prints without them when they cannot be read.
Future<void> printShiftReport(
  ShiftSummaryResponse summary, {
  required ApiClient client,
  required PrinterPort printer,
  required StorePort store,
  required L10n l10n,
  required DateTime now,
}) async {
  final settings = await readPrintSettings(client);
  await printDocument(
    shiftReportBytes(
      summary,
      l10n: l10n,
      printedAt: now,
      showProductSales: settings?.showProductSalesSummary ?? false,
      footerText: settings?.receiptFooterText,
    ),
    printer: printer,
    store: store,
  );
}
