/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'escpos.dart';

/// One visible text row and the ESC/POS state active when it was printed.
///
/// The Windows PDF path reads the same bytes sent over Bluetooth, rather than maintaining another
/// copy of receipt and report formatting rules. Named fields keep the row's print state explicit.
typedef EscPosPdfLine = ({String text, EscPosAlign alignment, bool bold});

/// Decodes the text-only ESC/POS commands emitted by Finnesia's receipt and shift-report formatters.
///
/// Only their current command set is accepted. Failing on an unknown command is safer than
/// silently producing a Windows document that no longer matches the Bluetooth layout.
List<EscPosPdfLine> parseEscPosPdfLayout(List<int> bytes) {
  final lines = <EscPosPdfLine>[];
  final textBytes = <int>[];
  var alignment = EscPosAlign.left;
  var bold = false;
  var index = 0;

  void finishLine() {
    lines.add((
      text: utf8.decode(textBytes),
      alignment: alignment,
      bold: bold,
    ));
    textBytes.clear();
  }

  void feedLines(int count) {
    for (var line = 0; line < count; line++) {
      lines.add((text: '', alignment: alignment, bold: bold));
    }
  }

  while (index < bytes.length) {
    final byte = bytes[index];
    if (byte == 0x0a) {
      finishLine();
      index++;
      continue;
    }

    if (byte == 0x1b) {
      if (textBytes.isNotEmpty) {
        throw FormatException('ESC/POS command interrupted a text row', index);
      }
      if (index + 1 >= bytes.length) {
        throw FormatException('Incomplete ESC/POS command', index);
      }
      switch (bytes[index + 1]) {
        case 0x40:
          alignment = EscPosAlign.left;
          bold = false;
          index += 2;
        case 0x61:
          if (index + 2 >= bytes.length) {
            throw FormatException(
                'Incomplete ESC/POS alignment command', index);
          }
          final code = bytes[index + 2];
          alignment = switch (code) {
            0 => EscPosAlign.left,
            1 => EscPosAlign.center,
            2 => EscPosAlign.right,
            _ =>
              throw FormatException('Unknown ESC/POS alignment $code', index),
          };
          index += 3;
        case 0x45:
          if (index + 2 >= bytes.length) {
            throw FormatException('Incomplete ESC/POS emphasis command', index);
          }
          bold = bytes[index + 2] != 0;
          index += 3;
        case 0x64:
          if (index + 2 >= bytes.length) {
            throw FormatException('Incomplete ESC/POS feed command', index);
          }
          feedLines(bytes[index + 2]);
          index += 3;
        default:
          throw FormatException(
            'Unsupported ESC/POS command 0x${bytes[index + 1].toRadixString(16)}',
            index,
          );
      }
      continue;
    }

    if (byte == 0x1d) {
      if (textBytes.isNotEmpty) {
        throw FormatException('ESC/POS command interrupted a text row', index);
      }
      if (index + 1 >= bytes.length) {
        throw FormatException('Incomplete ESC/POS command', index);
      }
      if (bytes[index + 1] != 0x56 ||
          index + 3 >= bytes.length ||
          bytes[index + 2] != 66 ||
          bytes[index + 3] != 0) {
        throw FormatException('Unsupported ESC/POS cut command', index);
      }
      index += 4;
      continue;
    }

    textBytes.add(byte);
    index++;
  }

  if (textBytes.isNotEmpty) {
    throw FormatException('ESC/POS document ended inside a text row', index);
  }
  return lines;
}
