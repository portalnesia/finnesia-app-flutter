/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';
import 'dart:io';

import 'package:dev/verify.dart';
import 'package:test/test.dart';

/// A throwaway repo on disk, so the checks run against real files and nothing else.
class Repo {
  Repo() : root = Directory.systemTemp.createTempSync('dev_verify_');

  final Directory root;

  File file(String relative) => File('${root.path}/$relative');

  void write(String relative, String content) {
    final f = file(relative);
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(utf8.encode(content));
  }

  String read(String relative) => utf8.decode(file(relative).readAsBytesSync());

  bool exists(String relative) => file(relative).existsSync();

  void dispose() => root.deleteSync(recursive: true);
}

void main() {
  late Repo repo;
  setUp(() => repo = Repo());
  tearDown(() => repo.dispose());

  // What the check protects: someone edits a model, forgets `build_runner`, and the stale
  // generated file still compiles. The check regenerates and compares.
  group('staleGenerated', () {
    setUp(() {
      repo.write('packages/a/lib/a.dart', 'source a');
      repo.write('packages/a/lib/a.g.dart', 'generated a v1');
      repo.write('packages/a/lib/a.freezed.dart', 'freezed a v1');
    });

    Future<List<String>> check(Future<void> Function() regenerate) =>
        staleGenerated(
          root: repo.root,
          packages: ['packages/a'],
          regenerate: regenerate,
        );

    test('finds nothing when regenerating changes nothing', () async {
      expect(await check(() async {}), isEmpty);
    });

    test('finds a generated file that regenerating would change', () async {
      final stale = await check(() async {
        repo.write('packages/a/lib/a.g.dart', 'generated a v2');
      });

      expect(stale, ['packages/a/lib/a.g.dart']);
    });

    test('finds a generated file that is missing altogether', () async {
      final stale = await check(() async {
        repo.write('packages/a/lib/b.g.dart', 'generated b');
      });

      expect(stale, ['packages/a/lib/b.g.dart']);
    });

    test('finds a generated file that regenerating would delete', () async {
      final stale = await check(() async {
        repo.file('packages/a/lib/a.freezed.dart').deleteSync();
      });

      expect(stale, ['packages/a/lib/a.freezed.dart']);
    });

    test('names every one of them, in a stable order', () async {
      final stale = await check(() async {
        repo.write('packages/a/lib/a.g.dart', 'v2');
        repo.write('packages/a/lib/a.freezed.dart', 'v2');
      });

      expect(stale, [
        'packages/a/lib/a.freezed.dart',
        'packages/a/lib/a.g.dart',
      ]);
    });

    // Line endings are the checkout's business (git converts them), not a stale model. Reported
    // as stale, every Windows developer would be told to regenerate files that are fine.
    test('does not mind a different line ending', () async {
      repo.write('packages/a/lib/a.g.dart', 'line 1\r\nline 2\r\n');

      final stale = await check(() async {
        repo.write('packages/a/lib/a.g.dart', 'line 1\nline 2\n');
      });

      expect(stale, isEmpty);
    });

    // `flutter gen-l10n` writes `app_localizations*.dart` from the ARB files. An ARB edited
    // without regenerating leaves the old words in the app, and nothing else notices.
    test(
        'finds a stale localizations file: the ARB was edited, gen-l10n forgotten',
        () async {
      repo.write('packages/a/lib/l10n/app_localizations_id.dart', 'Coba lagi');

      final stale = await check(() async {
        repo.write('packages/a/lib/l10n/app_localizations_id.dart', 'Ulangi');
      });

      expect(stale, ['packages/a/lib/l10n/app_localizations_id.dart']);
    });

    test('finds a localizations file for a language that was added', () async {
      final stale = await check(() async {
        repo.write(
            'packages/a/lib/l10n/app_localizations_en.dart', 'Try again');
      });

      expect(stale, ['packages/a/lib/l10n/app_localizations_en.dart']);
    });

    test('does not take a hand-written file beside them for generated',
        () async {
      repo.write('packages/a/lib/l10n/notes.dart', 'written by hand');

      final stale = await check(() async {
        repo.write('packages/a/lib/l10n/notes.dart', 'edited');
      });

      expect(stale, isEmpty);
    });

    test('only looks at generated files, not at source', () async {
      final stale = await check(() async {
        repo.write('packages/a/lib/a.dart', 'source a, edited');
      });

      expect(stale, isEmpty);
    });

    // The check is a question, not a fix: it must leave the working tree as it found it, or a
    // "check" would quietly rewrite the developer's files.
    group('leaves the working tree as it found it', () {
      test('a changed file is put back, byte for byte', () async {
        repo.write('packages/a/lib/a.g.dart', 'crlf\r\nfile\r\n');

        await check(() async {
          repo.write('packages/a/lib/a.g.dart', 'regenerated');
        });

        expect(repo.read('packages/a/lib/a.g.dart'), 'crlf\r\nfile\r\n');
      });

      test('a file that was created is removed again', () async {
        await check(() async {
          repo.write('packages/a/lib/b.g.dart', 'generated b');
        });

        expect(repo.exists('packages/a/lib/b.g.dart'), isFalse);
      });

      test('a file that was deleted is brought back', () async {
        await check(() async {
          repo.file('packages/a/lib/a.freezed.dart').deleteSync();
        });

        expect(repo.read('packages/a/lib/a.freezed.dart'), 'freezed a v1');
      });

      test('even when regenerating fails, and the failure still surfaces',
          () async {
        await expectLater(
          check(() async {
            repo.write('packages/a/lib/a.g.dart', 'half written');
            throw StateError('build_runner failed');
          }),
          throwsA(isA<StateError>()),
        );

        expect(repo.read('packages/a/lib/a.g.dart'), 'generated a v1');
      });
    });

    test('looks in test/ as well as lib/', () async {
      repo.write('packages/a/test/t.g.dart', 'generated t v1');

      final stale = await check(() async {
        repo.write('packages/a/test/t.g.dart', 'generated t v2');
      });

      expect(stale, ['packages/a/test/t.g.dart']);
    });

    test('ignores what build_runner keeps under .dart_tool and build',
        () async {
      final stale = await check(() async {
        repo.write('packages/a/.dart_tool/x.g.dart', 'cache');
        repo.write('packages/a/build/y.freezed.dart', 'output');
      });

      expect(stale, isEmpty);
    });
  });

  // `pn_pos` and `pn_types` must stay free of Flutter: that is what lets their tests run with
  // `dart test` in milliseconds. `dart analyze` does not catch it in a pub workspace, which is why
  // this is a text check (`.claude/rules/architecture.md` §3).
  group('flutterImports', () {
    List<String> scan() => flutterImports(
          root: repo.root,
          directories: ['packages/pn_pos/lib'],
        );

    test('finds an import of flutter', () {
      repo.write(
        'packages/pn_pos/lib/src/x.dart',
        "import 'package:flutter/material.dart';\n",
      );

      expect(scan(), [
        "packages/pn_pos/lib/src/x.dart:1: import 'package:flutter/material.dart';"
      ]);
    });

    test('finds a flutter plugin too, as the CI check does', () {
      repo.write(
        'packages/pn_pos/lib/y.dart',
        "import 'dart:math';\nimport 'package:flutter_blue_plus/x.dart';\n",
      );

      expect(scan(), hasLength(1));
      expect(scan().single, contains('y.dart:2'));
    });

    test('finds a double-quoted import', () {
      repo.write(
        'packages/pn_pos/lib/z.dart',
        'import "package:flutter/widgets.dart";\n',
      );

      expect(scan(), hasLength(1));
    });

    test('finds nothing in a package that does not import flutter', () {
      repo.write(
        'packages/pn_pos/lib/ok.dart',
        "import 'dart:math';\nimport 'package:pn_types/src/a.dart';\n",
      );

      expect(scan(), isEmpty);
    });

    test('does not mistake a comment or a longer word for an import', () {
      repo.write(
        'packages/pn_pos/lib/c.dart',
        "// import 'package:flutter/material.dart';\n"
            "final s = \"import 'package:flutter/x.dart'\";\n"
            "import 'package:not_flutter/x.dart';\n",
      );

      expect(scan(), isEmpty);
    });

    test('skips a directory that does not exist', () {
      expect(scan(), isEmpty);
    });
  });
}
