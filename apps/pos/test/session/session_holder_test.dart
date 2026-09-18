/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:pos/session/session_holder.dart';

// The 3 cases for `isSamePairing` are in `pn_types/test/session_test.dart`, which is where that
// function lives. The cache is an object here, not a module variable, so each test builds its
// own and needs no `beforeEach` to clear a shared one.

const paired = PosSession(
  baseUrl: 'https://erp.perusahaan.com',
  companyId: 'comp_1',
  outletId: 'out_1',
  deviceName: 'Tablet Kasir 1',
  sessionToken: '',
  deviceToken: 'dev_tok_1',
  branding: PosBranding(appName: 'Toko Budi'),
);

/// A paired device with a cashier signed in on it.
const signedIn = PosSession(
  baseUrl: 'https://erp.perusahaan.com',
  companyId: 'comp_1',
  outletId: 'out_1',
  deviceName: 'Tablet Kasir 1',
  sessionToken: 'tok_1',
  deviceToken: 'dev_tok_1',
  sessionRefreshToken: 'refresh_1',
  expiresAt: '2026-09-24T10:00:00Z',
  user: SessionUser(id: 'usr_1', name: 'Budi'),
  companies: [
    UserCompany(
      id: 'uc_1',
      userId: 'usr_1',
      companyId: 'comp_1',
      role: 'cashier',
      isActive: true,
    ),
  ],
  branding: PosBranding(appName: 'Toko Budi'),
);

