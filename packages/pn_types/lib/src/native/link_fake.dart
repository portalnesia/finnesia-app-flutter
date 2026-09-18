/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:collection';

import 'link_port.dart';

/// A [LinkPort] for tests: can be fed links, and can fail.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). Fails on request (§4: a fake with no failure path
/// never exercises what the caller does about one).
class FakeLinkPort implements LinkPort {
  final _controller = StreamController<Uri>.broadcast();

  /// Every link delivered through [links], in order — including the ones that failed.
  final delivered = <Uri>[];

  final _failures = Queue<LinkException>();

  /// Makes the next delivery throw [failure].
  void failNext(LinkException failure) => _failures.add(failure);

  /// Feeds a link as the platform would: cold-start links are delivered on subscription,
  /// running-app links whenever they are emitted.
  void receive(Uri uri) => _controller.add(uri);

  @override
  Stream<Uri> get links {
    // Delivered through the same stream, so ordering with [receive] stays honest.
    return _controller.stream.map((uri) {
      delivered.add(uri);
      final failure = _failures.isNotEmpty ? _failures.removeFirst() : null;
      if (failure != null) throw failure;
      return uri;
    });
  }
}
