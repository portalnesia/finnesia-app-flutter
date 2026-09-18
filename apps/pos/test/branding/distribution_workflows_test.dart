/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The owner's decision (2026-09-28): the Store is a destination for PRODUCTION only.
//
//   * Android production (`release-pos.yml`) -> Play Store AND a GitHub Release asset.
//   * Android staging (`staging-pos.yml`)    -> GitHub Release asset only. No Play upload.
//   * Windows (`windows-pos.yml`)            -> GitHub Release asset only. No Partner Center.
//
// The two removals have different reasons, and both are the owner's: staging is an internal
// artifact a tester installs from a link, and the Windows upload demanded an Entra tenant + app
// registration + Manager role + four secrets for a three-click manual job that happens once per
// release.
//
// A workflow is configuration nobody compiles, so it rots silently and the failure only shows up
// on a real tag. These checks are therefore proved on input that is known to be bad before their
// verdict on the real files means anything (`.claude/rules/testing.md` §0.3).

/// The repository root, found by walking up from the working directory.
///
/// `flutter test` runs with `apps/pos` as the working directory, but resolving by content rather
/// than by a fixed `../..` keeps this from silently reading nothing if it is ever run elsewhere.
Directory repoRoot() {
  var dir = Directory.current;
  while (!Directory('${dir.path}/.github/workflows').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('no .github/workflows above ${Directory.current.path}');
    }
    dir = parent;
  }
  return dir;
}

String readWorkflow(String name) =>
    File('${repoRoot().path}/.github/workflows/$name').readAsStringSync();

/// Whether [workflow] uploads a bundle to Play, by either of the two ways it can do that.
bool uploadsToPlay(String workflow) =>
    workflow.contains('upload-google-play') ||
    workflow.contains('internalsharing');

/// Whether [workflow] uploads to Partner Center through the `msstore` CLI.
bool uploadsToPartnerCenter(String workflow) =>
    workflow.contains('msstore') ||
    workflow.contains('microsoft-store-apppublisher');

/// Whether [workflow] builds an installable APK rather than a bundle.
bool buildsAnApk(String workflow) =>
    RegExp(r'flutter build apk\b').hasMatch(workflow);

/// Whether [workflow] attaches artifacts to a GitHub Release.
bool attachesToAGitHubRelease(String workflow) =>
    workflow.contains('softprops/action-gh-release');

/// The problems with the staging workflow, where each argument is what it does.
///
/// This is the detector under test: each check below is first proved to fire on a bad workflow.
List<String> stagingWorkflowProblems({
  required bool uploadsToPlay,
  required bool buildsAnApk,
  required bool attachesToAGitHubRelease,
}) => [
  if (uploadsToPlay)
    'staging uploads to Play, so it is back on a Store track the owner removed',
  if (!buildsAnApk) 'staging does not build an APK, so a tester cannot install the artifact directly',
  if (!attachesToAGitHubRelease) 'staging attaches nothing to a GitHub Release, so there is nothing to download',
];

/// The problems with the Windows workflow, where each argument is what it does.
List<String> windowsWorkflowProblems({
  required bool uploadsToPartnerCenter,
  required bool attachesToAGitHubRelease,
}) => [
  if (uploadsToPartnerCenter) 'Windows uploads to Partner Center, which needs Entra credentials the owner is not setting up',
  if (!attachesToAGitHubRelease) 'Windows attaches nothing to a GitHub Release, so there is nothing to download',
];

/// The `on.push.tags` patterns [workflow] declares, in order.
///
/// A line scan rather than a YAML parse, for the same reason as the other readers here: the repo
/// has no YAML dependency, and the shape being read is two lines deep and fixed.
List<String> tagPatterns(String workflow) {
  final lines = workflow.split(RegExp(r'\r?\n'));
  final tagsAt = lines.indexWhere((l) => l.trimRight() == '    tags:');
  if (tagsAt == -1) throw StateError('no on.push.tags block found');

  final patterns = <String>[];
  for (var i = tagsAt + 1; i < lines.length; i++) {
    final match = RegExp(r'^\s*-\s*"(.*)"\s*$').firstMatch(lines[i]);
    if (match == null) break;
    patterns.add(match.group(1)!);
  }
  return patterns;
}

