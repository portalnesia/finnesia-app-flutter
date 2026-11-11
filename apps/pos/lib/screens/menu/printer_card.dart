/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pn_types/src/native/print_queue_port.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/screens/menu/printer_format_controls.dart';
import 'package:pos/screens/menu/printer_pairing_sheet.dart';
import 'package:pos/screens/menu/windows_printer_queue_sheet.dart';

typedef _WindowsPrinterCardState = ({
  PrinterMode? mode,
  PrinterDevice? bluetooth,
  WindowsPrintQueue? queue,
  WindowsQueueFormat format,
});

/// Which printer this device prints to, and the way to change that.
///
/// Android keeps its existing BLE-only card. Windows can select a BLE printer or an installed
/// Windows queue; those settings are stored independently so switching does not forget either.
class PrinterCard extends StatefulWidget {
  const PrinterCard({super.key});

  @override
  State<PrinterCard> createState() => _PrinterCardState();
}

class _PrinterCardState extends State<PrinterCard> {
  Future<PrinterDevice?>? _saved;
  Future<_WindowsPrinterCardState>? _windowsSaved;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _windowsSaved ??= _loadWindowsState();
    } else {
      _saved ??= readSavedPrinter(AppScope.of(context).store);
    }
  }

  Future<_WindowsPrinterCardState> _loadWindowsState() async {
    final store = AppScope.of(context).store;
    final (mode, bluetooth, queue, format) = await (
      readPrinterMode(store, platform: TargetPlatform.windows),
      readSavedPrinter(store),
      readSavedWindowsPrinterQueue(store),
      readWindowsQueueFormat(store),
    ).wait;
    return (mode: mode, bluetooth: bluetooth, queue: queue, format: format);
  }

  Future<void> _pair() async {
    final paired = await showPrinterPairingSheet(context);
    if (!paired || !mounted) return;
    _reload();
  }

  Future<void> _selectMode(
    PrinterMode mode,
    _WindowsPrinterCardState state,
  ) async {
    final l10n = L10n.of(context);
    final store = AppScope.of(context).store;
    try {
      if (mode == PrinterMode.windowsQueue && state.queue == null) {
        final selected = await showWindowsPrinterQueueSheet(context);
        if (!selected || !mounted) return;
      } else {
        await savePrinterMode(mode, store);
      }
    } on StoreException {
      if (mounted) {
        showTopNotice(context, message: l10n.printerOutputSaveFailed);
      }
      return;
    }
    if (mounted) _reload();
  }

  Future<void> _selectQueueFormat(WindowsQueueFormat format) async {
    final l10n = L10n.of(context);
    try {
      await saveWindowsQueueFormat(format, AppScope.of(context).store);
    } on StoreException {
      if (mounted) {
        showTopNotice(context, message: l10n.printerFormatSaveFailed);
      }
      return;
    }
    if (mounted) _reload();
  }

  Future<void> _forgetBluetooth() async {
    final l10n = L10n.of(context);
    final services = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.menuPrinterForgetTitle),
        content: Text(l10n.menuPrinterForgetDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.menuPrinterForgetConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await clearPrinter(printer: services.printer, store: services.store);
    } on StoreException {
      if (mounted) {
        showTopNotice(context, message: l10n.menuPrinterForgetFailed);
      }
      return;
    }
    if (mounted) _reload();
  }

  Future<void> _forgetWindowsQueue() async {
    final l10n = L10n.of(context);
    final store = AppScope.of(context).store;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.printerWindowsQueueForgetTitle),
        content: Text(l10n.printerWindowsQueueForgetDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.printerWindowsQueueForgetConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await clearWindowsPrinterQueue(store);
    } on StoreException {
      if (mounted) {
        showTopNotice(context, message: l10n.printerWindowsQueueForgetFailed);
      }
      return;
    }
    if (mounted) _reload();
  }

  /// Reads saved printer settings again after a change.
  void _reload() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      final read = _loadWindowsState();
      setState(() {
        _windowsSaved = read;
      });
    } else {
      final read = readSavedPrinter(AppScope.of(context).store);
      setState(() {
        _saved = read;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return FutureBuilder<_WindowsPrinterCardState>(
        future: _windowsSaved,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasError) {
            return _cardFrame(l10n, Text(l10n.menuPrinterUnreadable));
          }
          return _windowsCard(l10n, snapshot.requireData);
        },
      );
    }

    return FutureBuilder<PrinterDevice?>(
      future: _saved,
      builder: (context, snapshot) {
        // Preserve the Android BLE card and its no-printer/error behavior.
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final saved = snapshot.data;
        return _cardFrame(
          l10n,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.hasError
                    ? l10n.menuPrinterUnreadable
                    : saved?.name ?? l10n.menuPrinterNone,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: PnTouch.min,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _pair,
                  child: Text(
                    saved == null
                        ? l10n.menuPrinterPair
                        : l10n.menuPrinterChange,
                  ),
                ),
              ),
              if (saved != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: PnTouch.min,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _forgetBluetooth,
                    child: Text(l10n.menuPrinterForget),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              PrinterFormatControls(showTestPrint: saved != null),
            ],
          ),
        );
      },
    );
  }

  Widget _windowsCard(L10n l10n, _WindowsPrinterCardState state) => _cardFrame(
    l10n,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.printerOutputSectionTitle,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SegmentedButton<PrinterMode>(
          emptySelectionAllowed: true,
          selected: state.mode == null ? const {} : {state.mode!},
          segments: [
            ButtonSegment(
              value: PrinterMode.bluetooth,
              label: Text(l10n.printerOutputBluetooth),
            ),
            ButtonSegment(
              value: PrinterMode.windowsQueue,
              label: Text(l10n.printerOutputWindowsQueue),
            ),
          ],
          onSelectionChanged: (values) {
            if (values.isNotEmpty) _selectMode(values.first, state);
          },
        ),
        const SizedBox(height: 8),
        Text(
          l10n.printerOutputFlutterModesNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (state.mode == null)
          Text(l10n.printerOutputChooseHint)
        else if (state.mode == PrinterMode.bluetooth)
          _bluetoothControls(l10n, state.bluetooth)
        else
          _windowsQueueControls(l10n, state.queue, state.format),
      ],
    ),
  );

  Widget _bluetoothControls(L10n l10n, PrinterDevice? saved) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(saved?.name ?? l10n.menuPrinterNone),
      const SizedBox(height: 12),
      SizedBox(
        height: PnTouch.min,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _pair,
          child: Text(
            saved == null ? l10n.menuPrinterPair : l10n.menuPrinterChange,
          ),
        ),
      ),
      if (saved != null) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: PnTouch.min,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _forgetBluetooth,
            child: Text(l10n.menuPrinterForget),
          ),
        ),
      ],
      const SizedBox(height: 16),
      PrinterFormatControls(showTestPrint: saved != null),
    ],
  );

  Widget _windowsQueueControls(
    L10n l10n,
    WindowsPrintQueue? queue,
    WindowsQueueFormat format,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(queue?.name ?? l10n.menuPrinterNone),
      const SizedBox(height: 12),
      Text(
        l10n.printerWindowsQueueFormat,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      SegmentedButton<WindowsQueueFormat>(
        selected: {format},
        segments: [
          ButtonSegment(
            value: WindowsQueueFormat.escPos,
            label: Text(l10n.printerWindowsQueueFormatEscPos),
          ),
          ButtonSegment(
            value: WindowsQueueFormat.pdf,
            label: Text(l10n.printerWindowsQueueFormatPdf),
          ),
        ],
        onSelectionChanged: (values) {
          if (values.first != format) _selectQueueFormat(values.first);
        },
      ),
      const SizedBox(height: 8),
      Text(
        format == WindowsQueueFormat.escPos
            ? l10n.printerWindowsQueueFormatEscPosNote
            : l10n.printerWindowsQueueFormattingNote,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: PnTouch.min,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () async {
            if (queue == null) {
              if (await showWindowsPrinterQueueSheet(context) && mounted) {
                _reload();
              }
            } else {
              await _selectMode(PrinterMode.windowsQueue, (
                mode: PrinterMode.windowsQueue,
                bluetooth: null,
                queue: null,
                format: format,
              ));
            }
          },
          child: Text(l10n.printerWindowsQueueChange),
        ),
      ),
      if (queue != null) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: PnTouch.min,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _forgetWindowsQueue,
            child: Text(l10n.printerWindowsQueueForget),
          ),
        ),
      ],
      if (format == WindowsQueueFormat.escPos) ...[
        const SizedBox(height: 16),
        PrinterFormatControls(showTestPrint: queue != null),
      ],
    ],
  );

  Widget _cardFrame(L10n l10n, Widget content) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.menuPrinterSection,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 12),
      content,
    ],
  );
}
