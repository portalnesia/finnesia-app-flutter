/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pn_types/src/native/opener_port.dart';
import 'package:pos/native/opener/opener_url_launcher.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';

const loginUrl =
    'https://apps.finnesia.com/api/auth/login?client=mobile&req=req_secret';

/// `url_launcher`'s own seam for tests: the platform interface, with no `MethodChannel` and no
/// device. It answers [result], or throws [failure], and records what it was asked.
class FakeLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  bool result = true;
  Object? failure;

  // The `Link` widget's delegate: this app does not use it.
  @override
  LinkDelegate? get linkDelegate => null;

  final launched = <(String, LaunchOptions)>[];
  var canLaunchAsked = 0;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add((url, options));
    if (failure != null) throw failure!;
    return result;
  }

  @override
  Future<bool> canLaunch(String url) async {
    canLaunchAsked++;
    return true;
  }
}

void main() {
  late FakeLauncherPlatform platform;

  setUp(() {
    platform = FakeLauncherPlatform();
    UrlLauncherPlatform.instance = platform;
  });

  group('UrlLauncherOpener', () {
    // Login depends on the OIDC session living in the browser's cookie jar and never in the
    // app's, so the URL must leave the app: the system browser, not a web view of ours.
    test(
      'hands the URL to the system browser, not to a view inside the app',
      () async {
        await UrlLauncherOpener().openUrl(loginUrl);

        final (url, options) = platform.launched.single;
        expect(url, loginUrl);
        expect(options.mode, PreferredLaunchMode.externalApplication);
      },
    );

    // Asking first ("can anything open this?") needs a package-visibility declaration in the
    // manifest on Android 11 and later, which is a permission for a question that does not need
    // asking: the launch itself says whether it worked.
    test('does not ask whether it can launch before launching', () async {
      await UrlLauncherOpener().openUrl(loginUrl);

      expect(platform.canLaunchAsked, 0);
    });

    test(
      'reports that nothing could open the URL when the platform says so',
      () async {
        platform.result = false;

        await expectLater(
          UrlLauncherOpener().openUrl(loginUrl),
          throwsA(isA<OpenerException>()),
        );
      },
    );

    test('reports it, and keeps the cause, when the platform fails', () async {
      platform.failure = PlatformException(code: 'ACTIVITY_NOT_FOUND');

      await expectLater(
        UrlLauncherOpener().openUrl(loginUrl),
        throwsA(
          isA<OpenerException>().having(
            (e) => e.cause,
            'cause',
            isA<PlatformException>(),
          ),
        ),
      );
    });

    test('reports a URL that is not a URL, and launches nothing', () async {
      await expectLater(
        UrlLauncherOpener().openUrl('http://[not-a-host'),
        throwsA(isA<OpenerException>()),
      );
      expect(platform.launched, isEmpty);
    });

    // The URL carries a login request id, and exception text ends up in logs and crash reports.
    test('does not put the URL in what it throws', () async {
      platform.result = false;

      await expectLater(
        UrlLauncherOpener().openUrl(loginUrl),
        throwsA(
          isA<OpenerException>().having(
            (e) => e.toString(),
            'text',
            allOf(isNot(contains('req_secret')), isNot(contains('finnesia'))),
          ),
        ),
      );
    });
  });
}
