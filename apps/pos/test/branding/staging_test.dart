/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The staging build type is `profile` — Flutter's own, created by `FlutterPlugin.kt` with
// `initWith(debugBuildType)`. Nothing in Dart can see it: it is Gradle configuration and Android
// resources, compiled at build time. That is the shape that rots silently — someone "tidies"
// `build.gradle.kts`, the signing config reverts to debug, and nobody notices until a tester's
// tablet refuses to install the next upload.
//
// So what is pinned here is the contract between four things that live in four places:
//
//   * `build.gradle.kts` — which signing config `profile` gets,
//   * `android/app/src/profile/` — the App Link host and the cleartext exception,
//   * `android/app/src/main/res/values/strings.xml` — the label a person reads,
//   * and `plan/staging/README.md` — the reasons.
//
// The checks are proved on input that is known to be bad before their verdict on the real files
// means anything (`.claude/rules/testing.md` §0.3). `stagingPlanProblems` is the probe: it is
// handed a plan with each thing wrong, and it has to name every one.

/// The staging host. A release build must never name it (`app_link_test.dart`), and the profile
/// build must.
const _stagingHost = 'apps-dev.finnesia.com';

/// The production host. It lives in the MAIN manifest, which every build type merges — which is
/// what gives a non-release build both hosts.
const _productionHost = 'apps.finnesia.com';

/// The label the staging build shows in the launcher, so a tester can tell it apart from
/// production on the same tablet. Owner's wording (2026-09-23).
const _stagingLabel = 'Finnesia POS (tester)';

/// The problems with a staging plan, where each argument is what the plan says.
///
/// This is the detector under test: every check below is first proved to fire on a bad plan, so
/// the verdict on the real files means something. Empty means the plan is coherent.
List<String> stagingPlanProblems({
  required bool profileUsesReleaseSigning,
  required bool profileManifestClaimsStagingHost,
  required bool profileAllowsLocalCleartext,
  required String launcherLabel,
}) {
  return [
    if (!profileUsesReleaseSigning) 'the profile build is signed with the debug key, so its identity differs from release',
    if (!profileManifestClaimsStagingHost)
      'the profile manifest does not claim $_stagingHost, so the App Link is dead there',
    if (!profileAllowsLocalCleartext)
      'the profile build cannot reach the `lokal` endpoint over cleartext HTTP',
    if (launcherLabel != _stagingLabel)
      'the launcher label is "$launcherLabel", so a tester cannot tell it from production',
  ];
}

/// The body of `named("<name>") { ... }` in [gradle], or `null` when it is absent.
///
/// Brace-matched rather than regexed: the line that matters is a one-liner inside a nested block,
/// and a pattern loose enough to span the nesting is also loose enough to read the `release`
/// block as the `profile` one. No string literal in these blocks contains a brace.
///
/// `create("<name>")` is deliberately NOT matched. The Flutter Gradle plugin creates the `profile`
/// build type while the plugin is applied — which runs before this script's body — so a `create`
/// here throws "already exists" and fails the build. Requiring `named` keeps that loud.
String? namedBlock(String gradle, String name) {
  final start = gradle.indexOf('named("$name")');
  if (start == -1) return null;

  final open = gradle.indexOf('{', start);
  if (open == -1) return null;

  var depth = 0;
  for (var i = open; i < gradle.length; i++) {
    if (gradle[i] == '{') {
      depth++;
    } else if (gradle[i] == '}') {
      depth--;
      if (depth == 0) return gradle.substring(open, i + 1);
    }
  }
  return null;
}

/// [xml] with its `<!-- ... -->` comments removed.
///
/// Load-bearing for a text-based check on a file that also carries prose. The first version of
/// the `base-config` check searched the raw file and fired on the *comment* explaining why a
/// `<base-config>` must not be added — a detector that could not tell a rule from a violation.
/// The same trap sits in every host check below: these manifests explain which hosts they name,
/// so a raw search would read the explanation as a declaration.
String withoutComments(String xml) =>
    xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

