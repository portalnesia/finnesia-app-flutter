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
import 'package:pn_types/src/pos.dart';
import 'package:pos/checkout/checkout_service.dart';

// Written new: there is no source to port. Reading `navigator.onLine` when a checkout fails
// cannot tell "the server said no" from "the server may have said yes".
//
// The queue is part of every case here, because writing the sale down before sending it is not
// an add-on: a send that leaves no record is the bug this whole step exists to remove.

const saleJson = '''
{"id":"x1","number":"POS-0001","shift_id":"s1","outlet_id":"o1","cashier_id":"u1",
 "transaction_date":"2026-09-20","subtotal":15000,"discount_amount":0,"tax_amount":0,
 "grand_total":15000,"tendered_amount":20000,"change_amount":5000,
 "status":"POSTED","created_at":"2026-09-20T03:00:00Z"}''';

const draft = POSCheckoutDTO(
  outletId: 'o1',
  transactionDate: '2026-09-20',
  items: [
    POSCheckoutItemDTO(productId: 'p1', unitId: 'u1', quantity: 2, price: 7500),
  ],
  payments: [POSTenderDTO(method: POSTenderMethod.cash, amount: 20000)],
);

TransportResponse json(int status, String body) => TransportResponse(
  status: status,
  headers: {'content-type': 'application/json'},
  body: body,
);

/// A service over a scripted transport and a real in-memory queue, with refs that are easy to
/// tell apart.
///
/// The queue is the `pn_pos` fake rather than a hand-rolled double so its failure switches are
/// the ones the real store's contract has: it throws on a failed read and a failed write, exactly
/// as `SqlitePendingSaleStore` does.
({
  CheckoutService service,
  FakeApiTransport transport,
  FakePendingSaleStore queue,
  FakeAnalytics analytics,
})
rig({Duration answerWithin = const Duration(seconds: 15)}) {
  final transport = FakeApiTransport();
  final queue = FakePendingSaleStore();
  final analytics = FakeAnalytics();
  var n = 0;
  return (
    service: CheckoutService(
      client: ApiClient(transport: transport, language: () => 'id'),
      queue: queue,
      analytics: analytics,
      newRef: () => 'REF-${++n}',
      answerWithin: answerWithin,
    ),
    transport: transport,
    queue: queue,
    analytics: analytics,
  );
}

/// The row the till would write, with everything the service cannot know filled in.
PendingSale entryFor(String ref) => PendingSale(
  clientRef: ref,
  companyId: 'comp_1',
  outletId: 'o1',
  cashierId: 'u1',
  shiftId: 's1',
  status: PendingSaleStatus.pending,
  paidAt: '2026-09-20T03:00:00.000Z',
  createdAt: '2026-09-20T03:00:00.000Z',
  payload: draft,
  receipt: const PendingSaleReceipt(
    subtotal: 15000,
    discountAmount: 0,
    taxAmount: 0,
    grandTotal: 15000,
    tenderedAmount: 20000,
    changeAmount: 5000,
    items: [],
  ),
);

/// `submit` with the row builder the tests do not care about.
Future<CheckoutOutcome> send(
  ({
    CheckoutService service,
    FakeApiTransport transport,
    FakePendingSaleStore queue,
    FakeAnalytics analytics,
  })
  r, [
  POSCheckoutDTO? basket,
  PendingSale Function(String)? entry,
]) => r.service.submit(basket ?? draft, entry: entry ?? entryFor);

Map<String, dynamic> sent(FakeApiTransport t, [int i = 0]) =>
    jsonDecode(t.requests[i].body!) as Map<String, dynamic>;

