/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/pos.dart';

/// The tenant's settings, for the optional parts of a printout (the footer, the product
/// breakdown), or `null` when they could not be read.
///
/// Read when a print button is pressed, not with the screen: most visits never print. A read
/// that fails prints without them. What a cashier reconciles against is all in the part that
/// always prints, and a printout missing its footer is better than none.
Future<POSPreferences?> readPrintSettings(ApiClient client) async {
  try {
    return await PosApi.settingsGet(client);
  } on ApiError {
    return null;
  } on TransportException {
    return null;
  }
}
