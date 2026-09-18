/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Reads this repo's rule files and reports structural problems.
///
/// Exits non-zero when there is a finding, so it can be dropped into CI and into the
/// completion gate in `.claude/rules/testing.md`.
///
/// Usage: `dart run tools/rule_lint/bin/rule_lint.dart`
library;

import 'dart:io';

import 'package:rule_lint/rule_lint.dart';

void main(List<String> args) {
  // Resolved from the script location, not the working directory, so the check works
  // whichever directory it is invoked from.
  final repoRoot = _repoRoot();
  final rulesDir = Directory('${repoRoot.path}/.claude/rules');
  final agentsFile = File('${repoRoot.path}/AGENTS.md');
  final copilotFile = File('${repoRoot.path}/.github/copilot-instructions.md');

  for (final file in [agentsFile, copilotFile]) {
    if (!file.existsSync()) {
      stderr.writeln('MISSING: ${file.path}');
      exitCode = 2;
      return;
    }
  }

  final ruleFiles = rulesDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.md'))
      .map((file) => RuleFile(
            name: file.uri.pathSegments.last,
            content: file.readAsStringSync(),
          ))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  final agentsMd = agentsFile.readAsStringSync();
  final copilotInstructions = copilotFile.readAsStringSync();
  final ruleFileNames = ruleFiles.map((rule) => rule.name).toSet();

  final findings = [
    ...checkIndex(
      ruleFileNames: ruleFileNames,
      agentsMd: agentsMd,
      copilotInstructions: copilotInstructions,
    ),
    ...checkNoDuplication(
      ruleFiles: ruleFiles,
      agentsMd: agentsMd,
      copilotInstructions: copilotInstructions,
    ),
    ...checkIndexShape(agentsMd: agentsMd),
  ];

  if (findings.isEmpty) {
    stdout.writeln(
        'OK — ${ruleFileNames.length} rule files, indexed and not duplicated.');
    return;
  }

  stderr.writeln('${findings.length} finding(s):\n');
  for (final finding in findings) {
    stderr.writeln('  $finding');
  }
  exitCode = 1;
}

Directory _repoRoot() {
  // bin/ -> rule_lint/ -> tools/ -> repo root
  final scriptDir = File(Platform.script.toFilePath()).parent;
  return Directory(scriptDir.parent.parent.parent.path);
}
