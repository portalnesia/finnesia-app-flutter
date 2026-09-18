/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_pending_sale_fake.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/queue/queue_sync.dart';
import 'package:pos/session/session_holder.dart';

// Written new: there is no source to port (`use-pos-sync.ts`'s timers and event listeners belong
// to a browser tab). What is ported is `syncQueue` itself (`pn_pos`, step Q3); this is the
// background worker that calls it (`plan/offline-queue/README.md` §5.2).

const draft = POSCheckoutDTO(
  outletId: 'out_1',
  transactionDate: '2026-09-22',
  items: [
    POSCheckoutItemDTO(
      productId: 'p1',
      unitId: 'u1',
      quantity: 1,
      price: 15000,
    ),
  ],
  payments: [POSTenderDTO(method: POSTenderMethod.cash, amount: 15000)],
);

const saleJson =
    '{"id":"x1","number":"POS-0001","shift_id":"s1","outlet_id":"out_1",'
    '"cashier_id":"u1","transaction_date":"2026-09-22","subtotal":15000,'
    '"discount_amount":0,"tax_amount":0,"grand_total":15000,'
    '"tendered_amount":15000,"change_amount":0,"status":"POSTED",'
    '"created_at":"2026-09-22T03:00:00Z"}';

PendingSale entry({
  String ref = 'REF-1',
  String cashierId = 'u1',
  String? shiftId,
  PendingSaleStatus status = PendingSaleStatus.pending,
}) => PendingSale(
  clientRef: ref,
  companyId: 'comp_1',
  outletId: 'out_1',
  cashierId: cashierId,
  shiftId: shiftId,
  status: status,
  paidAt: '2026-09-22T03:00:00.000Z',
  createdAt: '2026-09-22T03:00:00.000Z',
  payload: draft,
  receipt: const PendingSaleReceipt(
    subtotal: 15000,
    discountAmount: 0,
    taxAmount: 0,
    grandTotal: 15000,
    tenderedAmount: 15000,
    changeAmount: 0,
    items: [],
  ),
);

TransportResponse json(int status, String body) => TransportResponse(
  status: status,
  headers: const {'content-type': 'application/json'},
  body: body,
);

/// What `/pos/shifts/active` answers: no shift open, or the one with [id].
TransportResponse shiftAnswer([String? id]) => json(
  200,
  '{"data":${id == null ? 'null' : '{"id":"$id","number":"SH-1","cashier_id":"u1",'
            '"outlet_id":"out_1","opened_at":"2026-09-22T01:00:00Z","opening_cash":0,'
            '"total_sales":0,"total_transactions":0}'}}',
);

TransportResponse saleAnswer() => json(200, '{"data":$saleJson}');

/// Paired, with nobody signed in: a token has not been issued yet.
Future<void> pairOnly(SessionHolder session) => session.save(
  const PosSession(
    baseUrl: 'https://erp.perusahaan.com',
    companyId: 'comp_1',
    outletId: 'out_1',
    sessionToken: '',
  ),
);

/// Paired, and [userId] is at the till.
Future<void> signIn(SessionHolder session, {String userId = 'u1'}) =>
    session.save(
      PosSession(
        baseUrl: 'https://erp.perusahaan.com',
        companyId: 'comp_1',
        outletId: 'out_1',
        sessionToken: 'tok_1',
        user: SessionUser(id: userId),
      ),
    );

/// A session that already has a cashier signed in **before** any [QueueSync] is listening to it,
/// so building one against it does not itself count as the sign-in that D-Q8 wakes a pass for —
/// that trigger has its own tests, under "triggers".
Future<SessionHolder> signedIn({String userId = 'u1'}) async {
  final session = SessionHolder(FakeStorePort());
  await signIn(session, userId: userId);
  return session;
}

({
  QueueSync sync,
  FakeApiTransport transport,
  FakePendingSaleStore queue,
  SessionHolder session,
  FakeAnalytics analytics,
})
rig({Duration interval = const Duration(hours: 1), SessionHolder? session}) {
  final transport = FakeApiTransport();
  final queue = FakePendingSaleStore();
  final resolvedSession = session ?? SessionHolder(FakeStorePort());
  final analytics = FakeAnalytics();
  return (
    sync: QueueSync(
      client: ApiClient(transport: transport, language: () => 'id'),
      queue: queue,
      session: resolvedSession,
      analytics: analytics,
      interval: interval,
    ),
    transport: transport,
    queue: queue,
    session: resolvedSession,
    analytics: analytics,
  );
}

