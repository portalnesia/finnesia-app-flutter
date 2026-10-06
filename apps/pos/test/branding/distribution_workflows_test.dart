/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Where each build's artifacts go. The owner's decisions, and when each one was taken:
//
//   2026-09-28  Android production -> Play Store AND a GitHub Release asset.
//               Android staging    -> GitHub Release asset only. No Play upload.
//               Windows            -> GitHub Release asset only. No Partner Center.
//   2026-10-05  REVERSED the Play half of the production line. `release-pos.yml` now builds and
//               attaches only; the single road to Play is `publish-to-store.yml`, which starts when
//               a human presses Publish on the release page. The two removals have different
//               reasons, and both are the owner's: staging is an internal artifact a tester installs
//               from a link, and the Windows upload demanded an Entra tenant + app registration +
//               Manager role + four secrets for a three-click manual job that happens once per
//               release.
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

/// The keys declared under `on.<parentKey>.<section>`, in order.
///
/// A line scan for the same reason as [tagPatterns]: no YAML dependency in this repo, and the shape
/// is fixed. `parentKey` is `workflow_dispatch` for the manual door and `workflow_call` for a
/// reusable workflow; `section` is `inputs` or `secrets`. Keys under the other section belong to it,
/// not to this one, so they are skipped.
List<String> childKeys(String workflow, String parentKey, String section) {
  final lines = workflow.split(RegExp(r'\r?\n'));
  final at = lines.indexWhere((l) => l.trimRight() == '  $parentKey:');
  if (at == -1) return const [];

  final keys = <String>[];
  var inside = false;
  for (var i = at + 1; i < lines.length; i++) {
    final line = lines[i];
    // Anything less indented than the block closes it (`on:` has nothing after it).
    if (line.trim().isNotEmpty && !line.startsWith('    ')) break;
    if (line.trimRight() == '    $section:') {
      inside = true;
      continue;
    }
    if (RegExp(r'^    \w+:').hasMatch(line)) {
      inside = false;
      continue;
    }
    final match = RegExp(r'^      (\w+):').firstMatch(line);
    if (match != null && inside) keys.add(match.group(1)!);
  }
  return keys;
}

/// The lines of the job named [jobName], from its own key to the next job's.
///
/// Job-level keys sit two spaces in, and a `uses:`/`with:`/`secrets:` block sits six, so this is a
/// line scan for the same reason as [tagPatterns].
List<String> jobBlock(String workflow, String jobName) {
  final lines = workflow.split(RegExp(r'\r?\n'));
  final starts = <int>[
    for (var i = 0; i < lines.length; i++)
      if (RegExp(r'^  [\w-]+:\s*$').hasMatch(lines[i])) i,
  ];
  final at = starts.indexWhere((i) => lines[i].trimRight() == '  $jobName:');
  if (at == -1) return const [];
  final end = at + 1 < starts.length ? starts[at + 1] : lines.length;
  return lines.sublist(starts[at], end);
}

/// Every reusable `uses:` call in [workflow], with the block that configures it.
///
/// Paired with its callee so a test can ask "does THIS call pass its secrets" instead of "does the
/// file mention `secrets.X` somewhere", which would pass on a secret passed to the wrong workflow.
List<({String callee, String block})> reusableCalls(String workflow) {
  final lines = workflow.split(RegExp(r'\r?\n'));
  final calls = <({String callee, String block})>[];
  for (var i = 0; i < lines.length; i++) {
    final callee = RegExp(r'uses: \./\.github/workflows/([\w.-]+)')
        .firstMatch(lines[i])
        ?.group(1);
    if (callee == null) continue;
    final block = <String>[];
    for (var j = i + 1; j < lines.length; j++) {
      // `with:`/`secrets:` sit four spaces in, the next job's key two, so anything less indented
      // than four ends this call.
      if (lines[j].trim().isNotEmpty && !lines[j].startsWith('    ')) break;
      block.add(lines[j]);
    }
    calls.add((callee: callee, block: block.join('\n')));
  }
  return calls;
}

/// The `if:` expression on the `play` job, or null when the job has none.
///
/// Read as text rather than evaluated, because what matters is that the filter SAYS the two rules:
/// a tag starting with `pos-v`, and a tag carrying no suffix. Parsing them out also keeps this
/// test from silently passing if the expression is rewritten into something narrower.
/// The six workflow files, in one place.
///
/// Any check that claims to cover "every workflow" reads this list, so a file added later cannot be
/// missed by being absent from a scan.
const _workflowFiles = [
  'publish-to-store.yml',
  'release-dispatch.yml',
  'release-pos.yml',
  'shorebird-patch.yml',
  'staging-pos.yml',
  'windows-pos.yml',
];

/// The scalars a YAML 1.1 parser resolves to a boolean, so an unquoted one arrives as a boolean and
/// not as the word that was written.
///
/// Lowercased before comparison, because the resolution is case-insensitive: `NO`, `No` and `no` are
/// all false. `y`/`n` are here too, for the same reason, and not only the `on`/`off` family that
/// made the bug famous.
const _yaml11Booleans = {'y', 'n', 'yes', 'no', 'on', 'off', 'true', 'false'};