void main() {
  group('a checkout the server accepts', () {
    test('returns the sale as Synced', () async {
      final r = rig();
      r.transport.respond(json(200, '{"data":$saleJson}'));

      final outcome = await send(r, draft);

      expect(outcome, isA<CheckoutSynced>());
      expect((outcome as CheckoutSynced).sale.number, 'POS-0001');
      expect(outcome.sale.changeAmount, 5000);
    });

    test(
      'posts the payload to the checkout endpoint with a client_ref',
      () async {
        final r = rig();
        r.transport.respond(json(200, '{"data":$saleJson}'));

        await send(r, draft);

        expect(r.transport.requests.single.path, '/api/v1/pos/sales/checkout');
        expect(sent(r.transport)['client_ref'], 'REF-1');
        expect(sent(r.transport)['outlet_id'], 'o1');
      },
    );
  });

  group('a checkout the server refuses', () {
    test('is Rejected with the server\'s own message, unchanged', () async {
      // The cashier cannot fix an unmapped tender account or a stale product, so the
      // sentence the server wrote (in the cashier's language) is what they act on
      // (`ui/findings.md` F14).
      final r = rig();
      r.transport.respond(
        json(422, '{"message":"Akun untuk metode TRANSFER belum dipetakan"}'),
      );

      final outcome = await send(r, draft);

      expect(outcome, isA<CheckoutRejected>());
      expect(
        (outcome as CheckoutRejected).message,
        'Akun untuk metode TRANSFER belum dipetakan',
      );
      expect(outcome.status, 422);
    });

    test(
      'treats a rate limit as a refusal too, since nothing was recorded',
      () async {
        final r = rig();
        r.transport.respond(
          json(429, '{"message":"Terlalu banyak permintaan"}'),
        );

        final outcome = await send(r, draft);

        expect(outcome, isA<CheckoutRejected>());
        expect((outcome as CheckoutRejected).status, 429);
      },
    );
  });

  // The server finds a sale by (company, client_ref) and hands back the one it has, WITHOUT
  // comparing what was in it (`pos_service.go:1103-1109`). So a ref is only safe to reuse
  // for exactly the same basket: any other reuse silently returns somebody else's sale.
  group('the client_ref', () {
    final changed = draft.copyWith(
      items: [
        ...draft.items,
        const POSCheckoutItemDTO(
          productId: 'p2',
          unitId: 'u1',
          quantity: 1,
          price: 5000,
        ),
      ],
    );

    test(
      'is kept for a retry of the same basket after an unconfirmed attempt',
      () async {
        final r = rig();
        r.transport
          ..fail(TransportException('timeout'))
          ..respond(json(200, '{"data":$saleJson}'));

        await send(r, draft);
        final second = await send(r, draft);

        expect(second, isA<CheckoutSynced>());
        expect(sent(r.transport, 0)['client_ref'], 'REF-1');
        expect(sent(r.transport, 1)['client_ref'], 'REF-1');
      },
    );

    test('is kept across several unconfirmed attempts in a row', () async {
      final r = rig();
      r.transport
        ..fail(TransportException('timeout'))
        ..respond(json(503, '{"message":"down"}'))
        ..respond(json(200, '{"data":$saleJson}'));

      await send(r, draft);
      await send(r, draft);
      await send(r, draft);

      expect(
        r.transport.requests.map(
          (q) => (jsonDecode(q.body!) as Map)['client_ref'],
        ),
        ['REF-1', 'REF-1', 'REF-1'],
      );
    });

    test(
      'is new when the basket changed after an unconfirmed attempt',
      () async {
        // The first attempt may have been recorded. Sending the edited basket under the same
        // ref would return that old sale as if it were this one.
        final r = rig();
        r.transport
          ..fail(TransportException('timeout'))
          ..respond(json(200, '{"data":$saleJson}'));

        await send(r, draft);
        await send(r, changed);

        expect(sent(r.transport, 0)['client_ref'], 'REF-1');
        expect(sent(r.transport, 1)['client_ref'], 'REF-2');
      },
    );

    test('is new for the next sale after one was recorded, even for the same basket', () async {
      // Two coffees, then two coffees again for the next customer: the second is a new sale.
      final r = rig();
      r.transport
        ..respond(json(200, '{"data":$saleJson}'))
        ..respond(json(200, '{"data":$saleJson}'));

      await send(r, draft);
      await send(r, draft);

      expect(sent(r.transport, 0)['client_ref'], 'REF-1');
      expect(sent(r.transport, 1)['client_ref'], 'REF-2');
    });

    test('is new after a refusal, since no sale was recorded', () async {
      final r = rig();
      r.transport
        ..respond(json(422, '{"message":"no"}'))
        ..respond(json(200, '{"data":$saleJson}'));

      await send(r, draft);
      await send(r, draft);

      expect(sent(r.transport, 0)['client_ref'], 'REF-1');
      expect(sent(r.transport, 1)['client_ref'], 'REF-2');
    });
  });

  group('while a checkout is in flight', () {
    test('a second tap sends nothing and gets the same outcome', () async {
      // A double tap on Pay must not charge twice. One request goes out, whoever asked.
      final r = rig();
      r.transport.respond(json(200, '{"data":$saleJson}'));

      final first = send(r);
      final second = send(r);
      final outcomes = await Future.wait([first, second]);

      expect(r.transport.requests, hasLength(1));
      expect(outcomes[0], isA<CheckoutSynced>());
      expect(outcomes[1], same(outcomes[0]));
    });

    test(
      'a different basket is not sent either, until the first has finished',
      () async {
        final r = rig();
        r.transport.respond(json(200, '{"data":$saleJson}'));

        final first = send(r);
        final other = send(r, draft.copyWith(notes: 'changed while paying'));
        await Future.wait([first, other]);

        expect(r.transport.requests, hasLength(1));
      },
    );

    test('accepts the next checkout once the last one finished', () async {
      final r = rig();
      r.transport
        ..respond(json(200, '{"data":$saleJson}'))
        ..respond(json(200, '{"data":$saleJson}'));

      await send(r, draft);
      await send(r, draft);

      expect(r.transport.requests, hasLength(2));
    });
  });

  group('an exception nobody expected', () {
    test(
      'reaches the caller instead of being reported as an outcome',
      () async {
        // A bug must stay loud. Only the failures the server or the network can cause are
        // outcomes; anything else is not the cashier's to interpret.
        final r = rig(); // no scripted answer: the fake throws StateError

        await expectLater(send(r), throwsStateError);
      },
    );

    test('does not lock the service, and keeps the ref of a request that may have gone out', () async {
      final r = rig();
      await expectLater(send(r), throwsStateError);
      r.transport.respond(json(200, '{"data":$saleJson}'));

      final outcome = await send(r, draft);

      expect(outcome, isA<CheckoutSynced>());
      expect(sent(r.transport, 0)['client_ref'], 'REF-1');
      expect(sent(r.transport, 1)['client_ref'], 'REF-1');
    });
  });

  group('a checkout whose outcome nobody knows', () {
    test('is Queued when there was no response at all', () async {
      final r = rig();
      r.transport.fail(TransportException('timeout'));

      expect(await send(r, draft), isA<CheckoutQueued>());
    });

    test(
      'is Queued on a server error, which may have committed first',
      () async {
        final r = rig();
        r.transport.respond(json(500, '{"message":"Internal"}'));

        expect(await send(r, draft), isA<CheckoutQueued>());
      },
    );

    test(
      'is Queued when the server said yes in a form this app cannot read',
      () async {
        // The sale exists. Reporting it as a refusal would send the cashier to charge the
        // customer again.
        final r = rig();
        r.transport.respond(json(200, '{"data":{"unexpected":true}}'));

        expect(await send(r, draft), isA<CheckoutQueued>());
      },
    );
  });

  // `security.md` §5: stored before it is sent, not after. The web app keeps a sale only once a
  // send has failed, so an app that dies mid-request loses one the server may already have.
  group('the sale is written down before it is sent', () {
    test('a recorded sale is queued first, then taken out again', () async {
      final r = rig();
      r.transport.respond(json(200, '{"data":$saleJson}'));

      final outcome = await send(r, draft);

      expect(outcome, isA<CheckoutSynced>());
      expect(r.queue.enqueueCount, 1);
      expect(await r.queue.readAll(), isEmpty);
    });

    test('the row goes in under the ref the request carries', () async {
      // The queue is idempotent on `client_ref`, and that is what makes a resend safe. A row
      // under a different ref would be a second sale for money taken once.
      final r = rig();
      r.transport.fail(TransportException('offline'));

      await send(r, draft);

      expect(sent(r.transport)['client_ref'], 'REF-1');
      expect(r.queue.entries.single.clientRef, 'REF-1');
    });

    test(
      'a sale the server recorded leaves nothing behind in the queue',
      () async {
        final r = rig();
        r.transport.respond(json(200, '{"data":$saleJson}'));

        await send(r, draft);

        expect(await r.queue.count(status: null), 0);
      },
    );

    test('a refusal takes the row out too: nothing was recorded, so there is '
        'nothing to send again', () async {
      final r = rig();
      r.transport.respond(json(422, '{"message":"no"}'));

      final outcome = await send(r, draft);

      expect(outcome, isA<CheckoutRejected>());
      expect(await r.queue.count(status: null), 0);
    });

    test('a send nobody answered keeps the row pending', () async {
      final r = rig();
      r.transport.fail(TransportException('offline'));

      final outcome = await send(r) as CheckoutQueued;

      expect(outcome.entry.clientRef, 'REF-1');
      expect(await r.queue.count(), 1);
    });

    test('a retry of the same basket does not write a second row', () async {
      // The store is idempotent on the ref, and the ref is reused for the same basket: one row
      // for one sale, however many attempts it takes.
      final r = rig();
      r.transport
        ..fail(TransportException('offline'))
        ..fail(TransportException('offline'));

      await send(r, draft);
      await send(r, draft);

      expect(r.queue.enqueueCount, 2);
      expect(await r.queue.count(), 1);
    });

    test('an edited basket writes its own row under a new ref', () async {
      final r = rig();
      r.transport
        ..fail(TransportException('offline'))
        ..fail(TransportException('offline'));

      await send(r, draft);
      await send(r, draft.copyWith(notes: 'berubah'));

      expect(await r.queue.count(), 2);
    });

    test('a write that fails throws, and nothing is sent', () async {
      // The caller keeps the cart in front of the cashier and says the sale was not processed.
      // Clearing the cart for a sale that is in no queue and on no server is the one outcome
      // this port exists to prevent.
      final r = rig();
      r.queue.failWrite = true;
      r.transport.respond(json(200, '{"data":$saleJson}'));

      await expectLater(send(r), throwsA(isA<PendingSaleStoreException>()));
      expect(r.transport.requests, isEmpty);
    });

    test(
      'the row carries the entry the till built, not one of its own',
      () async {
        // The basket, the shift, the outlet and the cashier are the till's: this service only
        // hands over the ref.
        final r = rig();
        r.transport.fail(TransportException('offline'));

        await send(
          r,
          draft,
          (ref) => PendingSale(
            clientRef: ref,
            companyId: 'comp_1',
            outletId: 'out_9',
            cashierId: 'user_9',
            shiftId: null,
            status: PendingSaleStatus.pending,
            paidAt: '2026-09-20T03:00:00.000Z',
            createdAt: '2026-09-20T03:00:00.000Z',
            payload: draft,
            receipt: const PendingSaleReceipt(
              subtotal: 15000,
              discountAmount: 0,
              taxAmount: 0,
              grandTotal: 15000,
              tenderedAmount: 20000,
              changeAmount: 5000,
              items: [],
            ),
          ),
        );

        final row = (await r.queue.readAll()).single;
        expect(row.outletId, 'out_9');
        expect(row.cashierId, 'user_9');
        expect(row.shiftId, isNull);
      },
    );

    test('a row that cannot be taken out does not change the answer', () async {
      // The sale's fate is already decided, and telling the cashier "unknown" for a sale the
      // server recorded is what sends them to ring it up by hand. The leftover row is resolved
      // by the drain loop: the same ref answers with the same sale.
      final r = rig();
      r.transport.respond(json(200, '{"data":$saleJson}'));
      r.queue.failRemove = true;

      final outcome = await send(r, draft);

      expect(outcome, isA<CheckoutSynced>());
      expect(await r.queue.count(), 1);
    });

    test('a row that cannot be taken out after a refusal does not turn the '
        'refusal into a queue', () async {
      final r = rig();
      r.transport.respond(json(422, '{"message":"ditolak"}'));
      r.queue.failRemove = true;

      final outcome = await send(r, draft);

      expect(outcome, isA<CheckoutRejected>());
      expect((outcome as CheckoutRejected).message, 'ditolak');
    });
  });

  // D-Q4: the customer is standing at the counter while this runs. The transport's own limit is
  // thirty seconds (`public_http_dio.dart:38-40`), which is too long to keep somebody waiting
  // when a sale can simply be sent again under the same ref.
  group('waiting for an answer', () {
    test('gives up after the limit and queues the sale', () async {
      final r = rig(answerWithin: const Duration(milliseconds: 20));
      // The request goes out and the answer never comes, which is the state the limit exists
      // for. The fake holds it rather than answering at once — a fake that always answers
      // cannot exercise this path at all.
      r.transport.hold();

      final outcome = await send(r, draft);

      expect(outcome, isA<CheckoutQueued>());
      expect(r.transport.requests, hasLength(1));
      expect(await r.queue.count(), 1);
    });

    test('an answer that arrives in time is used', () async {
      final r = rig(answerWithin: const Duration(seconds: 30));
      r.transport.respond(json(200, '{"data":$saleJson}'));

      expect(await send(r, draft), isA<CheckoutSynced>());
    });

    test('the ref is kept for the resend after giving up, so the server can '
        'dedupe', () async {
      // The request is not cancelled. It may still be recorded, and the resend under the same
      // ref is answered with that sale instead of creating a second one.
      final r = rig(answerWithin: const Duration(milliseconds: 20));
      r.transport.hold();

      await send(r, draft);
      // The held request answers late, after the app had already given up on it. The sale is
      // recorded — which is exactly why the resend has to carry the same ref.
      r.transport.release(json(200, '{"data":$saleJson}'));
      r.transport.respond(json(200, '{"data":$saleJson}'));
      await send(r, draft);

      expect(sent(r.transport, 0)['client_ref'], 'REF-1');
      expect(sent(r.transport, 1)['client_ref'], 'REF-1');
      expect(await r.queue.count(status: null), 0);
    });
  });

  // `plan/firebase/README.md` §2: no raw error text as a parameter, only the status code — it is
  // already a category, not free text.
  group('analytics', () {
    test('logs sale_completed when the server records the sale', () async {
      final r = rig();
      r.transport.respond(json(200, '{"data":$saleJson}'));

      await send(r, draft);

      expect(r.analytics.logged.map((e) => e.$1), ['sale_completed']);
    });

    test('logs sale_queued_offline when nobody answered', () async {
      final r = rig();
      r.transport.fail(TransportException('timeout'));

      await send(r, draft);

      expect(r.analytics.logged.map((e) => e.$1), ['sale_queued_offline']);
    });

    test('logs sale_rejected with the status code, not the message', () async {
      final r = rig();
      r.transport.respond(
        json(422, '{"message":"Akun untuk metode TRANSFER belum dipetakan"}'),
      );

      await send(r, draft);

      expect(r.analytics.logged.map((e) => e.$1), ['sale_rejected']);
      expect(r.analytics.logged.single.$2, {'status': 422});
    });

    test('logs nothing for a request a bug threw out of', () async {
      final r = rig(); // no scripted answer: the fake throws StateError

      await expectLater(send(r), throwsStateError);

      expect(r.analytics.logged, isEmpty);
    });
  });
}