void main() {
  group('with nobody to send for', () {
    test('does nothing when the device is not paired', () async {
      final r = rig();
      addTearDown(r.sync.dispose);

      await r.sync.sync();

      expect(r.transport.requests, isEmpty);
    });

    test(
      'does nothing, and does not count an attempt, when nobody is signed in',
      () async {
        final session = SessionHolder(FakeStorePort());
        await pairOnly(session);
        final r = rig(session: session);
        addTearDown(r.sync.dispose);
        await r.queue.enqueue(entry());

        await r.sync.sync();

        expect(r.transport.requests, isEmpty);
        expect((await r.queue.readAll()).single.attempts, 0);
      },
    );

    test('does not ask the server anything when the queue is empty', () async {
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);

      await r.sync.sync();

      expect(r.transport.requests, isEmpty);
    });

    test('lets a queue that cannot be read reach the caller, rather than '
        'treating it as empty', () async {
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      r.queue.failRead = true;

      await expectLater(
        r.sync.sync(),
        throwsA(isA<PendingSaleStoreException>()),
      );
    });
  });

  group('sending', () {
    test(
      'sends a pending sale, and removes it once the server records it',
      () async {
        final r = rig(session: await signedIn());
        addTearDown(r.sync.dispose);
        await r.queue.enqueue(entry());
        r.transport
          ..respond(shiftAnswer())
          ..respond(saleAnswer());

        await r.sync.sync();

        expect(await r.queue.readAll(), isEmpty);
      },
    );

    test('keeps shift_id when it is the shift open now', () async {
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry(shiftId: 's1'));
      r.transport
        ..respond(shiftAnswer('s1'))
        ..respond(saleAnswer());

      await r.sync.sync();

      final body =
          jsonDecode(r.transport.requests.last.body!) as Map<String, dynamic>;
      expect(body['shift_id'], 's1');
    });

    test('drops shift_id when a different shift is open now', () async {
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry(shiftId: 's1'));
      r.transport
        ..respond(shiftAnswer('s2'))
        ..respond(saleAnswer());

      await r.sync.sync();

      final body =
          jsonDecode(r.transport.requests.last.body!) as Map<String, dynamic>;
      expect(body.containsKey('shift_id'), isFalse);
    });

    test(
      'sends without a shift_id when it cannot ask which one is open',
      () async {
        final r = rig(session: await signedIn());
        addTearDown(r.sync.dispose);
        await r.queue.enqueue(entry(shiftId: 's1'));
        r.transport
          ..fail(TransportException('down'))
          ..respond(saleAnswer());

        await r.sync.sync();

        final body =
            jsonDecode(r.transport.requests.last.body!) as Map<String, dynamic>;
        expect(body.containsKey('shift_id'), isFalse);
        expect(await r.queue.readAll(), isEmpty);
      },
    );

    test(
      'marks a refused sale failed, with the server sentence, and carries on',
      () async {
        final r = rig(session: await signedIn());
        addTearDown(r.sync.dispose);
        await r.queue.enqueue(entry());
        r.transport
          ..respond(shiftAnswer())
          ..respond(json(422, '{"message":"Stok tidak cukup"}'));

        await r.sync.sync();

        final stored = (await r.queue.readAll()).single;
        expect(stored.status, PendingSaleStatus.failed);
        expect(stored.error, 'Stok tidak cukup');
      },
    );

    test(
      'leaves a sale pending on a 401, rather than marking it failed',
      () async {
        final r = rig(session: await signedIn());
        addTearDown(r.sync.dispose);
        await r.queue.enqueue(entry());
        r.transport
          ..respond(shiftAnswer())
          ..respond(json(401, '{}'));

        await r.sync.sync();

        final stored = (await r.queue.readAll()).single;
        expect(stored.status, PendingSaleStatus.pending);
        expect(stored.attempts, 1);
      },
    );

    // 402 is not one thing. After the billing sprint the backend answers it for three different
    // reasons (`finnesia-monorepo` `middleware/tenant.go`, `service/outlet_resolver.go`), and a
    // 403 `outlet_inactive` is a fourth that belongs in the same bucket: the server understood
    // the sale and is refusing on the state of the tenant or the outlet. Parking any of them as
    // `failed` would strand money the cashier has already taken, for a reason the cashier cannot
    // act on, and none of them is permanent.
    //
    // The classifier must NOT map the key to a local sentence: the backend already translates
    // each key (`errors.yaml`), so the server's own sentence is what is stored and shown. What
    // the key decides is only whether the entry is blocked, never which text appears.
    test(
      'keeps a 402 subscription_expired pending, with the server sentence',
      () async {
        final r = rig(session: await signedIn());
        addTearDown(r.sync.dispose);
        await r.queue.enqueue(entry());
        r.transport
          ..respond(shiftAnswer())
          ..respond(
            json(
              402,
              '{"error":{"key":"subscription_expired","description":"Masa berlaku '
              'langganan untuk perusahaan ini telah berakhir"}}',
            ),
          );

        await r.sync.sync();

        final stored = (await r.queue.readAll()).single;
        expect(stored.status, PendingSaleStatus.pending);
        expect(stored.attempts, 1);
        expect(
          stored.error,
          'Masa berlaku langganan untuk perusahaan ini telah berakhir',
        );
      },
    );

    // What this locks is that the sentence travels through **unchanged**: the fixture text is
    // deliberately unlike anything in the POS, so a classifier that mapped `key` to a local
    // table would store a different string and fail here. The three keys already have three
    // different sentences on the server; POS must not have an opinion about them.
    test(
      'passes a second 402 key through as its own sentence, not a shared one',
      () async {
        final r = rig(session: await signedIn());
        addTearDown(r.sync.dispose);
        await r.queue.enqueue(entry());
        r.transport
          ..respond(shiftAnswer())
          ..respond(
            json(
              402,
              '{"error":{"key":"user_over_quota","description":"Jumlah kursi '
              'pengguna pada paket ini sudah penuh"}}',
            ),
          );

        await r.sync.sync();

        final stored = (await r.queue.readAll()).single;
        expect(stored.status, PendingSaleStatus.pending);
        expect(
          stored.error,
          'Jumlah kursi pengguna pada paket ini sudah penuh',
        );
      },
    );

    test('passes a third 402 key through as its own sentence too', () async {
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry());
      r.transport
        ..respond(shiftAnswer())
        ..respond(
          json(
            402,
            '{"error":{"key":"outlet_over_quota","description":"Batas jumlah '
            'outlet untuk paket ini sudah tercapai"}}',
          ),
        );

      await r.sync.sync();

      final stored = (await r.queue.readAll()).single;
      expect(stored.status, PendingSaleStatus.pending);
      expect(
        stored.error,
        'Batas jumlah outlet untuk paket ini sudah tercapai',
      );
    });

    test('blocks a 402 with no key and one with an unknown key', () async {
      // 402 is a block whatever it says: a backend that adds a fourth reason, or a proxy that
      // strips the error object, must not turn a blocked sale into a failed one. The block
      // direction is the safe one (spec §4h).
      for (final body in [
        '{}',
        '{"error":{"key":"mystery_reason","description":"Coba lagi nanti"}}',
      ]) {
        final r = rig(session: await signedIn());
        addTearDown(r.sync.dispose);
        await r.queue.enqueue(entry());
        r.transport
          ..respond(shiftAnswer())
          ..respond(json(402, body));

        await r.sync.sync();

        final stored = (await r.queue.readAll()).single;
        expect(stored.status, PendingSaleStatus.pending, reason: 'body $body');
      }
    });

    test(
      'blocks a 403 outlet_inactive, which also clears on its own',
      () async {
        final r = rig(session: await signedIn());
        addTearDown(r.sync.dispose);
        await r.queue.enqueue(entry());
        r.transport
          ..respond(shiftAnswer())
          ..respond(
            json(
              403,
              '{"error":{"key":"outlet_inactive","description":"Outlet ini '
              'sedang tidak aktif"}}',
            ),
          );

        await r.sync.sync();

        final stored = (await r.queue.readAll()).single;
        expect(stored.status, PendingSaleStatus.pending);
        expect(stored.error, 'Outlet ini sedang tidak aktif');
      },
    );

    test('does not blanket-block a 403: not_company_member is final', () async {
      // The negative for the test above. "You are not a member of this company" does not heal
      // by waiting, so blocking it would leave the queue stuck with no way out. The rule is a
      // key allow-list, not `status == 403` (spec §6 2).
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry());
      r.transport
        ..respond(shiftAnswer())
        ..respond(
          json(
            403,
            '{"error":{"key":"not_company_member","description":"Anda bukan '
            'anggota perusahaan ini"}}',
          ),
        );

      await r.sync.sync();

      final stored = (await r.queue.readAll()).single;
      expect(stored.status, PendingSaleStatus.failed);
      expect(stored.error, 'Anda bukan anggota perusahaan ini');
    });

    test('still parks a plain 4xx as failed', () async {
      // The regression guard for the classifier: adding the block branch must not swallow the
      // ordinary refusal.
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry());
      r.transport
        ..respond(shiftAnswer())
        ..respond(json(422, '{"message":"Stok tidak cukup"}'));

      await r.sync.sync();

      final stored = (await r.queue.readAll()).single;
      expect(stored.status, PendingSaleStatus.failed);
      expect(stored.error, 'Stok tidak cukup');
    });

    test(
      'a 5xx and a network failure are not blocks: no reason is written',
      () async {
        // The negative for the block branch. Neither has a server sentence, and storing one would
        // invent an explanation the cashier cannot act on.
        final server = rig(session: await signedIn());
        addTearDown(server.sync.dispose);
        await server.queue.enqueue(entry());
        server.transport
          ..respond(shiftAnswer())
          ..respond(json(503, '{}'));

        await server.sync.sync();

        final afterServer = (await server.queue.readAll()).single;
        expect(afterServer.status, PendingSaleStatus.pending);
        expect(afterServer.error, isNull);

        final offline = rig(session: await signedIn());
        addTearDown(offline.sync.dispose);
        await offline.queue.enqueue(entry());
        offline.transport
          ..respond(shiftAnswer())
          ..fail(TransportException('down'));

        await offline.sync.sync();

        final afterOffline = (await offline.queue.readAll()).single;
        expect(afterOffline.status, PendingSaleStatus.pending);
        expect(afterOffline.error, isNull);
      },
    );

    test(
      'a block stops the pass: one request, and the next sale is untouched',
      () async {
        // A block on the tenant applies to every sale behind the first one, so sending the rest
        // would only burn requests. Same bound as `SendUnreachable`.
        final r = rig(session: await signedIn());
        addTearDown(r.sync.dispose);
        await r.queue.enqueue(entry(ref: 'REF-1'));
        await r.queue.enqueue(entry(ref: 'REF-2'));
        r.transport
          ..respond(shiftAnswer())
          ..respond(
            json(
              402,
              '{"error":{"key":"subscription_expired","description":"habis"}}',
            ),
          );

        await r.sync.sync();

        expect(r.transport.requests, hasLength(2)); // shift lookup + one sale
        final entries = await r.queue.readAll();
        expect(entries.map((e) => e.clientRef), ['REF-1', 'REF-2']);
        expect(entries[0].attempts, 1);
        expect(entries[1].attempts, 0);
      },
    );

    test('once the block is gone, the next pass drains the queue', () async {
      // The block is not sticky, which is the whole reason the entry stays `pending`.
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry());
      r.transport
        ..respond(shiftAnswer())
        ..respond(
          json(
            402,
            '{"error":{"key":"subscription_expired","description":"habis"}}',
          ),
        );

      await r.sync.sync();
      expect(await r.queue.count(), 1);

      r.transport
        ..respond(shiftAnswer())
        ..respond(saleAnswer());
      await r.sync.sync();

      expect(await r.queue.readAll(), isEmpty);
    });

    test('sends only the sales the signed-in cashier typed', () async {
      final r = rig(session: await signedIn(userId: 'u1'));
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry(ref: 'REF-1', cashierId: 'u1'));
      await r.queue.enqueue(entry(ref: 'REF-2', cashierId: 'someone_else'));
      r.transport
        ..respond(shiftAnswer())
        ..respond(saleAnswer());

      await r.sync.sync();

      final left = await r.queue.readAll();
      expect(left.map((e) => e.clientRef), ['REF-2']);
      expect(left.single.attempts, 0);
    });
  });

  group('while a pass is under way', () {
    test('two calls at once share the one pass', () async {
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry());
      r.transport
        ..respond(shiftAnswer())
        ..respond(saleAnswer());

      final first = r.sync.sync();
      final second = r.sync.sync();
      await Future.wait([first, second]);

      expect(r.transport.requests, hasLength(2));
    });
  });

  group('triggers', () {
    test('does not run on its own until start() is called', () async {
      final r = rig(
        interval: const Duration(milliseconds: 20),
        session: await signedIn(),
      );
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry());

      await Future.delayed(const Duration(milliseconds: 80));

      expect(r.transport.requests, isEmpty);
    });

    test('runs a pass at once when started', () async {
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry());
      r.transport
        ..respond(shiftAnswer())
        ..respond(saleAnswer());

      r.sync.start();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(await r.queue.readAll(), isEmpty);
    });

    test('repeats the pass on its own every interval, after that', () async {
      final r = rig(
        interval: const Duration(milliseconds: 20),
        session: await signedIn(),
      );
      addTearDown(r.sync.dispose);
      r.sync.start();
      await Future.delayed(const Duration(milliseconds: 5));
      expect(
        r.transport.requests,
        isEmpty,
      ); // nothing queued yet: no pass to run

      await r.queue.enqueue(entry());
      r.transport
        ..respond(shiftAnswer())
        ..respond(saleAnswer());
      // Waits for the *next* tick rather than the one `start()` already ran: it is the periodic
      // repeat this test is about, not the immediate pass "runs a pass at once" already covers.
      await Future.delayed(const Duration(milliseconds: 80));

      expect(await r.queue.readAll(), isEmpty);
    });

    test('drains once a sign-in gives the session a token', () async {
      final session = SessionHolder(FakeStorePort());
      await pairOnly(session);
      final r = rig(session: session);
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry());
      r.transport
        ..respond(shiftAnswer())
        ..respond(saleAnswer());

      await signIn(r.session);
      await Future.delayed(const Duration(milliseconds: 80));

      expect(await r.queue.readAll(), isEmpty);
    });

    test('stops the timer it started, once disposed', () async {
      final r = rig(
        interval: const Duration(milliseconds: 20),
        session: await signedIn(),
      );
      await r.queue.enqueue(entry());
      r.transport
        ..respond(shiftAnswer())
        ..respond(saleAnswer());
      r.sync.start();
      await Future.delayed(
        const Duration(milliseconds: 20),
      ); // let the immediate pass land
      final before = r.transport.requests.length;

      r.sync.dispose();
      await Future.delayed(const Duration(milliseconds: 80));

      expect(r.transport.requests, hasLength(before));
    });
  });

  group('counts', () {
    test('updates pendingCount and failedCount after a pass', () async {
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry(ref: 'REF-1'));
      await r.queue.enqueue(entry(ref: 'REF-2'));
      r.transport
        ..respond(shiftAnswer())
        ..respond(json(422, '{"message":"no"}'))
        ..respond(saleAnswer());

      var notified = 0;
      r.sync.addListener(() => notified++);
      await r.sync.sync();

      expect(r.sync.pendingCount, 0);
      expect(r.sync.failedCount, 1);
      expect(notified, greaterThan(0));
    });

    test('refreshCounts reads the counts straight from the store, without asking the server', () async {
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry());

      await r.sync.refreshCounts();

      expect(r.sync.pendingCount, 1);
      expect(r.transport.requests, isEmpty);
    });

    test('refreshCounts does nothing when the device is not paired', () async {
      final r = rig();
      addTearDown(r.sync.dispose);

      await r.sync.refreshCounts();

      expect(r.sync.pendingCount, 0);
      expect(r.transport.requests, isEmpty);
    });
  });

  group('analytics', () {
    test('logs queue_sale_synced once per sale the server records', () async {
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry(ref: 'REF-1'));
      await r.queue.enqueue(entry(ref: 'REF-2'));
      r.transport
        ..respond(shiftAnswer())
        ..respond(saleAnswer())
        ..respond(saleAnswer());

      await r.sync.sync();

      expect(r.analytics.logged.map((e) => e.$1), [
        'queue_sale_synced',
        'queue_sale_synced',
      ]);
    });

    test('logs nothing for a refusal or an unreachable server', () async {
      final r = rig(session: await signedIn());
      addTearDown(r.sync.dispose);
      await r.queue.enqueue(entry());
      r.transport
        ..respond(shiftAnswer())
        ..respond(json(422, '{"message":"no"}'));

      await r.sync.sync();

      expect(r.analytics.logged, isEmpty);
    });
  });
}
