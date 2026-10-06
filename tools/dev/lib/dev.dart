/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Turns `./dev <task> [args...]` into the commands to run.
///
/// Pure on purpose: it decides what to run and never runs it, so every task is tested without a
/// device, a network or a Flutter SDK. `bin/dev.dart` is the part that spawns processes.
///
/// Why a Dart script and not a Makefile or `melos`: Dart has no `scripts` in `pubspec.yaml`;
/// `make` is not on a stock Windows machine and passes flags only through variables; and
/// `architecture.md` §7 postpones melos. A script hands whatever follows the task name to the
/// tool underneath, as typed, and runs the same on Windows, macOS and Linux.
library;

import 'dispatch.dart';

/// One command to run: [executable] with [args], from [directory] (relative to the repo root).
class Step {
  const Step(this.executable, this.args, this.directory) : builtin = null;

  /// A check that is more than one command (it compares files), run by `bin/dev.dart` itself
  /// and not as a process. [args] are what it looks at: package or source directories.
  const Step.builtin(String this.builtin, this.args)
      : executable = '',
        directory = '.';

  final String executable;
  final List<String> args;
  final String directory;

  /// The name of the built-in check, or `null` for a command to spawn.
  final String? builtin;

  @override
  String toString() => builtin != null
      ? 'check $builtin ${args.join(' ')}'
      : '$executable ${args.join(' ')}  (in $directory)';
}

