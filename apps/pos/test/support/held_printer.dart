/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/printer_port.dart';

/// A printer whose scan and connect stay open until the test lets them finish, so what a screen
/// says *while* it waits can be looked at.
class HeldPrinter extends FakePrinter {
  HeldPrinter(super.devices);

  final scanning = Completer<void>();
  final connecting = Completer<void>();

  @override
  Future<List<PrinterDevice>> scan({
    Duration duration = defaultPrinterScanDuration,
  }) async {
    await scanning.future;
    return super.scan(duration: duration);
  }

  @override
  Future<PrinterDevice> connect(String address) async {
    await connecting.future;
    return super.connect(address);
  }
}
