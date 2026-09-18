/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Structural checks for the agent rule files in this repo.
///
/// The repo rule is "one source, the rest point at it": `.claude/rules/*.md` holds the
/// rule content, `AGENTS.md` is an index, `.github/copilot-instructions.md` is a pointer.
/// Nothing here can be enforced by a compiler, and `grep -c` cannot tell a real
/// duplication from an incidental shared phrase — so the checks are written out and
/// tested, rather than typed into a shell one-liner.
///
/// Every function is pure: input is file contents, output is findings. Reading from disk
/// happens in `bin/rule_lint.dart`, which keeps these testable without a fixture tree.
library;

/// A rule file that the repo actually has on disk.
class RuleFile {
  const RuleFile({required this.name, required this.content});

  /// File name only, e.g. `git.md` — not the path.
  final String name;
  final String content;
}

/// One problem found. `check` is a stable identifier so tests can assert on it.
class Finding {
  const Finding({required this.check, required this.message, this.detail});

  final String check;
  final String message;

  /// The offending text, when there is one worth showing.
  final String? detail;

  @override
  String toString() =>
      detail == null ? '$check: $message' : '$check: $message\n    $detail';
}

/// Every `.claude/rules/<name>.md` path mentioned anywhere in [markdown].
///
/// Used for the orphan check: a rule file that is never named at all cannot be found.
/// Deliberately lenient — it counts prose mentions as well as links — because flagging a
/// file that *is* mentioned would make the check cry wolf.
Set<String> mentionedRuleFiles(String markdown) => _ruleFilePattern
    .allMatches(markdown)
    .map((match) => match.group(1)!)
    .toSet();

/// Every `.claude/rules/<name>.md` that [markdown] **links to** as a markdown link target.
///
/// Used for the dangling check, and only there. The distinction matters: a rule file may
/// legitimately name a rule path that is not in this repo's `.claude/rules/` — a historical
/// note, or a file that lives in another repo. That is prose, not a pointer into this repo,
/// and treating it as one reports a link that was never broken.
Set<String> linkedRuleFiles(String markdown) {
  final targets = RegExp(r'\]\(([^)]+)\)')
      .allMatches(markdown)
      .map((match) => match.group(1)!)
      .join('\n');
  return mentionedRuleFiles(targets);
}

final _ruleFilePattern = RegExp(r'\.claude/rules/([A-Za-z0-9._-]+\.md)');

/// Reduces markdown to a lowercase word list, so two files can be compared on prose.
///
/// Link targets are dropped but their labels kept: the paths are pointers, not rule text,
/// and counting them would make every cross-reference look like duplication.
List<String> normalizeWords(String markdown) {
  var text = markdown;
  text = text.replaceAll(RegExp(r'```[A-Za-z0-9]*'), ' ');
  text = text.replaceAllMapped(
      RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => ' ${m.group(1)} ');
  text = text.replaceAll(RegExp(r'[*_`>#|]'), ' ');
  text = text.toLowerCase();
  return text
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList();
}

/// Maximal runs of at least [minWords] consecutive words that occur verbatim in both.
///
/// Runs are merged before returning: a copied paragraph shares many overlapping n-grams,
/// and reporting each one separately buries the actual duplicated passage.
List<String> sharedPassages(List<String> a, List<String> b,
    {int minWords = 8}) {
  if (a.length < minWords || b.length < minWords) return const [];

  final inA = <String>{};
  for (var i = 0; i + minWords <= a.length; i++) {
    inA.add(a.sublist(i, i + minWords).join(' '));
  }

  final passages = <String>[];
  int? runStart;
  for (var i = 0; i + minWords <= b.length; i++) {
    final matches = inA.contains(b.sublist(i, i + minWords).join(' '));
    if (matches) {
      runStart ??= i;
    } else if (runStart != null) {
      passages.add(b.sublist(runStart, i + minWords - 1).join(' '));
      runStart = null;
    }
  }
  if (runStart != null) passages.add(b.sublist(runStart).join(' '));
  return passages;
}

/// Words per shared passage before it counts as copied rule text.
///
/// Tuned against a known-bad fixture (rule text copied verbatim into an index file, which is
/// the failure this check exists to catch) rather than guessed — see `test/rule_lint_test.dart`.
const int kDuplicationMinWords = 12;

/// Checks that every rule file is indexed, and every index entry resolves.
///
/// Both directions matter. A rule file missing from the index is invisible — no agent will
/// read a rule it is never pointed at — and a link to a file that does not exist is a
/// pointer into nothing.
List<Finding> checkIndex({
  required Set<String> ruleFileNames,
  required String agentsMd,
  required String copilotInstructions,
}) {
  final findings = <Finding>[];
  final indexed = linkedRuleFiles(agentsMd);

  // Orphan: a file that is never named anywhere. Lenient on purpose — a prose mention is
  // enough to make a rule findable, and the point of this check is reachability.
  final mentioned = mentionedRuleFiles(agentsMd);
  for (final name in ruleFileNames.difference(mentioned).toList()..sort()) {
    findings.add(
      Finding(
        check: 'index-orphan',
        message:
            'rule file is never mentioned in AGENTS.md, so no agent will find it',
        detail: '.claude/rules/$name',
      ),
    );
  }

  // Dangling: a link target with no file behind it. Strict — only real links count.
  for (final name in indexed.difference(ruleFileNames).toList()..sort()) {
    findings.add(
      Finding(
        check: 'index-dangling',
        message: 'AGENTS.md links a rule file that does not exist',
        detail: '.claude/rules/$name',
      ),
    );
  }

  if (mentionedRuleFiles(copilotInstructions).isEmpty &&
      !copilotInstructions.contains('AGENTS.md')) {
    findings.add(
      const Finding(
        check: 'pointer-missing',
        message:
            'copilot-instructions.md must point at AGENTS.md or .claude/rules/, '
            'not restate the rules',
      ),
    );
  }

  return findings;
}