/// GitHub's branch/tag filter glob, as a Dart regex.
///
/// Translated from the documented "Filter pattern cheat sheet" so the exclusivity check below
/// means something: `*` matches zero or more characters but NOT `/`, `+` is one-or-more of the
/// preceding character, `?` is zero-or-one, and `[...]` is a character class. Everything else is
/// literal, including `.` — which is why `v[0-9]+.[0-9]+` matches `v1.2` and not `v1x2`.
RegExp githubGlob(String pattern) {
  final out = StringBuffer('^');
  for (var i = 0; i < pattern.length; i++) {
    final c = pattern[i];
    if (c == '*') {
      out.write('[^/]*');
    } else if (c == '[') {
      final close = pattern.indexOf(']', i);
      out.write(pattern.substring(i, close + 1));
      i = close;
    } else if ('+?'.contains(c)) {
      out.write(c);
    } else {
      out.write(RegExp.escape(c));
    }
  }
  return RegExp('$out\$');
}

/// Whether pushing tag [ref] runs a workflow declaring [patterns].
///
/// `!` negates, and the ORDER matters: a matching negative pattern after a positive match
/// excludes the ref, and a later positive match includes it again.
bool tagRuns(List<String> patterns, String ref) {
  var matched = false;
  for (final pattern in patterns) {
    final negated = pattern.startsWith('!');
    final glob = githubGlob(negated ? pattern.substring(1) : pattern);
    if (glob.hasMatch(ref)) matched = !negated;
  }
  return matched;
}

/// The version a `pos-v...` tag carries, with the application prefix stripped.
///
/// `pos-` names the application (this repo is a monorepo and will hold others); the version is
/// `1.2.0`. BOTH the `pos-` prefix and the `v` go away: `v` stays in the tag name by convention,
/// but must never reach a version VALUE. `pub_semver` rejects `v1.2.0` (`FormatException`), so
/// Shorebird would fail, and `msix_version` must be `1.2.0.0`, not `v1.2.0.0`.
String versionFromTag(String ref) => ref.startsWith('pos-v')
    ? ref.substring('pos-v'.length)
    : throw ArgumentError('tag "$ref" is not a POS release tag');

/// A semver with the optional `v` prefix, which `pub_semver` does NOT accept.
///
/// Used as the detector for "the `v` leaked into the version value": if this matches, the value
/// is not parseable as a semver and the build that consumes it fails.
final _semverWithV = RegExp(r'^v\d+\.\d+\.\d+');

