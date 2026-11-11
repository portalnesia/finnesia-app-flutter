/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pn_pos/src/pos_escpos_format.dart' show formatTestPageEscPos;
import 'package:pn_types/src/native/print_queue_port.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/printer_failure_text.dart';
import 'package:pos/printer/printer_output.dart';
import 'package:pos/printer/printer_queue_failure_text.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/printer/windows_print_format.dart';
import 'package:pos/printer/windows_print_pdf.dart';

/// ESC/POS formatting options for whatever receives the ESC/POS bytes: the paired Bluetooth
/// printer, or a Windows queue printing RAW. The test page goes to the selected output.
class PrinterFormatControls extends StatefulWidget {
  const PrinterFormatControls({super.key, required this.showTestPrint});

  final bool showTestPrint;

  @override
  State<PrinterFormatControls> createState() => _PrinterFormatControlsState();
}

class _PrinterFormatControlsState extends State<PrinterFormatControls> {
  PrinterFormatSettings? _settings;
  bool _loading = true;
  bool _saving = false;
  bool _printing = false;
  bool _loadFailed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await readPrinterFormatSettings(
        AppScope.of(context).store,
      );
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _loading = false;
      });
    } on StoreException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _save(PrinterFormatSettings next) async {
    final previous = _settings!;
    setState(() {
      _settings = next;
      _saving = true;
    });
    try {
      await savePrinterFormatSettings(next, AppScope.of(context).store);
    } on StoreException {
      if (mounted) {
        setState(() => _settings = previous);
        showTopNotice(
          context,
          message: L10n.of(context).printerFormatSaveFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _printTestPage() async {
    final settings = _settings!;
    final l10n = L10n.of(context);
    final services = AppScope.of(context);
    setState(() => _printing = true);
    try {
      final bytes = formatTestPageEscPos(
        l10n.printerTestPrintTitle,
        l10n.printerLineColumnsOption(settings.columns),
        settings.columns,
        settings.autoCutter,
      );
      await printSelectedDocument(
        bluetoothBytes: bytes,
        buildWindowsPdf: (pageSize) => renderWindowsPrintPdf(
          escPosBytes: bytes,
          columns: settings.columns,
          pageFormat: windowsQueuePageFormat(pageSize),
        ),
        documentName: l10n.printerTestPrintTitle,
        bluetooth: services.printer,
        printQueue: services.printQueue,
        store: services.store,
        platform: defaultTargetPlatform,
      );
      if (mounted) {
        showTopNotice(context, message: l10n.printerTestPrintSent);
      }
    } on PrinterException catch (error) {
      if (mounted) {
        showTopNotice(
          context,
          message: printerFailureText(
            l10n,
            error.reason,
            fallback: l10n.printerTestPrintFailed,
          ),
        );
      }
    } on PrintQueueException catch (error) {
      if (mounted) {
        showTopNotice(
          context,
          message: printerQueueFailureText(l10n, error.reason),
        );
      }
    } on StoreException {
      if (mounted) {
        showTopNotice(context, message: l10n.printerFormatLoadFailed);
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }
    if (_loadFailed || _settings == null) {
      return Text(l10n.printerFormatLoadFailed);
    }

    final settings = _settings!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.printerLineColumns,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.printerLineColumnsHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: settings.columns,
          decoration: InputDecoration(labelText: l10n.printerLineColumns),
          items: [
            for (final columns in printerColumnOptions)
              DropdownMenuItem(
                value: columns,
                child: Text(l10n.printerLineColumnsOption(columns)),
              ),
          ],
          onChanged: _saving
              ? null
              : (columns) {
                  if (columns != null && columns != settings.columns) {
                    _save((columns: columns, autoCutter: settings.autoCutter));
                  }
                },
        ),
        Material(
          color: Colors.transparent,
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.printerAutoCutter),
            subtitle: Text(l10n.printerAutoCutterHelp),
            value: settings.autoCutter,
            onChanged: _saving
                ? null
                : (autoCutter) => _save((
                    columns: settings.columns,
                    autoCutter: autoCutter,
                  )),
          ),
        ),
        if (widget.showTestPrint) ...[
          const SizedBox(height: 4),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saving || _printing ? null : _printTestPage,
              icon: _printing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_outlined),
              label: Text(l10n.printerTestPrint),
            ),
          ),
        ],
      ],
    );
  }
}
