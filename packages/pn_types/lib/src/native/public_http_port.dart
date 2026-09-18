/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/transport.dart';

/// HTTP for the calls that happen before there is a session: pairing (`activate`), the
/// native login start/poll, and token refresh.
///
/// A port because the real one is a platform HTTP stack, which does not run under `dart test`.
///
/// It is not [ApiTransport]: that one is the seam the API client sends through, and this one is
/// the HTTP underneath it. The host is an argument, because the calls that run before a session
/// (`activate`, login start/poll, refresh) have no session to read it from. It takes the same
/// [TransportRequest] as the seam rather than growing a second request type.
///
/// Credentials do pass through here: `refresh_token` in the body of a refresh, and the bearer
/// token when `PosTransport` sends an authenticated request. So an implementation must not
/// follow a redirect to another host with those attached (`.claude/rules/security.md` §1.1) —
/// the port's contract is "the request goes to [baseUrl] and nowhere else".
///
/// Pure types — no plugin import may appear here (`.claude/rules/native-ports.md` §2.1).
abstract interface class PublicHttpPort {
  /// Sends [request] to [baseUrl] (`https://apps.finnesia.com`, no trailing slash) and
  /// returns whatever came back — any status, 4xx and 5xx included.
  ///
  /// Throws [TransportException] when there is no response at all.
  Future<TransportResponse> send(String baseUrl, TransportRequest request);
}