/// Every `options:` entry of [workflow] that is unquoted and YAML 1.1 would read as a boolean.
///
/// A line scan rather than a YAML parse, for the same reason as [tagPatterns]: the repo has no YAML
/// dependency and the shape is one fixed line. The line IS the bug, so scanning the line is
/// correct, not a shortcut: nothing downstream of the parser can see what the file said.
///
/// A quoted entry is skipped whatever it says, because the quotes are the fix and
/// `options: ["no", "yes"]` is the string `no`, not the boolean false.
List<String> unquotedBooleanOptions(String workflow) {
  final findings = <String>[];
  for (final line in workflow.split(RegExp(r'\r?\n'))) {
    final list = RegExp(r'^\s*options:\s*\[(.*)\]\s*$').firstMatch(line);
    if (list == null) continue;

    for (final raw in list.group(1)!.split(',')) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      if (value.startsWith('"') || value.startsWith("'")) continue;
      if (_yaml11Booleans.contains(value.toLowerCase())) findings.add(value);
    }
  }
  return findings;
}

String? publishGate(String workflow) {
  final lines = workflow.split(RegExp(r'\r?\n'));
  final at = lines.indexWhere((l) => l.trimRight() == '  play:');
  if (at == -1) return null;
  for (var i = at + 1; i < lines.length; i++) {
    final match = RegExp(r'^    if:\s*(.+?)\s*$').firstMatch(lines[i]);
    if (match != null) return match.group(1);
  }
  return null;
}

/// Whether the job-level `if:` admits a tag carrying [prefix], or null when it states none.
///
/// Job-level filtering can only answer "is this OUR tag". `null` stays distinct from `false` so a
/// gate that vanished reads as unknown rather than as a gate that admits nothing.
bool? publishGateAllows(String gate, String tag) {
  final prefix = RegExp(
    r"startsWith\(github\.event\.release\.tag_name,\s*'([^']*)'\)",
  ).firstMatch(gate)?.group(1);
  if (prefix == null) return null;
  return tag.startsWith(prefix);
}

/// Whether [tag] is a plain production tag under the shell gate written in [workflow].
///
/// `null` when the workflow states no gate at all, kept distinct from `false` on purpose: a gate
/// that went missing must read as "unknown", never as "allowed".
bool? plainTagAccepted(String workflow, String tag) {
  final pattern = plainTagRegex(workflow);
  if (pattern == null) return null;
  final regex = RegExp(pattern);
  return regex.hasMatch(tag);
}

/// The tag-shape regex the shell gate tests against, or null when there is no such gate.
///
/// The prefix rule IS expressible in a job-level `if:`, but "this tag carries no suffix" is not:
/// GitHub's expression language has no substring removal, no split and no regex, so the shape has
/// to be decided in a shell step where `=~` exists.
String? plainTagRegex(String workflow) {
  final match = RegExp(r'''if \[\[\s*"\$TAG"\s*=~\s*(\S+)\s*\]\]''')
      .firstMatch(workflow);
  return match?.group(1);
}

/// Every expression in [workflow]: each `${{ ... }}` plus every bare `if:` value.
///
/// `if:` accepts a bare expression as well as an interpolated one, and that is how `publish-to-store`
/// spelled its filter, so a scanner that only read `${{ }}` would have missed the very bug it was
/// written for.
List<String> expressions(String workflow) {
  final found = <String>[
    for (final m in RegExp(r'\$\{\{(.*?)\}\}').allMatches(workflow))
      m.group(1)!,
  ];
  for (final line in workflow.split(RegExp(r'\r?\n'))) {
    final bare = RegExp(r'^\s*(?:-\s*)?if:\s*(.+?)\s*$').firstMatch(line);
    if (bare != null) found.add(bare.group(1)!);
  }
  return found;
}

