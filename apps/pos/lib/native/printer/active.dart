/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/printer_port.dart';
import 'package:pos/native/printer/printer_ble.dart';

/// The thermal printer, over BLE. Widgets and `printer_service` use this, never the plugin
/// (`.claude/rules/native-ports.md` §1.1).
PrinterPort get printer => _printer;
PrinterPort _printer = BlePrinter();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setPrinter(PrinterPort impl) => _printer = impl;
