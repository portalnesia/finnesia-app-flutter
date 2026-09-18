/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/widgets.dart';

/// Why the camera view could not show anything.
enum ScannerFailure {
  /// The cashier said no to the camera, or has switched it off for this app in Settings.
  permissionDenied,

  /// Anything else: no camera on this tablet, one another app is holding, a platform error.
  unavailable,
}

/// Reads QR codes with the tablet's camera.
///
/// A port because the real one is a platform plugin, which does not exist under `flutter test`
/// (`.claude/rules/native-ports.md` §1). It is a view rather than a `Future<String>` because a
/// camera preview is a widget: the screen decides where it sits, and closing it is what turns
/// the camera off.
///
/// Lives in `apps/pos` and not in `pn_types` because it names a Flutter type, and `pn_types` is
/// pure Dart.
abstract interface class ScannerPort {
  /// Whether this platform has a camera scanner at all. Where it does not, the button that would
  /// open it is not shown: a control that leads nowhere is worse than none.
  bool get isAvailable;

  /// A live camera view. [onCode] gets the text of each QR code the camera reads, possibly the
  /// same one many times over: the caller decides what a code means and when to stop looking.
  ///
  /// [failureBuilder] is what the view shows instead of the camera when it cannot have one. The
  /// words are the caller's, because they are the caller's language.
  Widget buildView({
    required void Function(String code) onCode,
    required Widget Function(BuildContext context, ScannerFailure failure)
    failureBuilder,
  });
}
