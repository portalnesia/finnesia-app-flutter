/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The three values a Microsoft Store package must carry are NOT ours to choose: they are
// assigned by Partner Center (Product management -> Product identity) and must match character
// for character. A mismatch does not fail the build — it fails the *upload*, with a manifest
// error that does not name the offending field.
//
// They used to be invented here for the sideload path (`com.finnesia.pos` / `Portalnesia`), which
// is exactly the shape that rots silently: the sideload still worked, so nothing complained, and
// the first Store upload would have failed somewhere that cannot be debugged locally.
//
// So they are pinned here over the real `pubspec.yaml`, and the checks are proved on input that
// is known to be bad before their verdict means anything (`.claude/rules/testing.md` §0.3).

/// The Store identity as Partner Center reports it. Changing any of these means the app was
/// re-registered, not that someone tidied a name.
const _storeIdentityName = 'PutuAditya.FinnesiaPOS';
const _storePublisher = 'CN=FD977251-3866-4FF0-ABD2-D71AAABF5137';
const _storePublisherDisplayName = 'Putu Aditya';

/// The values that are NOT the Store identity, and were here before. Kept as a named constant
/// because "must not be this" is a different assertion from "must be that", and this is the
/// regression the file exists to catch.
const _sideloadOnlyIdentityName = 'com.finnesia.pos';
const _sideloadOnlyPublisherDisplayName = 'Portalnesia';

String read(String path) => File(path).readAsStringSync();

/// The scalar `key: value` under the top-level `msix_config:` block of [pubspec], or `null`.
///
/// A scan rather than a YAML parse for the same reason as the other readers here: the repo has
/// no YAML dependency in the test path, and this file needs three scalars out of one block.
///
/// The value is everything after the colon, trimmed — **not** `\S+`. `publisher_display_name`
/// is `Putu Aditya`, and a non-whitespace pattern silently returns `Putu`, which then compares
/// unequal for a reason that looks nothing like the real one. A trailing `#` comment is stripped
/// so a note on the same line cannot become part of the value.
///
/// Stops at the first line at or left of the key's own indent, so a scalar of the same name
/// under a different top-level key cannot be picked up.
String? msixScalar(String pubspec, String key) {
  int? blockIndent;
  for (final line in pubspec.split('\n')) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    final indent = line.length - line.trimLeft().length;

    if (blockIndent == null) {
      if (RegExp(r'^\s*msix_config:\s*$').hasMatch(line)) blockIndent = indent;
      continue;
    }
    // A line at or left of the block key ends the block.
    if (indent <= blockIndent) return null;

    final match = RegExp('^\\s+$key:\\s*(.+?)\\s*\$').firstMatch(line);
    if (match != null) {
      return match.group(1)!.replaceAll(RegExp(r'\s+#.*$'), '').trim();
    }
  }
  return null;
}

/// The four sections of a Windows package version, or `null` if [value] is not `a.b.c.d`.
///
/// Partner Center accepts only this shape for MSIX, and the tool's own check is on the format
/// alone (`msix/lib/src/configuration.dart`: *"msix version can be only in this format"*), which
/// is why the *value* rules below are ours to enforce.
List<int>? parsePackageVersion(String? value) {
  if (value == null) return null;
  final parts = value.split('.');
  if (parts.length != 4) return null;
  final numbers = <int>[];
  for (final part in parts) {
    final number = int.tryParse(part);
    if (number == null || number < 0) return null;
    numbers.add(number);
  }
  return numbers;
}

/// The top-level `version:` of [pubspec], or `null`.
String? pubspecVersion(String pubspec) {
  for (final line in pubspec.split('\n')) {
    if (line.trimLeft().startsWith('#')) continue;
    final match = RegExp(r'^version:\s*(\S+)\s*$').firstMatch(line);
    if (match != null) return match.group(1);
  }
  return null;
}

