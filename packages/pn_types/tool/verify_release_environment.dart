/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:pn_types/src/api/environment.dart';

/// Verifies the release-only branch of [canonicalHost] in a real AOT executable.
///
/// The caller must compile this with `dart.vm.product=true`, just as Flutter does
/// for `--release`. This is intentionally separate from the notification-link
/// allowlist: a development web origin may be a valid link destination without
/// being a valid API endpoint for a production app.
void main() {
  if (isDebugApp) {
    stderr.writeln(
      'Release endpoint check was not compiled with dart.vm.product=true.',
    );
    exitCode = 1;
    return;
  }

  for (final choice in EndpointEnvironment.values) {
    final host = canonicalHost(choice);
    if (host != productionHost) {
      stderr.writeln(
        'Release endpoint for $choice is $host, expected $productionHost.',
      );
      exitCode = 1;
      return;
    }
  }

  stdout.writeln('AOT release endpoint verified: $productionHost');
}
