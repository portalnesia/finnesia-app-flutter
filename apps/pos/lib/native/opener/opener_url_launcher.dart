/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:pn_types/src/native/opener_port.dart';
import 'package:url_launcher/url_launcher.dart';

/// [OpenerPort] over `url_launcher`.
///
/// The system browser, on purpose (`LaunchMode.externalApplication`): login depends on the OIDC
/// session living in the browser's cookie jar and never in the app's, so the URL has to leave
/// the app rather than open in a view of its own.
///
/// It does not call `canLaunchUrl` first. That question needs a package-visibility declaration
/// in the manifest on Android 11 and later — a permission for a question that does not need
/// asking, since the launch itself says whether it worked.
///
/// Every way this can fail is an [OpenerException]: a URL that is not one, a platform that says
/// nothing could open it, and a platform that throws. None of them carries the URL, which holds
/// a login request id.
class UrlLauncherOpener implements OpenerPort {
  @override
  Future<void> openUrl(String url) async {
    final Uri uri;
    try {
      uri = Uri.parse(url);
    } on FormatException catch (failure) {
      throw OpenerException('the address is not a valid URL', cause: failure);
    }

    final bool opened;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException catch (failure) {
      throw OpenerException('the browser could not be started', cause: failure);
    }
    if (!opened) throw OpenerException('nothing could open the address');
  }
}
