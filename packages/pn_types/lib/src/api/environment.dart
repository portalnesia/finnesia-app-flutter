/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// The address the app talks to. Only [production] is reachable in a release build.
enum EndpointEnvironment { lokal, staging, production }

/// True in a debug build. `dart.vm.product` is true under AOT and false under JIT — the
/// same constant as Flutter's `kReleaseMode`, but readable from a package that must not
/// import `flutter`.
const bool isDebugApp = !bool.fromEnvironment('dart.vm.product');

const productionHost = 'https://apps.finnesia.com';

// Private on purpose: the only way to reach a non-production host is [canonicalHost]'s
// debug branch. `isDebugApp` is const, so in a release build that branch and this
// function are removed as dead code and the strings leave the binary. A public
// `hostFor` would invite a caller the tree-shaker cannot prove dead.
String _hostFor(EndpointEnvironment env) => switch (env) {
  EndpointEnvironment.lokal => 'http://localhost:4000',
  EndpointEnvironment.staging => 'https://apps-dev.finnesia.com',
  EndpointEnvironment.production => productionHost,
};

/// The host used BEFORE a tenant is known (pairing).
///
/// In a release build this is always [productionHost] and [choice] is ignored.
String canonicalHost(EndpointEnvironment choice) =>
    isDebugApp ? _hostFor(choice) : productionHost;

/// May the user pick an endpoint environment?
///
/// Only a debug app that is not paired yet. After pairing the host belongs to the session
/// and is never recomputed (`.claude/rules/security.md` §1.1); a release app has a single
/// endpoint. [debug] exists so the release case can be tested — under `dart test`
/// [isDebugApp] is always true.
bool canChooseEndpoint({required bool isPaired, bool debug = isDebugApp}) =>
    debug && !isPaired;
