/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/native/print_queue_port.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pos/printer/printer_service.dart';

/// Sends the same logical document over the existing BLE port or to a saved Windows system queue,
/// as RAW ESC/POS bytes or as a generated PDF. Non-Windows platforms always retain BLE.
Future<void> printSelectedDocument({
  required Uint8List bluetoothBytes,
  required WindowsPrintPdfBuilder buildWindowsPdf,
  required String documentName,
  required PrinterPort bluetooth,
  required PrintQueuePort printQueue,
  required StorePort store,
  required TargetPlatform platform,
}) async {
  final mode = await readPrinterMode(store, platform: platform);
  if (mode != PrinterMode.windowsQueue) {
    await printDocument(bluetoothBytes, printer: bluetooth, store: store);
    return;
  }

  final selected = await readSavedWindowsPrinterQueue(store);
  if (selected == null) {
    throw const PrintQueueException(PrintQueueFailure.notConfigured);
  }
  final queues = await printQueue.listQueues();
  if (!queues.any((queue) => queue.id == selected.id)) {
    throw const PrintQueueException(PrintQueueFailure.notFound);
  }
  switch (await readWindowsQueueFormat(store)) {
    case WindowsQueueFormat.escPos:
      await printQueue.printRaw(
        queueId: selected.id,
        name: documentName,
        bytes: bluetoothBytes,
      );
    case WindowsQueueFormat.pdf:
      await printQueue.printPdf(
        queueId: selected.id,
        name: documentName,
        buildPdf: buildWindowsPdf,
      );
  }
}
