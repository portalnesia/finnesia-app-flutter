/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pdf/pdf.dart';
import 'package:pn_types/src/native/print_queue_port.dart'
    show WindowsPrintPageSize;

/// The left/right safe area accounts for non-printable margins on Windows queues.
const windowsPrintPageMargin = 5 * PdfPageFormat.mm;

/// Noto Sans Mono is six-tenths of an em wide, matching a fixed ESC/POS text column.
const windowsPrintMonospaceColumnFactor = 0.6;
const windowsPrintBodyFontSize = 7.0;

typedef WindowsPrintMetrics = ({
  double availableWidth,
  double contentWidth,
  double fontSize,
});

/// Reserves the driver's unprintable edge area and scales down rather than clipping columns.
WindowsPrintMetrics windowsPrintMetrics(
  PdfPageFormat pageFormat, {
  required int columns,
}) {
  if (columns < 1) {
    throw ArgumentError.value(columns, 'columns', 'Must be positive');
  }
  final availableWidth = pageFormat.width - 2 * windowsPrintPageMargin;
  if (availableWidth <= 0) {
    throw ArgumentError.value(
      pageFormat.width,
      'pageFormat.width',
      'Page is narrower than the printable margins',
    );
  }

  final maximumFontSize =
      availableWidth / (columns * windowsPrintMonospaceColumnFactor);
  final fontSize = maximumFontSize < windowsPrintBodyFontSize
      ? maximumFontSize
      : windowsPrintBodyFontSize;
  return (
    availableWidth: availableWidth,
    contentWidth: columns * fontSize * windowsPrintMonospaceColumnFactor,
    fontSize: fontSize,
  );
}

/// Wraps any line that would otherwise run past the Bluetooth printer's columns.
List<String> windowsPrintWrapLine(String text, {required int columns}) {
  if (columns < 1) {
    throw ArgumentError.value(columns, 'columns', 'Must be positive');
  }
  final codePoints = text.runes.toList();
  final wrapped = <String>[];
  for (var start = 0; start < codePoints.length; start += columns) {
    final end = start + columns < codePoints.length
        ? start + columns
        : codePoints.length;
    wrapped.add(String.fromCharCodes(codePoints.getRange(start, end)));
  }
  return wrapped;
}

/// Keeps the physical page dimensions reported by the selected Windows driver.
PdfPageFormat windowsQueuePageFormat(WindowsPrintPageSize pageSize) =>
    PdfPageFormat(pageSize.width, pageSize.height);
