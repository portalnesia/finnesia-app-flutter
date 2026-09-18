/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_pos/src/pos_hold_fake.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_pending_sale_fake.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pn_types/src/native/public_http_fake.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/device/device_reset.dart';
import 'package:pos/session/session_holder.dart';

// New module, no oracle: `DELETE /pos/devices/me` did not exist when the app was ported. The
// behaviour is fixed by `plan/pos-device-registry/01-kontrak-aplikasi-android.md` §3.4.
//
// The login screen exercises the happy path and the failure path through the widget; this file
// covers the branches a widget cannot reach — a device with no token at all, and the ordering
// that decides whether the server row is actually deleted.

const tenantHost = 'https://erp.perusahaan.com';

const paired = PosSession(
  baseUrl: tenantHost,
  companyId: 'comp_1',
  outletId: 'out_1',
  sessionToken: '',
  deviceToken: 'dev_tok_1',
);

/// A device paired before the registry existed: no token, so no row to delete.
const pairedWithoutToken = PosSession(
  baseUrl: tenantHost,
  companyId: 'comp_1',
  outletId: 'out_1',
  sessionToken: '',
);

class Rig {
  final store = FakeStorePort();
  late final session = SessionHolder(store);
  final http = FakePublicHttp();

  final holdStore = FakeHoldOrderStore();
  final pendingSaleStore = FakePendingSaleStore();
  final analytics = FakeAnalytics();

  DeviceResetDeps get deps => (
    http: http,
    session: session,
    holdStore: holdStore,
    pendingSaleStore: pendingSaleStore,
    analytics: analytics,
  );

  Future<void> pair([PosSession s = paired]) => session.save(s);

  /// The session as the next launch would read it from the store.
  Future<PosSession?> stored() => SessionHolder(store).hydrate();

  void answer({int status = 200, String? body}) => http.respond(
    TransportResponse(
      status: status,
      headers: const {'Content-Type': 'application/json'},
      body: body,
    ),
  );
}

HeldOrder _basket(String id, String outletId) => HeldOrder(
  id: id,
  label: 'Meja $id',
  outletId: outletId,
  headerDiscount: 0,
  lines: const [],
  heldAt: '2026-09-21T03:00:00Z',
);