/// The task was not understood. [message] is what to show the developer.
class UsageException implements Exception {
  UsageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The tasks, in the order the usage text lists them.
const taskNames = [
  'setup',
  'run',
  'build',
  'windows',
  'reverse',
  'gen',
  'l10n',
  'icons',
  'gen-check',
  'guard',
  'dispatch',
  'test',
  'format',
  'check',
];

const usage = r'''
Usage: ./dev <task> [args...]        (Windows: .\dev <task> [args...])

  setup                 Resolve the whole workspace (dart pub get).
  run [flutter args]    Run the app from apps/pos, e.g. `run -d emulator-5554`.
  build [debug|release|staging] [flutter args]
                        Build an APK (default debug), e.g. `build release --build-name 1.2.3`.
                        Release and staging need apps/pos/android/keystore.properties.
                        `staging` is the `profile` build type: appId release, but the app
                        behaves like debug — staging host, endpoint picker, inspector. It is
                        what internal testers install (`plan/staging/README.md`). The AAB for
                        Play Console is not built by this task; run
                        `flutter build appbundle --profile` in apps/pos for that.
  windows [debug|release|msix] [args]
                        The Windows build, which is a separate artifact from the APK.
                        No mode: `flutter run -d windows`, so a link can be injected with
                        `windows -- <url>` — the app reads it from its own command line, the
                        same path Windows uses when it launches the app for a tapped App Link.
                        `windows debug|release`: `flutter build windows`.
                        `windows msix`: a release build, then an MSIX package. Windows resolves
                        a tapped `https` link through the registry, and only a packaged app can
                        register there — the command line above needs no package. The packager
                        runs with `--install-certificate false` so it never waits on a prompt;
                        the certificate is trusted once, by hand (see
                        plan/api-client/findings.md §Deeplink Windows).
  reverse [adb args]    Forward tcp:4000 to this machine, so a tablet can reach a local backend
                        (`lokal`). With more than one device: `reverse -s <serial>`.
  gen [build_runner args]
                        Regenerate freezed / json code in every package that has it.
  l10n [flutter args]   Regenerate the localizations after editing apps/pos/lib/l10n/*.arb
                        (flutter gen-l10n). The generated app_localizations*.dart are committed.
  icons [args]          Regenerate the app icons from apps/pos/assets/icon/: the Android launcher
                        icon and its adaptive layers (flutter_launcher_icons), then the Windows
                        .ico at six sizes. The output under apps/pos/android/... and
                        apps/pos/windows/... is committed, so re-run this after changing the
                        artwork or `flutter_launcher_icons.yaml`.
  gen-check [package]   Is the generated code up to date (freezed / json, and the localizations
                        of pos)? Regenerates, compares, and puts the files back: it changes
                        nothing. pn_types, pn_pos, pos.
  guard                 Fail if pn_types or pn_pos imports flutter (they must stay pure).
  dispatch --env E --device D --draft Y [--version V]
                        Check one release-dispatch combination, and run nothing. E is
                        staging | production | patch, D is android | windows | all, Y is
                        no | yes. `--version` is required when --draft yes. A refused
                        combination prints `::error::` with the reason and exits non-zero,
                        so the dispatcher job can gate the build on it; an accepted one
                        exits 0 silently. The rules live in lib/dispatch.dart and are tested
                        in test/dispatch_test.dart (plan/release-dispatch/SPEC.md §2a, §3.1).
  test [package]        Run the tests: pn_types, pn_pos, pn_ui, pos. No name runs all of them.
  format                Just the format check, which is what CI runs as its own step. The source
                        roots come from the tool, not from the caller: `dart format` has no
                        exclusion flag and does not read `.gitignore`, so `dart format .` walks
                        into `build/` and dies. See `formatTargets`.
  check                 Everything CI runs, in CI's order: pub get (root, then each tool under
                        tools/ separately), format, analyze, generated code up to date, no
                        flutter in pn_types/pn_pos, tests, rule_lint.

Anything after the task name goes to the tool underneath, untouched.
''';

/// One pub package in the workspace. Public because [packages] is public, and a test reads it.
typedef Package = ({String name, String directory, bool flutter});

/// Every pub package in the workspace, with what `plan()` needs to know about each.
const packages = <Package>[
  (name: 'pn_types', directory: 'packages/pn_types', flutter: false),
  (name: 'pn_pos', directory: 'packages/pn_pos', flutter: false),
  (name: 'pn_ui', directory: 'packages/pn_ui', flutter: true),
  (name: 'pos', directory: 'apps/pos', flutter: true),
];

/// The packages that carry generated code (`*.freezed.dart`, `*.g.dart`).
const _generating = ['packages/pn_types', 'packages/pn_pos', 'apps/pos'];

/// Packages that must stay free of Flutter (`architecture.md` §3).
const _pure = ['packages/pn_types/lib', 'packages/pn_pos/lib'];

/// The tools under `tools/`, each a Dart package of its own with `bin`, `lib` and `test`.
const toolDirectories = ['tools/dev', 'tools/rule_lint', 'tools/string_lint'];

/// The packages that keep one-off Dart scripts in `tool/` (a build icon, an ESC/POS case
/// generator). A package with no such script simply is not in here; `pn_types` and `pn_ui` are
/// not because they have none.
const _packageToolDirectories = ['apps/pos', 'packages/pn_pos'];

/// What `dart format` is pointed at, derived from [packages] and [toolDirectories].
///
/// **Not `.`, and that is not a style choice.** `dart format` has no exclusion flag and does not
/// read `.gitignore`, so a `.` walk descends into every `build/`, `.dart_tool/` and
/// `.widget_preview/` in the tree. Under `apps/pos/build/` it reaches a firebase crashlytics
/// transform directory that no longer exists, and dies with a `PathNotFoundException` — a
/// traversal failure, not a format complaint, so it formats nothing at all and `check` can never
/// finish. Naming the source roots is the only way to keep those directories out.
///
/// Derived, never written out: a package or a tool added to the lists above joins this list by
/// itself, and the `check formats the source roots by name` test fails when one is forgotten.
final formatTargets = <String>[
  for (final package in packages) ...[
    '${package.directory}/lib',
    '${package.directory}/test',
  ],
  for (final directory in _packageToolDirectories) '$directory/tool',
  for (final tool in toolDirectories) ...[
    '$tool/bin',
    '$tool/lib',
    '$tool/test',
  ],
];

/// Where the backend a `lokal` app talks to listens (`environment.dart`: `http://localhost:4000`).
const _localBackendPort = 'tcp:4000';

const _app = 'apps/pos';

const _pubGet = Step('dart', ['pub', 'get'], '.');

/// Resolve each tool under `tools/` as its own package, one `dart pub get` per directory.
///
/// They are deliberately not members of the root workspace (their `pubspec.yaml` say so, for two
/// reasons: a tool must run before the workspace resolves, and it must not add a dependency to
/// the app's graph). The consequence is that the root `dart pub get` never writes a
/// `.dart_tool/package_config.json` for them, and a fresh checkout does not have one either
/// because `.dart_tool/` is gitignored. `dart analyze` from the root walks into `tools/` anyway,
/// finds no config there, falls back to the root one, and then `package:dev` and friends do not
/// exist: hundreds of `Target of URI doesn't exist` issues and exit code 3.
///
/// Resolving them here is what makes the analysis path exist without touching the workspace
/// list, which the two design reasons forbid. Derived from [toolDirectories], so a tool added
/// there is resolved by this list by itself, and the `check` test fails when one is forgotten.
final _toolPubGet = [
  for (final tool in toolDirectories) Step('dart', ['pub', 'get'], tool),
];

/// The format check, shared by `format` and `check`.
///
/// One `Step`, one list of targets: a second literal here would be [formatTargets] written down a
/// second time, and that copy is what stops growing when a package joins the workspace.
final _format = Step(
  'dart',
  ['format', '--output=none', '--set-exit-if-changed', ...formatTargets],
  '.',
);

/// The commands for [argv], or a [UsageException].
///
/// [hasTests] says whether a package directory has a `test/` folder. `dart test` and
/// `flutter test` exit non-zero in one that does not, and CI skips such a package, so this does.
List<Step> plan(
  List<String> argv, {
  required bool Function(String directory) hasTests,
}) {
  if (argv.isEmpty) throw UsageException(usage);
  final task = argv.first;
  final rest = argv.sublist(1);

  return switch (task) {
    'setup' => [_pubGet],
    'run' => [
        Step('flutter', ['run', ...rest], _app)
      ],
    'build' => [_build(rest)],
    'windows' => _windows(rest),
    'reverse' => [
        Step('adb', [...rest, 'reverse', _localBackendPort, _localBackendPort],
            '.'),
      ],
    'gen' => [
        for (final directory in _generating)
          Step('dart', ['run', 'build_runner', 'build', ...rest], directory),
      ],
    'l10n' => [
        Step('flutter', ['gen-l10n', ...rest], _app)
      ],
    'icons' => [
        Step('dart', ['run', 'flutter_launcher_icons', ...rest], _app),
        // Windows needs a second pass: `flutter_launcher_icons` writes a single-size `.ico`
        // and Windows asks the shell for six sizes. See `tool/generate_windows_icon.dart`.
        // Android is unaffected by this step, so it is safe to run with Windows unbuilt.
        Step('dart', ['run', 'tool/generate_windows_icon.dart'], _app),
      ],
    'guard' => [const Step.builtin('no-flutter-imports', _pure)],
    'gen-check' => [Step.builtin('gen-fresh', _generatingOf(rest))],
    'dispatch' => _dispatch(rest),
    'test' => _tests(rest, hasTests),
    'format' => [_format],
    'check' => [
        _pubGet,
        ..._toolPubGet,
        _format,
        const Step('dart', ['analyze'], '.'),
        const Step.builtin('gen-fresh', _generating),
        const Step.builtin('no-flutter-imports', _pure),
        ..._tests(const [], hasTests),
        const Step('dart', ['run', 'tools/rule_lint/bin/rule_lint.dart'], '.'),
      ],
    _ => throw UsageException('unknown task "$task"\n$usage'),
  };
}

// The mode is the first word only when it is one; a flag in first place is a flag for
// flutter, and the mode stays debug.
//
// `staging` is the word a person types; `profile` is what Flutter calls the build type behind
// it. Typing Flutter's internal name would make the command read as if it were about profiling,
// which is not what this build is for — see `plan/staging/README.md` §3.
const _buildModes = {
  'debug': 'debug',
  'release': 'release',
  'staging': 'profile'
};

Step _build(List<String> rest) {
  final first = rest.isEmpty ? null : rest.first;
  final mode = _buildModes[first] ?? 'debug';
  // The word is consumed only when it really was a mode word, so
  // `build --dart-define=PN_X=staging` keeps its argument.
  final flags = _buildModes.containsKey(first) ? rest.sublist(1) : rest;
  return Step('flutter', ['build', 'apk', '--$mode', ...flags], _app);
}

/// The Windows side: run, build, or package.
///
/// A separate task from `build` because it produces a different artifact with a different
/// follow-up. `msix` exists for exactly one thing — a tapped `https` link in a browser, which
/// Windows resolves through the registry and only a packaged app can register for. The
/// command-line path (`windows -- <url>`) needs no package at all.
List<Step> _windows(List<String> rest) {
  final first = rest.isEmpty ? null : rest.first;

  if (first == 'msix') {
    final flags = rest.sublist(1);
    return [
      // The packager builds a release Windows app itself when the output is missing, but doing
      // it here means the build failure is reported as a build failure.
      const Step('flutter', ['build', 'windows', '--release'], _app),
      // `--install-certificate false` is not optional: the packager otherwise asks "install the
      // certificate?" and waits on a console. That prompt needs admin, so it cannot be answered
      // here — and a task that can hang forever is not a task (it cost a 600s timeout once).
      Step(
        'dart',
        ['run', 'msix:create', '--install-certificate', 'false', ...flags],
        _app,
      ),
    ];
  }

  if (first == 'debug' || first == 'release') {
    return [
      Step('flutter', ['build', 'windows', '--$first', ...rest.sublist(1)],
          _app),
    ];
  }

  // Default: run. Anything after the task name goes to `flutter run` untouched, so a link can
  // be handed to the app with `windows -- <url>`.
  return [
    Step('flutter', ['run', '-d', 'windows', ...rest], _app),
  ];
}

// The directories `gen-check` compares: all of them, or the one named.
List<String> _generatingOf(List<String> rest) {
  if (rest.isEmpty) return _generating;

  final name = rest.first;
  final matching = packages.where((package) => package.name == name);
  if (matching.isEmpty || !_generating.contains(matching.single.directory)) {
    final known = packages
        .where((package) => _generating.contains(package.directory))
        .map((package) => package.name)
        .join(', ');
    throw UsageException(
      '"$name" has no generated code, or is not a package (one of: $known)',
    );
  }
  return [matching.single.directory];
}

/// Checks one `release-dispatch.yml` combination and plans nothing to run.
///
/// Two outputs, because the dispatcher job needs both: exit 0 and no output for an accepted
/// combination, a `::error::` line and a non-zero exit for a refused one. `bin/dev.dart` already
/// turns [UsageException] into that second shape (stderr plus exit 64), so the gate needs no
/// process of its own.
///
/// The `::error::` prefix is what GitHub Actions turns into an annotation on the run page. Plain
/// stderr in a workflow step shows in the raw log, which nobody reads when the run went red.
List<Step> _dispatch(List<String> rest) {
  final DispatchAction action;
  try {
    action = planDispatch(parseDispatchRequest(rest));
  } on DispatchRejection catch (refusal) {
    throw UsageException('::error::${refusal.message}');
  }
  // Silence is the success signal here: the job's exit code is what the YAML gates on, and a
  // "looks fine" line would only invite someone to parse it instead.
  assert(action.workflows.length > 0);
  return const [];
}

List<Step> _tests(List<String> rest, bool Function(String) hasTests) {
  if (rest.isEmpty) {
    return [
      for (final package in packages)
        if (hasTests(package.directory)) _testStep(package),
    ];
  }

  final name = rest.first;
  final matching = packages.where((package) => package.name == name);
  if (matching.isEmpty) {
    final known = packages.map((package) => package.name).join(', ');
    throw UsageException('unknown package "$name" (one of: $known)');
  }
  final package = matching.single;
  if (!hasTests(package.directory)) {
    throw UsageException(
        '$name has no tests yet (${package.directory}/test does not exist)');
  }
  return [_testStep(package)];
}

Step _testStep(Package package) => Step(
    package.flutter ? 'flutter' : 'dart', const ['test'], package.directory);
