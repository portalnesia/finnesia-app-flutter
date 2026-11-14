/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pn_types/src/native/app_exit_port.dart';

/// [AppExitPort] over the framework's own exits.
///
/// Android: `SystemNavigator.pop`, which is what the back press at the root does when nothing
/// holds it. Everywhere else: `exitApplication(AppExitType.required)`, which closes without
/// asking the app again (asking would loop straight back into the open-shift reminder that just
/// got its answer).
class SystemAppExit implements AppExitPort {
  @override
  Future<void> exit() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await SystemNavigator.pop();
        return;
      }
      await ServicesBinding.instance.exitApplication(AppExitType.required);
    } on PlatformException catch (failure) {
      throw AppExitException(
        'the platform did not leave the app',
        cause: failure,
      );
    }
  }
}
