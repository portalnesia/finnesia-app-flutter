/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:pn_types/src/native/link_port.dart';
import 'package:pos/native/link/link_app_links.dart';

/// The App Link listener, **on Windows only** — `null` everywhere else.
///
/// Android deliberately has no listener: the wake-up is already covered by
/// `AppLifecycleState.resumed` → `AppServices.onForeground()` → `LoginControl.pollNow()`, which
/// is the path that was verified on a tablet, and a second one would be a plugin kept alive for
/// nothing (see `link_port.dart`). Returning `null` is what keeps that true.
///
/// Read by `main.dart` only, and passed into `bootstrap` like every other port. It is
/// deliberately not consulted from inside `bootstrap`: that made every boot — including every
/// `flutter test` — construct the real plugin, whose `EventChannel` needs a Flutter binding and
/// fails asynchronously from inside the plugin's own `onListen`.
LinkPort? get link => Platform.isWindows ? _link : null;

final LinkPort _link = AppLinksLink();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setLink(LinkPort impl) => _override = impl;

LinkPort? _override;

/// The link a test has installed, if any. `main.dart` uses [link]; a test that wants to drive
/// the Windows behaviour from any host uses this through `setLink`.
LinkPort? get testLink => _override;
