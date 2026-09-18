/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:path/path.dart' as p;

/// One string literal that should have come from the dictionary.
class Finding {
  const Finding({required this.line, required this.text});

  /// 1-based.
  final int line;

  /// The literal as written, quotes included.
  final String text;

  @override
  String toString() => 'line $line: $text';
}

/// Where a literal is text the cashier reads: the first argument of `Text(`, or one of the
/// named arguments Flutter widgets show. Technical arguments (`key:`, `heroTag:`, ...) are not
/// in the list on purpose.
const _shownArguments =
    'labelText|hintText|helperText|errorText|counterText|prefixText|suffixText|'
    'tooltip|semanticLabel|semanticsLabel|title|subtitle|label|content|message|hint|text';

final _shownLiteral = RegExp(
  r'\b(?:Text\(|(?:' + _shownArguments + r''')\s*:)\s*('[^']*'|"[^"]*")''',
);

final _interpolation = RegExp(r'\$\{[^}]*\}|\$\w+');
final _letter = RegExp(r'\p{L}', unicode: true);

/// Whether [literal] holds a word. Figures, symbols and pure interpolation are not language:
/// there is nothing in them to translate.
bool _hasWords(String literal) =>
    _letter.hasMatch(literal.replaceAll(_interpolation, ''));

// A line that is a comment. Docs and notes mention widgets and strings without drawing them.
final _commentLine = RegExp(r'^\s*(//|/\*|\*)');

// The exception marker. The reason after the colon is required: an exception nobody can explain
// is a hole in the check, the same rule as `// ignore:` in `style.md` §10.
final _excused = RegExp(r'//\s*l10n-ignore:\s*\S');

/// The user-facing string literals in [source].
List<Finding> findHardcodedStrings(String source) {
  final lines = source.split('\n');
  final found = <Finding>[];
  for (final m in _shownLiteral.allMatches(source)) {
    if (!_hasWords(m.group(1)!)) continue;
    final line = '\n'.allMatches(source.substring(0, m.start)).length;
    final text = lines[line];
    if (_commentLine.hasMatch(text) || _excused.hasMatch(text)) continue;
    found.add(Finding(line: line + 1, text: m.group(1)!));
  }
  return found;
}

/// A [Finding] and the file it is in.
class FileFinding {
  const FileFinding(this.path, this.finding);

  final String path;
  final Finding finding;

  @override
  String toString() => '$path:${finding.line}: ${finding.text}';
}

// The generated localizations are the dictionary itself, and generated code holds no text the
// cashier reads.
bool _isGenerated(String path) =>
    p.split(path).contains('l10n') ||
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart');

/// Every hardcoded string in the `.dart` files under [root].
List<FileFinding> scanTree(Directory root) => [
      for (final file in root.listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart') && !_isGenerated(file.path))
          for (final finding in findHardcodedStrings(file.readAsStringSync()))
            FileFinding(file.path, finding),
    ];
