/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:string_lint/string_lint.dart';
import 'package:test/test.dart';

// The checker is proved on text that is known to be bad before an empty result on the real
// tree means anything (`.claude/rules/testing.md` §0.3).

List<int> lines(String source) =>
    findHardcodedStrings(source).map((f) => f.line).toList();

void main() {
  group('a string written into a Text', () {
    test('is found, with the line it is on', () {
      const source = '''
Widget build() {
  return Text('Bayar');
}
''';

      expect(lines(source), [2]);
    });

    test('is found with double quotes, after const, and across lines', () {
      const source = '''
const Text("Bayar");
const Text(
  'Kembalian',
);
''';

      expect(lines(source), [1, 2]);
    });

    test('is found when it only interpolates around a word', () {
      expect(lines(r"Text('$count barang');"), [1]);
    });
  });

  group('a string in an argument the cashier reads', () {
    test('is found: labels, hints, tooltips, titles, messages', () {
      const source = '''
InputDecoration(labelText: 'Nama');
InputDecoration(hintText: "Cari produk");
IconButton(tooltip: 'Tutup');
Icon(Icons.close, semanticLabel: 'Tutup');
AppBar(title: 'Kasir');
SnackBar(content: 'Tersimpan');
Tooltip(message: 'Hapus');
''';

      expect(lines(source), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('is left alone when the argument is technical', () {
      const source = '''
Column(key: Key('checkout'));
ListView(restorationId: 'cart');
FloatingActionButton(heroTag: 'pay');
''';

      expect(lines(source), isEmpty);
    });

    test('is left alone when the value is not a literal', () {
      expect(lines('InputDecoration(labelText: l10n.name);'), isEmpty);
    });
  });

  group('a string in a comment', () {
    test('is left alone: docs and notes mention widgets', () {
      const source = '''
// Text('Bayar') would be wrong here.
/// Shows Text("Kembalian") in the sheet.
 * Text('Tutup')
''';

      expect(lines(source), isEmpty);
    });
  });

  group('the exception marker', () {
    test('leaves a line alone when it gives a reason', () {
      const source = '''
Text('Finnesia'); // l10n-ignore: brand name, the same in every language
''';

      expect(lines(source), isEmpty);
    });

    test('does not count without a reason, and the string is still found', () {
      const source = '''
Text('Finnesia'); // l10n-ignore:
Text('Finnesia'); // l10n-ignore
''';

      expect(lines(source), [1, 2]);
    });
  });

  group('a string that is not language', () {
    test('is left alone: figures, symbols, and interpolation only', () {
      const source = r'''
Text('12');
Text('•');
Text('/');
Text('$total');
Text('${sale.number}');
Text('Rp $total') ;
''';

      // Only the last one has a word in it.
      expect(lines(source), [6]);
    });

    test('is left alone when the text comes from the dictionary', () {
      expect(lines('Text(l10n.pay);'), isEmpty);
    });
  });

  group('scanning a tree', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('string_lint_'));
    tearDown(() => root.deleteSync(recursive: true));

    File put(String path, String content) => File(p.join(root.path, path))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    test('names the file and line of each hardcoded string', () {
      put('screens/pay.dart', "\nText('Bayar');\n");
      put('screens/ok.dart', 'Text(l10n.pay);');

      final found = scanTree(root);

      expect(found.map((f) => '${f.path}:${f.finding.line}'), [
        p.join(root.path, 'screens', 'pay.dart') + ':2',
      ]);
    });

    test('skips the generated localizations and generated code', () {
      put('l10n/app_localizations_id.dart', "Text('Bayar');");
      put('model/sale.g.dart', "Text('Bayar');");
      put('model/sale.freezed.dart', "Text('Bayar');");
      put('notes.txt', "Text('Bayar');");

      expect(scanTree(root), isEmpty);
    });
  });
}
