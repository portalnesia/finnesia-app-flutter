/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/exit_notice_port.dart';
import 'package:pos/native/exit_notice/exit_notice_channel.dart';

/// The runner's side of `pos/exit_notice`, with no platform behind it: records what it was told,
/// or answers as a platform that failed or has no handler at all.
class _FakeHost {
  _FakeHost() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ChannelExitNotice.channel, _handle);
  }

  final calls = <MethodCall>[];
  Object? failure;

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    if (failure != null) throw failure!;
    return null;
  }

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ChannelExitNotice.channel, null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChannelExitNotice', () {
    late _FakeHost host;

    setUp(() => host = _FakeHost());
    tearDown(() => host.dispose());

    test('hands the platform the title and the body', () async {
      await ChannelExitNotice().setNotice(
        const ExitNotice(
          title: 'Shift masih aktif',
          body: 'Shift SH-1 belum ditutup.',
        ),
      );

      expect(host.calls.single.method, 'set');
      expect(host.calls.single.arguments, {
        'title': 'Shift masih aktif',
        'body': 'Shift SH-1 belum ditutup.',
      });
    });

    test('tells the platform to say nothing', () async {
      await ChannelExitNotice().setNotice(null);

      expect(host.calls.single.method, 'clear');
    });

    test('reports a platform failure', () async {
      host.failure = PlatformException(code: 'boom');

      await expectLater(
        ChannelExitNotice().setNotice(null),
        throwsA(isA<ExitNoticeException>()),
      );
    });

    // Linux, macOS and iOS have no handler: there is no exit there this could speak at, so
    // nobody is missing a notice.
    test('treats a platform with no handler as nothing to tell', () async {
      host.dispose();

      await ChannelExitNotice().setNotice(null);
    });
  });
}
