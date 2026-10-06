/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:dev/dev.dart';
import 'package:test/test.dart';

/// Every package has tests, unless a test says otherwise.
bool allHaveTests(String directory) => true;

List<Step> planFor(
  List<String> argv, {
  bool Function(String directory) hasTests = allHaveTests,
}) =>
    plan(argv, hasTests: hasTests);

Matcher isStep(String executable, List<String> args, String directory) =>
    isA<Step>()
        .having((s) => s.executable, 'executable', executable)
        .having((s) => s.args, 'args', args)
        .having((s) => s.directory, 'directory', directory);

Matcher usageError([String? part]) => throwsA(
      isA<UsageException>().having(
        (e) => e.message,
        'message',
        part == null ? isNotEmpty : contains(part),
      ),
    );

void main() {
  group('run', () {
    test('runs the app from apps/pos', () {
      expect(planFor(['run']), [
        isStep('flutter', ['run'], 'apps/pos')
      ]);
    });

    // The reason this is a script and not a Makefile: whatever the developer types after the
    // task name reaches Flutter untouched.
    test('hands every flag to flutter as it was typed', () {
      expect(
        planFor(['run', '-d', 'emulator-5554', '--flavor=x', '--verbose']),
        [
          isStep(
              'flutter',
              [
                'run',
                '-d',
                'emulator-5554',
                '--flavor=x',
                '--verbose',
              ],
              'apps/pos'),
        ],
      );
    });
  });

  group('build', () {
    test('is a debug APK unless told otherwise', () {
      expect(planFor(['build']), [
        isStep('flutter', ['build', 'apk', '--debug'], 'apps/pos'),
      ]);
    });

    test('takes the mode as its first word', () {
      expect(planFor(['build', 'release']), [
        isStep('flutter', ['build', 'apk', '--release'], 'apps/pos'),
      ]);
      expect(planFor(['build', 'debug']), [
        isStep('flutter', ['build', 'apk', '--debug'], 'apps/pos'),
      ]);
    });

    // The staging build is the `profile` build type — Flutter's own, which already carries a
    // plain applicationId and `dart.vm.product=false`. `--profile` is the whole difference; no
    // `--dart-define` is involved (`plan/staging/README.md` §3).
    //
    // `staging`, not `profile`, as the word to type: `profile` is Flutter's internal name, and
    // what a person means here is "the staging build".
    test('takes `staging` for the profile build type', () {
      expect(planFor(['build', 'staging']), [
        isStep('flutter', ['build', 'apk', '--profile'], 'apps/pos'),
      ]);
    });

    test('hands the rest to flutter for staging too', () {
      expect(planFor(['build', 'staging', '--build-name', '1.2.0']), [
        isStep('flutter',
            ['build', 'apk', '--profile', '--build-name', '1.2.0'], 'apps/pos'),
      ]);
    });

    // `staging` is a mode word only in first place, like `release`. A `--dart-define` that
    // happens to contain the word must not be mistaken for it.
    test('does not treat `staging` as a mode when it is not first', () {
      expect(
        planFor(['build', '--dart-define=PN_X=staging']),
        [
          isStep(
              'flutter',
              [
                'build',
                'apk',
                '--debug',
                '--dart-define=PN_X=staging',
              ],
              'apps/pos'),
        ],
      );
    });

    test('a flag in first place is a flag, and the mode stays debug', () {
      expect(planFor(['build', '--target-platform', 'android-arm64']), [
        isStep(
            'flutter',
            [
              'build',
              'apk',
              '--debug',
              '--target-platform',
              'android-arm64',
            ],
            'apps/pos'),
      ]);
    });

    test('hands the rest to flutter as it was typed', () {
      expect(
        planFor(
            ['build', 'release', '--build-name', '1.2.3', '--split-per-abi']),
        [
          isStep(
              'flutter',
              [
                'build',
                'apk',
                '--release',
                '--build-name',
                '1.2.3',
                '--split-per-abi',
              ],
              'apps/pos'),
        ],
      );
    });

    test('a flag in first place is a flag, and the mode stays debug', () {
      expect(planFor(['build', '--target-platform', 'android-arm64']), [
        isStep(
            'flutter',
            [
              'build',
              'apk',
              '--debug',
              '--target-platform',
              'android-arm64',
            ],
            'apps/pos'),
      ]);
    });

    // `build` is Android only; the Windows build is its own task, because it is a different
    // artifact with a different follow-up (see the `windows` group).
    test('never targets Windows', () {
      expect(
        planFor(['build']).single.args,
        isNot(contains('windows')),
      );
    });
  });

  group('windows', () {
    // The Windows half of the login deeplink. `flutter run -d windows -- <url>` is the everyday
    // way to exercise it: the app reads the URL from its own command line, exactly as it does
    // when Windows launches it for a tapped App Link — no package needed. Verified on a real
    // Windows run (2026-09-21): the process came up with the URL in `argv[1]`.
    test('runs the app, handing the rest to flutter as it was typed', () {
      expect(planFor(['windows']), [
        isStep('flutter', ['run', '-d', 'windows'], 'apps/pos'),
      ]);
      expect(
        planFor([
          'windows',
          '--',
          'https://apps-dev.finnesia.com/api/auth/mobile/return'
        ]),
        [
          isStep(
              'flutter',
              [
                'run',
                '-d',
                'windows',
                '--',
                'https://apps-dev.finnesia.com/api/auth/mobile/return',
              ],
              'apps/pos'),
        ],
      );
    });

    test('takes a mode as its first word, and builds the runner', () {
      expect(planFor(['windows', 'debug']), [
        isStep('flutter', ['build', 'windows', '--debug'], 'apps/pos'),
      ]);
      expect(planFor(['windows', 'release']), [
        isStep('flutter', ['build', 'windows', '--release'], 'apps/pos'),
      ]);
    });

    test('a flag in first place is a flag, and it runs instead of building',
        () {
      expect(planFor(['windows', '--dart-define=PN_POS_ENV=staging']), [
        isStep(
            'flutter',
            [
              'run',
              '-d',
              'windows',
              '--dart-define=PN_POS_ENV=staging',
            ],
            'apps/pos'),
      ]);
    });

    group('msix', () {
      // A package is needed for exactly one thing: a tapped `https` link in a browser. Windows
      // resolves that through the registry, and only a packaged app can register there. The
      // command-line path above needs no package at all.
      test('packages, and never prompts for the certificate', () {
        expect(planFor(['windows', 'msix']), [
          isStep('flutter', ['build', 'windows', '--release'], 'apps/pos'),
          isStep(
              'dart',
              ['run', 'msix:create', '--install-certificate', 'false'],
              'apps/pos'),
        ]);
      });

      // The prompt ("install the certificate?") waits on a console and needs admin, so a build
      // that hit it would hang forever in CI or a script. Pinned because it cost a 600s timeout.
      test('never leaves the certificate prompt reachable', () {
        final step = planFor(['windows', 'msix']).last;
        expect(step.args, contains('--install-certificate'));
        expect(step.args, contains('false'));
      });

      test('hands extra flags to the packager', () {
        expect(planFor(['windows', 'msix', '--version', '1.2.3']), [
          isStep('flutter', ['build', 'windows', '--release'], 'apps/pos'),
          isStep(
              'dart',
              [
                'run',
                'msix:create',
                '--install-certificate',
                'false',
                '--version',
                '1.2.3',
              ],
              'apps/pos'),
        ]);
      });
    });
  });

  group('reverse', () {
    // A physical tablet reaches a backend on this machine (`lokal`, http://localhost:4000)
    // only through this.
    test('forwards the local backend port', () {
      expect(planFor(['reverse']), [
        isStep('adb', ['reverse', 'tcp:4000', 'tcp:4000'], '.'),
      ]);
    });

    test('puts adb\'s own options before the subcommand', () {
      expect(planFor(['reverse', '-s', '127.0.0.1:58526']), [
        isStep(
            'adb',
            [
              '-s',
              '127.0.0.1:58526',
              'reverse',
              'tcp:4000',
              'tcp:4000',
            ],
            '.'),
      ]);
    });
  });

  group('setup', () {
    test('resolves the whole workspace from the root', () {
      expect(planFor(['setup']), [
        isStep('dart', ['pub', 'get'], '.')
      ]);
    });
  });

  group('gen', () {
    test('runs build_runner in every package that has generated code', () {
      expect(planFor(['gen']), [
        isStep('dart', ['run', 'build_runner', 'build'], 'packages/pn_types'),
        isStep('dart', ['run', 'build_runner', 'build'], 'packages/pn_pos'),
        isStep('dart', ['run', 'build_runner', 'build'], 'apps/pos'),
      ]);
    });

    test('hands flags to each of them', () {
      expect(
        planFor(['gen', '--delete-conflicting-outputs']),
        everyElement(
          isA<Step>().having(
            (s) => s.args,
            'args',
            ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
          ),
        ),
      );
    });
  });

  group('l10n', () {
    test('regenerates the localizations from the ARB files, in apps/pos', () {
      expect(planFor(['l10n']), [
        isStep('flutter', ['gen-l10n'], 'apps/pos')
      ]);
    });

    test('hands what follows to flutter as it was typed', () {
      expect(planFor(['l10n', '--verbose']), [
        isStep('flutter', ['gen-l10n', '--verbose'], 'apps/pos')
      ]);
    });
  });

  // The gate the dispatcher workflow calls. It plans nothing: the whole job is whether the exit
  // code is 0 or not, so `check` must not start paying for it (SPEC §5.1).
  group('dispatch', () {
    test('runs nothing at all for an accepted combination', () {
      expect(
          planFor([
            'dispatch',
            '--env',
            'staging',
            '--device',
            'android',
            '--draft',
            'no'
          ]),
          isEmpty);
      expect(
          planFor([
            'dispatch',
            '--env',
            'production',
            '--device',
            'all',
            '--draft',
            'yes',
            '--version',
            '1.2.0'
          ]),
          isEmpty);
    });

    // Exit 64 plus a `::error::` line is what `bin/dev.dart` already does with a
    // `UsageException`, and it is what the YAML gate reads. Without the prefix the refusal is
    // only visible in the raw log.
    test('refuses a combination as an ::error::, so the job exits non-zero',
        () {
      expect(
        () => planFor([
          'dispatch',
          '--env',
          'staging',
          '--device',
          'windows',
          '--draft',
          'no'
        ]),
        usageError('::error::'),
      );
      expect(
        () => planFor([
          'dispatch',
          '--env',
          'staging',
          '--device',
          'windows',
          '--draft',
          'no'
        ]),
        usageError('windows'),
      );
    });

    test('refuses draft release = yes without a version', () {
      expect(
        () => planFor([
          'dispatch',
          '--env',
          'production',
          '--device',
          'android',
          '--draft',
          'yes'
        ]),
        usageError('::error::'),
      );
    });

    test('refuses flags it does not know, by name', () {
      expect(
        () => planFor([
          'dispatch',
          '--env',
          'staging',
          '--device',
          'android',
          '--draft',
          'no',
          '--tag',
          'pos-v1.2.0'
        ]),
        usageError('::error::'),
      );
      expect(() => planFor(['dispatch']), usageError('::error::'));
    });

    test('is not part of check, which stays the CI list', () {
      expect(
        planFor(['check']).map((s) => s.builtin ?? s.executable),
        isNot(contains('dispatch')),
      );
    });
  });

  group('test', () {
    test('pure packages with dart test, Flutter ones with flutter test', () {
      expect(planFor(['test']), [
        isStep('dart', ['test'], 'packages/pn_types'),
        isStep('dart', ['test'], 'packages/pn_pos'),
        isStep('flutter', ['test'], 'packages/pn_ui'),
        isStep('flutter', ['test'], 'apps/pos'),
      ]);
    });

    // CI skips a package that has no test/ folder, and so does this: `dart test` in one exits 1.
    test('skips a package that has no tests yet', () {
      final steps = planFor(
        ['test'],
        hasTests: (directory) => directory != 'packages/pn_ui',
      );

      expect(steps.map((s) => s.directory), [
        'packages/pn_types',
        'packages/pn_pos',
        'apps/pos',
      ]);
    });

    test('can be narrowed to one package, by its short name', () {
      expect(planFor(['test', 'pos']), [
        isStep('flutter', ['test'], 'apps/pos'),
      ]);
      expect(planFor(['test', 'pn_pos']), [
        isStep('dart', ['test'], 'packages/pn_pos'),
      ]);
    });

    test('refuses a package it does not know', () {
      expect(() => planFor(['test', 'nope']), usageError('nope'));
    });

    test('refuses to narrow to a package that has no tests', () {
      expect(
        () => planFor(
          ['test', 'pn_ui'],
          hasTests: (directory) => directory != 'packages/pn_ui',
        ),
        usageError('pn_ui'),
      );
    });
  });

  group('guard', () {
    test('looks for flutter imports in the packages that must stay pure', () {
      expect(planFor(['guard']), [
        isA<Step>()
            .having((s) => s.builtin, 'builtin', 'no-flutter-imports')
            .having((s) => s.args, 'directories', [
          'packages/pn_types/lib',
          'packages/pn_pos/lib',
        ]),
      ]);
    });
  });

  group('gen-check', () {
    Matcher isGenFresh(List<String> packages) => isA<Step>()
        .having((s) => s.builtin, 'builtin', 'gen-fresh')
        .having((s) => s.args, 'packages', packages);

    test('compares the generated code of every package that has some', () {
      expect(planFor(['gen-check']), [
        isGenFresh(['packages/pn_types', 'packages/pn_pos', 'apps/pos']),
      ]);
    });

    test('can be narrowed to one package, by its short name', () {
      expect(planFor(['gen-check', 'pos']), [
        isGenFresh(['apps/pos'])
      ]);
      expect(planFor(['gen-check', 'pn_pos']), [
        isGenFresh(['packages/pn_pos']),
      ]);
    });

    test(
        'refuses a package that has no generated code, and one it does not know',
        () {
      expect(() => planFor(['gen-check', 'pn_ui']), usageError('pn_ui'));
      expect(() => planFor(['gen-check', 'nope']), usageError('nope'));
    });
  });

  // CI runs this step on its own, so it has to be reachable without running all of `check`. It is
  // the same `Step` object `check` uses: a second literal would be the list of paths written twice,
  // and the copy is the thing that goes stale when a package is added.
  group('format', () {
    test('runs the same step check runs, and nothing else', () {
      final format = planFor(['format']).single;
      final inCheck = planFor(['check']).singleWhere(
          (s) => s.executable == 'dart' && s.args.contains('format'));

      expect(identical(format, inCheck), isTrue,
          reason:
              '`format` and `check` must share one Step, not two copies of it');

      expect(format.executable, 'dart');
      expect(format.directory, '.');
      expect(format.args, [
        'format',
        '--output=none',
        '--set-exit-if-changed',
        ...formatTargets,
      ]);
      expect(formatTargets, hasLength(19));
    });

    test('names the source roots, never the whole tree', () {
      final targets = planFor(['format']).single.args;

      expect(targets, isNot(contains('.')));
      // A package added to `packages` and left out of `formatTargets` would never be formatted,
      // and CI would not say so.
      for (final package in packages) {
        expect(targets, contains('${package.directory}/lib'));
        expect(targets, contains('${package.directory}/test'));
      }
    });
  });

  // The order of AGENTS.md §Verification and CI: an earlier failure stops the later steps.
  group('check', () {
    // Every step of `ci.yml` that is a check and not the setup of a runner, in its order. The two
    // `builtin` ones are checks that need more than one command (they compare files).
    test('runs what CI runs, in the order CI runs it', () {
      expect(
          planFor(['check']).map((s) => s.builtin != null
              ? 'builtin ${s.builtin} ${s.args.join(' ')}'
              : '${s.executable} ${s.args.join(' ')} @${s.directory}'),
          [
            'dart pub get @.',
            'dart pub get @tools/dev',
            'dart pub get @tools/rule_lint',
            'dart pub get @tools/string_lint',
            'dart format --output=none --set-exit-if-changed '
                '${formatTargets.join(' ')} @.',
            'dart analyze @.',
            'builtin gen-fresh packages/pn_types packages/pn_pos apps/pos',
            'builtin no-flutter-imports packages/pn_types/lib packages/pn_pos/lib',
            'dart test @packages/pn_types',
            'dart test @packages/pn_pos',
            'flutter test @packages/pn_ui',
            'flutter test @apps/pos',
            'dart run tools/rule_lint/bin/rule_lint.dart @.',
          ]);
    });

    test('formats the source roots by name, never the whole tree', () {
      final format = planFor(['check']).singleWhere(
          (s) => s.executable == 'dart' && s.args.contains('format'));

      expect(format.directory, '.');
      expect(format.args, isNot(contains('.')));

      final targets =
          format.args.skipWhile((a) => a != '--set-exit-if-changed').skip(1);

      // A package added to `packages` and forgotten here would never be formatted, and nothing
      // else in `check` would say so.
      for (final package in packages) {
        expect(targets, contains('${package.directory}/lib'));
        expect(targets, contains('${package.directory}/test'));
      }
      for (final tool in toolDirectories) {
        expect(targets, contains('$tool/bin'));
        expect(targets, contains('$tool/lib'));
        expect(targets, contains('$tool/test'));
      }
    });

    test('leaves out the tests of a package that has none', () {
      final steps = planFor(
        ['check'],
        hasTests: (directory) => directory != 'packages/pn_ui',
      );

      expect(steps.map((s) => s.directory), isNot(contains('packages/pn_ui')));
    });
  });

  // A check that finds nothing proves nothing until it is shown to find something
  // (`.claude/rules/testing.md` §0.3).
  group('what it does not know', () {
    test('an unknown task is refused, by name', () {
      expect(() => planFor(['deploy']), usageError('deploy'));
    });

    test('no task at all is refused too', () {
      expect(() => planFor([]), usageError());
    });

    test('every task the usage text lists is one the planner knows', () {
      for (final name in taskNames) {
        expect(
          () => planFor([name]),
          isNot(usageError('unknown')),
          reason: 'usage lists "$name", so it must be plannable',
        );
        expect(usage, predicate<String>((u) => u.contains(name)));
      }
    });
  });
}
