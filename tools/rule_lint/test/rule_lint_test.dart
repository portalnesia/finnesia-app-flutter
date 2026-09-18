/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Tests for the rule-file structural checks.
///
/// The detector is the thing being tested, not just the repo. A check that cannot fail is
/// indistinguishable from a repo that is clean — and this task exists precisely because a
/// "0 duplications" result was once trusted without ever proving the detector fires.
library;

import 'dart:io';

import 'package:rule_lint/rule_lint.dart';
import 'package:test/test.dart';

/// Real rule text that was once copied verbatim into an index file, kept as the fixture that
/// proves the duplication detector fires.
const _realRuleText = '''
# Testing & Verification Rules — STRICT (TDD ONLY)

## 0. Prinsip Utama (TDD WAJIB)

TDD MUTLAK — Tulis test dulu (RED) → implementasi minimal (GREEN) → refactor.
DILARANG menulis code production tanpa test yang gagal terlebih dahulu.

Laporan bug BUKAN pengecualian dari TDD. Urutan yang WAJIB untuk setiap bug:
bentuk dugaan akar masalah, tulis test yang meng-encode perilaku yang BENAR,
jalankan terhadap kode yang belum disentuh sama sekali, konfirmasi RED, baru fix.

Unit test ONLY — HARAM integration test yang butuh resource eksternal.
Semua dependency eksternal WAJIB di-mock lewat port.
''';

