/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:pn_types/src/native/link_port.dart';

/// [LinkPort] over `app_links`.
///
/// The plugin's Windows implementation reads a cold-start link from `argv[1]` and later links
/// from `WM_COPYDATA` forwarded by `SendAppLinkToInstance` (`windows/runner/main.cpp`), and
/// exposes both through one stream — which is exactly the contract [LinkPort] asks for.
///
/// Only the URI stream is subscribed. `getInitialLink`/`getLatestLink` are one-shot reads that
/// could race a running-app link; the stream merges cold-start and in-flight deliveries, so a
/// subscriber that starts listening cannot miss a link that arrived meanwhile.
class AppLinksLink implements LinkPort {
  AppLinksLink({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream;
}
