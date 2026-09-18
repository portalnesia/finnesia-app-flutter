/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:collection';

import 'transport.dart';

/// An [ApiTransport] for tests: answers from a queue and records what it was sent.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). It is deliberately not permissive: a request
/// with no queued answer throws, because a fake that quietly returns 200 hides a request
/// the test forgot to expect (§4).
class FakeApiTransport implements ApiTransport {
  /// Every request received, in order — including the ones that failed or were refused.
  final requests = <TransportRequest>[];

  // Each entry produces the response for one request; consumed once, in order. A `Future` and
  // not a plain value, because a test sometimes needs a request that is **out and unanswered** —
  // which is what a timeout is for (`hold`).
  final _outcomes = Queue<Future<TransportResponse> Function()>();

  final _held = Queue<Completer<TransportResponse>>();

  /// Queues a response for the next unanswered request.
  void respond(TransportResponse response) =>
      _outcomes.add(() => Future.value(response));

  /// Queues a network failure for the next unanswered request.
  void fail(TransportException failure) =>
      _outcomes.add(() => Future.error(failure));

  /// Leaves the next request **unanswered** until [release] is called.
  ///
  /// The state a checkout timeout exists for: the request has gone out and the answer has not
  /// come back. A fake that always answers at once cannot exercise that path at all.
  void hold() {
    final completer = Completer<TransportResponse>();
    _held.add(completer);
    _outcomes.add(() => completer.future);
  }

  /// Answers the request held by [hold], in the order the holds were taken.
  void release(TransportResponse response) =>
      _held.removeFirst().complete(response);

  @override
  Future<TransportResponse> send(TransportRequest request) async {
    requests.add(request);
    if (_outcomes.isEmpty) {
      // Method and path only: the headers carry the bearer token and the body carries
      // the sale, and this text ends up in test output and CI logs.
      throw StateError(
        'FakeApiTransport: no response queued for '
        '${request.method.wire} ${request.path}',
      );
    }
    return _outcomes.removeFirst()();
  }
}
