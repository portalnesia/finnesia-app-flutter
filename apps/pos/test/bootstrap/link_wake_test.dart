/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/link_fake.dart';
import 'package:pn_types/src/native/link_port.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/session/session_holder.dart';

import '../support/boot_rig.dart';

// The Windows App Link (`apps/pos/lib/native/link/`): the browser's way of saying the login is
// done. The link carries no data (`plan/pos-deeplink/README.md` §D1) — it is a "poll now"
// signal, and the only behaviour to verify is that a running poll wakes when one arrives.
//
// The link is a speed-up over the poll, never a requirement: a link that never arrives (an
// unverified host, a browser that stays on the page) must not change what the login does.

// These tests drive `signIn`, not `resumePendingLogin`. The resume path shares one future across
// callers through a module-level variable and is documented as unusable with two different
// `deps` in one process (`plan/api-client/findings.md` §Langkah 11) — which is exactly what a
// test file does. `signIn` starts its own poll loop, so each test is independent.

const _startedBody =
    '{"data":{"request_id":"req_abc","login_url":"https://erp.perusahaan.com/api/auth/login","expires_in":300}}';
const _pendingBody = '{"data":{"status":"pending"}}';
const _readyBody =
    '{"data":{"status":"ready","session_token":"sess_tok","session_refresh_token":"sess_ref","expires_at":"2026-09-24T10:00:00Z","user":{"id":"user_1","name":"Budi"},"companies":[]}}';

/// A poll HTTP whose answers are held until the test releases them, so the login loop is
/// genuinely waiting when the link arrives. Self-contained: the held-poll fakes in the other
/// test files belong to those files (`testing.md` §3), not to a shared barrel.
class _HeldHttp implements PublicHttpPort {
  final calls = <TransportRequest>[];
  final _answers = <TransportResponse>[];
  final _held = <Completer<TransportResponse>>[];

  void respond(TransportResponse response) => _answers.add(response);

  @override
  Future<TransportResponse> send(String baseUrl, TransportRequest request) {
    calls.add(request);
    if (_answers.isEmpty) {
      final held = Completer<TransportResponse>();
      _held.add(held);
      return held.future;
    }
    return Future.value(_answers.removeAt(0));
  }

  void answerHeld(TransportResponse response) {
    if (_held.isNotEmpty) _held.removeAt(0).complete(response);
  }

  int get pollCount =>
      calls.where((c) => c.path.endsWith('/mobile/poll')).length;
}

/// A paired device with a sign-in running, left **sitting in the wait between two polls** — the
/// state a link is supposed to end.
///
/// The wait never ends on its own ([Rig.delay] is a future that is never completed): if the loop
/// moved on by itself, a second poll would prove nothing about the link. The first poll is
/// answered `pending`, so the loop is genuinely waiting rather than still in its first call.
Future<(AppServices, FakeLinkPort, _HeldHttp)> _signingIn({
  FakeLinkPort? link,
  String firstPollBody = _pendingBody,
}) async {
  final rig = Rig();
  final linkPort = link ?? FakeLinkPort();
  final held = _HeldHttp()
    ..respond(TransportResponse(status: 200, body: _startedBody))
    ..respond(TransportResponse(status: 200, body: firstPollBody));

  // The device must be paired first: `loginNative` refuses to start without a host, and a test
  // that skipped this asserted against a login that never ran.
  await rig.store.write(sessionKey, jsonEncode(paired.toJson()));
  rig.delay = () => Completer<void>().future;

  final result = await rig.bootWithLink(http: held, link: linkPort);
  expect(result, isA<BootReady>());
  final services = (result as BootReady).services;

  // Deliberately NOT awaited: the loop is meant to end up in a wait that never ends, so awaiting
  // it here would hang the test instead of leaving it in the state under test.
  unawaited(services.login.signIn());
  await pumpEventQueue();
  expect(
    held.pollCount,
    1,
    reason: 'the login must be waiting after its first poll',
  );
  return (services, linkPort, held);
}

/// Ends the login a test left waiting and drops the services, so nothing leaks into the next
/// test.
Future<void> _finish(AppServices services) async {
  services.login.cancel();
  await pumpEventQueue();
  services.dispose();
}

void main() {
  group('AppServices — the App Link listener', () {
    test('wakes a running poll when a link arrives', () async {
      final (services, linkPort, held) = await _signingIn();

      linkPort.receive(
        Uri.parse('https://apps-dev.finnesia.com/api/auth/mobile/return'),
      );
      await pumpEventQueue();

      // The same login polled again, immediately — not two seconds later.
      expect(held.pollCount, 2);
      await _finish(services);
    });

    test('a link after the login finished does nothing', () async {
      // The first poll already answers `ready`, so the login is over before the link arrives —
      // which is the state this asserts about.
      final (services, linkPort, held) = await _signingIn(
        firstPollBody: _readyBody,
      );
      final callsBefore = held.calls.length;

      linkPort.receive(
        Uri.parse('https://apps-dev.finnesia.com/api/auth/mobile/return'),
      );
      await pumpEventQueue();

      // No login is running, so there is nothing to wake: no request can appear out of it.
      expect(held.calls.length, callsBefore);
      await _finish(services);
    });

    test('a broken link listener does not break the login', () async {
      final linkPort = FakeLinkPort()
        ..failNext(LinkException('the listener is not available'));
      final (services, linkPort2, held) = await _signingIn(link: linkPort);

      // `failNext` fails the *delivery*, so the link never reaches the handler — which is the
      // point: a platform whose listener is broken must still poll. The poll that was already
      // running is the one that counts, and the failure changed nothing about it.
      linkPort2.receive(
        Uri.parse('https://apps-dev.finnesia.com/api/auth/mobile/return'),
      );
      await pumpEventQueue();

      expect(held.pollCount, 1);
      await _finish(services);
    });

    // The Android decision, pinned: no listener on a platform that has no link, so the plugin is
    // never opened there and the lifecycle wake-up stays the only path (`native/link/active.dart`).
    test('boots and disposes with no link listener at all', () async {
      final rig = Rig();
      await rig.store.write(sessionKey, jsonEncode(paired.toJson()));

      final result = await rig.boot();
      expect(result, isA<BootReady>());
      final services = (result as BootReady).services;

      // Disposing must not throw on a null subscription — the Android path, where nothing was
      // ever subscribed.
      services.dispose();
    });
  });
}