/// The `android:host` values [xml] declares, ignoring anything inside a comment.
Set<String> hostsIn(String xml) =>
    RegExp(r'android:host="([^"]+)"')
        .allMatches(withoutComments(xml))
        .map((m) => m.group(1)!)
        .toSet();

/// The hosts a build actually ends up with: the main manifest's, plus its build type's.
///
/// Manifest merging ADDS intent filters rather than replacing them (`src/profile` uses no
/// `tools:replace`, deliberately), so this is what Android sees in the built artifact. Measured,
/// not assumed — `processProfileMainManifest` then reading the merged file gives:
///   profile → apps.finnesia.com + apps-dev.finnesia.com, package com.finnesia.pos
///   release → apps.finnesia.com only,                  package com.finnesia.pos
///   debug   → both,                                    package com.finnesia.pos.debug
Set<String> mergedHosts({required String main, required String buildType}) => {
  ...hostsIn(main),
  ...hostsIn(buildType),
};

/// Whether `build.gradle.kts` gives the `profile` build type the release signing config.
///
/// Read as text, not evaluated: a Gradle build is not runnable from a Dart test. The check is
/// that the wiring is *present* — a `named("profile")` block inside `buildTypes` that sets
/// `signingConfig` from the `release` config. Whether Gradle then does the right thing was
/// measured separately, with an init script (`plan/staging/README.md` §3.1).
bool profileUsesReleaseSigning(String gradle) {
  final block = namedBlock(gradle, 'profile');
  if (block == null) return false;

  return RegExp(
    r'signingConfig\s*=\s*signingConfigs\s*\.\s*getByName\s*\(\s*"release"\s*\)',
  ).hasMatch(block);
}