/// The function names called inside [expression], in order.
///
/// Only `name(` counts, so a context property (`steps.version.outputs.base`) and a string literal are
/// not mistaken for a call.
List<String> calledFunctions(String expression) => [
  for (final m in RegExp(
    r'([A-Za-z_][A-Za-z0-9_]*)\s*\(',
  ).allMatches(expression))
    m.group(1)!,
];

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

    test('does not upload to Play anymore: the bundle waits for a human to publish', () {
      // SUPERSEDED, with the reversal on the record. The correction of 2026-09-28 — "production itu
      // keduanya. upload ke play store dan ke assets github juga" — was true and was implemented
      // here: this workflow uploaded to Play and attached the APK in the same run. The owner
      // reversed the Play half on 2026-10-05. Attaching stays; uploading moved out, because a
      // build run is not a decision to publish. `the publish-to-store workflow` below is what
      // locks the new split, so this test asserts the split from the build side.
      expect(uploadsToPlay(workflow), isFalse);
      expect(attachesToAGitHubRelease(workflow), isTrue);
    });

    test(
      'still attaches the release APK, and still marks the release a draft',
      () {
        expect(workflow, contains('draft: true'));
        expect(workflow, contains(r'${{ steps.apk.outputs.path }}'));
      },
    );

    test('attaches the bundle beside the APK, in that one draft', () {
      // The AAB is the record of what was actually sent to Play, stored next to the APK. Two files
      // in ONE release step: a second step would be a second draft, and a draft nobody can publish.
      expect(workflow, contains(r'${{ steps.aab.outputs.path }}'));
      expect(
        RegExp('softprops/action-gh-release').allMatches(workflow),
        hasLength(1),
        reason: 'exactly one release step, so APK and bundle cannot land in different drafts',
      );
    });

    test('no longer names a Play track: the upload moved out of the build', () {
      // `track: internal` left with the upload step itself. A leftover here would mean two
      // destinations again, and only one of them would be behind a human.
      expect(workflow, isNot(contains('track: internal')));
      expect(workflow, isNot(contains('PLAY_SERVICE_ACCOUNT_JSON')));
    });
  });

  group('the dispatcher', () {
    final workflow = readWorkflow('release-dispatch.yml');
    final calls = reusableCalls(workflow);

    test(
      'is a second door, and the tag doors stay exactly where they were',
      () {
        expect(childKeys(workflow, 'workflow_dispatch', 'inputs'), [
          'aplikasi',
          'env',
          'device',
          'draft_release',
          'version',
        ]);
        // The owner decision that one `git push --tags` starts exactly one workflow is guarded by the
        // routing test above. The dispatcher ADDS a door; it must not edit a pattern to make room.
        for (final name in const [
          'release-pos.yml',
          'staging-pos.yml',
          'windows-pos.yml',
          'shorebird-patch.yml',
        ]) {
          expect(childKeys(readWorkflow(name), 'workflow_call', 'inputs'), [
            'version',
            'draft_release',
          ], reason: '$name must stay callable as a reusable workflow');
        }
      },
    );

    test('validates with the tested Dart gate before any build starts', () {
      // The refusal table lives in Dart (`tools/dev/lib/dispatch.dart`) because YAML `if:` chains
      // cannot be tested in this repo. What the YAML must do is CALL it and let a non-zero exit
      // stop everything: `bin/dev.dart` prints `::error::` and exits 64, so there is no output to
      // read and nothing to keep in sync here.
      expect(
        workflow,
        contains('dart run tools/dev/bin/dev.dart dispatch --env'),
      );
      expect(workflow, contains(r'--device "${{ inputs.device }}"'));
      expect(workflow, contains(r'--draft "${{ inputs.draft_release }}"'));
      expect(workflow, contains(r'--version "${{ inputs.version }}"'));
    });

    test('every reusable call waits for the validation job', () {
      for (final name in const [
        'staging-android',
        'production-android',
        'production-windows',
        'patch-android',
      ]) {
        final block = jobBlock(workflow, name).join('\n');
        expect(
          block,
          contains('needs: [validate, tag]'),
          reason:
              '$name must not start a build before the combination is accepted',
        );
        expect(
          block,
          contains('uses: ./.github/workflows/'),
          reason:
              '$name must call the existing workflow, not re-implement its build',
        );
      }
    });

    test('names the secrets of each callee explicitly, never inherit', () {
      const signing = [
        'ANDROID_KEY_BASE64',
        'ANDROID_KEY_ALIAS',
        'ANDROID_KEY_PASSWORD',
      ];
      final expected = <String, List<String>>{
        'staging-pos.yml': signing,
        'release-pos.yml': [...signing, 'SHOREBIRD_TOKEN'],
        'shorebird-patch.yml': [...signing, 'SHOREBIRD_TOKEN'],
        // Zero. `windows-pos.yml` needs no secret, so it must receive none.
        'windows-pos.yml': const [],
      };
      expect(calls.map((c) => c.callee).toSet(), expected.keys.toSet());

      for (final call in calls) {
        final needed = expected[call.callee]!;
        if (needed.isEmpty) {
          expect(
            call.block,
            isNot(contains('secrets:')),
            reason:
                '${call.callee} needs NO secret; anything here widens its exposure',
          );
          continue;
        }
        expect(
          call.block,
          contains('secrets:'),
          reason:
              '${call.callee} must pass its secrets explicitly, not inherit every one',
        );
        for (final secret in needed) {
          expect(
            call.block,
            contains('$secret: \${{ secrets.$secret }}'),
            reason: '${call.callee} must receive $secret',
          );
        }
      }
    });

    test('creates the release tag itself, from the dispatched commit', () {
      // `softprops/action-gh-release` creates a missing tag from the DEFAULT BRANCH, which may not
      // be the commit that was dispatched. The tag is made explicitly from this run's SHA so the
      // release cannot drift onto another commit.
      expect(workflow, contains(r'pos-v${{ inputs.version }}'));
      expect(workflow, contains('createRef'));
      expect(workflow, contains('context.sha'));
      expect(workflow, contains("if: inputs.draft_release == 'yes'"));
    });
  });

  group('the YAML 1.1 boolean options', () {
    // The whole finding is one line of `release-dispatch.yml`, written as `options: [no, yes]`.
    // YAML 1.1 resolves `no` to false and `yes` to true, so GitHub's parser never saw the words:
    // the UI offered `false`/`true`, the dispatch sent `--draft "true"`, and the Dart gate refused it
    // with exit 64. Every test in this file read the TEXT and saw `no, yes`, so all of them passed.
    // That is the class of gap this group closes.
    test('names an unquoted boolean, in any case', () {
      expect(unquotedBooleanOptions('        options: [no, yes]'), [
        'no',
        'yes',
      ]);
      // Case-insensitive, like the parser.
      expect(unquotedBooleanOptions('options: [NO, Yes]'), ['NO', 'Yes']);
      // The rest of the YAML 1.1 boolean set, not just the pair that bit us.
      for (final word in const [
        'y',
        'n',
        'on',
        'off',
        'true',
        'false',
        'Off',
      ]) {
        expect(unquotedBooleanOptions('options: [$word]'), [
          word,
        ], reason: '$word is a YAML 1.1 boolean and must be reported unquoted');
      }
    });

    test('accepts a quoted option, whatever the word is', () {
      // The quotes are the fix, so a quoted boolean is exactly what must NOT be reported.
      expect(unquotedBooleanOptions('        options: ["no", "yes"]'), isEmpty);
      expect(unquotedBooleanOptions("options: ['no', 'yes']"), isEmpty);
      // And a plain word never needed quoting in the first place.
      expect(unquotedBooleanOptions('        options: [pos]'), isEmpty);
      expect(
        unquotedBooleanOptions('        options: [staging, production, patch]'),
        isEmpty,
      );
    });

    test('ignores an options list that is not on one line', () {
      // Block form, so nothing is read. Reported only if a workflow ever switches to it, and then
      // by a human, not by a silent pass.
      expect(unquotedBooleanOptions('options:\n  - no\n  - yes'), isEmpty);
      expect(unquotedBooleanOptions('description: "no = uji coba"'), isEmpty);
      expect(unquotedBooleanOptions('env: [no]'), isEmpty);
    });

    test('no workflow offers an unquoted YAML 1.1 boolean', () {
      for (final name in _workflowFiles) {
        final offenders = unquotedBooleanOptions(readWorkflow(name));
        expect(
          offenders,
          isEmpty,
          reason:
              '$name offers $offenders unquoted. YAML 1.1 reads those as booleans, so the UI and '
              'every condition receive false/true instead of the words written. Quote them.',
        );
      }
    });

    test('the scan reaches every workflow file', () {
      // A scan that quietly skipped files would pass the test above for the wrong reason, so the
      // list itself is asserted: all six workflow files, all of them present.
      expect(_workflowFiles, hasLength(6));
      for (final name in _workflowFiles) {
        expect(
          File('${repoRoot().path}/.github/workflows/$name').existsSync(),
          isTrue,
          reason: '$name is scanned, so it must exist',
        );
      }

      // And the scan really reads the only file that declares a choice. A regex that stopped
      // matching would report nothing and pass.
      expect(
        RegExp(
          r'^\s*options:',
          multiLine: true,
        ).allMatches(readWorkflow('release-dispatch.yml')).length,
        4,
        reason: 'aplikasi, env, device, draft_release',
      );
    });

    test('the draft choice reaches the validator and the callees as words', () {
      // The chain that produced exit 64: YAML turned the two words into false/true, and the Dart
      // validator, which only knows `no` and `yes`, refused them.
      final workflow = readWorkflow('release-dispatch.yml');
      expect(workflow, contains(r'--draft "${{ inputs.draft_release }}"'));
      // The tag is made only when the input IS the word `yes`.
      expect(workflow, contains("if: inputs.draft_release == 'yes'"));
      // The three building callees skip their draft work only when the input is the word `no`.
      // Read as text: what matters is that the comparison names `no`, because `"false" != "no"`
      // is true and would tag and draft a rehearsal run.
      expect(
        RegExp(r"!= 'no'").allMatches(readWorkflow('release-pos.yml')).length,
        greaterThan(0),
      );
      for (final name in const ['staging-pos.yml', 'windows-pos.yml']) {
        expect(
          readWorkflow(name),
          contains("!= 'no'"),
          reason: '$name skips the draft work when the input is the word no',
        );
      }
    });
  });

  group('the publish-to-store workflow', () {
    final workflow = readWorkflow('publish-to-store.yml');
    final gate = publishGate(workflow);

    test('waits for a human: only a published release starts it', () {
      // Creating a draft must not reach Play. That is the whole point of the split.
      expect(workflow, contains('release:'));
      expect(workflow, contains('types: [published]'));
      expect(workflow, isNot(contains('created')));
      expect(workflow, isNot(contains('prereleased')));
    });

    test('takes the bundle off the release, not off an Actions artifact', () {
      // Artifacts live 30 days and need a `run-id` plus a cross-run token. The release asset is
      // the thing the human just published, and it cannot expire underneath the next step.
      expect(workflow, contains('gh release download'));
      expect(workflow, contains("'*.aab'"));
      expect(workflow, isNot(contains('upload-artifact')));
    });

    test('uploads the internal track, the only track CI may choose', () {
      // Promotion stays a manual action in the Console, so the artifact that gets validated must
      // be the exact file that gets promoted.
      expect(workflow, contains('track: internal'));
      expect(workflow, contains('status: completed'));
      expect(uploadsToPlay(workflow), isTrue);
    });

    test(
      'needs only the Play service account, and no more permission than a read',
      () {
        expect(workflow, contains('secrets.PLAY_SERVICE_ACCOUNT_JSON'));
        // Shorebird finished during the build run; nothing here pushes an OTA patch.
        expect(workflow, isNot(contains('SHOREBIRD')));
        expect(workflow, contains('contents: read'));
      },
    );

    test('accepts a plain production tag and refuses every suffixed one', () {
      expect(gate, isNotNull);
      expect(
        gate,
        contains("startsWith(github.event.release.tag_name, 'pos-v')"),
      );
      // The job-level filter may only carry the prefix rule. "No suffix anywhere in the tag" cannot
      // be written here: GitHub's expression language has no substring removal, no split and no
      // regex, and the only readable workaround, testing the whole tag for a hyphen, is unsatisfiable
      // because the `pos-v` prefix itself contains one, so it would refuse every POS tag including
      // the plain one that must upload. Anything beyond `startsWith` here is an attempt to re-express
      // what only the shell step below can say.
      expect(gate, isNot(contains('replace(')));
      expect(gate, isNot(contains('contains(')));

      expect(publishGateAllows(gate!, 'pos-v1.2.0'), isTrue);
      expect(publishGateAllows(gate, 'web-v1.2.0'), isFalse);
      // A staging release still enters the job (it carries the prefix); what the shell gate decides
      // is whether it goes on to Play.
      expect(publishGateAllows(gate, 'pos-v1.2.0-staging.3'), isTrue);
    });

    test('queues per tag, and stays out of the shared release group', () {
      // It writes no draft, so it must not take the group the two release writers share; one
      // release is published once, so per-tag is enough.
      expect(workflow, contains('concurrency:'));
      expect(
        workflow,
        contains(
          r'group: publish-to-store-${{ github.event.release.tag_name }}',
        ),
      );
      expect(workflow, isNot(contains(r'release-pos-${{ github.ref }}')));
    });
  });

  group('the GitHub Actions expression vocabulary', () {
    // The complete list, and it is short. A name outside it is not "deprecated": GitHub refuses to
    // parse the file at all, so the workflow never runs and the failure names only the offending
    // line. That is what a push to `main` did on 2026-10-06 with `replace(...)`.
    //   https://docs.github.com/actions/reference/workflows-and-actions/expressions
    //     §Functions (contains, startsWith, endsWith, format, join, toJSON, fromJSON, hashFiles)
    //   https://docs.github.com/actions/reference/workflows-and-actions/expressions
    //     §Status check functions (success, always, cancelled, failure)
    const supported = {
      'contains',
      'startsWith',
      'endsWith',
      'format',
      'join',
      'toJSON',
      'fromJSON',
      'hashFiles',
      'success',
      'always',
      'cancelled',
      'failure',
    };

    test('every function called in every workflow is one GitHub documents', () {
      // `testing.md` §0.3: the checker is proved on a name that is certainly not supported, or its
      // silence over 108 real expressions would prove nothing.
      expect(calledFunctions(r"replace(x, 'a', '')"), ['replace']);
      expect(calledFunctions(r"startsWith(x, 'pos-v')"), ['startsWith']);
      expect(
        calledFunctions(r'steps.version.outputs.tag'),
        isEmpty,
        reason: 'a context property is not a call',
      );

      var scanned = 0;
      for (final name in const [
        'publish-to-store.yml',
        'release-dispatch.yml',
        'release-pos.yml',
        'shorebird-patch.yml',
        'staging-pos.yml',
        'windows-pos.yml',
      ]) {
        for (final expression in expressions(readWorkflow(name))) {
          scanned++;
          for (final function in calledFunctions(expression)) {
            expect(
              supported,
              contains(function),
              reason:
                  '$name calls $function(), which GitHub Actions does not have, so the file '
                  'fails to parse',
            );
          }
        }
      }

      // A scan that quietly found one expression would pass the loop above for the wrong reason.
      expect(scanned, greaterThan(100));
    });

    test('the job-level if expressions keep their brackets balanced', () {
      // Not a YAML parser and not an expression evaluator: just enough to catch a half-rewritten
      // chain, which is the shape a hand edit to `if:` actually breaks.
      for (final name in const [
        'publish-to-store.yml',
        'release-dispatch.yml',
        'release-pos.yml',
        'shorebird-patch.yml',
        'staging-pos.yml',
        'windows-pos.yml',
      ]) {
        for (final expression in expressions(readWorkflow(name))) {
          final balanced = _balanced(expression);
          expect(balanced, isTrue, reason: '$name: $expression');
        }
      }
    });

    test('the detector fires on an unbalanced chain', () {
      expect(_balanced("a && (b || c"), isFalse);
      expect(_balanced('always() && x == 1'), isTrue);
      // Quotes must be closed too, or `startsWith(x, 'pos-v)` would pass as balanced.
      expect(_balanced("startsWith(x, 'pos-v)"), isFalse);
    });
  });

  group('the publish gate', () {
    final workflow = readWorkflow('publish-to-store.yml');

    test('checks the exact tag shape in a shell step, not a guess', () {
      final pattern = plainTagRegex(workflow);
      expect(pattern, isNotNull, reason: 'the shell gate must state a regex');

      expect(RegExp(pattern!).hasMatch('pos-v1.2.0'), isTrue);
      // The three shapes of docs/distribution.md §4.1.
      expect(RegExp(pattern).hasMatch('pos-v1.2.0-staging.3'), isFalse);
      expect(RegExp(pattern).hasMatch('pos-v1.2.0-5'), isFalse);
      expect(RegExp(pattern).hasMatch('web-v1.2.0'), isFalse);
      // Shapes a `startsWith('pos-v')` prefix check alone would wave through.
      expect(RegExp(pattern).hasMatch('pos-v1.2.0-rc.1'), isFalse);
      expect(RegExp(pattern).hasMatch('pos-v1.2'), isFalse);

      // The detector is proved against a too-loose gate, which is exactly mutation M2.
      expect(RegExp(r'^pos-v.*$').hasMatch('pos-v1.2.0-staging.3'), isTrue);
    });

    test('a missing gate reads as unknown, never as allowed', () {
      expect(plainTagAccepted('', 'pos-v1.2.0'), isNull);
      expect(plainTagAccepted(workflow, 'pos-v1.2.0'), isTrue);
    });

    test('gates every uploading step on the plain tag', () {
      // The shell gate produces the decision, so each step that touches Play or the release asset
      // has to wait for it. Without the guard, a staging release would still upload.
      expect(workflow, contains('id: tag'));
      expect(workflow, contains(r'echo "plain=true" >> "$GITHUB_OUTPUT"'));
      expect(workflow, contains(r'echo "plain=false" >> "$GITHUB_OUTPUT"'));
      expect(
        RegExp(r'if: steps\.tag\.outputs\.plain == .true.')
            .allMatches(workflow)
            .length,
        greaterThanOrEqualTo(2),
        reason:
            'the download step and the upload step must both wait for the gate',
      );
    });

    test('a non-plain tag is a notice, not a failed run', () {
      // Staging and patch releases are ordinary states of this repository, and both produce a
      // release, so this workflow runs for them. A red run on a normal release teaches the owner to
      // ignore red, which is how a real failure goes unnoticed.
      expect(workflow, contains('::notice::'));
      expect(workflow, isNot(contains('::error::')));
      final shell = _shellRun(workflow, 'Accept only a plain');
      expect(shell, isNotNull);
      expect(shell, isNot(contains('exit 1')));
      expect(shell, isNot(contains('exit 2')));
    });
  });

  group('the tool resolution before every Analyze step', () {
    // The Windows CI job died with exit code 3: 386 issues, `package:dev` not found. `.dart_tool/`
    // is gitignored, `tools/dev`, `tools/rule_lint` and `tools/string_lint` are deliberately not
    // workspace members (each pubspec excludes them), so root `dart pub get` never writes THEIR
    // `package_config.json`, and `dart analyze` walked into `tools/` and found none. Five files
    // gained a `Resolve tools` step and NOTHING here held that in place: the same class of gap the
    // `options: [no, yes]` group below exists for, a checker that reads text while the product
    // breaks on the runner.
    const bad = '''
      - name: Analyze
        run: dart analyze
''';
    const good = '''
      - name: Resolve tools
        run: |
          for tool in tools/dev; do (cd "\$tool" && dart pub get); done
      - name: Analyze
        run: dart analyze
''';

    test('names a step that analyzes with nothing resolved', () {
      expect(unresolvedAnalyzeSteps(bad), ['Analyze']);
    });

    test('accepts a resolve step immediately before the analyze step', () {
      expect(unresolvedAnalyzeSteps(good), isEmpty);
    });

    test('a comment or blank line between the two steps is not a bug', () {
      // Interposing a line is legal YAML and legal practice; pinning the distance between the two
      // steps instead of the ORDER would fail this and teach the next author to fear editing.
      expect(
        unresolvedAnalyzeSteps('''
      - name: Resolve tools
        run: dart pub get --directory tools/dev
      # Menambah satu tool lagi berarti menambah satu baris di sini.
      - name: Analyze
        run: dart analyze
'''),
        isEmpty,
      );
    });

    test('a resolve step AFTER the analyze step does not count', () {
      // Same red build, and the reason "somewhere earlier in the file" was rejected: this ordering
      // resolves the tools too late.
      expect(
        unresolvedAnalyzeSteps('''
      - name: Analyze
        run: dart analyze
      - name: Resolve tools
        run: dart pub get --directory tools/dev
'''),
        ['Analyze'],
      );
    });

    test('names every offending step, so one fix does not hide another', () {
      expect(
        unresolvedAnalyzeSteps('''
      - name: Analyze
        run: dart analyze
      - name: Resolve tools
        run: dart pub get --directory tools/dev
      - name: Analyze again
        run: dart analyze
'''),
        ['Analyze'],
      );
      expect(
        unresolvedAnalyzeSteps('$bad$bad'),
        ['Analyze', 'Analyze'],
        reason: 'both jobs are broken, and only the first is reported if the scan stops early',
      );
    });

    test('every Analyze step follows a resolve step', () {
      final files = _allWorkflowFiles();
      expect(files, hasLength(greaterThanOrEqualTo(6)));

      final offenders = <String, List<String>>{};
      var analyzers = 0;
      for (final name in files) {
        final findings = unresolvedAnalyzeSteps(readWorkflow(name));
        if (findings.isNotEmpty) offenders[name] = findings;
        analyzers += RegExp(
          r'^\s*run:\s*dart analyze\s*$',
          multiLine: true,
        ).allMatches(readWorkflow(name)).length;
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'these workflows run `dart analyze` with no `Resolve tools` step before it, so on a '
            'fresh runner the tools have no package_config.json and analyze exits 3 with hundreds '
            'of "Target of URI doesn\'t exist" issues',
      );
      // The pass above would be vacuous on a scan that matched nothing, so the steps it looked for
      // are counted.
      expect(analyzers, greaterThanOrEqualTo(5));
    });
  });

  group('the base directory of every path consumer', () {
    // Production ran green up to `Build release APK` (7m11s, a real 60.7MB APK) and then died on
    // the very next step that touches the file: `unzip: cannot find or open
    // apps/pos/build/app/outputs/flutter-apk/app-release.apk`. The APK was there, and it had been
    // written by a step with no `working-directory`, so the emitter produced a WORKSPACE-ROOT-RELATIVE
    // path. The guard step that read it declared `working-directory: apps/pos`, so `$APK` resolved
    // to apps/pos/apps/pos/... and unzip exited 9. `windows-pos.yml` went green in the same run for
    // exactly this reason: its guard has no `working-directory`.
    //
    // Root-relative is the representation that has to survive, because three other consumers cannot
    // read anything else: `upload-artifact` resolves `path:` from `$GITHUB_WORKSPACE`, and
    // `softprops/action-gh-release` resolves `files:` the same way. So the invariant is not "no
    // working-directory anywhere" -- `flutter build` legitimately runs in `apps/pos`. It is narrower:
    // a step that consumes `steps.<id>.outputs.path` must not declare `working-directory`.
    const bad = '''
      - name: Locate APK
        id: apk
        run: echo "path=\$APK" >> "\$GITHUB_OUTPUT"
      - name: Guard
        working-directory: apps/pos
        env:
          APK: \${{ steps.apk.outputs.path }}
        run: unzip -o -q "\$APK"
''';
    const good = '''
      - name: Locate APK
        id: apk
        run: echo "path=\$APK" >> "\$GITHUB_OUTPUT"
      - name: Guard
        env:
          APK: \${{ steps.apk.outputs.path }}
        run: unzip -o -q "\$APK"
''';

    test('names a consumer that rebases the emitter path', () {
      expect(pathConsumersWithWorkingDirectory(bad), ['Guard']);
    });

    test('accepts a consumer at the workspace root, like the emitters', () {
      expect(pathConsumersWithWorkingDirectory(good), isEmpty);
    });

    test(
      'accepts a working-directory on a step that reads no emitter path',
      // The narrower half, and the one that decides whether the rule above is a rule or a ban: the
      // build steps genuinely need `apps/pos`, and pinning them too would forbid the one fix that
      // works.
      () {
        expect(
          pathConsumersWithWorkingDirectory('''
      - name: Build release APK
        working-directory: apps/pos
        run: flutter build apk --release
'''),
          isEmpty,
        );
      },
    );

    test('a comment inside the guard step is not a second base directory', () => expect(
          pathConsumersWithWorkingDirectory('''
      - name: Guard
        # working-directory: apps/pos -- jangan, path-nya root-relative
        env:
          APK: \${{ steps.apk.outputs.path }}
        run: unzip -o -q "\$APK"
'''),
          isEmpty,
        ));

    test('names every offending step, so one fix does not hide another', () {
      expect(pathConsumersWithWorkingDirectory('$bad$bad'), ['Guard', 'Guard']);
      expect(
        pathConsumersWithWorkingDirectory('''
      - name: Upload artifact
        working-directory: apps/pos
        with:
          path: \${{ steps.apk.outputs.path }}
      - name: Create draft release
        working-directory: apps/pos
        with:
          files: \${{ steps.apk.outputs.path }}
'''),
        ['Upload artifact', 'Create draft release'],
        reason: 'the with: consumers are rebased too, not only the shell guards',
      );
    });

    test('no workflow rebases a step that reads an emitter path', () {
      final files = _allWorkflowFiles();
      expect(files, hasLength(greaterThanOrEqualTo(6)));

      final offenders = <String, List<String>>{};
      var consumers = 0;
      for (final name in files) {
        final workflow = readWorkflow(name);
        final findings = pathConsumersWithWorkingDirectory(workflow);
        if (findings.isNotEmpty) offenders[name] = findings;
        consumers += RegExp(
          r'steps\.[\w-]+\.outputs\.path',
        ).allMatches(workflow).length;
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'these workflows read a `steps.<id>.outputs.path` from a step that declares a '
            '`working-directory`. The emitters run at the workspace root, so the path is '
            'root-relative; a consumer that changes the base directory looks for it one level too '
            'deep and fails on a file that exists (unzip exit 9).',
      );
      // The pass above is vacuous on a scan that matched nothing, so the expressions it looked for
      // are counted. Two workflows x (guard + upload + release) is already past this.
      expect(consumers, greaterThanOrEqualTo(4));
    });
  });
}

