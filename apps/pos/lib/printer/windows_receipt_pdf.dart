/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import 'windows_print_pdf.dart';

/// Renders the already-formatted Bluetooth receipt stream for an installed Windows queue.
Future<Uint8List> renderReceiptPdf({
  required Uint8List escPosBytes,
  required int columns,
  required PdfPageFormat pageFormat,
}) => renderWindowsPrintPdf(
  escPosBytes: escPosBytes,
  columns: columns,
  pageFormat: pageFormat,
);
