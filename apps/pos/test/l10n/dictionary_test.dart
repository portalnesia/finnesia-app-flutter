/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/preferences/app_preferences.dart';

// The two dictionaries carry exactly the same keys, and nothing is empty. The compiler does
// not catch either. A missing translation falls back at runtime and nobody notices, so the
// check has to run over the files.
//
// The checker is proved on input that is known to be bad before its verdict on the real files
// means anything (`.claude/rules/testing.md` §0.3).

/// What is wrong between the template [id] and the translation [en]. Empty means nothing.
List<String> problems(Map<String, Object?> id, Map<String, Object?> en) {
  // `@key` is metadata for a key and `@@locale` marks the file; neither is a translation.
  Map<String, String> texts(Map<String, Object?> arb) => {
    for (final e in arb.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
  Set<String> placeholders(String text) => {
    for (final m in RegExp(r'\{(\w+)(?=[,}])').allMatches(text)) m.group(1)!,
  };

  final a = texts(id);
  final b = texts(en);
  return [
    for (final key in a.keys.where((k) => !b.containsKey(k)))
      '$key: missing in en',
    for (final key in b.keys.where((k) => !a.containsKey(k)))
      '$key: only in en',
    for (final MapEntry(:key, :value) in [...a.entries, ...b.entries])
      if (value.trim().isEmpty) '$key: empty translation',
    for (final key in a.keys.where(b.containsKey))
      if (!_sameSet(placeholders(a[key]!), placeholders(b[key]!)))
        '$key: placeholders differ',
  ];
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

Map<String, Object?> read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

void main() {
  group('the checker', () {
    test('names a key the English dictionary is missing', () {
      final found = problems({'a': 'A', 'b': 'B'}, {'a': 'A'});

      expect(found, [contains('b')]);
    });

    test('names a key only the English dictionary has', () {
      final found = problems({'a': 'A'}, {'a': 'A', 'z': 'Z'});

      expect(found, [contains('z')]);
    });

    test('names an empty translation in either language', () {
      expect(problems({'a': ''}, {'a': 'A'}), [contains('a')]);
      expect(problems({'a': 'A'}, {'a': '  '}), [contains('a')]);
    });

    test('names a placeholder that one language leaves out', () {
      final found = problems({'a': 'Halo {name}'}, {'a': 'Hello'});

      expect(found, [contains('a')]);
    });

    test('leaves metadata entries and the locale marker alone', () {
      final found = problems(
        {
          '@@locale': 'id',
          'a': 'A',
          '@a': {'description': 'x'},
        },
        {'@@locale': 'en', 'a': 'A'},
      );

      expect(found, isEmpty);
    });

    test('reads a plural as using its placeholder', () {
      final found = problems(
        {'n': '{count} barang'},
        {'n': '{count, plural, =1{1 item} other{{count} items}}'},
      );

      expect(found, isEmpty);
    });
  });

  group('the dictionaries', () {
    final id = read('lib/l10n/app_id.arb');
    final en = read('lib/l10n/app_en.arb');

    test('are read: a checker over two empty files finds nothing', () {
      // Without this, an ARB that failed to load would pass every check below.
      expect(id.length, greaterThan(200));
    });

    test('carry the same keys, none empty, with the same placeholders', () {
      expect(problems(id, en), isEmpty);
    });
  });

  group('the generated localizations', () {
    test('cover every language the cashier can pick', () {
      for (final language in AppLanguage.values) {
        expect(
          L10n.supportedLocales,
          contains(language.locale),
          reason: '${language.name} has no ARB file',
        );
      }
    });

    test('count items in the cashier\'s language', () async {
      final id = await L10n.delegate.load(const Locale('id'));
      final en = await L10n.delegate.load(const Locale('en'));

      expect(id.posItemCount(2), '2 barang');
      expect(en.posItemCount(1), '1 item');
      expect(en.posItemCount(2), '2 items');
    });
  });
}
