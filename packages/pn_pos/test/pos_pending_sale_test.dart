/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_pending_sale_fake.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_pos/src/pos_pending_sale_sync.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/product.dart';
import 'package:test/test.dart';

// The queue entry, the two pure functions that read it, and the store it lives behind.
//
// `toCheckoutPayload` and `isFinalError` are ports of `apps/web/src/hooks/use-pos-sync.ts`,
// and its test (`use-pos-sync.test.ts`) is the oracle. The case names below follow it, so the
// two can be compared line by line when either side changes (`.claude/rules/cross-repo.md` §4).
//
// The store's cases come from `pos-offline-queue.test.ts`, with the failure contract
// **reversed**: the web app swallows a storage failure and reads the queue as empty, and this
// one throws (`plan/offline-queue/README.md` §4.1). The three oracle cases that pin the web
// behaviour are therefore not ported — the reversal is the finding (`cross-repo.md` §4).

PendingSaleReceipt receipt() => const PendingSaleReceipt(
      outletName: 'Outlet Pusat',
      cashierName: 'Putu',
      subtotal: 1000,
      discountAmount: 0,
      taxAmount: 0,
      grandTotal: 1000,
      tenderedAmount: 1000,
      changeAmount: 0,
      items: [
        SalesInvoiceItem(
          id: 'inv_1',
          quantity: 1,
          price: 1000,
          lineSubtotal: 1000,
          lineTotal: 1000,
          product: NamedRef(id: 'prd_1', name: 'Kopi Susu'),
        ),
      ],
    );

/// A queued sale, with the stored payload carrying no `clientRef`, no `paidAt` and no
/// `shiftId`: those live in their own columns so the same value is not written twice
/// (`plan/offline-queue/README.md` §4.2).
PendingSale sale({
  String clientRef = '01J0000000000000000000000A',
  String companyId = 'comp_1',
  String outletId = 'out_1',
  String cashierId = 'user_1',
  String? shiftId = 'shift_1',
  String? customerId,
  num? discountAmount,
  String? tableNumber,
  String? queueNumber,
  String? notes,
  PendingSaleStatus status = PendingSaleStatus.pending,
  String? error,
  int attempts = 0,
}) =>
    PendingSale(
      clientRef: clientRef,
      companyId: companyId,
      outletId: outletId,
      cashierId: cashierId,
      shiftId: shiftId,
      status: status,
      error: error,
      paidAt: '2026-09-11T10:00:00.000Z',
      createdAt: '2026-09-11T10:00:01.000Z',
      attempts: attempts,
      payload: POSCheckoutDTO(
        outletId: outletId,
        transactionDate: '2026-09-11',
        items: const [
          POSCheckoutItemDTO(
            productId: 'prd_1',
            unitId: 'unt_1',
            quantity: 1,
            price: 1000,
          ),
        ],
        payments: const [
          POSTenderDTO(method: POSTenderMethod.cash, amount: 1000)
        ],
        customerId: customerId,
        discountAmount: discountAmount,
        tableNumber: tableNumber,
        queueNumber: queueNumber,
        notes: notes,
      ),
      receipt: receipt(),
    );

