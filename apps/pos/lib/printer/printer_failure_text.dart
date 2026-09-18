/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/printer_port.dart';
import 'package:pos/l10n/app_localizations.dart';

/// The sentence for a printer that would not do what was asked, or [fallback] when none of the
/// reasons that have a cure of their own is the one.
///
/// Three reasons read the same wherever they happen, because the cure is the same: allow
/// Bluetooth in Settings, switch it on, or accept that this tablet cannot. The rest depend on
/// what was being attempted, so the caller says it: "could not scan" is no help to someone whose
/// printer refused to connect.
String printerFailureText(
  L10n l10n,
  PrinterFailure reason, {
  required String fallback,
}) => switch (reason) {
  PrinterFailure.permissionDenied => l10n.printerPermissionDenied,
  PrinterFailure.bluetoothOff => l10n.printerBluetoothOff,
  PrinterFailure.unsupported => l10n.printerUnsupported,
  _ => fallback,
};