const _draft = POSCheckoutDTO(
  outletId: 'out_1',
  transactionDate: '2026-09-21',
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

PendingSale _queued({
  String ref = 'REF-1',
  String outletId = 'out_1',
  String cashierId = 'user_1',
  PendingSaleStatus status = PendingSaleStatus.pending,
}) => PendingSale(
  clientRef: ref,
  companyId: 'comp_1',
  outletId: outletId,
  cashierId: cashierId,
  status: status,
  paidAt: '2026-09-21T03:00:00.000Z',
  createdAt: '2026-09-21T03:00:00.000Z',
  payload: _draft,
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

void main() {
  // What is parked on a tablet belongs to the outlet it was paired to. A tablet released from it
  // (or handed to another tenant) must not carry that tenant's customers and orders on its disk:
  // the owner decided every held basket goes with the pairing (2026-09-21).
  group('resetDevice: the baskets held on the tablet', () {
    test(
      'every one of them is dropped, whichever outlet it belongs to',
      () async {
        final rig = Rig()..answer();
        await rig.pair();
        await rig.holdStore.writeAll([
          _basket('a', 'out_1'),
          // From an earlier pairing: hidden by the outlet lock, but still on the disk.
          _basket('b', 'out_old'),
        ]);

        await resetDevice(rig.deps);

        expect(await rig.holdStore.readAll(), isEmpty);
      },
    );

    test(
      'and they go when the server could not be told, as the pairing does',
      () async {
        final rig = Rig()..answer(status: 500, body: '{}');
        await rig.pair();
        await rig.holdStore.writeAll([_basket('a', 'out_1')]);

        final outcome = await resetDevice(rig.deps);

        expect(outcome, DeviceResetOutcome.serverFailed);
        expect(await rig.holdStore.readAll(), isEmpty);
      },
    );

    test('and they go from a tablet that was never paired', () async {
      final rig = Rig();
      await rig.holdStore.writeAll([_basket('a', 'out_old')]);

      await resetDevice(rig.deps);

      expect(await rig.holdStore.readAll(), isEmpty);
    });
  });

  group('resetDevice — the call it makes', () {
    test('DELETEs the device to the paired host', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await resetDevice(rig.deps);

      final call = rig.http.calls.single;
      expect(call.request.method, HttpMethod.delete);
      expect(call.request.path, '/api/v1/pos/devices/me');
      expect(call.baseUrl, tenantHost);
    });

    // The token is the endpoint's only credential, so it has to be on the request. Without it
    // the server answers 401 and the row survives.
    test('sends the device token, and no bearer', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await resetDevice(rig.deps);

      final headers = rig.http.calls.single.request.headers;
      expect(headers['X-Device-Token'], 'dev_tok_1');
      // A cashier credential has no use here, and sending it would spread the bearer to an
      // endpoint that is deliberately outside the session chain.
      expect(
        headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('authorization')),
      );
    });

    // There is no body, and a header promising one is a lie the server may act on.
    test('sends no content type and no body', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await resetDevice(rig.deps);

      final request = rig.http.calls.single.request;
      expect(request.body, isNull);
      expect(
        request.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('content-type')),
      );
    });
  });

  group('resetDevice — what it reports', () {
    test('is done for a 200', () async {
      final rig = Rig()..answer();
      await rig.pair();

      expect(await resetDevice(rig.deps), DeviceResetOutcome.done);
    });

    // The device is already gone: from the cashier's side the request is already true, which
    // the contract calls idempotent.
    test('is done for a 401, without showing the cashier an error', () async {
      final rig = Rig()
        ..answer(
          status: 401,
          body:
              '{"data":null,"error":{"name":"authorization","code":137,'
              '"key":"pos_device_unregistered"}}',
        );
      await rig.pair();

      expect(await resetDevice(rig.deps), DeviceResetOutcome.done);
    });

    // A 500 is not "already gone": the row may well still be there, and the cashier has to be
    // told rather than left believing the dashboard is clean.
    test('reports a server failure for a 500', () async {
      final rig = Rig()..answer(status: 500, body: '{}');
      await rig.pair();

      expect(await resetDevice(rig.deps), DeviceResetOutcome.serverFailed);
    });

    test('reports a server failure when there is no connection', () async {
      final rig = Rig()..http.fail(TransportException('no connection'));
      await rig.pair();

      expect(await resetDevice(rig.deps), DeviceResetOutcome.serverFailed);
    });
  });

  group('resetDevice — what it leaves behind', () {
    // In every outcome. A cashier who asked to release the tablet must not be left holding a
    // device they can no longer use: a tablet stuck on the login screen can only be recovered
    // by the admin who could already delete the row.
    test('clears the session after a success', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await resetDevice(rig.deps);

      expect(rig.session.current, isNull);
      expect(await rig.stored(), isNull);
    });

    test(
      'clears the session even when the server could not be reached',
      () async {
        final rig = Rig()..http.fail(TransportException('no connection'));
        await rig.pair();

        await resetDevice(rig.deps);

        expect(rig.session.current, isNull);
        expect(await rig.stored(), isNull);
      },
    );

    test('clears the session even when the server refused', () async {
      final rig = Rig()..answer(status: 500, body: '{}');
      await rig.pair();

      await resetDevice(rig.deps);

      expect(rig.session.current, isNull);
    });

    // The whole reason for the ordering: the token authenticates the call, so it has to still
    // be there when the request goes out. Clearing first would leave the server row behind with
    // nothing able to identify it.
    test('sends the token before clearing it', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await resetDevice(rig.deps);

      expect(
        rig.http.calls.single.request.headers['X-Device-Token'],
        'dev_tok_1',
      );
      expect(rig.session.current, isNull);
    });

    // No token means the tablet was never in the registry: there is no row to delete, and a
    // request without the header would only earn a 401. Clearing locally is the whole of it.
    test('makes no request when the device has no token', () async {
      final rig = Rig();
      await rig.pair(pairedWithoutToken);

      expect(await resetDevice(rig.deps), DeviceResetOutcome.done);
      expect(rig.http.calls, isEmpty);
      expect(rig.session.current, isNull);
    });

    // Nothing paired, nothing to release — and nothing to tell the server about. Calling with no
    // session would throw on a null base URL.
    test('makes no request when nothing is paired', () async {
      final rig = Rig();

      expect(await resetDevice(rig.deps), DeviceResetOutcome.done);
      expect(rig.http.calls, isEmpty);
    });

    // Losing the store is not a reason to report success: the pairing would come back at the
    // next launch, and the tablet would look paired to an outlet whose server row is gone.
    test('surfaces a storage failure instead of swallowing it', () async {
      final rig = Rig()..answer();
      await rig.pair();
      rig.store.failNext(StoreException('disk full'));

      await expectLater(resetDevice(rig.deps), throwsA(isA<StoreException>()));
    });
  });

  // README §6: the queue is money already taken, on this tablet, whoever rang it up and
  // whichever outlet — so it blocks before anything else is touched, including the held
  // baskets F46 already covers.
  group('resetDevice — the offline queue guard', () {
    test(
      'is rejected while a sale is still queued, and nothing is touched',
      () async {
        final rig = Rig()..answer();
        await rig.pair();
        await rig.holdStore.writeAll([_basket('a', 'out_1')]);
        await rig.pendingSaleStore.enqueue(_queued());

        final outcome = await resetDevice(rig.deps);

        expect(outcome, DeviceResetOutcome.queueNotEmpty);
        expect(rig.http.calls, isEmpty);
        expect(rig.session.current, isNotNull);
        expect(await rig.holdStore.readAll(), isNotEmpty);
      },
    );

    // A failed sale is not the drain loop's problem any more, but the cashier has not decided
    // whether to retry or discard it yet — the money is still unaccounted for either way.
    test('is rejected for a failed sale too, not only a pending one', () async {
      final rig = Rig()..answer();
      await rig.pair();
      await rig.pendingSaleStore.enqueue(
        _queued(status: PendingSaleStatus.failed),
      );

      expect(await resetDevice(rig.deps), DeviceResetOutcome.queueNotEmpty);
    });

    // Whichever outlet or cashier: the tablet's whole queue must be sent or discarded first, not
    // only the entries for the outlet or cashier currently signed in.
    test('is rejected for a sale from another outlet and cashier', () async {
      final rig = Rig()..answer();
      await rig.pair();
      await rig.pendingSaleStore.enqueue(
        _queued(outletId: 'out_9', cashierId: 'someone_else'),
      );

      expect(await resetDevice(rig.deps), DeviceResetOutcome.queueNotEmpty);
    });

    // An unreadable queue is not an empty one (`pos_pending_sale_store.dart`): resetting over a
    // queue that cannot be proven clear is the exact mistake the guard exists to prevent.
    test('is rejected when the queue cannot be read', () async {
      final rig = Rig()..answer();
      await rig.pair();
      rig.pendingSaleStore.failRead = true;

      final outcome = await resetDevice(rig.deps);

      expect(outcome, DeviceResetOutcome.queueNotEmpty);
      expect(rig.session.current, isNotNull);
    });

    test('proceeds once the queue is empty', () async {
      final rig = Rig()..answer();
      await rig.pair();

      expect(await resetDevice(rig.deps), DeviceResetOutcome.done);
      expect(rig.session.current, isNull);
    });
  });

  group('resetDevice — analytics', () {
    test('logs device_reset once the server confirms', () async {
      final rig = Rig()..answer();
      await rig.pair();

      await resetDevice(rig.deps);

      expect(rig.analytics.logged.single.$1, 'device_reset');
    });

    // The tablet is reset locally either way, so this is still a completed reset — not the
    // blocked outcome, which is reserved for "nothing was touched".
    test('logs device_reset even when the server could not be told', () async {
      final rig = Rig()..answer(status: 500, body: '{}');
      await rig.pair();

      await resetDevice(rig.deps);

      expect(rig.analytics.logged.single.$1, 'device_reset');
    });

    test('logs device_reset_blocked with the reason, and not device_reset, '
        'when the queue is not empty', () async {
      final rig = Rig()..answer();
      await rig.pair();
      await rig.pendingSaleStore.enqueue(_queued());

      await resetDevice(rig.deps);

      expect(rig.analytics.logged.single.$1, 'device_reset_blocked');
      expect(rig.analytics.logged.single.$2, {'reason': 'queue_not_empty'});
    });
  });
}
