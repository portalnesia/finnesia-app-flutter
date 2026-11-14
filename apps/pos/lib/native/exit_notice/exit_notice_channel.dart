/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:pn_types/src/native/exit_notice_port.dart';

/// [ExitNoticePort] over the app's own `pos/exit_notice` channel.
///
/// Answered by `MainActivity.kt` on Android (which keeps `ShiftReminderService` running while
/// there is something to say, so a swipe from Recents can still post it) and by
/// `windows_exit_notice.cpp` on Windows (which gives it to Windows as the reason on its
/// shutdown/sign-out screen). Other platforms have no handler and nothing to say it at.
class ChannelExitNotice implements ExitNoticePort {
  /// Named here so a test can stand in for the platform.
  static const channel = MethodChannel('pos/exit_notice');

  @override
  Future<void> setNotice(ExitNotice? notice) async {
    try {
      if (notice == null) {
        await channel.invokeMethod<void>('clear');
      } else {
        await channel.invokeMethod<void>('set', {
          'title': notice.title,
          'body': notice.body,
        });
      }
    } on MissingPluginException {
      // No handler on this platform: no exit here that the notice could be shown at.
    } on PlatformException catch (failure) {
      throw ExitNoticeException(
        'the platform could not be told',
        cause: failure,
      );
    }
  }
}
