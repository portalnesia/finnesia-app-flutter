/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pdf/pdf.dart';
import 'package:pn_types/src/native/print_queue_port.dart'
    show WindowsPrintPageSize;

const windowsPrintPageMargin = 4 * PdfPageFormat.mm;
const windowsPrintBodyFontSize = 9.0;
const windowsPrintDetailFontSize = 8.0;
const windowsPrintHeadingFontSize = 12.0;
const windowsPrintSectionFontSize = 9.0;

/// Uses the physical page size returned by the selected Windows printer driver.
PdfPageFormat windowsQueuePageFormat(WindowsPrintPageSize pageSize) =>
    PdfPageFormat(pageSize.width, pageSize.height);
