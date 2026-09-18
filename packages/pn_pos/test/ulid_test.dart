/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/ulid.dart';
import 'package:test/test.dart';

// Ported from `finnesia-monorepo/apps/web/src/lib/ulid.test.ts`. The last oracle case,
// "survives a non-finite clock", has no Dart counterpart: `nowMs` is an `int`, and Dart has
// no NaN integer. Recorded in `plan/api-client/findings.md`, not dropped silently.

// The alphabet the server accepts: oklog/ulid rejects anything outside Crockford base32,
// and a rejected `client_ref` means an offline sale can never be replayed.
final valid = RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$');

const maxMs = 0xFFFFFFFFFFFF; // 2^48 - 1

void main() {
  group('ulid', () {
    test('is exactly 26 characters', () {
      expect(ulid(), hasLength(ulidLength));
    });

    // The whole point of the module: the earlier base36 ref looked like an id but carried
    // characters (U in particular) that ulid.Parse refuses.
    test('only uses Crockford base32 characters', () {
      for (var i = 0; i < 2000; i++) {
        expect(ulid(), matches(valid));
      }
    });

    test('never emits I, L, O or U', () {
      for (var i = 0; i < 2000; i++) {
        expect(ulid(), isNot(matches(RegExp('[ILOU]'))));
      }
    });

    test('gives every id its own value', () {
      final ids = <String>{for (var i = 0; i < 10000; i++) ulid()};
      expect(ids, hasLength(10000));
    });

    // Ids minted in a burst (several sales in one millisecond) must not come back
    // shuffled: the random part is incremented rather than redrawn, so the sequence is
    // non-decreasing and "sort by client_ref" stays truthful.
    test('never goes backwards on the real clock', () {
      var previous = ulid();
      for (var i = 0; i < 5000; i++) {
        final next = ulid();
        expect(next.compareTo(previous) >= 0, isTrue);
        previous = next;
      }
    });

    // A caller-supplied clock (tests, backfills) is independent: it must not consume or
    // disturb the monotonic counter used by genuine ids.
    test('treats an explicit timestamp as independent', () {
      expect(ulid(nowMs: 1700000000000), matches(valid));
      expect(ulid(nowMs: 1700000000000), matches(valid));
    });

    // The oracle only checks that explicit ids are valid. The property its comment
    // promises is stronger: a far-future explicit clock must not leak into real ids.
    test('an explicit timestamp does not poison later real ids', () {
      ulid(nowMs: maxMs);
      final real = ulidTime(ulid());
      expect(real, isNotNull);
      expect((real! - DateTime.now().millisecondsSinceEpoch).abs(),
          lessThan(5000));
    });

    // Sortability is what makes client_ref usable for ordering offline sales server-side.
    test('sorts in generation order', () {
      final a = ulid(nowMs: 1700000000000);
      final b = ulid(nowMs: 1700000000001);
      expect(a.compareTo(b) < 0, isTrue);
    });

    test('encodes and decodes its own timestamp', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(ulidTime(ulid(nowMs: now)), now);
    });

    test('rejects a malformed id when decoding', () {
      expect(ulidTime('too-short'), isNull);
      expect(ulidTime('U' * 26), isNull);
    });

    test('rejects what the source rejects but a permissive parser accepts', () {
      // package:ulid parses lowercase and 32/36-char UUID forms; the source does not.
      expect(ulidTime('01arz3ndektsv4rrffq69g5fav'), isNull);
      // Expected value taken from running the TypeScript `ulidTime`, not from memory.
      expect(ulidTime('01ARZ3NDEKTSV4RRFFQ69G5FAV'), 1469922850259);
      expect(ulidTime('01ARZ3NDEKTSV4RRFFQ69G5FAV'.toLowerCase()), isNull);
      expect(ulidTime('018f7c1e-3a5b-7c9d-8e2f-0123456789ab'), isNull);
      expect(ulidTime(''), isNull);
      // A leading digit above 7 overflows 48 bits; oklog's Parse refuses it, and a
      // decoder that drops the overflow bits would report a wrong time instead.
      expect(ulidTime('8${'0' * 25}'), isNull);
    });

    test('clamps a clock past the 48-bit ceiling instead of emitting garbage',
        () {
      final id = ulid(nowMs: 1 << 60);
      expect(id, matches(valid));
      expect(ulidTime(id), maxMs);
    });

    test('clamps a negative clock to zero', () {
      final id = ulid(nowMs: -5);
      expect(id, matches(valid));
      expect(ulidTime(id), 0);
    });
  });
}
