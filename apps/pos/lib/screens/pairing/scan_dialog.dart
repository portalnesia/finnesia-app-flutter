/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/native/scanner/scanner_port.dart';
import 'package:pos/pairing/pairing_controller.dart';

/// The camera, for reading the QR on the dashboard instead of typing the code.
///
/// It closes the moment a code is taken, and the pairing carries on behind it like a tap on
/// Pasangkan: the answer, good or bad, shows on the screen underneath. A QR that is not a
/// pairing code is passed over and the camera keeps looking, since a cashier holding the tablet
/// up to the wrong screen has nothing to fix on this side.
Future<void> showScanDialog(
  BuildContext context, {
  required ScannerPort scanner,
  required PairingController controller,
}) => showDialog<void>(
  context: context,
  builder: (context) {
    final l10n = L10n.of(context);
    return AlertDialog(
      title: Text(l10n.pairingScanTitle),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox.square(
              dimension: 320,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: scanner.buildView(
                  onCode: (code) {
                    if (controller.useScannedCode(code)) {
                      Navigator.of(context).pop();
                    }
                  },
                  failureBuilder: (context, failure) =>
                      _Failure(failure: failure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.pairingScanHint),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  },
);

class _Failure extends StatelessWidget {
  const _Failure({required this.failure});

  final ScannerFailure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return ColoredBox(
      color: context.pn.surfaceMuted,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            liveRegion: true,
            child: Text(switch (failure) {
              ScannerFailure.permissionDenied => l10n.pairingScanDenied,
              ScannerFailure.unavailable => l10n.pairingScanUnavailable,
            }, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