void main() {
  group('pending sale status', () {
    test('reads the two wire values the database stores', () {
      expect(PendingSaleStatus.tryParse('pending'), PendingSaleStatus.pending);
      expect(PendingSaleStatus.tryParse('failed'), PendingSaleStatus.failed);
    });

    test('writes the wire value, not the Dart name', () {
      // The column is TEXT and a query filters on it. Writing `failed` from the enum's own
      // name would work today and break the moment a value is renamed.
      expect(PendingSaleStatus.pending.wire, 'pending');
      expect(PendingSaleStatus.failed.wire, 'failed');
    });

    test('answers null for a value it does not know, so the store can throw',
        () {
      // Not a default: a row whose status is unreadable is a row this app cannot act on, and
      // the queue's contract is to throw rather than treat it as pending (README §4.1).
      expect(PendingSaleStatus.tryParse(''), isNull);
      expect(PendingSaleStatus.tryParse('PENDING'), isNull);
      expect(PendingSaleStatus.tryParse('sent'), isNull);
    });
  });

  group('toCheckoutPayload', () {
    test('sends client_ref and paid_at so the server can dedupe', () {
      final payload = toCheckoutPayload(sale());

      expect(payload.clientRef, '01J0000000000000000000000A');
      expect(payload.paidAt, '2026-09-11T10:00:00.000Z');
    });

    test('carries the basket through unchanged', () {
      final payload = toCheckoutPayload(sale());

      expect(payload.outletId, 'out_1');
      expect(payload.transactionDate, '2026-09-11');
      expect(payload.items.single.productId, 'prd_1');
      expect(payload.payments.single.method, POSTenderMethod.cash);
      expect(payload.payments.single.amount, 1000);
    });

    test('forwards queue_number when present', () {
      expect(
        toCheckoutPayload(sale(queueNumber: '12')).queueNumber,
        '12',
      );
    });

    test('omits queue_number when the sale never had one', () {
      expect(toCheckoutPayload(sale()).queueNumber, isNull);
    });

    test('never posts the queue bookkeeping fields', () {
      // The entry carries `status`, `error`, `created_at` and `attempts` so the panel can show
      // them. None of them is a checkout field, and posting local-only state would blur the DTO
      // contract (the source says so in the same words).
      //
      // The DTO has no field for any of them, so this asserts on the JSON that would go out:
      // that is what the server actually sees.
      final json = toCheckoutPayload(
        sale(
            status: PendingSaleStatus.failed,
            error: 'stock habis',
            attempts: 3),
      ).toJson();

      expect(json.keys, isNot(contains('status')));
      expect(json.keys, isNot(contains('error')));
      expect(json.keys, isNot(contains('created_at')));
      expect(json.keys, isNot(contains('attempts')));
      expect(json.keys, isNot(contains('cashier_id')));
      expect(json.keys, isNot(contains('position')));
    });

    test('omits shift_id when the sale shift is no longer open', () {
      // A sale rung up against a shift that has since closed cannot be posted to it: the server
      // refuses to write into a closed financial period. Dropping the id lets
      // `resolveCheckoutShift` attach the sale to the shift that is open now.
      expect(
        toCheckoutPayload(sale(), openShiftId: 'shift_other').shiftId,
        isNull,
      );
    });

    test('keeps shift_id while that shift is still the open one', () {
      expect(
        toCheckoutPayload(sale(), openShiftId: 'shift_1').shiftId,
        'shift_1',
      );
    });

    test('omits shift_id when there is no open shift at all', () {
      // The company may run without shifts, in which case the server opens one itself. A stale
      // id here is what used to fail these syncs permanently.
      expect(toCheckoutPayload(sale()).shiftId, isNull);
    });

    test('drops an optional string that is empty, not just one that is absent',
        () {
      // The source is `if (sale.customer_id) payload.customer_id = ...`, and JavaScript treats
      // `''` as falsy (`.claude/rules/patterns.md` §1.1). The DTO writes a `''` as `''`, and
      // `customer_id: ''` is a customer that does not exist — the checkout is refused **after**
      // the cashier has taken the money. `buildCheckoutPayload` already turns `''` into null on
      // the way in; this is the second door, for an entry written by an older build.
      final json = toCheckoutPayload(
        sale(
          customerId: '',
          tableNumber: '',
          queueNumber: '',
          notes: '',
        ),
      ).toJson();

      expect(json.keys, isNot(contains('customer_id')));
      expect(json.keys, isNot(contains('table_number')));
      expect(json.keys, isNot(contains('queue_number')));
      expect(json.keys, isNot(contains('notes')));
    });

    test('keeps a whitespace-only optional string: `||` does not trim', () {
      // `'   '` is truthy in JavaScript, so the source sends it. Trimming here would be a
      // behaviour change the oracle does not sanction (`cross-repo.md` §4).
      expect(toCheckoutPayload(sale(notes: '   ')).notes, '   ');
    });

    test('keeps a discount of zero, which is not the same as no discount', () {
      // The source checks `discount_amount !== undefined`, not truthiness, so `0` is sent. The
      // two checks differ on purpose: `0` is a stated discount, absent is "not stated".
      expect(toCheckoutPayload(sale(discountAmount: 0)).discountAmount, 0);
      expect(toCheckoutPayload(sale()).discountAmount, isNull);
    });
  });

  group('isFinalError', () {
    test('a 4xx is final: replaying it verbatim can only fail again', () {
      for (final status in [400, 401, 404, 409, 422, 499]) {
        expect(isFinalError(status), isTrue, reason: 'status $status');
      }
    });

    test('a 5xx is not final: the write may have committed before it failed',
        () {
      for (final status in [500, 502, 503, 504]) {
        expect(isFinalError(status), isFalse, reason: 'status $status');
      }
    });

    test('a 2xx or 3xx is not final: the write was made', () {
      for (final status in [200, 201, 204, 301, 399]) {
        expect(isFinalError(status), isFalse, reason: 'status $status');
      }
    });
  });

  group('the entry', () {
    test('round-trips through JSON: the store keeps it as one column', () {
      final entry = sale(
        status: PendingSaleStatus.failed,
        error: 'stock habis',
        attempts: 2,
        customerId: 'cust_1',
        discountAmount: 500,
        tableNumber: '4',
        queueNumber: 'A-7',
        notes: 'tanpa gula',
      );

      expect(PendingSale.fromJson(entry.toJson()), entry);
    });

    test('starts at zero attempts and keeps a failed sale with its reason', () {
      // A failed entry stays in the queue with the server's own sentence: the goods have
      // already left the shop, so the cashier has to see it and decide.
      final failed = sale(
        status: PendingSaleStatus.failed,
        error: 'stock habis',
      );

      expect(failed.attempts, 0);
      expect(failed.status, PendingSaleStatus.failed);
      expect(failed.error, 'stock habis');
    });
  });

  // The port and the fake, from `pos-offline-queue.test.ts`. The **failure contract is
  // reversed** from the web app and from `HoldOrderStore`: a read that fails throws, and so
  // does a write. A queue that reads as empty when it is unreadable would let a cashier close
  // the shift and reset the tablet on top of sales nobody can see
  // (`plan/offline-queue/README.md` §4.1).
  group('the queue store', () {
    late FakePendingSaleStore store;

    setUp(() => store = FakePendingSaleStore());

    group('keeping and reading', () {
      test('a new store is empty', () async {
        expect(await store.readAll(), isEmpty);
      });

      test(
          'a queued sale comes back as it went in, with its payload and '
          'receipt', () async {
        // The payload and the receipt are what the temporary receipt prints from and what
        // gets posted, so a field lost here is a field lost in both.
        final entry = sale(
          customerId: 'cust_1',
          discountAmount: 500,
          tableNumber: '4',
          queueNumber: 'A-7',
          notes: 'tanpa gula',
        );

        await store.enqueue(entry);

        expect(await store.readAll(), [entry]);
      });

      test('keeps each company queue separate', () async {
        // Tenant safety: a shared queue would post one tenant's sales to another on a
        // re-paired device. The fake holds both rows, like the table does, so this proves the
        // filter rather than the absence of data.
        await store.enqueue(sale(companyId: 'comp_1'));
        final other = FakePendingSaleStore(
          companyId: 'comp_2',
          seed: [sale(companyId: 'comp_2')],
        );

        expect(await other.readAll(), hasLength(1));
        expect((await store.readAll()).single.companyId, 'comp_1');
        expect(await store.count(), 1);
      });

      test('refuses a sale belonging to another company, loudly', () async {
        // The column would accept it and no read would ever return it — a sale silently
        // outside its own queue, which is the failure mode this port exists to prevent.
        await expectLater(
          store.enqueue(sale(companyId: 'comp_2')),
          throwsA(isA<ArgumentError>()),
        );
        expect(await store.readAll(), isEmpty);
      });

      test('reads the queue in the order it was written', () async {
        // Send order. A sale rung up first belongs in the drawer first.
        await store.enqueue(sale(clientRef: 'A'));
        await store.enqueue(sale(clientRef: 'B'));
        await store.enqueue(sale(clientRef: 'C'));

        expect(
          (await store.readAll()).map((e) => e.clientRef),
          ['A', 'B', 'C'],
        );
      });
    });

    group('idempotency', () {
      test('queuing the same client_ref twice writes it once', () async {
        // The real case: a caller retries after a timeout, and the first write did land. A
        // second row would be a second sale for money taken once.
        await store.enqueue(sale(clientRef: 'A'));
        await store.enqueue(sale(clientRef: 'A'));

        expect(await store.count(), 1);
      });

      test('re-queuing does not overwrite the entry that is already there',
          () async {
        // The first write is the one that knows the money was taken; a retry carrying a
        // rebuilt payload must not replace it.
        await store.enqueue(sale(clientRef: 'A', notes: 'asli'));
        await store.enqueue(sale(clientRef: 'A', notes: 'berbeda'));

        expect((await store.readAll()).single.payload.notes, 'asli');
      });
    });

    group('counting', () {
      test('counts only pending sales', () async {
        await store.enqueue(sale(clientRef: 'A'));
        await store.enqueue(sale(clientRef: 'B'));
        await store.markFailed('B', 'boom');

        expect(await store.count(), 1);
      });

      test('can count per outlet', () async {
        await store.enqueue(sale(clientRef: 'A', outletId: 'out_1'));
        await store.enqueue(sale(clientRef: 'B', outletId: 'out_2'));

        expect(await store.count(outletId: 'out_1'), 1);
        expect(await store.count(), 2);
      });

      test('a failed sale is still in the list, and not counted as pending',
          () async {
        // The goods have already left the shop, so it has to stay visible — but it must not
        // be sent again by itself, which is what the separate count is for.
        await store.enqueue(sale(clientRef: 'A'));
        await store.markFailed('A', 'stock habis');

        expect(await store.readAll(), hasLength(1));
        expect((await store.readAll()).single.status, PendingSaleStatus.failed);
        expect(await store.count(), 0);
      });
    });

    group('marking and removing', () {
      test('removes the sale once it has been sent', () async {
        await store.enqueue(sale(clientRef: 'A'));

        await store.remove('A');

        expect(await store.readAll(), isEmpty);
      });

      test('keeps a failed sale in the list and records why', () async {
        await store.enqueue(sale(clientRef: 'A'));

        await store.markFailed('A', 'stock habis');

        final entry = (await store.readAll()).single;
        expect(entry.status, PendingSaleStatus.failed);
        expect(entry.error, 'stock habis');
      });

      test('puts a retried sale back in the pending queue, without its reason',
          () async {
        await store.enqueue(sale(clientRef: 'A'));
        await store.markFailed('A', 'boom');

        await store.retry('A');

        final entry = (await store.readAll()).single;
        expect(entry.status, PendingSaleStatus.pending);
        expect(entry.error, isNull);
        expect(await store.count(), 1);
      });

      test('dropping a sale removes it for good', () async {
        await store.enqueue(sale(clientRef: 'A'));

        await store.remove('A');

        expect(await store.readAll(), isEmpty);
      });

      test('an unknown client_ref changes nothing, and does not throw',
          () async {
        // "The row is gone" is an ordinary state, not a failure: another till's pass may have
        // removed it, or the cashier discarded it while this one was retrying.
        await store.enqueue(sale(clientRef: 'A'));

        await store.markFailed('tidak-ada', 'boom');
        await store.retry('tidak-ada');
        await store.remove('tidak-ada');

        expect(
            (await store.readAll()).single.status, PendingSaleStatus.pending);
      });

      test('counts the attempts a sale has failed to send', () async {
        // Shown in the panel so a sale that keeps failing is visible rather than silently
        // retrying forever.
        await store.enqueue(sale(clientRef: 'A'));

        await store.recordAttempt('A');
        await store.recordAttempt('A');

        expect((await store.readAll()).single.attempts, 2);
      });

      test('records the reason alongside the attempt, in the same call',
          () async {
        // A blocked sale (402, or 403 `outlet_inactive`) stays `pending`, so `markFailed` is
        // never reached; the reason has to travel with the attempt or the panel shows
        // "Menunggu" with no explanation (spec §3c).
        await store.enqueue(sale(clientRef: 'A'));

        await store.recordAttempt('A', reason: 'langganan habis');

        final entry = (await store.readAll()).single;
        expect(entry.status, PendingSaleStatus.pending);
        expect(entry.attempts, 1);
        expect(entry.error, 'langganan habis');
      });

      test('an attempt without a reason leaves the last reason in place',
          () async {
        // A later network failure must not erase the explanation the server gave.
        await store.enqueue(sale(clientRef: 'A'));
        await store.recordAttempt('A', reason: 'langganan habis');

        await store.recordAttempt('A');

        final entry = (await store.readAll()).single;
        expect(entry.attempts, 2);
        expect(entry.error, 'langganan habis');
      });

      test('retry clears a reason an attempt wrote', () async {
        await store.enqueue(sale(clientRef: 'A'));
        await store.recordAttempt('A', reason: 'langganan habis');

        await store.retry('A');

        final entry = (await store.readAll()).single;
        expect(entry.status, PendingSaleStatus.pending);
        expect(entry.error, isNull);
      });
    });

    group('when the storage misbehaves', () {
      test('a failed read throws, it does not read as empty', () async {
        // The reversal from the web app, and the point of the whole port: an unreadable queue
        // that looks empty lets the cashier close the shift and reset the tablet over sales
        // nobody can see.
        await store.enqueue(sale(clientRef: 'A'));
        store.failRead = true;

        await expectLater(
            store.readAll(), throwsA(isA<PendingSaleStoreException>()));
        await expectLater(
            store.count(), throwsA(isA<PendingSaleStoreException>()));
      });

      test('a failed write throws, so the cart is not cleared over it',
          () async {
        // The caller keeps the cashier on the pay screen and says the sale was not processed.
        // Swallowing it would let the cart be emptied for a sale with no record anywhere.
        store.failWrite = true;

        await expectLater(
          store.enqueue(sale(clientRef: 'A')),
          throwsA(isA<PendingSaleStoreException>()),
        );
      });

      test('a failed remove throws: the sale may still be queued', () async {
        // Silent here would tell the drain loop the sale is gone while it is still on disk,
        // and the next pass would post it a second time.
        await store.enqueue(sale(clientRef: 'A'));
        store.failWrite = true;

        await expectLater(
          store.remove('A'),
          throwsA(isA<PendingSaleStoreException>()),
        );
      });

      test('the failure carries what the storage said, for the log', () async {
        // Not a token and not a payload: the message is for a developer reading a bug report,
        // and `security.md` §1 keeps the sale's contents out of it.
        store.failRead = true;

        await expectLater(
          store.readAll(),
          throwsA(
            isA<PendingSaleStoreException>().having(
              (e) => e.message,
              'message',
              isNotEmpty,
            ),
          ),
        );
      });
    });
  });

  // The drain loop, ported from `syncQueue` in `apps/web/src/hooks/use-pos-sync.ts`. Its test
  // is the oracle and the case names follow it, so the two can be compared line by line.
  //
  // The network call is a seam (`options.send`), exactly as it is in the source: that is what
  // makes this testable with `dart test` and no server.
  group('syncQueue', () {
    late FakePendingSaleStore store;
    late List<POSCheckoutDTO> sent;
    late SendOutcome? failure;

    setUp(() {
      store = FakePendingSaleStore();
      sent = [];
      failure = null;
    });

    /// The seam. Records what was posted and answers whatever the test set.
    Future<SendOutcome> send(POSCheckoutDTO payload) async {
      sent.add(payload);
      return failure ?? const SendSucceeded();
    }

    Future<void> sync({
      String? openShiftId,
      String? cashierId,
      SendOutcome? fail,
    }) {
      failure = fail;
      return syncQueue(
        store,
        send: send,
        openShiftId: openShiftId,
        cashierId: cashierId,
      );
    }

    test('drains the queue and removes the sale once posted', () async {
      await store.enqueue(sale());

      await sync();

      expect(sent, hasLength(1));
      expect(await store.count(), 0);
      expect(await store.readAll(), isEmpty);
    });

    test('sends client_ref and paid_at so the server can dedupe', () async {
      await store.enqueue(sale());

      await sync();

      expect(sent.single.clientRef, '01J0000000000000000000000A');
      expect(sent.single.paidAt, '2026-09-11T10:00:00.000Z');
    });

    test('omits shift_id when the sale shift is no longer open', () async {
      await store.enqueue(sale());

      await sync(openShiftId: 'shift_other');

      expect(sent.single.shiftId, isNull);
    });

    test('keeps shift_id while that shift is still the open one', () async {
      await store.enqueue(sale());

      await sync(openShiftId: 'shift_1');

      expect(sent.single.shiftId, 'shift_1');
    });

    test('marks a sale failed on a 4xx but keeps it in the queue', () async {
      // A 4xx is final: replaying it verbatim fails again, so it is parked for the cashier.
      await store.enqueue(sale());

      await sync(fail: const SendRefused(422, 'stock habis'));

      expect(await store.count(), 0);
      expect(await store.readAll(), hasLength(1));
      expect((await store.readAll()).single.status, PendingSaleStatus.failed);
      expect((await store.readAll()).single.error, 'stock habis');
    });

    test('leaves a sale pending when the network is down', () async {
      await store.enqueue(sale());

      await sync(fail: const SendUnreachable());

      expect(await store.count(), 1);
      expect((await store.readAll()).single.status, PendingSaleStatus.pending);
    });

    test('leaves a sale pending on a 5xx so it can be retried', () async {
      await store.enqueue(sale());

      await sync(fail: const SendRefused(503, 'server error'));

      expect(await store.count(), 1);
      expect((await store.readAll()).single.status, PendingSaleStatus.pending);
    });

    test('keeps a blocked sale pending, and stores the server reason',
        () async {
      // A block is not a refusal: the server understood the sale and is refusing on the state
      // of the tenant/outlet, so the sale is not wrong and the refusal is not permanent. It
      // stays `pending` and the reason is kept where the panel can show it (spec §3a).
      await store.enqueue(sale());

      await sync(fail: const SendBlocked('langganan habis'));

      final entry = (await store.readAll()).single;
      expect(entry.status, PendingSaleStatus.pending);
      expect(entry.attempts, 1);
      expect(entry.error, 'langganan habis');
    });

    test('stops the pass on a block: everything behind it is blocked too',
        () async {
      // Same shape as `SendUnreachable`: a tenant-wide block applies to every sale behind the
      // first one, and sending them would only burn requests. The second entry is not even
      // attempted, so its counter stays at zero.
      await store.enqueue(sale(clientRef: 'A'));
      await store.enqueue(sale(clientRef: 'B'));

      await sync(fail: const SendBlocked('kuota outlet penuh'));

      expect(sent, hasLength(1));
      final entries = await store.readAll();
      expect(entries.map((e) => e.clientRef), ['A', 'B']);
      expect(entries[0].attempts, 1);
      expect(entries[1].attempts, 0);
    });

    test('an unreachable server writes no reason: nothing was said', () async {
      // The negative for `SendBlocked`. A network failure or a 5xx has no server sentence, and
      // writing one would be inventing an explanation the cashier cannot act on (spec §3f 5).
      await store.enqueue(sale());

      await sync(fail: const SendUnreachable());

      final entry = (await store.readAll()).single;
      expect(entry.attempts, 1);
      expect(entry.error, isNull);
    });

    test('a block that later clears lets the next pass remove the row',
        () async {
      // The block is not sticky: once the server stops answering with it, the same pass drains
      // the queue as usual (spec §3a 3).
      await store.enqueue(sale());

      await sync(fail: const SendBlocked('langganan habis'));
      expect(await store.count(), 1);

      await sync();

      expect(await store.readAll(), isEmpty);
    });

    test('counts an attempt on a failure that is not final', () async {
      // Shown in the panel: a sale that keeps failing has to be visible rather than silently
      // retrying forever.
      await store.enqueue(sale());

      await sync(fail: const SendUnreachable());

      expect((await store.readAll()).single.attempts, 1);
    });

    test('does not count an attempt on a 4xx: it is parked, not retried',
        () async {
      // The attempt counter is for "we do not know", and a 4xx is the one case where we do.
      await store.enqueue(sale());

      await sync(fail: const SendRefused(400, 'bad request'));

      expect((await store.readAll()).single.attempts, 0);
    });

    test('posts sales one at a time, in the order they were queued', () async {
      await store.enqueue(sale(clientRef: 'A'));
      await store.enqueue(sale(clientRef: 'B'));

      await sync();

      expect(sent, hasLength(2));
      expect(sent[0].clientRef, 'A');
      expect(sent[1].clientRef, 'B');
    });

    test('stops the pass on a network error instead of skipping ahead',
        () async {
      // Everything behind the failure would fail the same way, and stopping keeps the
      // remaining sales in order instead of scattering retries across the queue.
      await store.enqueue(sale(clientRef: 'A'));
      await store.enqueue(sale(clientRef: 'B'));

      await sync(fail: const SendUnreachable());

      expect(sent, hasLength(1));
      expect(await store.count(), 2);
    });

    test('keeps going past a failed sale', () async {
      // A 4xx is final for that sale only; the next one can still succeed.
      await store.enqueue(sale(clientRef: 'A'));
      await store.enqueue(sale(clientRef: 'B'));
      var first = true;

      await syncQueue(
        store,
        send: (payload) async {
          if (first) {
            first = false;
            return const SendRefused(400, 'bad request');
          }
          sent.add(payload);
          return const SendSucceeded();
        },
      );

      expect(sent, hasLength(1));
      expect(sent.single.clientRef, 'B');
      expect((await store.readAll()).single.status, PendingSaleStatus.failed);
    });

    test('never touches a sale that is already failed', () async {
      // Only `pending` entries are sent. A failed one waits for the cashier to retry or
      // discard it — sending it again by itself is what the status is for.
      await store.enqueue(sale(clientRef: 'A'));
      await store.enqueue(sale(clientRef: 'B'));
      await store.markFailed('A', 'stock habis');

      await sync();

      expect(sent, hasLength(1));
      expect(sent.single.clientRef, 'B');
    });

    test('does nothing when there is nothing to send', () async {
      await sync();

      expect(sent, isEmpty);
    });

    // D-Q1. The server attributes a sale to whoever is authenticated at send time, so a sale
    // rung up by another cashier would be recorded against the sender
    // (`plan/offline-queue/findings.md` F4).
    group('ownership', () {
      test('sends only the sales the given cashier typed', () async {
        await store.enqueue(sale(clientRef: 'A', cashierId: 'user_1'));
        await store.enqueue(sale(clientRef: 'B', cashierId: 'user_2'));

        await sync(cashierId: 'user_1');

        expect(sent, hasLength(1));
        expect(sent.single.clientRef, 'A');
      });

      test('skips the other cashier sales without counting them as failures',
          () async {
        // A sale that was not sent was not refused: counting an attempt against it would make
        // another cashier's queue look broken.
        await store.enqueue(sale(clientRef: 'B', cashierId: 'user_2'));

        await sync(cashierId: 'user_1');

        expect((await store.readAll()).single.attempts, 0);
        expect(
            (await store.readAll()).single.status, PendingSaleStatus.pending);
      });

      test('sends every cashier sales when no cashier is given', () async {
        // The worker in `apps/pos` always names one; the seam is optional so a test, or a
        // device with no signed-in cashier, can drain the whole queue.
        await store.enqueue(sale(clientRef: 'A', cashierId: 'user_1'));
        await store.enqueue(sale(clientRef: 'B', cashierId: 'user_2'));

        await sync();

        expect(sent, hasLength(2));
      });
    });

    // `optimization.md` §5.3: the drain loop is I/O inside a loop, allowed only under the
    // exception written there. Its limits are what these two tests pin.
    group('the cost of a pass', () {
      test('reads the queue once, however many sales are behind it', () async {
        for (var i = 0; i < 10; i++) {
          await store.enqueue(sale(clientRef: 'ref_$i'));
        }
        final before = store.readCount;

        await sync();

        expect(store.readCount - before, 1);
      });

      test(
          'stops after one request when the network is down, whatever the queue holds',
          () async {
        // The bound that makes the exception acceptable: a failing pass costs one request,
        // not one per queued sale.
        for (var i = 0; i < 50; i++) {
          await store.enqueue(sale(clientRef: 'ref_$i'));
        }

        await sync(fail: const SendUnreachable());

        expect(sent, hasLength(1));
        expect(await store.count(), 50);
      });

      test('writes once per sale sent, and once for the one that failed',
          () async {
        // Not asserted for its own sake: a pass that wrote the whole list per sale would be
        // O(n²) on a tablet, which is the shape `optimization.md` §1 forbids.
        await store.enqueue(sale(clientRef: 'A'));
        await store.enqueue(sale(clientRef: 'B'));

        await sync();

        expect(store.writeCount, 2);
      });
    });

    group('when the storage misbehaves', () {
      test('a queue that cannot be read throws, and nothing is sent', () async {
        // Silently treating it as empty would report "everything is sent" over sales that are
        // still on disk.
        await store.enqueue(sale());
        store.failRead = true;

        await expectLater(
          sync(),
          throwsA(isA<PendingSaleStoreException>()),
        );
        expect(sent, isEmpty);
      });

      test(
          'a sale that was posted but cannot be removed throws, and is not '
          'reported as sent', () async {
        // The worst case: the server has the sale, the tablet still has the row, and the next
        // pass would post it again. It is safe — the same `client_ref` answers with the same
        // sale — but the caller has to be told rather than shown a clean pass.
        await store.enqueue(sale());
        store.failRemove = true;

        await expectLater(
          sync(),
          throwsA(isA<PendingSaleStoreException>()),
        );
        expect(sent, hasLength(1));
        expect(await store.count(), 1);
      });

      test('a sale that cannot be marked failed throws, and stays pending',
          () async {
        // Leaving it pending is the safe direction: the next pass retries it, and the server
        // answers with the same refusal.
        await store.enqueue(sale());
        store.failWrite = true;

        await expectLater(
          sync(fail: const SendRefused(422, 'stock habis')),
          throwsA(isA<PendingSaleStoreException>()),
        );
        expect(
            (await store.readAll()).single.status, PendingSaleStatus.pending);
      });
    });
  });

  // Building the queue entry at the till, the moment the cashier confirms payment
  // (`plan/offline-queue/README.md` §3 step 1). Pure, so `dart test` runs it in milliseconds
  // and the money path is covered without a widget.
  group('buildPendingSale', () {
    const kopi = Product(
      id: 'p1',
      name: 'Kopi Susu',
      unitId: 'u1',
      sellPrice: 15000,
    );
    const teh = Product(id: 'p2', name: 'Teh', unitId: 'u1', sellPrice: 5000);

    List<CartLine> lines() => [
          const CartLine(id: 'l1', product: kopi, qty: 2),
          const CartLine(id: 'l2', product: teh, qty: 1),
        ];

    PendingSale build({
      String clientRef = 'REF-1',
      String? shiftId = 'shift_1',
      List<CartLine>? basket,
      List<POSTenderDTO>? payments,
      num tendered = 40000,
      String? customerId,
      String? notes,
      String? tableNumber,
      String? queueNumber,
      num discountAmount = 0,
      String? outletName,
      String? cashierName,
      DateTime? now,
    }) =>
        buildPendingSale(
          clientRef: clientRef,
          companyId: 'comp_1',
          outletId: 'out_1',
          cashierId: 'user_1',
          shiftId: shiftId,
          outletName: outletName,
          cashierName: cashierName,
          transactionDate: '2026-09-22',
          customerId: customerId,
          notes: notes,
          tableNumber: tableNumber,
          queueNumber: queueNumber,
          discountAmount: discountAmount,
          lines: basket ?? lines(),
          payments: payments ??
              [POSTenderDTO(method: POSTenderMethod.cash, amount: tendered)],
          now: now,
        );

    test('carries the basket, the payments and who rang it up', () {
      final entry = build();

      expect(entry.clientRef, 'REF-1');
      expect(entry.companyId, 'comp_1');
      expect(entry.outletId, 'out_1');
      expect(entry.cashierId, 'user_1');
      expect(entry.shiftId, 'shift_1');
      expect(entry.status, PendingSaleStatus.pending);
      expect(entry.attempts, 0);
      expect(entry.payload.items.map((i) => i.productId), ['p1', 'p2']);
      expect(entry.payload.items.map((i) => i.quantity), [2, 1]);
      expect(entry.payload.payments.single.amount, 40000);
    });

    test('leaves client_ref, paid_at and shift_id out of the stored payload',
        () {
      // They live in their own columns and are stamped back on the way out
      // (`toCheckoutPayload`). Writing them twice would be two values of the one field the
      // server dedupes on (`plan/offline-queue/README.md` §4.2).
      final entry = build();

      expect(entry.payload.clientRef, isNull);
      expect(entry.payload.paidAt, isNull);
      expect(entry.payload.shiftId, isNull);
    });

    test('stamps the tablet clock for paid_at, so a retry can say when', () {
      final entry = build(now: DateTime.utc(2026, 9, 22, 3, 30));

      expect(entry.paidAt, '2026-09-22T03:30:00.000Z');
      expect(entry.createdAt, '2026-09-22T03:30:00.000Z');
    });

    test('prices the basket for the printed proof, not only for the payload',
        () {
      // The temporary receipt is printed from this copy, with no server to ask
      // (README D-Q3), so the figures have to be here.
      final entry = build(tendered: 40000);

      expect(entry.receipt.subtotal, 35000);
      expect(entry.receipt.grandTotal, 35000);
      expect(entry.receipt.tenderedAmount, 40000);
      expect(entry.receipt.changeAmount, 5000);
    });

    test('takes the discount off the grand total the receipt prints', () {
      final entry = build(discountAmount: 5000);

      expect(entry.receipt.discountAmount, 5000);
      expect(entry.receipt.grandTotal, 30000);
    });

    test('counts the change from what was actually tendered', () {
      // A split payment (part cash, part transfer) is one of the commonest things a cashier
      // does, and the change is the part the drawer gives back — not the cash row alone.
      final entry = build(
        tendered: 0,
        payments: const [
          POSTenderDTO(method: POSTenderMethod.cash, amount: 20000),
          POSTenderDTO(method: POSTenderMethod.transfer, amount: 20000),
        ],
      );

      expect(entry.receipt.tenderedAmount, 40000);
      expect(entry.receipt.changeAmount, 5000);
    });

    test('prints no change when the customer pays exactly', () {
      final entry = build(tendered: 35000);

      expect(entry.receipt.changeAmount, 0);
    });

    test(
        'carries the goods into the receipt with their names, not only their ids',
        () {
      // The payload has ids; a receipt needs what the customer bought.
      final entry = build();

      expect(entry.receipt.items.map((i) => i.product?.name), [
        'Kopi Susu',
        'Teh',
      ]);
      expect(entry.receipt.items.map((i) => i.lineTotal), [30000, 5000]);
    });

    test('names the outlet and the cashier when the till knows them', () {
      final entry = build(outletName: 'Outlet Pusat', cashierName: 'Putu');

      expect(entry.receipt.outletName, 'Outlet Pusat');
      expect(entry.receipt.cashierName, 'Putu');
    });

    test('leaves the names null when the till does not know them', () {
      // Neither is needed to print, and neither is a reason to hold up a sale
      // (`print_receipt.dart` makes the same call for a recorded sale).
      final entry = build();

      expect(entry.receipt.outletName, isNull);
      expect(entry.receipt.cashierName, isNull);
    });

    test('forwards the table, the queue number and the notes', () {
      final entry = build(
        customerId: 'cust_1',
        notes: 'tanpa gula',
        tableNumber: '4',
        queueNumber: 'A-7',
      );

      expect(entry.payload.customerId, 'cust_1');
      expect(entry.payload.notes, 'tanpa gula');
      expect(entry.payload.tableNumber, '4');
      expect(entry.payload.queueNumber, 'A-7');
    });

    test('omits an optional field the cashier left empty', () {
      // `customer_id: ''` is a customer that does not exist, and the checkout is refused
      // **after** the money has been taken (`pos_checkout.dart`).
      final entry =
          build(customerId: '', notes: '', tableNumber: '', queueNumber: '');

      expect(entry.payload.customerId, isNull);
      expect(entry.payload.notes, isNull);
      expect(entry.payload.tableNumber, isNull);
      expect(entry.payload.queueNumber, isNull);
    });

    test('a company without shifts gets an entry with no shift', () {
      final entry = build(shiftId: null);

      expect(entry.shiftId, isNull);
      expect(entry.payload.shiftId, isNull);
    });

    test(
        'the ref the caller chose is the one stored, so a retry cannot double it',
        () {
      // The queue is idempotent on this value, and the same ref is what makes a resend safe.
      final entry = build(clientRef: 'REF-9');

      expect(entry.clientRef, 'REF-9');
      expect(entry.payload.clientRef, isNull);
    });
  });
}
