/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:convert';

import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/public_http_port.dart';

/// A backend that answers by path, so a test does not depend on which of two parallel reads
/// happens to go first, and can hold one answer to look at the screen while it is out.
class RoutedHttp implements PublicHttpPort {
  final calls = <TransportRequest>[];
  final _answers = <String, List<Future<TransportResponse> Function()>>{};
  final _held = <String, Completer<TransportResponse>>{};

  void respond(String path, TransportResponse response) =>
      (_answers[path] ??= []).add(() => Future.value(response));

  /// The next call to [path] gets no answer at all: the connection dropped.
  void fail(String path) => (_answers[path] ??= []).add(
    () => Future.error(TransportException('offline')),
  );

  /// The next call to [path] waits until [release] is called with its answer.
  void hold(String path) => _held[path] = Completer<TransportResponse>();

  void release(String path, TransportResponse response) =>
      _held.remove(path)!.complete(response);

  int count(String path) => calls.where((c) => c.path.startsWith(path)).length;

  @override
  Future<TransportResponse> send(String baseUrl, TransportRequest request) {
    calls.add(request);
    final path = request.path.split('?').first;
    final held = _held[path];
    if (held != null) return held.future;
    final queue = _answers[path];
    if (queue == null || queue.isEmpty) {
      throw StateError('RoutedHttp: no answer queued for $path');
    }
    return queue.removeAt(0)();
  }
}

const activePath = '/api/v1/pos/shifts/active';
const settingsPath = '/api/v1/pos/settings';
const openPath = '/api/v1/pos/shifts/open';

const _json = {'content-type': 'application/json'};

TransportResponse ok(Object? data) => TransportResponse(
  status: 200,
  headers: _json,
  body: jsonEncode({'data': data}),
);

/// A refusal, with [message] as the sentence the server gives for it.
///
/// The sentence goes in `error.description`, which is where the real backend puts it (the
/// translated `key`'s text — see `finnesia-monorepo` `apps/api/internal/cerror`), and which
/// `ApiClient` reads before `error.message`. A fake that put it only in `message` would pass
/// against a client that never looked at `description`, and the sentence on screen would still
/// be wrong in production.
TransportResponse refused(int status, String message) => TransportResponse(
  status: status,
  headers: _json,
  body: jsonEncode({
    'error': {'message': message, 'description': message},
  }),
);