/// Checks that rule text is not restated in the index or the pointer.
///
/// This is the rule the plan cares most about, and the one that is easiest to let rot:
/// a summary is a second copy, and a second copy drifts.
List<Finding> checkNoDuplication({
  required List<RuleFile> ruleFiles,
  required String agentsMd,
  required String copilotInstructions,
  int minWords = kDuplicationMinWords,
}) {
  final findings = <Finding>[];
  final indexWords = normalizeWords(agentsMd);
  final pointerWords = normalizeWords(copilotInstructions);

  for (final rule in ruleFiles) {
    // `project.md` describes the repo itself, and `AGENTS.md` is required to carry a short
    // project overview. Overlap there is the design, not a defect, so it is excluded —
    // the rule being enforced is about *rule* text.
    if (rule.name == 'project.md') continue;

    final ruleWords = normalizeWords(rule.content);
    for (final passage
        in sharedPassages(ruleWords, indexWords, minWords: minWords)) {
      findings.add(
        Finding(
          check: 'duplication-index',
          message:
              'AGENTS.md restates rule text from .claude/rules/${rule.name} '
              '(${passage.split(' ').length} words)',
          detail: passage,
        ),
      );
    }
    for (final passage
        in sharedPassages(ruleWords, pointerWords, minWords: minWords)) {
      findings.add(
        Finding(
          check: 'duplication-pointer',
          message: 'copilot-instructions.md restates rule text from '
              '.claude/rules/${rule.name} (${passage.split(' ').length} words)',
          detail: passage,
        ),
      );
    }
  }

  return findings;
}

/// Checks that `AGENTS.md` keeps the shape of an index.
///
/// Two properties, both of which an index can easily violate. A rule entry must **point**
/// somewhere — a summary with no link is a rule that lives only in `AGENTS.md`, which is
/// the first half of the duplication problem. And it must be **short** — a long entry has
/// stopped being a summary and become a rule body, which is the second half.
///
/// A table row is a rule entry only when it names a rule file in some column. The header
/// and separator rows describe the columns, so they are identified structurally — by the
/// separator that follows the header — rather than by guessing at their cell contents.
List<Finding> checkIndexShape(
    {required String agentsMd, int maxRuleWords = 25}) {
  final findings = <Finding>[];
  final lines = agentsMd.split('\n');

  var inRules = false;
  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();

    if (trimmed.startsWith('## ')) {
      inRules = trimmed.toLowerCase().contains('rule');
      continue;
    }
    if (!inRules) continue;
    if (trimmed.isEmpty) continue;

    final isBullet = trimmed.startsWith('- ');
    final isTableRow = trimmed.startsWith('|') && trimmed.endsWith('|');
    if (!isBullet && !isTableRow) continue;

    if (isTableRow) {
      if (_isTableSeparator(trimmed)) continue;
      // The row above a separator is the header.
      final next = i + 1 < lines.length ? lines[i + 1].trim() : '';
      if (next.startsWith('|') && _isTableSeparator(next)) continue;
    }

    final linksToRule = linkedRuleFiles(trimmed).isNotEmpty;
    if (!linksToRule) {
      findings.add(
        Finding(
          check: 'index-shape',
          message:
              'AGENTS.md rule entry has no link to .claude/rules/ — a rule that '
              'lives only here is a rule with no single source',
          detail: 'line ${i + 1}: ${_excerpt(trimmed)}',
        ),
      );
      continue;
    }

    final words = normalizeWords(trimmed);
    if (words.length > maxRuleWords) {
      findings.add(
        Finding(
          check: 'index-shape',
          message:
              'AGENTS.md rule entry is ${words.length} words (max $maxRuleWords) — '
              'a rule body belongs in .claude/rules/, leave a one-line summary and a link',
          detail: 'line ${i + 1}: ${_excerpt(trimmed)}',
        ),
      );
    }
  }

  return findings;
}

/// True for a markdown table separator row, e.g. `| - | ------ |`.
bool _isTableSeparator(String row) {
  final cells =
      row.split('|').map((cell) => cell.trim()).where((c) => c.isNotEmpty);
  return cells.isNotEmpty &&
      cells.every((cell) => RegExp(r'^:?-+:?$').hasMatch(cell));
}

String _excerpt(String line) =>
    line.length > 100 ? '${line.substring(0, 100)}…' : line;
