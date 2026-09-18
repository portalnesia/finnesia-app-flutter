/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The launcher icon and the splash are Android resources, so no widget test can see them:
// `flutter test` has no resource compiler, and `flutter_launcher_icons` is a one-off code
// generator whose output is committed. That is exactly the shape that rots — someone edits the
// config, or regenerates with a different tool version, and nothing says so until a tablet
// shows the wrong icon.
//
// So the two facts that are easy to get silently wrong are pinned here, over the real files:
// the icon is generated from the owner's artwork at a scale that survives every launcher mask,
// and the splash is the same amber on every API level and in both themes.
//
// The checks are proved on input that is known to be bad before their verdict on the real
// files means anything (`.claude/rules/testing.md` §0.3).

/// The colour every path of the launch screen must agree on. `rgb(255,152,0)`, the amber of
/// `assets/icon/icon.png` itself and the owner's answer.
const _amber = '#FF9800';

/// Android's own numbers, from `developer.android.com/develop/ui/views/launch/icon_design_adaptive`:
/// a logo must be at least 48 dp and at most 66 dp, inside a layer drawn at 108 dp.
const _minLogoDp = 48.0;
const _maxLogoDp = 66.0;

/// The glyph's measured bounding box in `assets/icon/icon_only.png`, in dp at a 108 dp layer.
/// Measured with ImageMagick over the alpha channel, not read off a document:
/// `716 x 726 px` of a 1080 px canvas, and 726 px is the larger side -> `72.75 dp`.
const _glyphWidestDp = 72.75;

/// The glyph's furthest corner from the centre, in dp at a 108 dp layer: `50.91 dp`.
/// This is the radius a round mask needs, and it is why a square bounding box is not enough to
/// answer "does it fit" — a round-masked launcher clips corners a square safe zone allows.
const _glyphCornerDp = 50.91;

/// The largest circle a launcher may draw over the icon: the 72 dp masked viewport, so r = 36.
const _maskRadiusDp = 36.0;

/// Problems with the adaptive icon at [insetPercent], which is what
/// `flutter_launcher_icons.yaml` sets and what `ic_launcher.xml` therefore carries.
///
/// `InsetDrawable` multiplies the percentage by the layer's bound size, and the layer is drawn
/// at its natural 108 dp (`AdaptiveIconDrawable.getIntrinsicWidth()` returns `108 * 2/3` = 72 dp,
/// so the 108 dp artwork is scaled *down* to the viewport rather than up to 150%). The visible
/// width is therefore `108 * (1 - 2 * inset)`. Empty means nothing is wrong.
List<String> adaptiveIconProblems(int insetPercent) {
  final scale = 1 - 2 * insetPercent / 100;
  final logoDp = _glyphWidestDp * scale;
  final cornerDp = _glyphCornerDp * scale;

  return [
    if (insetPercent < 0 || scale <= 0)
      'inset $insetPercent% leaves nothing visible (scale $scale)',
    if (logoDp < _minLogoDp)
      'logo ${logoDp.toStringAsFixed(1)} dp is under the ${_minLogoDp.toInt()} dp minimum',
    if (logoDp > _maxLogoDp)
      'logo ${logoDp.toStringAsFixed(1)} dp is over the ${_maxLogoDp.toInt()} dp maximum',
    if (cornerDp > _maskRadiusDp)
      'corners reach ${cornerDp.toStringAsFixed(1)} dp from centre; '
          'a round launcher mask (r=${_maskRadiusDp.toInt()}) would clip them',
  ];
}

/// The inset the generated `ic_launcher.xml` actually carries, or `null` when the file has no
/// inset — which would mean the artwork is drawn at full 108 dp, far past the 66 dp ceiling.
int? readInset(String xml) {
  final m = RegExp(r'android:inset="(\d+)%"').firstMatch(xml);
  return m == null ? null : int.parse(m.group(1)!);
}

