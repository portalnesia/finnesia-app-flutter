/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:typed_data';

import 'print_queue_port.dart';

enum PrintQueueOperation { list, print }

/// A visible, configurable fake for tests that cannot call the Windows spooler.
class FakePrintQueuePort implements PrintQueuePort {
  FakePrintQueuePort([List<WindowsPrintQueue> queues = const []])
    : queues = List.of(queues);

  final List<WindowsPrintQueue> queues;
  WindowsPrintPageSize pageSize = const (width: 226.77165, height: 850.3937);
  final operations = <PrintQueueOperation>[];
  final printed = <({String queueId, String name, Uint8List bytes})>[];
  final _failures = <PrintQueueOperation, List<PrintQueueException>>{};

  void failNext(PrintQueueOperation operation, PrintQueueException failure) {
    (_failures[operation] ??= []).add(failure);
  }

  PrintQueueException? _takeFailure(PrintQueueOperation operation) {
    final failures = _failures[operation];
    if (failures == null || failures.isEmpty) return null;
    final failure = failures.removeAt(0);
    if (failures.isEmpty) _failures.remove(operation);
    return failure;
  }

  @override
  Future<List<WindowsPrintQueue>> listQueues() async {
    operations.add(PrintQueueOperation.list);
    final failure = _takeFailure(PrintQueueOperation.list);
    if (failure != null) throw failure;
    return List.unmodifiable(queues);
  }

  @override
  Future<void> printPdf({
    required String queueId,
    required String name,
    required WindowsPrintPdfBuilder buildPdf,
  }) async {
    operations.add(PrintQueueOperation.print);
    final failure = _takeFailure(PrintQueueOperation.print);
    if (failure != null) throw failure;
    final bytes = await buildPdf(pageSize);
    printed.add((
      queueId: queueId,
      name: name,
      bytes: Uint8List.fromList(bytes),
    ));
  }
}
