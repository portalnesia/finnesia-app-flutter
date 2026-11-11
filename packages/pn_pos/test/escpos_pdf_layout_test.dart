/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/escpos.dart';
import 'package:pn_pos/src/escpos_pdf_layout.dart';
import 'package:test/test.dart';

void main() {
  test('keeps Bluetooth text, emphasis, alignment, and feed gaps in order', () {
    final bytes = buildCommands([
      cmdInit(),
      cmdFeed(2),
      cmdAlign(EscPosAlign.center),
      cmdBold(true),
      cmdText('SHIFT'),
      cmdBold(false),
      cmdText('Café'),
      cmdAlign(EscPosAlign.left),
      cmdText('Total                      Rp 1.000'),
      cmdText(''),
      cmdAlign(EscPosAlign.center),
      cmdText('Finnesia.com'),
      cmdFeed(3),
      cmdCut(),
    ]);

    expect(parseEscPosPdfLayout(bytes), [
      (text: '', alignment: EscPosAlign.left, bold: false),
      (text: '', alignment: EscPosAlign.left, bold: false),
      (text: 'SHIFT', alignment: EscPosAlign.center, bold: true),
      (text: 'Café', alignment: EscPosAlign.center, bold: false),
      (
        text: 'Total                      Rp 1.000',
        alignment: EscPosAlign.left,
        bold: false,
      ),
      (text: '', alignment: EscPosAlign.left, bold: false),
      (text: 'Finnesia.com', alignment: EscPosAlign.center, bold: false),
      (text: '', alignment: EscPosAlign.center, bold: false),
      (text: '', alignment: EscPosAlign.center, bold: false),
      (text: '', alignment: EscPosAlign.center, bold: false),
    ]);
  });
}