/// The colour of `<color name="...">` in [xml], or `null` when the name is absent.
String? readColour(String xml, String name) =>
    RegExp('<color name="$name">([^<]+)</color>').firstMatch(xml)?.group(1);

/// The values of `<item name="...">` in [xml], keyed by name.
Map<String, String> readItems(String xml) => {
  for (final m in RegExp(
    r'<item name="([^"]+)">([^<]+)</item>',
  ).allMatches(xml))
    m.group(1)!: m.group(2)!,
};

/// The pixel size of the PNG at [path], read from its IHDR chunk.
///
/// The width and height are the two big-endian `uint32`s after the 8-byte signature and the
/// 4-byte length and 4-byte `IHDR` tag, so no image decoder is needed for a size check.
(int, int) pngSize(String path) {
  final b = File(path).readAsBytesSync();

  expect(b.sublist(0, 8), [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ], reason: '$path is not a PNG');
  int u32(int at) =>
      (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];

  return (u32(16), u32(20));
}

/// The (width, height) of every image inside the `.ico` at [path].
///
/// An `.ico` is a 6-byte header (reserved, type, count) followed by one 16-byte directory entry
/// per image, where bytes 0 and 1 of each entry are the width and height. The image data comes
/// after the whole directory, so the sizes are readable without decoding anything.
///
/// This is the check that catches a single-size `.ico` — which is what `flutter_launcher_icons`
/// writes by default, and which Windows then rescales for the taskbar, Alt-Tab, Explorer and the
/// 256 px tile.
List<(int, int)> icoSizes(String path) {
  final b = File(path).readAsBytesSync();

  expect(b.length, greaterThan(6), reason: '$path is too short to be an ICO');
  expect(b[2] | (b[3] << 8), 1, reason: '$path is not an ICO (type must be 1)');
  final count = b[4] | (b[5] << 8);
  expect(count, greaterThan(0), reason: '$path holds no images');
  expect(
    b.length,
    greaterThanOrEqualTo(6 + count * 16),
    reason:
        '$path is truncated: $count images need a ${6 + count * 16} byte header',
  );

  return [
    for (var i = 0; i < count; i++)
      () {
        // 0 is how the format writes 256, which does not fit in the entry's one byte.
        int dim(int v) => v == 0 ? 256 : v;
        final at = 6 + i * 16;
        return (dim(b[at]), dim(b[at + 1]));
      }(),
  ];
}

String read(String path) => File(path).readAsStringSync();

/// The `generate` flag under the top-level `windows:` key in [yaml], or `null` when either is
/// absent.
///
/// A small scan rather than a YAML dependency: this reads one flag from one checked-in file,
/// and adding a parser to the test suite for that is not worth it. The scan is proved on
/// known-bad input below before its verdict on the real file means anything.
bool? windowsGenerate(String yaml) {
  int? keyIndent;
  for (final line in yaml.split('\n')) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    final indent = line.length - line.trimLeft().length;
    if (keyIndent == null) {
      if (RegExp(r'^\s*windows:\s*$').hasMatch(line)) keyIndent = indent;
      continue;
    }
    // A line at or left of the key's own indent ends the block.
    if (indent <= keyIndent) return null;
    final m = RegExp(r'^\s+generate:\s*(true|false)\s*$').firstMatch(line);
    if (m != null) return m.group(1) == 'true';
  }
  return null;
}

