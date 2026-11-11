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

enum PrintQueueFailure {
  unsupported,
  notConfigured,
  listFailed,
  notFound,
  printFailed,
  cancelled,
}

/// A failure enumerating or submitting a PDF to an installed system printer queue.
class PrintQueueException implements Exception {
  const PrintQueueException(this.reason, {this.cause});

  final PrintQueueFailure reason;

  /// Native/plugin cause retained for a debugger; never shown to the cashier.
  final Object? cause;

  @override
  String toString() => 'PrintQueueException: $reason';
}

/// Native queue printer contract. Unlike [PrinterPort], this accepts PDF documents rather than
/// ESC/POS byte streams and represents printers installed through the operating-system driver.
abstract interface class PrintQueuePort {
  Future<List<WindowsPrintQueue>> listQueues();

  Future<void> printPdf({
    required String queueId,
    required String name,
    required Uint8List bytes,
  });
}
