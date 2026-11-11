/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/native/print_queue_port.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/print_settings.dart';
import 'package:pos/printer/printer_output.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/printer/shift_report.dart';
import 'package:pos/printer/windows_shift_report_pdf.dart';

/// Prints the closing report of [summary] to the selected printer.
///
/// Windows renders the same normalized summary and labels into PDF, then sends it through the
/// selected installed system queue. Other platforms keep the existing BLE ESC/POS output. The
/// tenant's settings decide whether the product breakdown and footer appear; unreadable settings
/// still leave the core report printable.
Future<void> printShiftReport(
  ShiftSummaryResponse summary, {
  required ApiClient client,
  required PrinterPort printer,
  required PrintQueuePort printQueue,
  required StorePort store,
  required L10n l10n,
  required DateTime now,
  required TargetPlatform platform,
}) async {
  final settings = await readPrintSettings(client);
  final showProductSales = settings?.showProductSalesSummary ?? false;
  final footerText = settings?.receiptFooterText;
  final outputMode = await readPrinterMode(store, platform: platform);
  final printerFormat = outputMode == PrinterMode.windowsQueue
      ? defaultPrinterFormatSettings
      : await readPrinterFormatSettings(store);
  await printSelectedDocument(
    bluetoothBytes: shiftReportBytes(
      summary,
      l10n: l10n,
      printedAt: now,
      showProductSales: showProductSales,
      footerText: footerText,
      columns: printerFormat.columns,
      autoCutter: printerFormat.autoCutter,
    ),
    buildWindowsPdf: () => renderShiftReportPdf(
      summary: shiftReportData(summary),
      printedAt: now.toIso8601String(),
      labels: shiftReportLabels(l10n),
      showProductSales: showProductSales,
      footerText: footerText,
    ),
    documentName: l10n.posShiftReportTitle,
    bluetooth: printer,
    printQueue: printQueue,
    store: store,
    platform: platform,
  );
}
