/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/pos_escpos_format.dart'
    show CategoryTicketEscPosLabels, formatCategoryTicketEscPos;
import 'package:pn_pos/src/pos_print_category.dart' show CategoryGroup;
import 'package:pn_types/src/native/print_queue_port.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/printer_output.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/printer/receipt.dart' show receiptBrandingText;
import 'package:pos/printer/windows_print_format.dart';
import 'package:pos/printer/windows_receipt_pdf.dart';

/// Prints the kitchen/bar ticket of one category [group] to the selected printer.
///
/// The web app's `printCategory` (`pos-print-controls.tsx`): the category's goods and quantities,
/// no prices, stamped with the moment it prints. A held basket and the live cart have no sale yet,
/// so [saleNumber] and [outletName] are optional. The Finnesia branding follows, as on every slip
/// this app prints.
Future<void> printCategoryTicket(
  CategoryGroup group, {
  String? outletName,
  String? saleNumber,
  String? tableNumber,
  String? queueNumber,
  required PrinterPort printer,
  required PrintQueuePort printQueue,
  required StorePort store,
  required L10n l10n,
  required TargetPlatform platform,
}) async {
  final format = await readPrinterFormatSettings(store);
  final bytes = formatCategoryTicketEscPos(
    group.name,
    group.lines,
    outletName,
    saleNumber,
    CategoryTicketEscPosLabels(
      noItems: l10n.receiptNoItems,
      tableNumber: l10n.posTableNumber,
      queueNumber: l10n.posQueueNumber,
      finnesiaBranding: receiptBrandingText,
    ),
    tableNumber,
    queueNumber,
    null,
    format.columns,
    format.autoCutter,
    true,
  );
  await printSelectedDocument(
    bluetoothBytes: bytes,
    buildWindowsPdf: (pageSize) => renderReceiptPdf(
      escPosBytes: bytes,
      columns: format.columns,
      pageFormat: windowsQueuePageFormat(pageSize),
    ),
    documentName: group.name,
    bluetooth: printer,
    printQueue: printQueue,
    store: store,
    platform: platform,
  );
}
