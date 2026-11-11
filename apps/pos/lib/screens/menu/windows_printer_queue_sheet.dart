/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pn_types/src/native/print_queue_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/printer_queue_failure_text.dart';
import 'package:pos/printer/printer_service.dart';

/// Lists drivers installed in Windows and remembers the queue the cashier chooses.
Future<bool> showWindowsPrinterQueueSheet(BuildContext context) async {
  final selected = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const WindowsPrinterQueueSheet(),
  );
  return selected ?? false;
}

class WindowsPrinterQueueSheet extends StatefulWidget {
  const WindowsPrinterQueueSheet({super.key});

  @override
  State<WindowsPrinterQueueSheet> createState() =>
      _WindowsPrinterQueueSheetState();
}

class _WindowsPrinterQueueSheetState extends State<WindowsPrinterQueueSheet> {
  bool _started = false;
  bool _loading = true;
  String? _savingQueueId;
  String? _error;
  List<WindowsPrintQueue> _queues = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_loadQueues());
  }

  Future<void> _loadQueues() async {
    if (!_loading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final queues = await AppScope.of(context).printQueue.listQueues();
      if (!mounted) return;
      setState(() {
        _queues = queues;
        _loading = false;
        _error = null;
      });
    } on PrintQueueException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = printerQueueFailureText(L10n.of(context), error.reason);
        _loading = false;
      });
    }
  }

  Future<void> _choose(WindowsPrintQueue queue) async {
    if (_savingQueueId != null) return;
    setState(() => _savingQueueId = queue.id);
    try {
      await rememberWindowsPrinterQueue(queue, AppScope.of(context).store);
      if (mounted) Navigator.of(context).pop(true);
    } on StoreException {
      if (!mounted) return;
      setState(() {
        _savingQueueId = null;
        _error = L10n.of(context).printerWindowsQueueSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.78;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.printerWindowsQueueTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonClose,
                  onPressed: _savingQueueId == null
                      ? () => Navigator.of(context).pop(false)
                      : null,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.printerWindowsQueueDesc),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_error!),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadQueues,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRetry),
                  ),
                ],
              )
            else if (_queues.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.printerWindowsQueueEmpty),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadQueues,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRetry),
                  ),
                ],
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _queues.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final queue = _queues[index];
                    return ListTile(
                      enabled: _savingQueueId == null,
                      leading: const Icon(Icons.print_outlined),
                      title: Text(queue.name),
                      subtitle: queue.isAvailable
                          ? null
                          : Text(l10n.printerWindowsQueueUnavailable),
                      trailing: _savingQueueId == queue.id
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : queue.isDefault
                          ? Text(l10n.printerWindowsQueueDefault)
                          : null,
                      onTap: _savingQueueId == null
                          ? () => _choose(queue)
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
