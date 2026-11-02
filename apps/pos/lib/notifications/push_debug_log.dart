/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';

/// Emits safe push diagnostics only in debug builds.
void logPushDebug(String message) {
  if (!kDebugMode) return;
  debugPrint('[Push] $message');
}