void main() {
  group('the tag patterns', () {
    // The repo is a monorepo that will hold other applications, so tags are prefixed with the
    // application name: `pos-v1.2.0` triggers the POS workflows, and the version it carries is
    // `1.2.0` — the prefix is not part of the version.
    final release = tagPatterns(readWorkflow('release-pos.yml'));
    final patch = tagPatterns(readWorkflow('shorebird-patch.yml'));
    final staging = tagPatterns(readWorkflow('staging-pos.yml'));
    final windows = tagPatterns(readWorkflow('windows-pos.yml'));

    test('the matcher agrees with the documented examples', () {
      // `testing.md` §0.3: the exclusivity check below is only worth reading if this matcher can
      // be wrong. These are the two examples the GitHub cheat sheet states outright.
      expect(githubGlob('v[12].[0-9]+.[0-9]+').hasMatch('v1.10.1'), isTrue);
      expect(githubGlob('v[12].[0-9]+.[0-9]+').hasMatch('v2.0.0'), isTrue);
      expect(githubGlob('v[12].[0-9]+.[0-9]+').hasMatch('v3.0.0'), isFalse);
      // `.` is a literal, not a wildcard.
      expect(githubGlob('v[0-9]+.[0-9]+').hasMatch('v1x2'), isFalse);
      // `*` does not cross `/`.
      expect(githubGlob('a/*').hasMatch('a/b/c'), isFalse);
      // Negation is order-sensitive.
      expect(tagRuns(['a*', '!a-b'], 'a-b'), isFalse);
      expect(tagRuns(['a*', '!a-b', 'a-b'], 'a-b'), isTrue);
    });

    test('every workflow matches the pos- prefix', () {
      for (final patterns in [release, patch, staging, windows]) {
        expect(patterns.join(' '), contains('pos-v'));
      }
    });

    test('strips the prefix to get the version', () {
      expect(versionFromTag('pos-v1.2.0'), '1.2.0');
      expect(versionFromTag('pos-v1.2.0-5'), '1.2.0-5');
      expect(versionFromTag('pos-v1.2.0-staging.3'), '1.2.0-staging.3');
    });

    test('drops the v as well as the pos- prefix', () {
      // `pos-v1.2.0` -> `1.2.0`, NOT `v1.2.0`. The `v` is part of the tag NAME by convention and
      // must not reach a version VALUE: `pub_semver` rejects `v1.2.0` with a FormatException, so
      // `shorebird release android` would fail on it, and `msix_version` would become
      // `v1.2.0.0` and be rejected by Partner Center.
      final version = versionFromTag('pos-v1.2.0');
      expect(version, '1.2.0');
      expect(version, isNot(startsWith('v')));
      expect(_semverWithV.hasMatch(version), isFalse);

      // The detector fires on the wrong answer, so its verdict above means something.
      expect(_semverWithV.hasMatch('v1.2.0'), isTrue);
    });

    test('the msix version is four plain numbers, with no v', () {
      // `msix:create --version` accepts only `1.0.0.0` (`configuration.dart:259`), and the fourth
      // part is reserved for the Store. `v1.2.0.0` would be rejected.
      expect('${versionFromTag('pos-v1.2.0')}.0', '1.2.0.0');
    });

    test('every workflow strips pos-v from the ref, not just v', () {
      // The shell side of the same rule, and it is separate from the glob above: a workflow can
      // match the right tags and still publish the wrong version. `${GITHUB_REF_NAME#v}` leaves
      // `pos-v1.2.0` as `pos-v1.2.0`, which becomes the versionName and the build number input.
      // Measured: removing `pos-` from any one of these made every other test stay green.
      for (final name in [
        'release-pos.yml',
        'shorebird-patch.yml',
        'staging-pos.yml',
        'windows-pos.yml',
      ]) {
        final workflow = readWorkflow(name);
        expect(
          workflow,
          contains(r'${GITHUB_REF_NAME#pos-v}'),
          reason: '$name must strip the pos- prefix',
        );
        expect(
          workflow,
          isNot(contains(r'${GITHUB_REF_NAME#v}')),
          reason: '$name must not strip only the leading v',
        );
      }
    });

    test('refuses a tag that is not a POS tag', () {
      expect(() => versionFromTag('v1.2.0'), throwsArgumentError);
      expect(() => versionFromTag('web-v1.2.0'), throwsArgumentError);
    });

    test('routes each tag shape to exactly one workflow', () {
      // The four tag shapes in docs/distribution.md §4.1, plus the shapes that must trigger
      // nothing. Overlap here means one `git push --tags` starts two workflows that fight over
      // the same GitHub Release.
      final cases = <String, String?>{
        'pos-v1.2.0': 'release-pos.yml',
        'pos-v1.2.0-5': 'shorebird-patch.yml',
        'pos-v1.2.0-staging.3': 'staging-pos.yml',
        // A bare version, or another application's tag, must start nothing.
        'v1.2.0': null,
        'web-v1.2.0': null,
        // An unclassified suffix is not a POS release: better ignored than published.
        'pos-v1.2.0-rc.1': null,
      };

      cases.forEach((ref, expected) {
        final ran = <String>[
          if (tagRuns(release, ref)) 'release-pos.yml',
          if (tagRuns(patch, ref)) 'shorebird-patch.yml',
          if (tagRuns(staging, ref)) 'staging-pos.yml',
          if (tagRuns(windows, ref)) 'windows-pos.yml',
        ];

        if (expected == null) {
          expect(
            ran,
            isEmpty,
            reason: 'tag "$ref" must trigger no POS workflow',
          );
        } else {
          expect(
            ran,
            contains(expected),
            reason: 'tag "$ref" must run $expected',
          );
        }
      });
    });

    test(
      'the native release and Windows agree on which tags are plain versions',
      () {
        // They share a tag and a GitHub Release, so a tag that runs one but not the other leaves
        // the release with an APK and no MSIX (or the reverse).
        for (final ref in [
          'pos-v1.2.0',
          'pos-v1.2.0-5',
          'pos-v1.2.0-staging.3',
          'v1.2.0',
        ]) {
          expect(
            tagRuns(windows, ref),
            tagRuns(release, ref),
            reason: 'tag "$ref" must be treated the same by both workflows',
          );
        }
      },
    );
  });

  group('the staging workflow detector', () {
    // `testing.md` §0.3: a checker that has never fired is indistinguishable from a broken one.
    test('accepts a workflow that only publishes to GitHub', () {
      expect(
        stagingWorkflowProblems(
          uploadsToPlay: false,
          buildsAnApk: true,
          attachesToAGitHubRelease: true,
        ),
        isEmpty,
      );
    });

    test('names a workflow that still uploads to Play', () {
      final problems = stagingWorkflowProblems(
        uploadsToPlay: true,
        buildsAnApk: true,
        attachesToAGitHubRelease: true,
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains('Play'));
    });

    test('names a workflow whose artifact cannot be installed', () {
      final problems = stagingWorkflowProblems(
        uploadsToPlay: false,
        buildsAnApk: false,
        attachesToAGitHubRelease: true,
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains('APK'));
    });

    test('names a workflow that publishes nothing', () {
      final problems = stagingWorkflowProblems(
        uploadsToPlay: false,
        buildsAnApk: true,
        attachesToAGitHubRelease: false,
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains('GitHub Release'));
    });

    test('names every problem at once, so one fix does not hide another', () {
      expect(
        stagingWorkflowProblems(
          uploadsToPlay: true,
          buildsAnApk: false,
          attachesToAGitHubRelease: false,
        ),
        hasLength(3),
      );
    });
  });

  group('the Windows workflow detector', () {
    test('accepts a workflow that only publishes to GitHub', () {
      expect(
        windowsWorkflowProblems(
          uploadsToPartnerCenter: false,
          attachesToAGitHubRelease: true,
        ),
        isEmpty,
      );
    });

    test('names a workflow that still uploads to Partner Center', () {
      final problems = windowsWorkflowProblems(
        uploadsToPartnerCenter: true,
        attachesToAGitHubRelease: true,
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains('Partner Center'));
    });

    test('names a workflow that publishes nothing', () {
      final problems = windowsWorkflowProblems(
        uploadsToPartnerCenter: false,
        attachesToAGitHubRelease: false,
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains('GitHub Release'));
    });
  });

  group('the staging workflow', () {
    final workflow = readWorkflow('staging-pos.yml');

    test('publishes only to GitHub, with an APK a tester can install', () {
      expect(
        stagingWorkflowProblems(
          uploadsToPlay: uploadsToPlay(workflow),
          buildsAnApk: buildsAnApk(workflow),
          attachesToAGitHubRelease: attachesToAGitHubRelease(workflow),
        ),
        isEmpty,
        reason: 'owner decision 2026-09-28: staging is a GitHub artifact, not a Store release',
      );
    });

    test('builds the profile APK, not a bundle', () {
      // `--profile` is what gives staging its debug behaviour with the release appId
      // (`plan/staging/README.md` §3). A bundle cannot be installed, so it cannot be handed to a
      // tester as a download.
      expect(workflow, contains('flutter build apk --profile'));
      expect(workflow, isNot(contains('flutter build appbundle')));
    });

    test('creates a draft GitHub Release and attaches the APK to it', () {
      expect(workflow, contains('softprops/action-gh-release'));
      expect(workflow, contains('draft: true'));
      expect(workflow, contains(r'${{ steps.apk.outputs.path }}'));
    });

    test('asks for the permission a release write needs', () {
      // Without `contents: write` the release step fails with a permission error that reads like
      // a token problem.
      expect(workflow, contains('contents: write'));
    });

    test(
      'still reads the release signing key, so its identity matches production',
      () {
        // Kept deliberately: staging uses the same appId and the same key as production, which is
        // what makes a staging APK an upgrade of a production install rather than a second app.
        expect(workflow, contains('secrets.ANDROID_KEY_BASE64'));
        expect(workflow, contains('keystore.properties'));
      },
    );

    test('has no Shorebird step', () {
      // Owner decision: testers must exercise a native build, and an OTA patch can mask a native
      // bug (`plan/staging/README.md` §1).
      expect(workflow, isNot(contains('shorebird')));
    });

    test('guards the artifact: staging host present, production appId, no debug appId', () {
      // The guard runs over the ARTIFACT, not the build inputs, and it has to read the manifest
      // with `aapt2`: an APK manifest is compiled to binary XML, where the host is UTF-16, so
      // `strings` silently finds nothing and the check passes without checking anything.
      expect(workflow, contains('aapt2'));
      expect(workflow, contains('dump xmltree'));
      expect(workflow, contains(r'$STAGING_HOST'));
      expect(workflow, contains('apps-dev.finnesia.com'));
      expect(workflow, contains(r'${ANDROID_PACKAGE_NAME}.debug'));
    });
  });

  group('the Windows workflow', () {
    final workflow = readWorkflow('windows-pos.yml');

    test('publishes only to GitHub, so no Entra tenant is needed', () {
      expect(
        windowsWorkflowProblems(
          uploadsToPartnerCenter: uploadsToPartnerCenter(workflow),
          attachesToAGitHubRelease: attachesToAGitHubRelease(workflow),
        ),
        isEmpty,
        reason: 'owner decision 2026-09-28: the package is uploaded to Partner Center by hand',
      );
    });

    test('names no Entra secret and no Store product id', () {
      // Each of these was a setup step that blocked the pipeline. Leaving one behind means the
      // workflow still cannot run for someone who has not done the Entra setup.
      expect(workflow, isNot(contains('AZURE_AD_TENANT_ID')));
      expect(workflow, isNot(contains('AZURE_AD_APPLICATION_CLIENT_ID')));
      expect(workflow, isNot(contains('AZURE_AD_APPLICATION_SECRET')));
      expect(workflow, isNot(contains('SELLER_ID')));
      expect(workflow, isNot(contains('MSSTORE_PRODUCT_ID')));
    });

    test('creates a draft GitHub Release and attaches the MSIX to it', () {
      expect(workflow, contains('softprops/action-gh-release'));
      expect(workflow, contains('draft: true'));
      expect(workflow, contains(r'${{ steps.msix.outputs.path }}'));
    });

    test('does not overwrite the release title that release-pos.yml sets', () {
      // Both workflows write ONE release for the same tag. The action resolves the title as
      // `input_name || existingRelease.name || tag`, so leaving `name:` out preserves
      // "Finnesia POS vX.Y.Z" instead of flipping it to "... Windows ..." whenever this job
      // finishes last — even though the release also carries the Android APK.
      expect(
        RegExp(
          r'^\s+name:.*Finnesia POS Windows',
          multiLine: true,
        ).hasMatch(workflow),
        isFalse,
      );

      // And the workflow that owns the title really does set it.
      expect(readWorkflow('release-pos.yml'), contains('Finnesia POS v'));
    });

    test('asks for the permission a release write needs', () {
      expect(workflow, contains('contents: write'));
    });

    test(
      'still packages with the Store identity, because the upload is manual',
      () {
        // `--store` keeps `publisher` from `pubspec.yaml` and skips signing; the Store re-signs at
        // certification. The package the owner uploads by hand must still be this one.
        expect(workflow, contains('msix:create'));
        expect(workflow, contains('--store'));

        expect(workflow, contains('PutuAditya.FinnesiaPOS'));
        expect(workflow, contains('CN=FD977251-3866-4FF0-ABD2-D71AAABF5137'));
      },
    );
  });

  group('the production Android workflow', () {
    final workflow = readWorkflow('release-pos.yml');

    test('keeps BOTH destinations: Play Store and a GitHub Release asset', () {
      // The owner's correction (2026-09-28): "production itu keduanya. upload ke play store dan
      // ke assets github juga". This is the one workflow the change must NOT touch.
      expect(uploadsToPlay(workflow), isTrue);
      expect(attachesToAGitHubRelease(workflow), isTrue);
    });

    test(
      'still attaches the release APK, and still marks the release a draft',
      () {
        expect(workflow, contains('draft: true'));
        expect(workflow, contains(r'${{ steps.apk.outputs.path }}'));
      },
    );

    test('still uploads the bundle to the internal track', () {
      expect(workflow, contains('track: internal'));
    });
  });
}