void main() {
  group('the staging plan detector', () {
    // `testing.md` §0.3: a checker that has never fired is indistinguishable from a broken one.
    // Each probe below is a real way this plan goes wrong, and the detector must name it.
    test('accepts a coherent plan', () {
      expect(
        stagingPlanProblems(
          profileUsesReleaseSigning: true,
          profileManifestClaimsStagingHost: true,
          profileAllowsLocalCleartext: true,
          launcherLabel: _stagingLabel,
        ),
        isEmpty,
      );
    });

    test('names a profile build signed with the debug key', () {
      final problems = stagingPlanProblems(
        profileUsesReleaseSigning: false,
        profileManifestClaimsStagingHost: true,
        profileAllowsLocalCleartext: true,
        launcherLabel: _stagingLabel,
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains('debug key'));
    });

    test('names a manifest that does not claim the staging host', () {
      final problems = stagingPlanProblems(
        profileUsesReleaseSigning: true,
        profileManifestClaimsStagingHost: false,
        profileAllowsLocalCleartext: true,
        launcherLabel: _stagingLabel,
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains(_stagingHost));
    });

    test('names a build that cannot reach the local endpoint', () {
      final problems = stagingPlanProblems(
        profileUsesReleaseSigning: true,
        profileManifestClaimsStagingHost: true,
        profileAllowsLocalCleartext: false,
        launcherLabel: _stagingLabel,
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains('cleartext'));
    });

    test('names a label a tester cannot tell from production', () {
      final problems = stagingPlanProblems(
        profileUsesReleaseSigning: true,
        profileManifestClaimsStagingHost: true,
        profileAllowsLocalCleartext: true,
        launcherLabel: 'Finnesia POS',
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains('production'));
    });

    test('names every problem at once, so one fix does not hide another', () {
      expect(
        stagingPlanProblems(
          profileUsesReleaseSigning: false,
          profileManifestClaimsStagingHost: false,
          profileAllowsLocalCleartext: false,
          launcherLabel: 'Finnesia POS',
        ),
        hasLength(4),
      );
    });
  });

  group('the signing-config reader', () {
    test('finds the wiring when it is there', () {
      expect(
        profileUsesReleaseSigning('''
buildTypes {
    named("profile") {
        signingConfig = signingConfigs.getByName("release")
    }
}
'''),
        isTrue,
      );
    });

    test('does not fire on an empty file or an unrelated block', () {
      expect(profileUsesReleaseSigning(''), isFalse);
      expect(
        profileUsesReleaseSigning('''
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
'''),
        isFalse,
      );
    });

    test('needs the profile block, not the release one', () {
      // The `release` block above already sets this. What must not be missed is that PROFILE
      // gets it — a reader that just looked for any `getByName("release")` would pass while
      // staging shipped debug-signed.
      expect(
        profileUsesReleaseSigning('''
buildTypes {
    named("profile") {
        signingConfig = signingConfigs.getByName("debug")
    }
}
'''),
        isFalse,
      );
    });

    test('does not accept create(), which would throw at configure time', () {
      // The build type already exists by the time this script runs (the Flutter plugin creates
      // it during `plugins {}`), so `create` fails the build. This keeps that mistake loud here
      // rather than at Gradle configure time.
      expect(
        profileUsesReleaseSigning('''
buildTypes {
    create("profile") {
        signingConfig = signingConfigs.getByName("release")
    }
}
'''),
        isFalse,
      );
    });

    test('stops at the block\'s own closing brace, not the file\'s', () {
      expect(
        namedBlock('''
buildTypes {
    named("profile") {
        signingConfig = signingConfigs.getByName("release")
    }
    named("other") {
        unrelated()
    }
}
''', 'profile'),
        isNot(contains('unrelated')),
      );
    });
  });

  group('the comment stripper', () {
    test('removes comments and keeps elements', () {
      expect(
        withoutComments('<!-- Do NOT add a <base-config>: ... -->\n<a/>'),
        '\n<a/>',
      );
    });

    test('does not remove an element that is really there', () {
      // The probe that matters: the check below must still fire on a file that genuinely has a
      // `<base-config>`. A stripper that removed everything would pass the suite for the wrong
      // reason.
      expect(
        withoutComments(
          '<network-security-config><base-config/></network-security-config>',
        ),
        contains('<base-config'),
      );
    });
  });

  group('the profile build', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    test('is signed with the release key, not the debug one', () {
      // A different signing identity from the one already in use means the next upload cannot be
      // installed as an upgrade, and a locally built staging AAB would differ from CI's.
      expect(
        profileUsesReleaseSigning(gradle),
        isTrue,
        reason:
            'the profile build type must be pointed at signingConfigs.release; '
            'see plan/staging/README.md §3.1',
      );
    });

    test('does not add a build type or a flavor of its own', () {
      // `FlutterPluginUtils.buildModeFor` derives the Flutter build mode from the build type
      // name, so a custom type that is not debuggable silently becomes a RELEASE build. And a
      // flavor would make `flutter build` refuse to run without `--flavor`
      // (`gradle_errors.dart:277`). `profile` is Flutter's own and avoids both.
      expect(gradle, isNot(contains('productFlavors')));
      expect(gradle, isNot(contains('applicationIdSuffix = ".staging"')));
    });

    test('leaves the debug build type alone', () {
      // `flutter run` day to day depends on `.debug` being a separate app with its own data.
      expect(gradle, contains('applicationIdSuffix = ".debug"'));
    });
  });

  group('the profile manifest', () {
    final manifest = File('android/app/src/profile/AndroidManifest.xml')
        .readAsStringSync();

    test('claims the staging host, verified, at the return path', () {
      // Without this the "Kembali ke aplikasi" button on the done page stays in the browser:
      // `src/debug/` is not read by a profile build.
      expect(manifest, contains('android:autoVerify="true"'));
      expect(manifest, contains('android:host="$_stagingHost"'));
      expect(manifest, contains('/api/auth/mobile/return'));
    });

    test('allows cleartext only for the two names a local backend has', () {
      // The owner asked for the endpoint picker to come along, and `lokal` is
      // http://localhost:4000. Android refuses cleartext by default, and the exception that
      // exists in `src/debug/` is not read here.
      expect(
        manifest,
        contains(
          'android:networkSecurityConfig="@xml/network_security_config"',
        ),
      );

      final config = withoutComments(
        File('android/app/src/profile/res/xml/network_security_config.xml')
            .readAsStringSync(),
      );

      expect(config, contains('cleartextTrafficPermitted="true"'));
      expect(config, contains('>localhost<'));
      expect(config, contains('>10.0.2.2<'));
      // Nothing else. A blanket `cleartextTrafficPermitted="true"` on `<base-config>` would let
      // every host be plain HTTP, including the ones that must never be. Checked over the file
      // with its comments stripped, so the comment explaining this cannot trip it.
      expect(config, isNot(contains('<base-config')));
    });

    test('together with the main manifest, gives this build TWO hosts', () {
      // The owner's requirement (2026-09-23): "non release, dapat 2 host".
      //
      // It is not extra configuration — it falls out of where each host is declared. Production
      // is declared in `src/main/`, which every build type merges; staging is declared here, in
      // the profile source set. A profile build therefore answers both, and a release build
      // answers only production because it never reads this source set.
      //
      // Measured on the built debug APK with `aapt2 dump xmltree` rather than assumed:
      //   android:host="apps.finnesia.com"
      //   android:host="apps-dev.finnesia.com"
      final main = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      final hosts = mergedHosts(main: main, buildType: manifest);

      expect(hosts, containsAll([_productionHost, _stagingHost]));
      expect(hosts, hasLength(2));
    });

    test('declares the staging host itself, so it does not depend on the debug set', () {
      // The failure this closes: someone "deduplicates" by deleting the filter here, reasoning
      // that `src/debug/` already has one. A profile build does not read `src/debug/`, so the
      // filter would simply be gone and the App Link would die silently on tester tablets.
      expect(hostsIn(manifest), contains(_stagingHost));
      expect(hostsIn(manifest), isNot(contains(_productionHost)));
    });
  });

  group('the launcher label', () {
    test('says tester, so it can be told apart from production', () {
      final strings = File('android/app/src/profile/res/values/strings.xml')
          .readAsStringSync();

      expect(
        strings,
        contains('<string name="app_name">$_stagingLabel</string>'),
      );
    });

    test('is NOT the label production uses', () {
      // The failure this prevents: a tester installs staging next to production, both read
      // "Finnesia POS", and neither can be identified in the launcher or in app settings.
      final main = File('android/app/src/main/res/values/strings.xml')
          .readAsStringSync();

      expect(main, contains('<string name="app_name">Finnesia POS</string>'));
      expect(main, isNot(contains(_stagingLabel)));
    });

    test('is distinct from the debug label too', () {
      final debug = File('android/app/src/debug/res/values/strings.xml')
          .readAsStringSync();

      expect(debug, contains('Finnesia POS (debug)'));
      expect(debug, isNot(contains(_stagingLabel)));
    });
  });

  group('the whole plan', () {
    test('is coherent over the real files', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      final manifest = File('android/app/src/profile/AndroidManifest.xml')
          .readAsStringSync();
      final strings = File('android/app/src/profile/res/values/strings.xml')
          .readAsStringSync();

      expect(
        stagingPlanProblems(
          profileUsesReleaseSigning: profileUsesReleaseSigning(gradle),
          profileManifestClaimsStagingHost: manifest.contains(
            'android:host="$_stagingHost"',
          ),
          profileAllowsLocalCleartext: File(
            'android/app/src/profile/res/xml/network_security_config.xml',
          ).existsSync(),
          launcherLabel:
              RegExp(r'<string name="app_name">([^<]+)</string>')
                  .firstMatch(strings)
                  ?.group(1) ??
              '',
        ),
        isEmpty,
      );
    });
  });
}
