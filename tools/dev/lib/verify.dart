/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// The two checks of `ci.yml` that are more than one command: they compare or read files.
///
/// Neither writes to git. CI did the first with `git add -N`, which changes the index; a script a
/// developer runs by hand must not, so it compares files on disk and puts them back as it found
/// them.
library;

import 'dart:convert';
import 'dart:io';

typedef _Snapshot = Map<String, List<int>>;

/// The generated files of [packages] (build_runner's and gen-l10n's) that regenerating would
/// change, as paths relative to [root].
///
/// A model is edited, `build_runner` is forgotten (or an ARB file is, and `gen-l10n`), and the stale generated file still compiles:
/// a wrong behaviour that no build reports. [regenerate] runs the generators; this compares what
/// was on disk before with what is there after, and names every file that differs, is new, or
/// went away.
///
/// A question, not a fix: the files are put back byte for byte afterwards, also when
/// [regenerate] throws (and the exception still surfaces), so checking never rewrites the
/// developer's working tree.
///
/// Line endings do not count as a difference: they are the checkout's business, and a Windows
/// developer must not be told to regenerate files that are fine.
Future<List<String>> staleGenerated({
  required Directory root,
  required List<String> packages,
  required Future<void> Function() regenerate,
}) async {
  final before = _snapshot(root, packages);
  try {
    await regenerate();
    final after = _snapshot(root, packages);
    return [
      for (final path in {...before.keys, ...after.keys})
        if (!_sameText(before[path], after[path])) path,
    ]..sort();
  } finally {
    _restore(root, packages, before);
  }
}

/// The lines of Dart under [directories] (relative to [root]) that import Flutter, as
/// `path:line: text`.
///
/// `pn_types` and `pn_pos` must stay free of Flutter: that is what lets their tests run with
/// `dart test` in milliseconds, and keeps money logic out of widgets. `dart analyze` does not
/// catch it in a pub workspace (they share one package config that carries Flutter), so it is a
/// text check (`.claude/rules/architecture.md` §3). It matches `package:flutter` as a prefix, so
/// a Flutter plugin such as `flutter_blue_plus` counts too, as it does in CI.
List<String> flutterImports({
  required Directory root,
  required List<String> directories,
}) {
  final import = RegExp('''^import\\s+['"]package:flutter''');
  final found = <String>[];
  for (final directory in directories) {
    for (final file
        in _files(root, directory, (name) => name.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (import.hasMatch(lines[i])) {
          found.add('${_relative(root, file)}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
  }
  return found..sort();
}

// `*.g.dart` and `*.freezed.dart` come from build_runner; `app_localizations*.dart` come from
// `flutter gen-l10n` (`output-localization-file` in `l10n.yaml`), one per language.
bool _isGenerated(String name) =>
    name.endsWith('.g.dart') ||
    name.endsWith('.freezed.dart') ||
    (name.startsWith('app_localizations') && name.endsWith('.dart'));

// Generated code sits next to its source, in `lib/` and `test/`. `.dart_tool/` and `build/`
// hold build_runner's own cache and output, not the sources, and are not looked at.
const _generatedIn = ['lib', 'test'];

_Snapshot _snapshot(Directory root, List<String> packages) => {
      for (final package in packages)
        for (final where in _generatedIn)
          for (final file in _files(root, '$package/$where', _isGenerated))
            _relative(root, file): file.readAsBytesSync(),
    };

Iterable<File> _files(
  Directory root,
  String directory,
  bool Function(String name) wanted,
) sync* {
  final dir = Directory('${root.path}/$directory');
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is File && wanted(entity.uri.pathSegments.last)) yield entity;
  }
}

String _relative(Directory root, File file) =>
    file.path.substring(root.path.length + 1).replaceAll('\\', '/');

String? _text(List<int>? bytes) => bytes == null
    ? null
    : utf8.decode(bytes, allowMalformed: true).replaceAll('\r\n', '\n');

bool _sameText(List<int>? a, List<int>? b) => _text(a) == _text(b);

void _restore(Directory root, List<String> packages, _Snapshot before) {
  final now = _snapshot(root, packages);
  for (final path in now.keys) {
    if (!before.containsKey(path)) File('${root.path}/$path').deleteSync();
  }
  for (final entry in before.entries) {
    final current = now[entry.key];
    if (current == null || !_sameBytes(current, entry.value)) {
      final file = File('${root.path}/${entry.key}');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(entry.value);
    }
  }
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