/// The entries of the `assets:` list under the top-level `flutter:` key in [pubspec]: what the
/// app packs into the APK, and nothing else that happens to mention a path.
///
/// Not "everything after the word `assets:`": other blocks (`msix_config: logo_path:`) name files
/// under `assets/` too, and are not shipped. A small scan for the same reason as
/// [windowsGenerate], and proved on known-bad input below.
List<String> flutterAssets(String pubspec) {
  final assets = <String>[];
  var inFlutter = false;
  int? assetsIndent;
  for (final line in pubspec.split('\n')) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    final indent = line.length - line.trimLeft().length;
    if (indent == 0) {
      // A new top-level key ends whatever block was open.
      inFlutter = RegExp(r'^flutter:\s*$').hasMatch(line);
      assetsIndent = null;
      continue;
    }
    if (!inFlutter) continue;
    if (assetsIndent == null) {
      if (RegExp(r'^\s+assets:\s*$').hasMatch(line)) assetsIndent = indent;
      continue;
    }
    final item = RegExp(r'^\s+-\s*(\S+)\s*$').firstMatch(line);
    if (item == null || indent < assetsIndent) {
      // The list is over: a sibling key of `assets:`, or something that is not an entry.
      assetsIndent = null;
      continue;
    }
    assets.add(item.group(1)!);
  }
  return assets;
}

