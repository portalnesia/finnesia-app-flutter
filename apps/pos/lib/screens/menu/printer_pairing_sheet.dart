/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/top_notice.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/printer_failure_text.dart';
import 'package:pos/printer/printer_pairing_controller.dart';
import 'package:pos/screens/till/pos_sheet.dart';

/// S15: find a printer, choose it, keep it.
///
/// Resolves to true when a printer was paired, so the card that opened it reads what is saved
/// again.
Future<bool> showPrinterPairingSheet(BuildContext context) async {
  final paired = await showPosSheet<bool>(
    context,
    heightFactor: 0.8,
    builder: (context) => const PrinterPairingSheet(),
  );
  return paired ?? false;
}

class PrinterPairingSheet extends StatefulWidget {
  const PrinterPairingSheet({super.key});

  @override
  State<PrinterPairingSheet> createState() => _PrinterPairingSheetState();
}

class _PrinterPairingSheetState extends State<PrinterPairingSheet> {
  PrinterPairingController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    _controller ??= PrinterPairingController(
      printer: services.printer,
      store: services.store,
      analytics: services.analytics,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pair(PrinterDevice device) async {
    final controller = _controller!;
    await controller.pair(device);
    final state = controller.state;
    if (state is! PairingDone || !mounted) return;
    showTopNotice(
      context,
      message: L10n.of(context).printerPaired(state.device.name),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final controller = _controller!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PosSheetHeader(title: l10n.printerPairTitle),
        Expanded(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.printerPairDesc),
                const SizedBox(height: 16),
                SizedBox(
                  height: PnTouch.primary,
                  child: FilledButton(
                    onPressed: controller.isBusy ? null : controller.scan,
                    child: Text(l10n.printerScanButton),
                  ),
                ),
                const SizedBox(height: 16),
                ..._result(controller.state, l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _result(PairingState state, L10n l10n) => switch (state) {
    PairingScanning() => [_Waiting(l10n.printerScanning)],
    PairingConnecting() => [_Waiting(l10n.printerPairing)],
    PairingFound(:final devices) when devices.isEmpty => [
      Text(l10n.printerNoneFound),
    ],
    PairingFound(:final devices) => [
      for (final device in devices)
        ListTile(
          minVerticalPadding: 12,
          title: Text(device.name.isEmpty ? l10n.printerUnnamed : device.name),
          subtitle: Text(device.address),
          onTap: () => _pair(device),
        ),
    ],
    PairingFailed(:final reason, :final step) => [
      Text(
        printerFailureText(
          l10n,
          reason,
          fallback: switch (step) {
            PairingStep.scan => l10n.printerScanFailed,
            PairingStep.connect => l10n.printerPairFailed,
          },
        ),
      ),
    ],
    PairingSaveFailed() => [Text(l10n.printerSaveFailed)],
    _ => const [],
  };
}

/// Something is going on and nothing can be pressed until it ends: a spinner and the word for it.
class _Waiting extends StatelessWidget {
  const _Waiting(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    );
  }
}
