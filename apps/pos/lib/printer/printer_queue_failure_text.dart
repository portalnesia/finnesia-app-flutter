/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/print_queue_port.dart';
import 'package:pos/l10n/app_localizations.dart';

String printerQueueFailureText(L10n l10n, PrintQueueFailure reason) =>
    switch (reason) {
      PrintQueueFailure.unsupported => l10n.printerWindowsQueueUnsupported,
      PrintQueueFailure.notConfigured => l10n.printerWindowsQueueNotConfigured,
      PrintQueueFailure.listFailed => l10n.printerWindowsQueueLoadFailed,
      PrintQueueFailure.notFound => l10n.printerWindowsQueueNotFound,
      PrintQueueFailure.printFailed => l10n.printerWindowsQueuePrintFailed,
      PrintQueueFailure.cancelled => l10n.printerWindowsQueueCancelled,
    };