void main() {
  group('the adaptive icon checker', () {
    test('accepts a logo that fits the safe zone', () {
      expect(adaptiveIconProblems(16), isEmpty);
    });

    test('rejects an inset so large the logo is under the minimum', () {
      // Measured, not guessed. The safe range for this artwork is exactly 15%..17%, and the
      // config sits at 16 — the middle of it. The bounds come from the two constraints:
      //
      //   logo >= 48 dp  ->  inset <= 17.01%   (at 18% the logo is 46.6 dp)
      //   corners <= 36 dp  ->  inset >= 14.64%  (at 14% the corners are 36.7 dp)
      //
      // My first attempt was 28%, which gives 32.0 dp — well under Android's floor.
      expect(adaptiveIconProblems(18), anyElement(contains('minimum')));
      expect(adaptiveIconProblems(28), anyElement(contains('minimum')));
    });

    test('accepts the whole safe range and nothing outside it', () {
      for (final inset in [15, 16, 17]) {
        expect(
          adaptiveIconProblems(inset),
          isEmpty,
          reason: 'inset $inset% should be safe',
        );
      }
      for (final inset in [14, 18]) {
        expect(
          adaptiveIconProblems(inset),
          isNotEmpty,
          reason: 'inset $inset% should fail',
        );
      }
    });

    test('rejects an inset so small the corners leave the mask', () {
      // At 14% the corners reach 36.7 dp, past the 36 dp the 72 dp viewport allows. 0% is the
      // worst case: the artwork is drawn at its full 108 dp, over the 66 dp ceiling as well.
      expect(adaptiveIconProblems(14), anyElement(contains('clip')));
      expect(adaptiveIconProblems(0), anyElement(contains('clip')));
    });

    test('rejects an inset that leaves nothing visible', () {
      expect(adaptiveIconProblems(50), anyElement(contains('nothing visible')));
    });
  });

  group('the icon config', () {
    test('is generated from the owner\'s artwork, not a stand-in', () {
      final yaml = read('flutter_launcher_icons.yaml');

      expect(yaml, contains('assets/icon/icon_only.png'));
      expect(yaml, contains('assets/icon/icon.png'));
    });

    test('names the amber of the artwork', () {
      expect(read('flutter_launcher_icons.yaml'), contains(_amber));
    });

    test('uses an inset that survives every launcher mask', () {
      final inset = readInset(
        read('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml'),
      );

      expect(
        inset,
        isNotNull,
        reason: 'no inset: the artwork would be drawn at 108 dp',
      );
      expect(adaptiveIconProblems(inset!), isEmpty);
    });

    test('keeps the asset out of the APK', () {
      // `assets/icon/` is an input to the generator, not something the app reads at runtime.
      // Listing it under `flutter: assets:` would ship ~33 KB of artwork that nothing loads.
      final shipped = flutterAssets(read('pubspec.yaml'));

      // Not empty: a reader that found nothing at all would pass the check below for the wrong
      // reason, so the one asset the app does ship has to be seen.
      expect(shipped, contains('assets/logo/finnesia.png'));
      expect(shipped.where((a) => a.startsWith('assets/icon/')), isEmpty);
    });
  });

  group('the launcher icon', () {
    test('has an adaptive variant, which is the one API 31+ draws', () {
      expect(
        File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
            .existsSync(),
        isTrue,
      );
    });

    // The densities Android derives the icon from, and the dp each must be drawn at. A wrong
    // `min_sdk_android` or a generator running at the wrong scale shows up here and nowhere
    // else — the build would still succeed and the icon would just look wrong on a tablet.
    const legacyDp = 48; // the pre-API-26 launcher icon
    const adaptiveDp = 108; // every adaptive layer
    const densities = {
      'mdpi': 1,
      'hdpi': 1.5,
      'xhdpi': 2,
      'xxhdpi': 3,
      'xxxhdpi': 4,
    };

    test('is drawn at the right size for every density', () {
      for (final MapEntry(key: density, value: scale) in densities.entries) {
        expect(
          pngSize('android/app/src/main/res/mipmap-$density/ic_launcher.png'),
          (legacyDp * scale, legacyDp * scale),
          reason: 'mipmap-$density',
        );
        for (final name in [
          'ic_launcher_foreground',
          'ic_launcher_monochrome',
        ]) {
          expect(
            pngSize('android/app/src/main/res/drawable-$density/$name.png'),
            (adaptiveDp * scale, adaptiveDp * scale),
            reason: 'drawable-$density/$name',
          );
        }
      }
    });

    test(
      'ships a monochrome layer, so Android 13+ theming is ours to control',
      () {
        // Without it, Android 16 QPR 2+ derives a silhouette from the foreground itself.
        expect(
          read('flutter_launcher_icons.yaml'),
          contains('adaptive_icon_monochrome'),
        );
      },
    );
  });

  group('the splash', () {
    test('is the same amber as the icon background', () {
      expect(
        readColour(
          read('android/app/src/main/res/values/colors_splash.xml'),
          'splash_background',
        ),
        _amber,
      );
      expect(
        readColour(
          read('android/app/src/main/res/values/colors.xml'),
          'ic_launcher_background',
        ),
        _amber,
      );
    });

    test('is set in BOTH themes', () {
      // `values-night/styles.xml` redefines `LaunchTheme` whole, so it does not inherit the
      // light file's items. Without this the splash would fall back to the system default in
      // dark mode, and the amber would only appear on tablets in light mode.
      for (final path in ['values', 'values-night']) {
        final items = readItems(
          read('android/app/src/main/res/$path/styles.xml'),
        );

        expect(
          items['android:windowSplashScreenBackground'],
          '@color/splash_background',
          reason: '$path/styles.xml does not set the splash background',
        );
      }
    });

    test('names its own icon in BOTH themes, and the file exists', () {
      // Left unset, the system draws the launcher icon, and on a tablet that came up as an empty
      // amber screen. The splash names the white glyph itself, so it does not depend on how a
      // launcher's adaptive icon is masked.
      for (final path in ['values', 'values-night']) {
        final items = readItems(
          read('android/app/src/main/res/$path/styles.xml'),
        );

        expect(
          items['android:windowSplashScreenAnimatedIcon'],
          '@drawable/splash_icon',
          reason: '$path/styles.xml does not name the splash icon',
        );
      }
      expect(
        File('android/app/src/main/res/drawable/splash_icon.xml').existsSync(),
        isTrue,
      );
      expect(
        File('android/app/src/main/res/drawable-nodpi/splash_glyph.png')
            .existsSync(),
        isTrue,
      );
    });

    test('sets the window background on both API paths', () {
      // `windowSplashScreenBackground` is API 31+; `drawable/launch_background.xml` is what
      // older devices would read. Both must point at the amber, or an API drop would put a
      // white flash in front of the logo.
      for (final path in ['drawable', 'drawable-v21']) {
        expect(
          read('android/app/src/main/res/$path/launch_background.xml'),
          contains('@color/splash_background'),
          reason: '$path/launch_background.xml is not the amber',
        );
      }
    });
  });

  // Windows is NOT a supported target (`architecture.md` §1.1): nothing builds, runs or tests
  // it, and these checks are all static. They exist because the owner asked for the name and
  // branding to be set now, and because a wrong `BINARY_NAME` fails the CMake configure step
  // rather than anything a Dart test would otherwise see.
  group('the Windows app', () {
    const cmake = 'windows/CMakeLists.txt';

    test('is named Finnesia POS in the title bar and the taskbar', () {
      // The window title, not the binary name: this is the one a person reads. Same string as
      // the Android launcher label.
      expect(read('windows/runner/main.cpp'), contains('L"Finnesia POS"'));
    });

    test('carries the product name in its version resource', () {
      final rc = read('windows/runner/Runner.rc');

      expect(rc, contains('VALUE "ProductName", "Finnesia POS"'));
      expect(rc, contains('VALUE "FileDescription", "Finnesia POS"'));
      expect(rc, contains('VALUE "CompanyName", "Finnesia"'));
      // `OriginalFilename` must track BINARY_NAME or Explorer's properties disagree with the
      // file on disk.
      expect(rc, contains('VALUE "OriginalFilename", "FinnesiaPOS.exe"'));
    });

    test('has a binary name flutter_tools can find and CMake can use unquoted', () {
      final contents = read(cmake);
      // This mirrors `getCmakeExecutableName` in flutter_tools' `lib/src/cmake.dart`. If the
      // `set(...)` line stops matching, `flutter run`/`build` cannot locate the executable.
      final match = RegExp(
        r'^\s*set\(BINARY_NAME\s*"(.*)"\s*\)\s*$',
        multiLine: true,
      ).firstMatch(contents);

      expect(
        match,
        isNotNull,
        reason: 'no BINARY_NAME line for flutter_tools to read',
      );
      final name = match!.group(1)!;
      expect(name, isNotEmpty);
      // `${BINARY_NAME}` is expanded UNQUOTED in `flutter/generated_plugins.cmake`, so a space
      // would split into two CMake arguments and the configure step would fail.
      expect(name, isNot(contains(' ')));
      expect(read('windows/runner/Runner.rc'), contains('"$name.exe"'));
    });

    test(
      'has a multi-size .ico, not the one size the generator defaults to',
      () {
        final sizes = icoSizes('windows/runner/resources/app_icon.ico');

        // Windows asks the shell for each of these; a single-size `.ico` gets rescaled for the
        // rest and looks soft.
        expect(sizes, [
          (16, 16),
          (24, 24),
          (32, 32),
          (48, 48),
          (64, 64),
          (256, 256),
        ]);
      },
    );

    test('uses the full-bleed artwork, not the transparent glyph', () {
      // Windows does not mask app icons. `icon_only.png` is a white glyph on transparency, so
      // in the light theme it would be white on white; `icon.png` carries its own amber field.
      expect(
        read('tool/generate_windows_icon.dart'),
        contains("const source = 'assets/icon/icon.png';"),
      );
    });

    test('leaves the .ico to our generator, not to flutter_launcher_icons', () {
      // The load-bearing flag in `flutter_launcher_icons.yaml`. Flipping it to true hands the
      // `.ico` back to a tool that writes one size, and nothing else in the repo would notice:
      // the six-size check above would still pass until the file was next regenerated, and then
      // fail as a mystery. This is the check that makes the flip loud.
      expect(windowsGenerate(read('flutter_launcher_icons.yaml')), isFalse);
    });
  });

  group('the readers', () {
    test('find an inset and refuse to invent one', () {
      expect(readInset('<inset android:inset="16%" />'), 16);
      expect(readInset('<inset android:drawable="@drawable/x" />'), isNull);
    });

    test('read every size in an ICO, and 0 as 256', () {
      // A hand-built header rather than the real file, so the 0-means-256 rule is exercised:
      // no `.ico` in this repo has a 256 written as a literal byte, because it cannot be one.
      final dir = Directory.systemTemp.createTempSync('ico_probe');
      addTearDown(() => dir.deleteSync(recursive: true));
      final probe = File('${dir.path}/probe.ico');

      // Header: reserved 0, type 1, two images. Then two 16-byte entries.
      final bytes = <int>[0, 0, 1, 0, 2, 0];
      for (final (w, h) in [(16, 16), (0, 0)]) {
        bytes
          ..add(w)
          ..add(h)
          ..addAll(List.filled(14, 0));
      }
      probe.writeAsBytesSync(bytes);

      expect(icoSizes(probe.path), [(16, 16), (256, 256)]);
    });

    test('reject a file that is not an ICO', () {
      final dir = Directory.systemTemp.createTempSync('ico_probe');
      addTearDown(() => dir.deleteSync(recursive: true));
      final probe = File('${dir.path}/not-an-ico.ico')
        ..writeAsBytesSync(List.filled(64, 7));

      expect(() => icoSizes(probe.path), throwsA(isA<TestFailure>()));
    });

    test('read the windows generate flag, and only from the windows block', () {
      expect(windowsGenerate('windows:\n  generate: false\n'), isFalse);
      expect(windowsGenerate('windows:\n  generate: true\n'), isTrue);
    });

    test('refuse to invent a windows generate flag', () {
      // No `windows:` key at all.
      expect(windowsGenerate('android: true\n'), isNull);
      // A `generate` under a DIFFERENT platform must not be mistaken for Windows'. This is the
      // case a plain "find the first generate:" scan gets wrong.
      expect(
        windowsGenerate(
          'web:\n  generate: true\nwindows:\n  generate: false\n',
        ),
        isFalse,
      );
      expect(windowsGenerate('web:\n  generate: true\n'), isNull);
      // A commented-out flag is not a flag.
      expect(windowsGenerate('windows:\n  # generate: false\n'), isNull);
    });
    test('read the assets the app ships, and only those under flutter', () {
      const pubspec = '''
name: pos
flutter:
  uses-material-design: true

  assets:
    - assets/logo/finnesia.png
    - assets/icon/icon.png

msix_config:
  logo_path: assets/icon/other.png
''';

      expect(flutterAssets(pubspec), [
        'assets/logo/finnesia.png',
        'assets/icon/icon.png',
      ]);
    });

    test('refuse to invent assets, and do not take another key\'s list', () {
      expect(flutterAssets('name: pos\n'), isEmpty);
      // An `assets:` that belongs to some other key is not what Flutter packs into the APK.
      expect(
        flutterAssets('tool:\n  assets:\n    - assets/icon/icon.png\n'),
        isEmpty,
      );
      // A commented-out entry is not shipped.
      expect(
        flutterAssets('flutter:\n  assets:\n    # - assets/icon/icon.png\n'),
        isEmpty,
      );
    });

    test('read a PNG size and reject a file that is not one', () {
      expect(
        pngSize('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'),
        (192, 192),
      );
      expect(
        () => pngSize(
          'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    test('find a colour by name and ignore the others', () {
      const xml = '''
        <resources>
          <color name="a">#111111</color>
          <color name="splash_background">#FF9800</color>
        </resources>''';

      expect(readColour(xml, 'splash_background'), '#FF9800');
      expect(readColour(xml, 'b'), isNull);
    });

    test('read items and leave the rest alone', () {
      const xml = '''
        <style name="LaunchTheme">
          <item name="android:windowBackground">@drawable/launch_background</item>
          <item name="android:windowSplashScreenBackground">@color/splash_background</item>
        </style>''';
      final items = readItems(xml);

      expect(items, hasLength(2));
      expect(
        items['android:windowSplashScreenBackground'],
        '@color/splash_background',
      );
    });
  });
}