/// Whether [expression] closes every bracket and quote it opens.
///
/// A hand edit to an `if:` chain breaks on brackets long before it breaks on semantics, so this
/// counts the three kinds of closer instead of parsing anything.
bool _balanced(String expression) {
  final pairs = {')': '(', ']': '['};
  var round = 0;
  var square = 0;
  var singleQuote = false;
  for (var i = 0; i < expression.length; i++) {
    final c = expression[i];
    if (c == "'" && (i == 0 || expression[i - 1] != r'\')) {
      singleQuote = !singleQuote;
      continue;
    }
    // A bracket inside a string literal is not a bracket.
    if (singleQuote) continue;
    if (c == '(') round++;
    if (c == ')') round--;
    if (c == '[') square++;
    if (c == ']') square--;
    if (pairs.containsKey(c) && (round < 0 || square < 0)) return false;
  }
  return round == 0 && square == 0 && !singleQuote;
}

/// The names of the steps that run `dart analyze` while no `Resolve tools` step precedes them.
///
/// On a fresh runner `.dart_tool/` does not exist, `tools/*` is not a workspace member, so root
/// `dart pub get` never writes those tools' `package_config.json`. `dart analyze` then walks into
/// `tools/`, finds no config, falls back to the root one, and `package:dev` is unknown: 386 issues
/// and exit code 3. The `Resolve tools` step is the fix; this finds the places the fix is missing.
///
/// "Precedes" means the step IMMEDIATELY before, not "anywhere earlier in the file": a workflow
/// whose `Resolve tools` runs after its Analyze is just as broken as one with no such step, and a
/// distance rule would wave that through. Only step boundaries (`- name:`/`- uses:`) count as
/// boundaries, so a comment or a blank line between the two steps stays legal: interposing a line
/// is not a bug and this must not punish it.
///
/// A line scan rather than a YAML parse, for the same reason as [tagPatterns]: the repo has no YAML
/// dependency, and the shape read here is one step list two keys deep and fixed.
List<String> unresolvedAnalyzeSteps(String workflow) {
  final findings = <String>[];
  // Whether the step whose lines are being read is the one right after a `Resolve tools` step, and
  // whether the step just closed was that resolve step. The resolve serves the NEXT step, so the
  // flag is handed over at each boundary and never survives one.
  var resolved = false;
  var lastStepWasResolve = false;
  var stepName = '<unnamed step>';
  for (final line in workflow.split(RegExp(r'\r?\n'))) {
    final step = RegExp(r'^\s*-\s+(name|uses):\s*(.+?)\s*$').firstMatch(line);
    if (step != null) {
      stepName = step.group(2)!;
      resolved = lastStepWasResolve;
      lastStepWasResolve = stepName == 'Resolve tools';
      continue;
    }
    if (!RegExp(r'^\s*run:\s*dart analyze\s*$').hasMatch(line)) continue;
    if (!resolved) findings.add(stepName);
  }
  return findings;
}

/// The names of the steps that read `steps.<id>.outputs.path` while declaring a `working-directory`.
///
/// The emitters of that path (`Locate APK`, `Locate AAB`, `Locate MSIX`) declare no
/// `working-directory`, so they run at the workspace root and what they write is root-relative --
/// which is also the only form `upload-artifact` and `action-gh-release` can resolve. A consumer
/// that declares its own `working-directory` resolves the same string against a different base and
/// fails on a file that demonstrably exists.
///
/// A line scan rather than a YAML parse, for the same reason as [tagPatterns]: the repo has no YAML
/// dependency and the shape is one step list two keys deep. Step boundaries are `- name:`/`- uses:`,
/// so a comment or a blank line inside a step changes nothing.
List<String> pathConsumersWithWorkingDirectory(String workflow) {
  final findings = <String>[];
  var stepName = '<unnamed step>';
  var workingDirectory = false;
  var consumesPath = false;

  void closeStep() {
    if (consumesPath && workingDirectory) findings.add(stepName);
  }

  for (final line in workflow.split(RegExp(r'\r?\n'))) {
    final step = RegExp(r'^\s*-\s+(name|uses):\s*(.+?)\s*$').firstMatch(line);
    if (step != null) {
      closeStep();
      stepName = step.group(2)!;
      workingDirectory = false;
      consumesPath = false;
      continue;
    }
    // A commented-out key is not a key; M3 covers that so the scan cannot be fooled by a note.
    if (RegExp(r'^\s*working-directory:\s*\S').hasMatch(line)) {
      workingDirectory = true;
    }
    if (RegExp(r'steps\.[\w-]+\.outputs\.path').hasMatch(line)) {
      consumesPath = true;
    }
  }
  closeStep();
  return findings;
}

/// Every workflow file in the repository, the parked `ci.yml.disabled` among them.
///
/// Read from the directory rather than from a hand-kept list, because the failure this guards is
/// exactly a workflow nobody remembered: a sixth file running `dart analyze` without the resolve
/// step would be invisible to a list that did not yet exist. The disabled file is scanned too
/// because it is parked, not abandoned, and re-enabling it must not be the step that reddens CI.
List<String> _allWorkflowFiles() => [
  for (final entity in Directory(
    '${repoRoot().path}/.github/workflows',
  ).listSync())
    if (entity is File &&
        (entity.path.endsWith('.yml') || entity.path.endsWith('.yml.disabled')))
      entity.uri.pathSegments.last,
]..sort();

/// The `run:` body of the step whose `- name:` contains [fragment].
String? _shellRun(String workflow, String fragment) {
  final lines = workflow.split(RegExp(r'\r?\n'));
  final at = lines.indexWhere((l) => l.contains('- name: $fragment'));
  if (at == -1) return null;
  final body = <String>[];
  for (var i = at + 1; i < lines.length; i++) {
    // The next `- name:`/`- uses:` closes the block; body lines are indented at least as far.
    if (RegExp(r'^\s*-\s').hasMatch(lines[i])) break;
    if (lines[i].trim().isNotEmpty && lines[i].startsWith('        ')) {
      body.add(lines[i]);
    }
  }
  return body.join('\n');
}
