/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_pending_sale_fake.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pos/queue/pending_sales_controller.dart';
import 'package:pos/queue/queue_sync.dart';
import 'package:pos/session/session_holder.dart';
import 'package:pos/state/loadable.dart';

// Written new: S17 (`plan/offline-queue/README.md` §7). What the panel reads is `PendingSaleStore`
// directly, not `QueueSync`'s counts — a row here needs the whole entry, not a number.

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

PendingSale entry({
  String ref = 'REF-1',
  PendingSaleStatus status = PendingSaleStatus.pending,
  String? error,
}) => PendingSale(
  clientRef: ref,
  companyId: 'comp_1',
  outletId: 'out_1',
  cashierId: 'u1',
  status: status,
  error: error,
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

({
  PendingSalesController controller,
  FakePendingSaleStore store,
  FakeApiTransport transport,
  FakeAnalytics analytics,
})
rig({List<PendingSale> seed = const []}) {
  final store = FakePendingSaleStore(seed: seed);
  final transport = FakeApiTransport();
  final session = SessionHolder(FakeStorePort());
  final analytics = FakeAnalytics();
  final sync = QueueSync(
    client: ApiClient(transport: transport, language: () => 'id'),
    queue: store,
    session: session,
    // A separate fake: `QueueSync`'s own drain (`queue_sale_synced`) is not what this
    // controller's analytics test asserts on.
    analytics: FakeAnalytics(),
  );
  return (
    controller: PendingSalesController(
      store: store,
      sync: sync,
      analytics: analytics,
    ),
    store: store,
    transport: transport,
    analytics: analytics,
  );
}

void main() {
  group('reading the queue', () {
    test('starts loading', () async {
      final r = rig();
      addTearDown(r.controller.dispose);

      expect(r.controller.state, isA<Loading<List<PendingSale>>>());
    });

    test('lists every entry once it has read them', () async {
      final r = rig(
        seed: [
          entry(ref: 'REF-1'),
          entry(ref: 'REF-2'),
        ],
      );
      addTearDown(r.controller.dispose);

      await r.controller.load();

      final state = r.controller.state as Ready<List<PendingSale>>;
      expect(state.data.map((e) => e.clientRef), ['REF-1', 'REF-2']);
    });

    test(
      'says the queue could not be read, and it is not the same as empty',
      () async {
        final r = rig();
        r.store.failRead = true;
        addTearDown(r.controller.dispose);

        await r.controller.load();

        expect(r.controller.state, isA<Failed<List<PendingSale>>>());
      },
    );

    test('can be read again after a failure', () async {
      final r = rig(seed: [entry()]);
      r.store.failRead = true;
      addTearDown(r.controller.dispose);
      await r.controller.load();

      r.store.failRead = false;
      await r.controller.load();

      expect(r.controller.state, isA<Ready<List<PendingSale>>>());
    });
  });

  group('retrying a failed entry', () {
    test('puts it back to pending, and clears the reason', () async {
      final r = rig(
        seed: [entry(status: PendingSaleStatus.failed, error: 'ditolak')],
      );
      addTearDown(r.controller.dispose);
      await r.controller.load();

      await r.controller.retry('REF-1');

      final state = r.controller.state as Ready<List<PendingSale>>;
      expect(state.data.single.status, PendingSaleStatus.pending);
      expect(state.data.single.error, isNull);
    });
  });

  group('discarding an entry', () {
    test('removes it from the list', () async {
      final r = rig(
        seed: [
          entry(ref: 'REF-1'),
          entry(ref: 'REF-2'),
        ],
      );
      addTearDown(r.controller.dispose);
      await r.controller.load();

      await r.controller.discard('REF-1');

      final state = r.controller.state as Ready<List<PendingSale>>;
      expect(state.data.map((e) => e.clientRef), ['REF-2']);
    });
  });

  group('sending now', () {
    test('says it is sending while a pass is out', () async {
      final r = rig(seed: [entry()]);
      addTearDown(r.controller.dispose);
      await r.controller.load();
      r.transport.hold(); // the active-shift lookup, left unanswered

      final sending = r.controller.sendNow();
      expect(r.controller.isSending, isTrue);

      r.transport.release(
        TransportResponse(
          status: 200,
          headers: const {'content-type': 'application/json'},
          body: '{"data":null}',
        ),
      );
      await sending;
      expect(r.controller.isSending, isFalse);
    });

    test('reads the queue again once the pass is done', () async {
      final r = rig(
        seed: [
          entry(ref: 'REF-1'),
          entry(ref: 'REF-2'),
        ],
      );
      addTearDown(r.controller.dispose);
      await r.controller.load();

      // Something changed the store while this screen was open — the periodic pass, say — and
      // `sendNow` (no session token here, so `QueueSync.sync` itself does nothing) still has to
      // show it.
      await r.store.remove('REF-1');
      await r.controller.sendNow();

      expect(
        (r.controller.state as Ready<List<PendingSale>>).data.map(
          (e) => e.clientRef,
        ),
        ['REF-2'],
      );
    });
  });

  group('analytics', () {
    test('logs queue_sale_retried', () async {
      final r = rig(seed: [entry(status: PendingSaleStatus.failed)]);
      addTearDown(r.controller.dispose);
      await r.controller.load();

      await r.controller.retry('REF-1');

      expect(r.analytics.logged.map((e) => e.$1), ['queue_sale_retried']);
    });

    test('logs queue_sale_discarded', () async {
      final r = rig(seed: [entry()]);
      addTearDown(r.controller.dispose);
      await r.controller.load();

      await r.controller.discard('REF-1');

      expect(r.analytics.logged.map((e) => e.$1), ['queue_sale_discarded']);
    });

    test('logs queue_send_now_triggered', () async {
      final r = rig();
      addTearDown(r.controller.dispose);
      await r.controller.load();

      await r.controller.sendNow();

      expect(r.analytics.logged.map((e) => e.$1), ['queue_send_now_triggered']);
    });
  });
}
