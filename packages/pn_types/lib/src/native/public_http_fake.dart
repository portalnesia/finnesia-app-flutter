/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/native/public_http_port.dart';

/// One call the fake received: where it was addressed, and what was in it.
typedef PublicHttpCall = ({String baseUrl, TransportRequest request});

/// A [PublicHttpPort] for tests: answers from a queue, records every call, and can fail.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). The queue is [FakeApiTransport]'s, so the two fakes
/// cannot drift apart: a call with no queued answer throws, and its message names the method
/// and path but not the headers or the body.
class FakePublicHttp implements PublicHttpPort {
  final _transport = FakeApiTransport();

  /// Every call received, in order — including the ones that failed or were refused.
  final calls = <PublicHttpCall>[];

  /// Queues a response for the next unanswered call.
  void respond(TransportResponse response) => _transport.respond(response);

  /// Queues a network failure for the next unanswered call.
  void fail(TransportException failure) => _transport.fail(failure);

  @override
  Future<TransportResponse> send(String baseUrl, TransportRequest request) {
    calls.add((baseUrl: baseUrl, request: request));
    return _transport.send(request);
  }
}
