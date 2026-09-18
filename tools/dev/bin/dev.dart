/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Runs the commands `lib/dev.dart` plans, one after another, stopping at the first that fails.
///
/// Usage: `./dev <task> [args...]` (the shims in the repo root call this file), or directly
/// `dart run tools/dev/bin/dev.dart <task> [args...]`.
library;

import 'dart:io';

import 'package:dev/dev.dart';
import 'package:dev/verify.dart';

const _helpWords = {'help', '-h', '--help'};

Future<void> main(List<String> args) async {
  if (args.length == 1 && _helpWords.contains(args.first)) {
    stdout.write(usage);
    return;
  }

  // Resolved from the script location, not the working directory, so `./dev` works from any
  // directory of the repo.
  final root = File(Platform.script.toFilePath()).parent.parent.parent.parent;

  final List<Step> steps;
  try {
    steps = plan(
      args,
      hasTests: (directory) =>
          Directory('${root.path}/$directory/test').existsSync(),
    );
  } on UsageException catch (usageError) {
    stderr.writeln(usageError.message);
    exitCode = 64; // EX_USAGE
    return;
  }

  for (final step in steps) {
    stdout.writeln('\n> $step');
    if (step.builtin != null) {
      final code = await _runBuiltin(step, root);
      if (code != 0) {
        exitCode = code;
        return;
      }
      continue;
    }
    // `flutter`, `dart` and `adb` are `.bat` / `.cmd` files on Windows, which only a shell runs.
    final process = await Process.start(
      step.executable,
      step.args,
      workingDirectory: '${root.path}/${step.directory}',
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );
    final code = await process.exitCode;
    if (code != 0) {
      exitCode = code;
      return;
    }
  }
}

Future<int> _runBuiltin(Step step, Directory root) => switch (step.builtin) {
      'gen-fresh' => _genFresh(step.args, root),
      'no-flutter-imports' => Future.value(_noFlutterImports(step.args, root)),
      final other => throw StateError('no built-in check "$other"'),
    };

Future<int> _genFresh(List<String> packages, Directory root) async {
  final List<String> stale;
  try {
    stale = await staleGenerated(
      root: root,
      packages: packages,
      regenerate: () async {
        for (final package in packages) {
          stdout.writeln('  build_runner: $package');
          // Quiet unless it fails: a passing check should not print a page of build output.
          final result = await Process.run(
            'dart',
            ['run', 'build_runner', 'build'],
            workingDirectory: '${root.path}/$package',
            runInShell: Platform.isWindows,
          );
          if (result.exitCode != 0) {
            stdout.write(result.stdout);
            stderr.write(result.stderr);
            throw StateError('build_runner failed in $package');
          }
          // A package with an `l10n.yaml` also generates its localizations from the ARB files.
          if (File('${root.path}/$package/l10n.yaml').existsSync()) {
            stdout.writeln('  gen-l10n: $package');
            final l10n = await Process.run(
              'flutter',
              ['gen-l10n'],
              workingDirectory: '${root.path}/$package',
              runInShell: Platform.isWindows,
            );
            if (l10n.exitCode != 0) {
              stdout.write(l10n.stdout);
              stderr.write(l10n.stderr);
              throw StateError('flutter gen-l10n failed in $package');
            }
          }
        }
      },
    );
  } on StateError catch (failure) {
    stderr.writeln(failure.message);
    return 1;
  }

  if (stale.isEmpty) {
    stdout.writeln('  generated code is up to date');
    return 0;
  }
  stderr.writeln('Generated files are stale:');
  for (final path in stale) {
    stderr.writeln('  $path');
  }
  stderr.writeln(
    "Run './dev gen' (or './dev l10n' for the ARB files) and commit the result. "
    'Nothing was changed by this check.',
  );
  return 1;
}

int _noFlutterImports(List<String> directories, Directory root) {
  final found = flutterImports(root: root, directories: directories);
  if (found.isEmpty) {
    stdout.writeln('  no flutter import in ${directories.join(', ')}');
    return 0;
  }
  stderr.writeln(
    'These packages must stay free of Flutter (.claude/rules/architecture.md §3):',
  );
  for (final line in found) {
    stderr.writeln('  $line');
  }
  return 1;
}
