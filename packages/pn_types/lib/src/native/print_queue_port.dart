/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:typed_data';

/// An installed system printer queue. [id] is the operating-system queue identity, not a BLE id.
typedef WindowsPrintQueue = ({
  String id,
  String name,
  bool isDefault,
  bool isAvailable,
});

/// Physical page dimensions in PDF points, reported by the selected queue's driver.
typedef WindowsPrintPageSize = ({double width, double height});

/// Builds a PDF after the Windows queue has supplied its physical page dimensions.
typedef WindowsPrintPdfBuilder =
    Future<Uint8List> Function(WindowsPrintPageSize pageSize);

enum PrintQueueFailure {
  unsupported,
  notConfigured,
  listFailed,
  notFound,
  printFailed,
  cancelled,
}

/// A failure enumerating or submitting a job to an installed system printer queue.
class PrintQueueException implements Exception {
  const PrintQueueException(this.reason, {this.cause});

  final PrintQueueFailure reason;

  /// Native/plugin cause retained for a debugger; never shown to the cashier.
  final Object? cause;

  @override
  String toString() => 'PrintQueueException: $reason';
}

/// Native queue printer contract for printers installed through the operating-system driver.
/// A job is either a PDF the driver renders, or raw bytes the spooler passes to the printer
/// untouched (ESC/POS for a receipt printer).
abstract interface class PrintQueuePort {
  Future<List<WindowsPrintQueue>> listQueues();

  /// Submits [bytes] with the spooler's RAW datatype, so the driver does not render them.
  Future<void> printRaw({
    required String queueId,
    required String name,
    required Uint8List bytes,
  });

  Future<void> printPdf({
    required String queueId,
    required String name,
    required WindowsPrintPdfBuilder buildPdf,
  });
}
