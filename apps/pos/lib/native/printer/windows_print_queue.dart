/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pn_types/src/native/print_queue_port.dart';
import 'package:printing/printing.dart';

/// The installed Windows system printer queues. The printing plugin asks Windows to render each
/// PDF through the selected queue's driver; this is not a raw USB or ESC/POS transport.
class WindowsPrintQueueAdapter implements PrintQueuePort {
  const WindowsPrintQueueAdapter();

  void _requireWindows() {
    if (defaultTargetPlatform != TargetPlatform.windows) {
      throw const PrintQueueException(PrintQueueFailure.unsupported);
    }
  }

  @override
  Future<List<WindowsPrintQueue>> listQueues() async {
    _requireWindows();
    try {
      final printers = await Printing.listPrinters();
      final queues = [
        for (final printer in printers)
          (
            id: printer.url,
            name: printer.name,
            isDefault: printer.isDefault,
            isAvailable: printer.isAvailable,
          ),
      ];
      queues.sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return a.name.compareTo(b.name);
      });
      return queues;
    } on PrintQueueException {
      rethrow;
    } on Object catch (error) {
      throw PrintQueueException(PrintQueueFailure.listFailed, cause: error);
    }
  }

  @override
  Future<void> printPdf({
    required String queueId,
    required String name,
    required Uint8List bytes,
  }) async {
    _requireWindows();
    try {
      final sent = await Printing.directPrintPdf(
        printer: Printer(url: queueId, name: name),
        onLayout: (_) async => bytes,
        name: name,
        format: PdfPageFormat.a4,
        dynamicLayout: false,
        usePrinterSettings: true,
      );
      if (!sent) throw const PrintQueueException(PrintQueueFailure.cancelled);
    } on PrintQueueException {
      rethrow;
    } on Object catch (error) {
      throw PrintQueueException(PrintQueueFailure.printFailed, cause: error);
    }
  }
}
