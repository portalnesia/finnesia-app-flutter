/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Reports text written into widgets instead of coming from the dictionary
/// (`.claude/rules/style.md` §7). Exits non-zero when there is a finding.
///
/// Usage: `dart run tools/string_lint/bin/string_lint.dart`
library;

import 'dart:io';

import 'package:string_lint/string_lint.dart';

// `pn_ui` is scanned as well as the app: its widgets take their text as parameters
// (`style.md` §7.1), so a literal there is the same mistake one layer down.
const _roots = ['apps/pos/lib', 'packages/pn_ui/lib'];

void main() {
  // Resolved from the script location, not the working directory (as `rule_lint` does).
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final repoRoot = scriptDir.parent.parent.parent.path;

  final findings = <FileFinding>[];
  for (final root in _roots) {
    final dir = Directory('$repoRoot/$root');
    if (!dir.existsSync()) {
      stderr.writeln('MISSING: ${dir.path}');
      exitCode = 2;
      return;
    }
    findings.addAll(scanTree(dir));
  }

  if (findings.isEmpty) {
    stdout.writeln('OK — no hardcoded strings in ${_roots.join(', ')}.');
    return;
  }

  stderr.writeln('${findings.length} hardcoded string(s):\n');
  for (final finding in findings) {
    stderr.writeln('  $finding');
  }
  exitCode = 1;
}
