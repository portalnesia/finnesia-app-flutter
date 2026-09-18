/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:ulid/ulid.dart';

/// Ported from `finnesia-monorepo/apps/web/src/lib/ulid.ts`, on top of `package:ulid`
/// instead of a hand-written encoder.
///
/// The server validates every `client_ref` (the offline-checkout idempotency key) with
/// `ulid.Parse` from oklog/ulid, so a client-generated ref has to be a real ULID — a
/// base36 look-alike is rejected with a 400, which would strand the sale in the failed
/// queue forever. Layout is the standard one: 10 base32 chars of millisecond timestamp
/// followed by 16 chars of randomness, so lexicographic order == creation order.
const ulidLength = 26;

// A ULID carries a 48-bit timestamp, so the leading character can only reach '7'. A bad
// clock must yield a parseable ref rather than one the server refuses, hence the clamp.
const _maxTimeMs = 0xFFFFFFFFFFFF;

// Crockford base32 has no I, L, O or U, and the leading character stops at '7' (48 bits).
// Uppercase only — the source's decoder is case-sensitive, and `package:ulid` is not.
final _shape = RegExp(r'^[0-7][0-9A-HJKMNP-TV-Z]{25}$');

// Ids minted inside the same millisecond must still sort in the order they were created:
// the previous random part is incremented instead of redrawn, which is what keeps a burst
// of offline sales in the order they were rung up. `monotonicBufferBits: 1` guarantees the
// counter half its range of headroom, and `incrementMillisOnOverflow` moves to the next
// millisecond if it ever runs out — where the source wraps to zero and breaks the order,
// and the package default would throw mid-sale.
final _realClock = UlidFactory(
  monotonic: true,
  monotonicBufferBits: 1,
  incrementMillisOnOverflow: true,
);

// A caller-supplied timestamp (tests, backfills) must not touch the counter above:
// a far-future test clock would otherwise be reused by genuine ids minted afterwards.
final _explicitClock = UlidFactory();

/// A new ULID. Pass [nowMs] only to pin the timestamp (tests, backfills); it is clamped
/// into `0..2^48-1`, and it opts out of monotonic ordering.
String ulid({int? nowMs}) {
  if (nowMs == null) return _realClock.next().toBase32();
  return _explicitClock.next(millis: nowMs.clamp(0, _maxTimeMs)).toBase32();
}

/// The epoch milliseconds a ULID was minted at, or `null` if [id] is not one.
///
/// Used by anything that needs to know when a pending sale was minted without trusting
/// its own metadata.
int? ulidTime(String id) {
  if (!_shape.hasMatch(id)) return null;
  return Ulid.parse(id).toMillis();
}