void main() {
  final pubspec = read('pubspec.yaml');

  group('the package version', () {
    test('has four sections, which is the only shape the Store accepts', () {
      expect(
        parsePackageVersion(msixScalar(pubspec, 'msix_version')),
        hasLength(4),
      );
    });

    test('does not start at zero, which Partner Center rejects outright', () {
      // *"The other sections must be set to an integer between 0 and 65535 (except for the first
      // section, which cannot be 0)."* The tool does not check this, so a Major of 0 builds fine
      // locally and is refused at upload — the most expensive place to find out.
      final version = parsePackageVersion(msixScalar(pubspec, 'msix_version'))!;
      expect(
        version.first,
        isNot(0),
        reason: 'a package version cannot have a Major of 0',
      );
    });

    test(
      'leaves the fourth section at zero, which is reserved for the Store',
      () {
        final version = parsePackageVersion(
          msixScalar(pubspec, 'msix_version'),
        )!;
        expect(version.last, 0);
      },
    );

    test('agrees with the app version, so one release has one number', () {
      // `flutter build` stamps the Windows exe from the app version, and the MSIX carries
      // `msix_version`. If the two disagree, the Store listing and the running app report
      // different versions for the same build.
      final app = pubspecVersion(pubspec);
      expect(app, isNotNull, reason: 'no version: in pubspec.yaml');

      final appNumbers = app!.split('+').first.split('.');
      final packageVersion = parsePackageVersion(
        msixScalar(pubspec, 'msix_version'),
      )!;

      expect(
        packageVersion.take(appNumbers.length).toList(),
        appNumbers.map(int.parse).toList(),
      );
    });
  });

  group('the Store identity', () {
    test('is the name Partner Center assigned, not a reverse-DNS name', () {
      // `Package/Identity/Name` is `<PublisherId>.<AppName>`. It carries no domain, so
      // "tidying" it into one — which is what the sideload value looked like — is the mistake.
      expect(msixScalar(pubspec, 'identity_name'), _storeIdentityName);
    });

    test('is not the invented value that only ever worked for sideload', () {
      expect(
        msixScalar(pubspec, 'identity_name'),
        isNot(_sideloadOnlyIdentityName),
      );
    });

    test(
      'carries the publisher as the certificate subject Partner Center gave',
      () {
        // Required by the tool both for `store` and for `sign_msix: false`
        // (`msix/lib/src/configuration.dart`). It is a certificate *subject*, so it keeps `CN=`.
        expect(msixScalar(pubspec, 'publisher'), _storePublisher);
      },
    );

    test('carries the display name Partner Center gave', () {
      expect(
        msixScalar(pubspec, 'publisher_display_name'),
        _storePublisherDisplayName,
      );
      expect(
        msixScalar(pubspec, 'publisher_display_name'),
        isNot(_sideloadOnlyPublisherDisplayName),
      );
    });
  });

  group('the readers', () {
    const bad = '''
msix_config:
  identity_name: com.example.wrong
  publisher: CN=NOPE
other_key:
  identity_name: not-this-one
''';

    test('read a scalar from the block, and only from that block', () {
      expect(msixScalar(bad, 'identity_name'), 'com.example.wrong');
      expect(msixScalar(bad, 'publisher'), 'CN=NOPE');
    });

    test('keep a value that contains a space whole', () {
      // `publisher_display_name` is a person's name. A `\S+` pattern returns `Putu` and the
      // failure then reads as "wrong display name" rather than "broken reader" — which is
      // exactly what happened when this file was first written.
      expect(
        msixScalar(
          'msix_config:\n  publisher_display_name: Putu Aditya\n',
          'publisher_display_name',
        ),
        'Putu Aditya',
      );
    });

    test('do not take a trailing comment as part of the value', () {
      expect(
        msixScalar(
          'msix_config:\n  publisher: CN=ABC # the store one\n',
          'publisher',
        ),
        'CN=ABC',
      );
    });

    test(
      'stop at the block, so a same-named key elsewhere is not picked up',
      () {
        // `other_key:` carries the same key. If the scan ran to the end of the file it would
        // return that value instead, and every identity check above would be checking nothing.
        expect(msixScalar(bad, 'identity_name'), isNot('not-this-one'));
      },
    );

    test('refuse to invent a scalar that is not there', () {
      expect(msixScalar(bad, 'msix_version'), isNull);
      expect(msixScalar(bad, 'publisher_display_name'), isNull);
    });

    test('refuse a version that is not four numbers', () {
      expect(parsePackageVersion('1.0.0'), isNull);
      expect(parsePackageVersion('1.0.0.0.0'), isNull);
      expect(parsePackageVersion('1.0.0.x'), isNull);
      expect(parsePackageVersion(null), isNull);
      expect(parsePackageVersion('1.0.0.0'), [1, 0, 0, 0]);
    });

    test('read the app version, and only the top-level one', () {
      expect(pubspecVersion('name: pos\nversion: 2.3.4+5\n'), '2.3.4+5');
      expect(pubspecVersion('# version: 9.9.9\n'), isNull);
      expect(pubspecVersion('name: pos\n'), isNull);
    });
  });
}
