/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pn_pos/src/escpos.dart';
import 'package:pn_pos/src/escpos_pdf_layout.dart';

import 'windows_print_format.dart';

typedef _WindowsPrintFonts = ({pw.Font regular, pw.Font bold});

_WindowsPrintFonts? _fontCache;
Future<_WindowsPrintFonts>? _fontLoading;

Future<_WindowsPrintFonts> _loadFonts() async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSansMono-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSansMono-Bold.ttf'),
  );
  return (regular: regular, bold: bold);
}

Future<_WindowsPrintFonts> _fonts() async {
  final cached = _fontCache;
  if (cached != null) return cached;

  final loading = _fontLoading ??= _loadFonts();
  try {
    final loaded = await loading;
    _fontCache = loaded;
    return loaded;
  } finally {
    if (identical(_fontLoading, loading)) _fontLoading = null;
  }
}

/// Renders the same ESC/POS text stream sent over BLE, using the driver's page size.
Future<Uint8List> renderWindowsPrintPdf({
  required Uint8List escPosBytes,
  required int columns,
  required PdfPageFormat pageFormat,
}) async {
  final lines = parseEscPosPdfLayout(escPosBytes);
  final metrics = windowsPrintMetrics(pageFormat, columns: columns);
  final fonts = await _fonts();
  final document = pw.Document();

  document.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.all(windowsPrintPageMargin),
      build: (_) => [
        for (final line in lines)
          _lineWidget(line, columns: columns, metrics: metrics, fonts: fonts),
      ],
    ),
  );

  return document.save();
}

pw.Widget _lineWidget(
  EscPosPdfLine line, {
  required int columns,
  required WindowsPrintMetrics metrics,
  required _WindowsPrintFonts fonts,
}) {
  if (line.text.isEmpty) {
    return pw.SizedBox(height: metrics.fontSize * 1.2);
  }

  final (alignment, textAlignment, width) = switch (line.alignment) {
    EscPosAlign.left => (
      pw.Alignment.centerLeft,
      pw.TextAlign.left,
      metrics.contentWidth,
    ),
    EscPosAlign.center => (
      pw.Alignment.center,
      pw.TextAlign.center,
      metrics.availableWidth,
    ),
    EscPosAlign.right => (
      pw.Alignment.centerRight,
      pw.TextAlign.right,
      metrics.availableWidth,
    ),
  };
  final wrappedText = windowsPrintWrapLine(
    line.text,
    columns: columns,
  ).join('\n');

  return pw.Align(
    alignment: alignment,
    child: pw.SizedBox(
      width: width,
      child: pw.Text(
        wrappedText,
        textAlign: textAlignment,
        style: pw.TextStyle(
          font: line.bold ? fonts.bold : fonts.regular,
          fontSize: metrics.fontSize,
          color: PdfColors.black,
        ),
      ),
    ),
  );
}
