/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pos/printer/windows_print_format.dart';

void main() {
  group('Windows receipt PDF printable width', () {
    test('keeps the selected columns inside the driver page safe area', () {
      final page = PdfPageFormat(58 * PdfPageFormat.mm, 300 * PdfPageFormat.mm);
      final metrics = windowsPrintMetrics(page, columns: 32);

      expect(
        metrics.availableWidth,
        closeTo(page.width - 10 * PdfPageFormat.mm, 0.01),
      );
      expect(metrics.contentWidth, lessThanOrEqualTo(metrics.availableWidth));
      expect(metrics.fontSize, lessThanOrEqualTo(windowsPrintBodyFontSize));
    });

    test('reduces font size rather than clipping on narrow queue media', () {
      final page = PdfPageFormat(58 * PdfPageFormat.mm, 300 * PdfPageFormat.mm);
      final metrics = windowsPrintMetrics(page, columns: 48);

      expect(metrics.contentWidth, closeTo(metrics.availableWidth, 0.01));
      expect(metrics.fontSize, lessThan(windowsPrintBodyFontSize));
    });

    test('keeps the Bluetooth column width on wider queue media', () {
      final page = PdfPageFormat(80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm);
      final metrics = windowsPrintMetrics(page, columns: 32);

      expect(windowsPrintBodyFontSize, 7.0);
      expect(metrics.fontSize, 7.0);
      expect(metrics.contentWidth, closeTo(32 * 7.0 * 0.6, 0.01));
      expect(metrics.contentWidth, lessThanOrEqualTo(metrics.availableWidth));
    });

    test('wraps overlong printer rows instead of clipping at either edge', () {
      final line = List.filled(33, 'A').join();

      expect(windowsPrintWrapLine(line, columns: 32), [
        List.filled(32, 'A').join(),
        'A',
      ]);
      expect(windowsPrintWrapLine('', columns: 32), isEmpty);
    });
  });
}
