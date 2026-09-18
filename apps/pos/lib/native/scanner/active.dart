/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pos/native/scanner/scanner_mobile.dart';
import 'package:pos/native/scanner/scanner_port.dart';

ScannerPort get scanner => _scanner;
ScannerPort _scanner = MobileScannerReader();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setScanner(ScannerPort impl) => _scanner = impl;