// What is in the store, decoded, so a test asserts on the persisted session and not on the
// JSON text around it.
PosSession? stored(FakeStorePort store) {
  final raw = store.values[sessionKey];
  if (raw == null) return null;
  return PosSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

FakeStorePort seeded(PosSession s) =>
    FakeStorePort({sessionKey: jsonEncode(s.toJson())});

void main() {
  group('hydrate', () {
    test(
      'fills the cache from the store, so the transport has something to read',
      () async {
        final holder = SessionHolder(seeded(paired));

        final hydrated = await holder.hydrate();

        expect(hydrated?.outletId, 'out_1');
        expect(holder.current?.outletId, 'out_1');
      },
    );

    test('leaves the cache empty when nothing was ever stored', () async {
      final holder = SessionHolder(FakeStorePort());

      expect(await holder.hydrate(), isNull);
      expect(holder.current, isNull);
    });

    // A store that has been cleared (device reset) must clear the cache too, or the app
    // would keep talking to a tenant the device is no longer paired with.
    test('replaces a previous session rather than merging into it', () async {
      final holder = SessionHolder(FakeStorePort());
      await holder.save(paired);

      final reset = SessionHolder(FakeStorePort());
      await reset.hydrate();

      expect(reset.current, isNull);
    });
  });

  // The "corrupt data reads as absent" contract is enforced here, not in the store: the store
  // deals in `String` values and cannot know what a decoded value should look like
  // (see `StorePort`).
  group('hydrate, when what is stored is no good', () {
    // `main` awaits hydrate before anything renders, so throwing here would leave the app
    // with nothing on screen — worse than an unpaired device, which at least says so.
    test(
      'reads text that is not JSON as no session, without throwing',
      () async {
        final holder = SessionHolder(FakeStorePort({sessionKey: '{not json'}));

        expect(await holder.hydrate(), isNull);
        expect(holder.current, isNull);
      },
    );

    test('reads valid JSON of the wrong shape as no session', () async {
      for (final wrong in [
        '[]',
        'null',
        '"a string"',
        '42',
        '{}',
        '{"baseUrl":"https://x"}',
        '{"baseUrl":1,"companyId":"c","outletId":"o","sessionToken":""}',
        '{"baseUrl":"https://x","companyId":"c","outletId":"o"}',
      ]) {
        final holder = SessionHolder(FakeStorePort({sessionKey: wrong}));

        expect(await holder.hydrate(), isNull, reason: wrong);
        expect(holder.current, isNull, reason: wrong);
      }
    });

    test(
      'drops a session that was in memory when what is stored has gone bad',
      () async {
        final store = FakeStorePort();
        final holder = SessionHolder(store);
        await holder.save(paired);
        await store.write(sessionKey, '{not json');

        await holder.hydrate();

        expect(holder.current, isNull);
      },
    );

    // The other half. A failing disk is not the same as a device that was never paired:
    // treating a transient read failure as "unpaired" could send a cashier to re-pair a
    // device that is in fact paired. So the failure surfaces, and the session in memory is
    // left as it was.
    test(
      'lets a storage failure through and leaves the session in memory alone',
      () async {
        final store = FakeStorePort();
        final holder = SessionHolder(store);
        await holder.save(paired);
        store.failNext(StoreException('disk error'));

        await expectLater(holder.hydrate(), throwsA(isA<StoreException>()));

        expect(holder.current, paired);
      },
    );
  });

  group('save', () {
    // Both, not either: the store survives a restart, the cache is what the transport
    // reads on the very next request.
    test('writes to the store and the cache together', () async {
      final store = FakeStorePort();
      final holder = SessionHolder(store);

      await holder.save(paired);

      expect(stored(store), paired);
      expect(holder.current, paired);
    });
  });

  group('clearToken', () {
    test('keeps the pairing and clears only the credential', () async {
      final holder = SessionHolder(FakeStorePort());
      await holder.save(signedIn);

      await holder.clearToken();

      final session = holder.current;
      expect(session?.baseUrl, 'https://erp.perusahaan.com');
      expect(session?.companyId, 'comp_1');
      expect(session?.outletId, 'out_1');
      expect(session?.deviceName, 'Tablet Kasir 1');
      expect(session?.branding?.appName, 'Toko Budi');
      expect(session?.sessionToken, '');
    });

    // Leaving it behind would let a refresh quietly sign the device back in, which is the
    // opposite of what a cashier ending their shift asked for.
    test(
      'drops the refresh token, so a signed-out device cannot renew itself',
      () async {
        final holder = SessionHolder(FakeStorePort());
        await holder.save(signedIn);

        await holder.clearToken();

        expect(holder.current?.sessionRefreshToken, isNull);
      },
    );

    test(
      'drops the expiry and the cashier profile with the credential',
      () async {
        final holder = SessionHolder(FakeStorePort());
        await holder.save(signedIn);

        await holder.clearToken();

        expect(holder.current?.expiresAt, isNull);
        expect(holder.current?.user, isNull);
      },
    );

    // The memberships are who the cashier is inside the company. Leaving them behind would
    // let a signed-out device keep answering "may I?" with the previous cashier's roles.
    test('drops the company memberships with the credential', () async {
      final holder = SessionHolder(FakeStorePort());
      await holder.save(signedIn);

      await holder.clearToken();

      expect(holder.current?.companies, isNull);
    });

    // The device token is the tablet's identity, not the cashier's credential. Signing out is
    // a shift change, and a tablet that lost its token here would have to re-pair — which is
    // exactly what `clearToken` exists to avoid. The server uses it to write presence on every
    // request, so dropping it also silently blanks the device list in the dashboard.
    test('keeps the device token, which belongs to the tablet', () async {
      final holder = SessionHolder(FakeStorePort());
      await holder.save(signedIn);

      await holder.clearToken();

      expect(holder.current?.deviceToken, 'dev_tok_1');
    });

    test('persists the device token across a sign-out', () async {
      final store = FakeStorePort();
      final holder = SessionHolder(store);
      await holder.save(signedIn);

      await holder.clearToken();

      expect(stored(store)?.deviceToken, 'dev_tok_1');
    });

    test(
      'persists the sign-out, so a restart does not resurrect the token',
      () async {
        final store = FakeStorePort();
        final holder = SessionHolder(store);
        await holder.save(signedIn);

        await holder.clearToken();

        expect(stored(store)?.sessionToken, '');
        expect(stored(store)?.sessionRefreshToken, isNull);
        expect(stored(store)?.baseUrl, 'https://erp.perusahaan.com');
      },
    );

    // Signing out a device that was never paired must not invent a session for it.
    test('does nothing when there is no session', () async {
      final store = FakeStorePort();
      final holder = SessionHolder(store);

      await holder.clearToken();

      expect(holder.current, isNull);
      expect(store.values[sessionKey], isNull);
      expect(store.operations, isEmpty);
    });

    test('leaves a paired device that never signed in paired', () async {
      final holder = SessionHolder(FakeStorePort());
      await holder.save(paired);

      await holder.clearToken();

      expect(holder.current?.baseUrl, 'https://erp.perusahaan.com');
      expect(holder.current?.sessionToken, '');
    });
  });

  // What the server says when a tablet is deleted from the dashboard. The tablet has to stop
  // transacting and go back to pairing — but the cashier's login is not the server's business
  // here, and signing them out would make them sign in again for nothing.
  group('unregisterDevice', () {
    test('marks the pairing revoked and clears the device identity', () async {
      final holder = SessionHolder(FakeStorePort());
      await holder.save(signedIn);

      await holder.unregisterDevice();

      expect(holder.current?.deviceRevoked, isTrue);
      expect(holder.current?.deviceToken, isNull);
    });

    // The device token cannot be reissued without pairing again, and the branding is the
    // tenant's — both belong to the pairing that no longer exists.
    test('clears the branding with the token', () async {
      final holder = SessionHolder(FakeStorePort());
      await holder.save(signedIn);

      await holder.unregisterDevice();

      expect(holder.current?.branding, isNull);
    });

    // The contract is explicit: the cashier stays signed in, and pairing again is enough to
    // carry on. A shift that is open on the server is not touched by deleting a device.
    test('keeps the cashier signed in', () async {
      final holder = SessionHolder(FakeStorePort());
      await holder.save(signedIn);

      await holder.unregisterDevice();

      expect(holder.current?.sessionToken, 'tok_1');
      expect(holder.current?.user?.id, 'usr_1');
    });

    // Without this the tablet would be revoked in memory only, and the next launch would read
    // the old session back and carry on as though the device still existed.
    test('persists it, so a restart does not resurrect the pairing', () async {
      final store = FakeStorePort();
      final holder = SessionHolder(store);
      await holder.save(signedIn);

      await holder.unregisterDevice();

      expect(stored(store)?.deviceRevoked, isTrue);
      expect(stored(store)?.deviceToken, isNull);
    });

    test('does nothing when there is no session', () async {
      final store = FakeStorePort();
      final holder = SessionHolder(store);

      await holder.unregisterDevice();

      expect(holder.current, isNull);
      expect(store.operations, isEmpty);
    });

    // Pairing again is what clears it. The flag exists to move the device off the till, not to
    // blacklist the tablet — the same tablet may be paired to a different outlet.
    test('is cleared by saving a freshly paired session', () async {
      final holder = SessionHolder(FakeStorePort());
      await holder.save(signedIn);
      await holder.unregisterDevice();

      await holder.save(paired);

      expect(holder.current?.deviceRevoked, isFalse);
      expect(holder.current?.deviceToken, 'dev_tok_1');
    });
  });

  group('subscribe', () {
    // Records what a subscriber is told, and how to stop listening.
    ({List<PosSession?> seen, void Function() stop}) listen(
      SessionHolder holder,
    ) {
      final seen = <PosSession?>[];
      return (seen: seen, stop: holder.subscribe(seen.add));
    }

    // The reported bug: pairing saved the session from the pairing screen, the provider
    // that mirrors it into UI state never heard about it, and the gate sent the freshly
    // paired device straight back to the pairing screen.
    test('tells subscribers when pairing saves a session', () async {
      final holder = SessionHolder(FakeStorePort());
      final l = listen(holder);

      await holder.save(paired);
      l.stop();

      expect(l.seen, hasLength(1));
      expect(l.seen.first?.outletId, 'out_1');
    });

    test('tells subscribers when the cashier signs out, with the pairing still in it', () async {
      final holder = SessionHolder(FakeStorePort());
      await holder.save(signedIn);
      final l = listen(holder);

      await holder.clearToken();
      l.stop();

      expect(l.seen, hasLength(1));
      expect(l.seen.first?.baseUrl, 'https://erp.perusahaan.com');
      expect(l.seen.first?.sessionToken, '');
    });

    test('tells subscribers when the device is reset', () async {
      final holder = SessionHolder(FakeStorePort());
      await holder.save(signedIn);
      final l = listen(holder);

      await holder.clear();
      l.stop();

      expect(l.seen, [null]);
    });

    test('stops telling a subscriber that unsubscribed', () async {
      final holder = SessionHolder(FakeStorePort());
      final l = listen(holder);

      l.stop();
      await holder.save(paired);

      expect(l.seen, isEmpty);
    });

    test('tells every subscriber, not just the first', () async {
      final holder = SessionHolder(FakeStorePort());
      final first = listen(holder);
      final second = listen(holder);

      await holder.save(paired);
      first.stop();
      second.stop();

      expect(first.seen, hasLength(1));
      expect(second.seen, hasLength(1));
    });

    // Clearing the token of a device with no session does nothing; waking the UI for it would
    // be a render with no new information in it.
    test('stays quiet when a no-op write changes nothing', () async {
      final holder = SessionHolder(FakeStorePort());
      final l = listen(holder);

      await holder.clearToken();
      l.stop();

      expect(l.seen, isEmpty);
    });

    // Not in the oracle, but the source notifies here too, and the UI needs it: the provider
    // is built before hydrate finishes.
    test('tells subscribers what hydrate found', () async {
      final holder = SessionHolder(seeded(paired));
      final l = listen(holder);

      await holder.hydrate();
      l.stop();

      expect(l.seen, [paired]);
    });

    // Dart-only: JavaScript's Set tolerates a delete during iteration, Dart's throws. A
    // listener that is done after one notification (a one-shot gate) is ordinary.
    test(
      'lets a subscriber unsubscribe from inside its own notification',
      () async {
        final holder = SessionHolder(FakeStorePort());
        final secondSeen = <PosSession?>[];
        late void Function() stopFirst;
        stopFirst = holder.subscribe((_) => stopFirst());
        holder.subscribe(secondSeen.add);

        await holder.save(paired);

        expect(secondSeen, hasLength(1));
      },
    );

    // Dart-only in effect: a listener that throws is a bug in the UI, and it must not cost
    // the cashier the pairing. The session is still persisted, and the error still surfaces.
    test('still persists the session when a subscriber throws, and lets the error out', () async {
      final store = FakeStorePort();
      final holder = SessionHolder(store);
      holder.subscribe((_) => throw StateError('ui bug'));

      await expectLater(holder.save(paired), throwsA(isA<StateError>()));

      expect(stored(store), paired);
    });
  });

  // Not in the oracle, and none of these had a RED to observe: the order below is what the
  // source does and what `_commit` already does, so they pin it rather than drive it.
  //
  // The cache is written first because the transport reads it on the very next request, so
  // a failing disk must not stop the running app from using the session it just paired or
  // rotated. The failure still reaches the caller, which is what lets the pairing screen say
  // "could not save" instead of pretending.
  group('when the storage fails', () {
    test('save: the session is in memory, subscribers were told, and the error surfaces', () async {
      final store = FakeStorePort()..failNext(StoreException('disk full'));
      final holder = SessionHolder(store);
      final seen = <PosSession?>[];
      holder.subscribe(seen.add);

      await expectLater(holder.save(paired), throwsA(isA<StoreException>()));

      expect(holder.current, paired);
      expect(seen, [paired]);
      expect(store.values[sessionKey], isNull);
    });

    test(
      'clearToken: the cashier is signed out in memory, and the error surfaces',
      () async {
        final store = FakeStorePort();
        final holder = SessionHolder(store);
        await holder.save(signedIn);
        store.failNext(StoreException('disk full'));

        await expectLater(holder.clearToken(), throwsA(isA<StoreException>()));

        expect(holder.current?.sessionToken, '');
        expect(stored(store)?.sessionToken, 'tok_1');
      },
    );

    test(
      'clear: the device is unpaired in memory, and the error surfaces',
      () async {
        final store = FakeStorePort();
        final holder = SessionHolder(store);
        await holder.save(paired);
        store.failNext(StoreException('locked'));

        await expectLater(holder.clear(), throwsA(isA<StoreException>()));

        expect(holder.current, isNull);
        expect(stored(store), paired);
      },
    );
  });

  group('clear', () {
    test('empties the cache and the store', () async {
      final store = FakeStorePort();
      final holder = SessionHolder(store);
      await holder.save(paired);

      await holder.clear();

      expect(holder.current, isNull);
      expect(store.values[sessionKey], isNull);
    });
  });
}
