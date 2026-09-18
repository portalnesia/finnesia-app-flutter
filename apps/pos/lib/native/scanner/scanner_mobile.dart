/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/native/scanner/scanner_port.dart';

/// [ScannerPort] over `mobile_scanner`.
///
/// The plugin asks for the camera permission itself the first time the view starts, and reports
/// a refusal through its error builder, which is what [ScannerFailure.permissionDenied] is made
/// from. Not exercised by any test: it needs a camera (`.claude/rules/testing.md` §8).
class MobileScannerReader implements ScannerPort {
  MobileScannerReader({TargetPlatform? platform})
    : _platform = platform ?? defaultTargetPlatform;

  final TargetPlatform _platform;

  // Android only: the plugin also ships iOS, macOS and web, none of which this app targets, and
  // not Windows, where its channels do not exist and opening the view throws.
  @override
  bool get isAvailable => _platform == TargetPlatform.android;

  @override
  Widget buildView({
    required void Function(String code) onCode,
    required Widget Function(BuildContext context, ScannerFailure failure)
    failureBuilder,
  }) => _MobileScannerView(onCode: onCode, failureBuilder: failureBuilder);
}

class _MobileScannerView extends StatefulWidget {
  const _MobileScannerView({
    required this.onCode,
    required this.failureBuilder,
  });

  final void Function(String code) onCode;
  final Widget Function(BuildContext context, ScannerFailure failure)
  failureBuilder;

  @override
  State<_MobileScannerView> createState() => _MobileScannerViewState();
}

class _MobileScannerViewState extends State<_MobileScannerView> {
  // QR only: the plugin reads every format by default, and a pairing screen has no use for the
  // barcode on a receipt lying next to the tablet.
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: _controller,
    onDetect: (capture) {
      for (final barcode in capture.barcodes) {
        final text = barcode.rawValue;
        if (text != null) widget.onCode(text);
      }
    },
    errorBuilder: (context, error) => widget.failureBuilder(
      context,
      error.errorCode == MobileScannerErrorCode.permissionDenied
          ? ScannerFailure.permissionDenied
          : ScannerFailure.unavailable,
    ),
  );
}