void main() {
  group('normalizeWords', () {
    test('keeps link labels but drops link targets', () {
      final words =
          normalizeWords('See [git.md](.claude/rules/git.md) for details.');

      // The label is prose and must survive; the path is a pointer and must not, or every
      // cross-reference in AGENTS.md would register as copied text.
      expect(words, contains('git'));
      expect(words, contains('details'));
      expect(words.any((word) => word.contains('claude')), isFalse);
      expect(words.any((word) => word.contains('rules')), isFalse);
    });

    test('drops fenced code markers but keeps the code', () {
      final words = normalizeWords('```dart\ndart pub get\n```');

      expect(words, containsAllInOrder(['dart', 'pub', 'get']));
      expect(words, isNot(contains('dartdart')));
    });
  });

  group('sharedPassages', () {
    test('finds a verbatim passage', () {
      final a = 'the quick brown fox jumps over the lazy dog and then goes home'
          .split(' ');
      final b =
          'some preamble the quick brown fox jumps over the lazy dog and then goes home end'
              .split(' ');

      final passages = sharedPassages(a, b, minWords: 5);

      expect(passages, hasLength(1));
      expect(passages.single, contains('quick brown fox'));
      expect(passages.single, contains('goes home'));
    });

    test('merges overlapping windows into one passage', () {
      // A copied paragraph shares many overlapping n-grams. Reporting each separately
      // would bury the passage that was actually copied.
      final a =
          'alpha beta gamma delta epsilon zeta eta theta iota kappa'.split(' ');
      final b =
          'alpha beta gamma delta epsilon zeta eta theta iota kappa'.split(' ');

      expect(sharedPassages(a, b, minWords: 3), hasLength(1));
    });

    test('ignores passages shorter than minWords', () {
      final a = 'one two three four five six seven'.split(' ');
      final b = 'one two three four different words entirely'.split(' ');

      expect(sharedPassages(a, b, minWords: 8), isEmpty);
    });

    test('returns nothing when either side is shorter than minWords', () {
      expect(sharedPassages(['a', 'b'], ['a', 'b'], minWords: 8), isEmpty);
      expect(sharedPassages([], [], minWords: 1), isEmpty);
    });
  });

  group('checkIndex', () {
    test('flags a rule file that no one indexes', () {
      final findings = checkIndex(
        ruleFileNames: {'git.md', 'ghost.md'},
        agentsMd: '# AGENTS.md\n\n| 0 | Git | [git.md](.claude/rules/git.md) |',
        copilotInstructions: 'See AGENTS.md.',
      );

      expect(findings.map((f) => f.check), contains('index-orphan'));
      expect(findings.single.detail, '.claude/rules/ghost.md');
    });

    test('flags a link to a rule file that does not exist', () {
      final findings = checkIndex(
        ruleFileNames: {'git.md'},
        agentsMd:
            '# AGENTS.md\n\n| 0 | Git | [git.md](.claude/rules/git.md) |\n'
            '| 1 | Gone | [gone.md](.claude/rules/gone.md) |',
        copilotInstructions: 'See AGENTS.md.',
      );

      expect(findings.map((f) => f.check), contains('index-dangling'));
      expect(findings.single.detail, '.claude/rules/gone.md');
    });

    test('does not flag a prose mention of a rule file that is not here', () {
      // Naming a `.claude/rules/` path in prose — a historical note, or a file that lives in
      // another repo — is not a link into this repo's rules. Flagging it would make the check
      // cry wolf on accurate documentation, and a check that cries wolf gets ignored.
      final findings = checkIndex(
        ruleFileNames: {'security.md'},
        agentsMd: '# AGENTS.md\n\n## Rules\n\n'
            '| 10 | Security | [security.md](.claude/rules/security.md) |\n\n'
            'Aturan backend tinggal di `.claude/rules/backend.md` di repo lain.',
        copilotInstructions: 'See AGENTS.md.',
      );

      expect(findings, isEmpty);
    });

    test('flags a pointer that points nowhere', () {
      final findings = checkIndex(
        ruleFileNames: {'git.md'},
        agentsMd: '# AGENTS.md\n\n| 0 | Git | [git.md](.claude/rules/git.md) |',
        copilotInstructions: 'This repo is a POS app. Use TypeScript.',
      );

      expect(findings.map((f) => f.check), contains('pointer-missing'));
    });

    test('passes when every file is indexed and the pointer points', () {
      final findings = checkIndex(
        ruleFileNames: {'git.md', 'testing.md'},
        agentsMd:
            '# AGENTS.md\n\n| 0 | Git | [git.md](.claude/rules/git.md) |\n'
            '| 1 | TDD | [testing.md](.claude/rules/testing.md) |',
        copilotInstructions:
            'Rules live in `.claude/rules/`. Start at AGENTS.md.',
      );

      expect(findings, isEmpty);
    });
  });

  group('checkNoDuplication', () {
    test('fires when AGENTS.md carries a rule body verbatim', () {
      // The known-bad case: an index file carrying a rule body verbatim.
      final findings = checkNoDuplication(
        ruleFiles: [RuleFile(name: 'testing.md', content: _realRuleText)],
        agentsMd:
            '# AGENTS.md\n\n## Strict Engineering Rules\n\n$_realRuleText',
        copilotInstructions: 'See AGENTS.md.',
      );

      expect(findings, isNotEmpty);
      expect(findings.map((f) => f.check), contains('duplication-index'));
      expect(findings.first.detail, contains('laporan bug'));
    });

    test('fires when copilot-instructions.md carries a rule body verbatim', () {
      final findings = checkNoDuplication(
        ruleFiles: [RuleFile(name: 'testing.md', content: _realRuleText)],
        agentsMd:
            '# AGENTS.md\n\n| 1 | TDD | [testing.md](.claude/rules/testing.md) |',
        copilotInstructions: '## Quick Reference\n\n$_realRuleText',
      );

      expect(findings.map((f) => f.check), contains('duplication-pointer'));
    });

    test('does not fire on a one-line summary that links to the rule', () {
      final findings = checkNoDuplication(
        ruleFiles: [RuleFile(name: 'testing.md', content: _realRuleText)],
        agentsMd: '# AGENTS.md\n\n## Rules\n\n'
            '| 5 | TDD — test dulu, RED sebelum GREEN | [testing.md](.claude/rules/testing.md) |',
        copilotInstructions:
            'Read `.claude/rules/` before coding. Index: AGENTS.md.',
      );

      expect(findings, isEmpty);
    });

    test('exempts project.md, because AGENTS.md must carry a project overview',
        () {
      final overview =
          'Aplikasi Android POS Finnesia untuk tablet kasir dengan printer '
          'thermal BLE dan antrian offline di SQLite untuk data finansial penjualan.';
      final findings = checkNoDuplication(
        ruleFiles: [RuleFile(name: 'project.md', content: overview)],
        agentsMd: '# AGENTS.md\n\n## Project Overview\n\n$overview',
        copilotInstructions: 'See AGENTS.md.',
      );

      expect(findings, isEmpty);
    });

    test('does not treat a link path as shared text', () {
      final findings = checkNoDuplication(
        ruleFiles: [
          RuleFile(
            name: 'git.md',
            content:
                'Detail: `.claude/rules/testing.md` has the verification order. '
                'Never run git commands that write to the working tree.',
          ),
        ],
        agentsMd: '# AGENTS.md\n\n| 0 | Git | [git.md](.claude/rules/git.md) |',
        copilotInstructions: 'See AGENTS.md and `.claude/rules/`.',
      );

      expect(findings, isEmpty);
    });
  });

  group('checkIndexShape', () {
    test('flags a rule entry with no link', () {
      final findings = checkIndexShape(
        agentsMd: '# AGENTS.md\n\n## Rules\n\n'
            '- Git: read-only boleh, menulis dilarang. Command yang menulis termasuk '
            'add, commit, push, reset, clean, rebase, merge, dan seluruh keluarga stash.',
      );

      expect(findings.map((f) => f.check), contains('index-shape'));
      expect(findings.single.message, contains('no link'));
    });

    test('flags a rule entry that has become a rule body', () {
      final long =
          'TDD wajib. ${'Tulis test dulu, konfirmasi merah, baru implementasi. ' * 5}';
      final findings = checkIndexShape(
        agentsMd: '# AGENTS.md\n\n## Rules\n\n'
            '- $long [testing.md](.claude/rules/testing.md)',
      );

      expect(findings.map((f) => f.check), contains('index-shape'));
      expect(findings.single.message, contains('words (max'));
    });

    test('accepts table rows and short bullets, ignoring header and separator',
        () {
      final findings = checkIndexShape(
        agentsMd: '# AGENTS.md\n\n## Rules\n\n'
            '| # | Aturan | Detail |\n'
            '| - | ------ | ------ |\n'
            '| 0 | Git | [git.md](.claude/rules/git.md) |\n'
            '| 5 | TDD — RED sebelum GREEN | [testing.md](.claude/rules/testing.md) |\n'
            '- Verifikasi: [testing.md](.claude/rules/testing.md)\n',
      );

      expect(findings, isEmpty);
    });

    test('ignores prose outside the rules section', () {
      final findings = checkIndexShape(
        agentsMd: '# AGENTS.md\n\n## Tech Stack\n\n'
            '- Flutter 3.47.4, Dart 3.13.3, Android SDK 36, Gradle 9.3.1, Kotlin 2.4.0, '
            'SQLite, flutter_blue_plus, dan printer thermal BLE untuk tablet kasir.',
      );

      expect(findings, isEmpty);
    });
  });

  group('this repo', () {
    test('the checks pass on the real files', () {
      final repoRoot = Directory.current.path.endsWith('rule_lint')
          ? Directory('${Directory.current.path}/../..')
          : Directory.current;
      final rulesDir = Directory('${repoRoot.path}/.claude/rules');
      final agentsFile = File('${repoRoot.path}/AGENTS.md');
      final copilotFile =
          File('${repoRoot.path}/.github/copilot-instructions.md');

      expect(rulesDir.existsSync(), isTrue, reason: 'missing .claude/rules/');
      expect(agentsFile.existsSync(), isTrue, reason: 'missing AGENTS.md');
      expect(copilotFile.existsSync(), isTrue,
          reason: 'missing copilot-instructions.md');

      final ruleFiles = rulesDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.md'))
          .map((file) => RuleFile(
                name: file.uri.pathSegments.last,
                content: file.readAsStringSync(),
              ))
          .toList();

      final agentsMd = agentsFile.readAsStringSync();
      final copilotInstructions = copilotFile.readAsStringSync();
      final findings = [
        ...checkIndex(
          ruleFileNames: ruleFiles.map((r) => r.name).toSet(),
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

      expect(findings, isEmpty, reason: findings.join('\n'));
    });
  });
}
