/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The App Link is declared in the Android manifest, so no widget test can see it: `flutter test`
// has no resource merger and no manifest. That is exactly the shape that rots silently — someone
// edits the manifest, or a `flutter create` upgrade overwrites it, and nothing says so until a
// cashier taps "Kembali ke aplikasi" on a tablet and stays in the browser.
//
// What is pinned here is the contract between three things that live in three places and are
// never compiled together:
//
//   * the app's manifest (this repo),
//   * the App Links document the backend serves (`/.well-known/assetlinks.json`), and
//   * the button the done page renders (`apps/api/internal/rest/handler/auth_handler.go`).
//
// They are written down in `finnesia-monorepo/plan/pos-deeplink/README.md` §6. If one side
// changes, this test is what says the other has not.
//
// The checks are proved on input that is known to be bad before their verdict on the real files
// means anything (`.claude/rules/testing.md` §0.3).

/// The path the backend's done page links to, and the prefix Android must match.
///
/// Deliberately under `/api/` so the proxies that already forward `/api/*` need no change
/// (`plan/pos-deeplink/README.md` §W2).
const _returnPath = '/api/auth/mobile/return';

/// The canonical host each build talks to. A tenant's `custom_domain` cannot appear here: it is
/// not known at build time, and the done page is always served from the canonical host
/// (`plan/pos-deeplink/README.md` §D3).
const _productionHost = 'apps.finnesia.com';
const _stagingHost = 'apps-dev.finnesia.com';

/// An `<intent-filter>`: its own attributes, and the `<data>` elements inside it.
typedef Filter = ({String attributes, List<String> data});

/// Every `<intent-filter>` in [manifest], with the `<data>` elements each one carries.
List<Filter> intentFilters(String manifest) {
  final filter = RegExp(
    r'<intent-filter\b([^>]*)>(.*?)</intent-filter>',
    dotAll: true,
  );
  return [
    for (final match in filter.allMatches(manifest))
      (
        attributes: match.group(1)!,
        data: RegExp(r'<data\b[^>]*>')
            .allMatches(match.group(2)!)
            .map((d) => d.group(0)!)
            .toList(),
      ),
  ];
}

/// Whether [filters] contains an App Link filter for [host] at [pathPrefix].
///
/// `autoVerify` is what makes Android fetch the App Links document and verify the host; without
/// it the link is unverified and a tap may be answered by the browser or by another app. The
/// scheme, host and prefix must be on **one** `<data>` element: Android combines attributes
/// across elements in a filter, so a split declaration would work while reading as though it did
/// not — and this test is here to be readable as well as correct.
bool hasAppLink(List<Filter> filters, String host, String pathPrefix) {
  return filters.any((filter) {
    if (!filter.attributes.contains('android:autoVerify="true"')) return false;
    return filter.data.any(
      (data) =>
          data.contains('android:scheme="https"') &&
          data.contains('android:host="$host"') &&
          data.contains('android:pathPrefix="$pathPrefix"'),
    );
  });
}

/// The `<data>` elements of the launcher filter, for the detector's own probe.
const _badManifest = '''
<activity android:name=".MainActivity">
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>''';

/// A filter that declares the right host but never asked Android to verify it.
const _unverifiedManifest =
    '''
<intent-filter>
    <data android:scheme="https" android:host="$_productionHost" android:pathPrefix="$_returnPath"/>
</intent-filter>''';

/// A verified filter for the wrong host — the mistake that would send every tenant's cashier to
/// a host their device is not paired with.
const _wrongHostManifest =
    '''
<intent-filter android:autoVerify="true">
    <data android:scheme="https" android:host="example.com" android:pathPrefix="$_returnPath"/>
</intent-filter>''';

void main() {
  group('the detector', () {
    // `testing.md` §0.3: a checker that has never fired is indistinguishable from a broken one.
    // Each probe below is a real way this declaration goes wrong, and the detector must catch
    // every one of them before its verdict on the real manifests means anything.
    test('finds nothing in a launcher-only manifest', () {
      expect(
        hasAppLink(intentFilters(_badManifest), _productionHost, _returnPath),
        isFalse,
      );
    });

    test('rejects a filter that never asked to be verified', () {
      expect(
        hasAppLink(
          intentFilters(_unverifiedManifest),
          _productionHost,
          _returnPath,
        ),
        isFalse,
      );
    });

    test('rejects a verified filter for another host', () {
      expect(
        hasAppLink(
          intentFilters(_wrongHostManifest),
          _productionHost,
          _returnPath,
        ),
        isFalse,
      );
    });

    test('accepts a verified filter for the host it was given', () {
      // The one case that must pass, so the three above are known to be about the right thing
      // rather than about the parser rejecting everything.
      final verified =
          '''
<intent-filter android:autoVerify="true">
    <data android:scheme="https" android:host="$_productionHost" android:pathPrefix="$_returnPath"/>
</intent-filter>''';

      expect(
        hasAppLink(intentFilters(verified), _productionHost, _returnPath),
        isTrue,
      );
    });
  });

  group('the release manifest', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final filters = intentFilters(manifest);

    // Production is the only host a release build talks to, and the only host its App Links
    // document names (`com.finnesia.pos` + the upload keystore's fingerprint).
    test('claims the production host, verified, at the return path', () {
      expect(hasAppLink(filters, _productionHost, _returnPath), isTrue);
    });

    // The check CI already makes over the built APK, at the source it comes from: a staging host
    // in the release manifest would make every production tablet try to verify against a
    // document that does not name its package, and would ship a development host to customers.
    test('never names the staging host', () {
      expect(manifest.contains(_stagingHost), isFalse);
    });

    // `localhost` cannot be verified (http, and no App Links document), so a link there would be
    // dead weight in the manifest — the login still finishes by polling.
    test('never names a local development host', () {
      expect(manifest.contains('localhost'), isFalse);
    });
  });

  group('the debug manifest', () {
    final manifest = File('android/app/src/debug/AndroidManifest.xml')
        .readAsStringSync();

    // Debug builds are the ones that talk to staging (`README` §13), and staging's App Links
    // document names `com.finnesia.pos.debug`. Without this, the only way to test the App Link
    // on a tablet would be to build a release APK against production.
    test('claims the staging host, verified, at the return path', () {
      expect(
        hasAppLink(intentFilters(manifest), _stagingHost, _returnPath),
        isTrue,
      );
    });
  });
}
