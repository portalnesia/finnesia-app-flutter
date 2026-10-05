/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:pos/shift/shift_detail_controller.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/paged_loadable.dart';

// Written new. `shift-page.tsx` holds four queries in one component; there is no object to port.
// What is ported is what it reads and why: the open shift of the paired outlet (the same query
// the till reads, so the two never disagree), and the three things behind it that a cashier who
// has to explain a variance can only explain by looking — the summary, the drawer movements and
// the individual sales.

const _json = {'content-type': 'application/json'};

TransportResponse ok(Object? data) => TransportResponse(
  status: 200,
  headers: _json,
  body: jsonEncode({'data': data}),
);

TransportResponse page(List<Map<String, Object?>> items, {String? next}) =>
    TransportResponse(
      status: 200,
      headers: _json,
      body: jsonEncode({
        'data': items,
        'meta': {'next_cursor': next},
      }),
    );

TransportResponse refused(int status, String message) => TransportResponse(
  status: status,
  headers: _json,
  body: jsonEncode({
    'error': {'message': message},
  }),
);

Map<String, Object?> shiftJson({String id = 's1', String cashierId = 'u1'}) => {
  'id': id,
  'number': 'SH-0001',
  'cashier_id': cashierId,
  'outlet_id': 'out_1',
  'opened_at': '2026-09-20T01:00:00Z',
  'opening_cash': 100000,
  'total_sales': 0,
  'total_transactions': 0,
};

Map<String, Object?> summaryJson({String id = 's1'}) => {
  'shift_id': id,
  'number': 'SH-0001',
  'status': 'OPEN',
  'outlet_id': 'out_1',
  'cashier_id': 'u1',
  'opened_at': '2026-09-20T01:00:00Z',
  'total_transactions': 2,
  'total_sales': 150000,
  'opening_cash': 100000,
  'expected_cash': 250000,
  'cash_in': 0,
  'cash_out': 0,
  'cash_drop': 0,
  'sales_by_method': null,
  'non_cash_tenders': null,
  'product_sales': null,
};

Map<String, Object?> saleJson(String id) => {
  'id': id,
  'number': 'POS-$id',
  'shift_id': 's1',
  'outlet_id': 'out_1',
  'cashier_id': 'u1',
  'transaction_date': '2026-09-20',
  'subtotal': 75000,
  'discount_amount': 0,
  'tax_amount': 0,
  'grand_total': 75000,
  'tendered_amount': 75000,
  'change_amount': 0,
  'status': 'POSTED',
  'created_at': '2026-09-20T03:00:00Z',
};

Map<String, Object?> movementJson(String id) => {
  'id': id,
  'shift_id': 's1',
  'type': 'CASH_OUT',
  'amount': 5000,
  'reason': 'Beli galon',
  'created_at': '2026-09-20T04:00:00Z',
};

/// What opening the screen reads, in the order it starts the reads: the shift, then the summary,
/// the movements and the sales (which start together once the shift is known).
void opening(
  FakeApiTransport transport, {
  Map<String, Object?>? shift,
  String? nextSales,
}) {
  transport.respond(ok(shift ?? shiftJson()));
  transport.respond(ok(summaryJson()));
  transport.respond(ok([movementJson('m1')]));
  transport.respond(page([saleJson('a'), saleJson('b')], next: nextSales));
}

({ShiftDetailController controller, FakeApiTransport transport}) rig({
  String? userId = 'u1',
  String outletId = 'out_1',
  UserCompany? membership,
  POSShift? shift,
}) {
  final transport = FakeApiTransport();
  final controller = ShiftDetailController(
    client: ApiClient(transport: transport, language: () => 'id'),
    outletId: outletId,
    userId: userId,
    membership: membership,
    shift: shift,
  );
  addTearDown(controller.dispose);
  return (controller: controller, transport: transport);
}

const owner = UserCompany(
  id: 'uc_1',
  userId: 'u1',
  companyId: 'comp_1',
  role: 'owner',
  isActive: true,
);

Uri uriOf(TransportRequest request) => Uri.parse(request.path);

void main() {
  group('reading the shift and what is behind it', () {
    test('asks for the shift of the paired outlet, then for its figures by '
        'the id it found', () async {
      final (:controller, :transport) = rig();
      opening(transport);

      await controller.load();

      final paths = transport.requests.map((r) => uriOf(r).path).toList();
      expect(paths, [
        '/api/v1/pos/shifts/active',
        '/api/v1/pos/shifts/s1',
        '/api/v1/pos/shifts/s1/cash-movements',
        '/api/v1/pos/sales',
      ]);
      expect(uriOf(transport.requests[0]).queryParameters, {
        'outlet_id': 'out_1',
      });
      // The sales are the shift's, not the outlet's, and one page of 50 (the page size the
      // catalogue uses): a long day has hundreds.
      expect(uriOf(transport.requests[3]).queryParameters, {
        'shift_id': 's1',
        'page_size': '50',
      });
    });

    test('holds the four answers once they are in', () async {
      final (:controller, :transport) = rig();
      opening(transport);

      await controller.load();

      expect((controller.shift.state as Ready).data?.number, 'SH-0001');
      expect((controller.summary.state as Ready).data.totalTransactions, 2);
      expect(
        (controller.movements.state as Ready).data.single.reason,
        'Beli galon',
      );
      final sales = (controller.sales.state as Ready<PagedItems>).data;
      expect(sales.items, hasLength(2));
    });

    test('reads nothing further when no shift is open', () async {
      final (:controller, :transport) = rig();
      transport.respond(ok(null));

      await controller.load();

      // Null is an answer, not a failure: there is no shift to ask the figures of.
      expect(transport.requests, hasLength(1));
      expect((controller.shift.state as Ready).data, isNull);
    });

    test(
      'does not read the figures of a shift another cashier holds',
      () async {
        final (:controller, :transport) = rig(userId: 'u1');
        transport.respond(ok(shiftJson(cashierId: 'someone_else')));
        transport.respond(
          ok(<String>[]),
        ); // what the server allows this cashier

        await controller.load();

        // The shift and the permissions, and nothing about the drawer itself.
        expect(transport.requests, hasLength(2));
        expect(controller.isHeldByOther, isTrue);
        expect(controller.canOverride, isFalse);
      },
    );

    test('asks nothing when the session has no outlet', () async {
      // Without an outlet the server would answer with another outlet's drawer, which is worse
      // than showing none (`MenuScreenController` skips its reads for the same reason).
      final (:controller, :transport) = rig(outletId: '');

      await controller.load();

      expect(transport.requests, isEmpty);
      expect((controller.shift.state as Ready).data, isNull);
    });

    test(
      'takes a session that names nobody for someone else\'s drawer',
      () async {
        // The gate reads it the same way: an app that cannot prove the drawer is the cashier's
        // must not show its figures.
        final (:controller, :transport) = rig(userId: null);
        transport.respond(ok(shiftJson()));
        transport.respond(ok(<String>[]));

        await controller.load();

        expect(controller.isHeldByOther, isTrue);
        expect(transport.requests, hasLength(2));
      },
    );

    test('knows the drawer is the cashier\'s own', () async {
      final (:controller, :transport) = rig();
      opening(transport);

      await controller.load();

      expect(controller.isHeldByOther, isFalse);
    });
  });

  // The history opens a shift it already has in hand, so nothing asks which drawer is open: the
  // one picked is the one shown, and it may be long closed and another cashier's.
  group('a shift picked from the history', () {
    POSShift picked({String cashierId = 'u1', String? status = 'CLOSED'}) =>
        POSShift.fromJson({
          ...shiftJson(cashierId: cashierId),
          'status': ?status,
        });

    test('is not looked for again: its figures are read by its id', () async {
      final (:controller, :transport) = rig(shift: picked());
      transport.respond(ok(summaryJson()));
      transport.respond(ok([movementJson('m1')]));
      transport.respond(page([saleJson('a')]));

      await controller.load();

      final paths = transport.requests.map((r) => uriOf(r).path).toList();
      expect(paths, [
        '/api/v1/pos/shifts/s1',
        '/api/v1/pos/shifts/s1/cash-movements',
        '/api/v1/pos/sales',
      ]);
      expect((controller.shift.state as Ready).data?.number, 'SH-0001');
    });

    test('a closed shift of another cashier can be read, and asks nobody '
        'anything', () async {
      final (:controller, :transport) = rig(
        shift: picked(cashierId: 'someone_else'),
      );
      transport.respond(ok(summaryJson()));
      transport.respond(ok(<Object?>[]));
      transport.respond(page([]));

      await controller.load();

      // Nothing is held: there is no drawer to work, only figures to read.
      expect(controller.isHeldByOther, isFalse);
      expect(transport.requests, hasLength(3));
      expect(controller.summary.state, isA<Ready>());
    });

    test('an open shift of another cashier is still theirs to show', () async {
      final (:controller, :transport) = rig(
        shift: picked(cashierId: 'someone_else', status: 'OPEN'),
      );
      transport.respond(ok(<String>[]));

      await controller.load();

      expect(controller.isHeldByOther, isTrue);
      // The permissions, and nothing about the drawer itself.
      expect(transport.requests, hasLength(1));
    });

    test('a status this build cannot read is taken for open', () async {
      // The safe direction: a drawer that may still be open is not shown to whoever asks.
      final (:controller, :transport) = rig(
        shift: picked(cashierId: 'someone_else', status: null),
      );
      transport.respond(ok(<String>[]));

      await controller.load();

      expect(controller.isHeldByOther, isTrue);
    });
  });

  group('when a read fails', () {
    test('a failed shift read is a failure, not "no shift is open"', () async {
      final (:controller, :transport) = rig();
      transport.fail(TransportException('offline'));

      await controller.load();

      expect(controller.shift.state, isA<Failed<dynamic>>());
      expect(transport.requests, hasLength(1));
    });

    // The drawer with no movements at all: Go marshals its nil slice to `null`, so the endpoint
    // has to read that as an empty list. Otherwise the tab shows "Unexpected response from server"
    // and a retry button that asks for the same payload and fails the same way.
    test('a drawer with no movements shows none, not an error', () async {
      final (:controller, :transport) = rig();
      transport.respond(ok(shiftJson()));
      transport.respond(ok(summaryJson()));
      transport.respond(ok(null)); // `{"data":null}`, what the server sends
      transport.respond(page(<Map<String, Object?>>[]));

      await controller.load();

      expect(controller.movements.state, isA<Ready<dynamic>>());
      expect((controller.movements.state as Ready).data, isEmpty);
      expect(
        uriOf(
          transport.requests.firstWhere(
            (r) => uriOf(r).path.endsWith('/cash-movements'),
          ),
        ).path,
        '/api/v1/pos/shifts/s1/cash-movements',
      );
    });

    test(
      'a failed summary does not blank the sales or the movements',
      () async {
        final (:controller, :transport) = rig();
        transport.respond(ok(shiftJson()));
        transport.respond(refused(500, 'Gagal'));
        transport.respond(ok([movementJson('m1')]));
        transport.respond(page([saleJson('a')]));

        await controller.load();

        expect(controller.summary.state, isA<Failed<dynamic>>());
        expect(controller.movements.state, isA<Ready<dynamic>>());
        expect(controller.sales.state, isA<Ready<dynamic>>());
      },
    );

    test('a failed sales read leaves the summary standing', () async {
      final (:controller, :transport) = rig();
      transport.respond(ok(shiftJson()));
      transport.respond(ok(summaryJson()));
      transport.respond(ok(<Object?>[]));
      transport.respond(refused(500, 'Gagal'));

      await controller.load();

      expect(controller.sales.state, isA<Failed<dynamic>>());
      expect(controller.summary.state, isA<Ready<dynamic>>());
      final error = (controller.sales.state as Failed).error;
      expect(error, isA<ApiError>());
    });

    test('loading again after a failure reads everything again', () async {
      final (:controller, :transport) = rig();
      transport.fail(TransportException('offline'));
      await controller.load();

      opening(transport);
      await controller.load();

      expect(controller.shift.state, isA<Ready<dynamic>>());
      expect(controller.summary.state, isA<Ready<dynamic>>());
    });
  });

  group('scrolling the sales', () {
    test('asks for the next page with the cursor, once', () async {
      final (:controller, :transport) = rig();
      opening(transport, nextSales: 'c2');
      await controller.load();

      transport.respond(page([saleJson('c')]));
      await controller.sales.loadMore();

      final next = uriOf(transport.requests.last);
      expect(next.path, '/api/v1/pos/sales');
      expect(next.queryParameters['next_cursor'], 'c2');
      expect(next.queryParameters['shift_id'], 's1');
      final sales = (controller.sales.state as Ready<PagedItems>).data;
      expect(sales.items, hasLength(3));
    });
  });

  group('reading again', () {
    test(
      'finds the shift again and reads the figures of the one it finds',
      () async {
        final (:controller, :transport) = rig();
        opening(transport);
        await controller.load();

        // The drawer was closed and another opened while the screen was up.
        transport.respond(ok(shiftJson(id: 's2')));
        transport.respond(ok(summaryJson(id: 's2')));
        transport.respond(ok(<Object?>[]));
        transport.respond(page([]));
        await controller.load();

        final paths = transport.requests.skip(4).map((r) => uriOf(r).path);
        expect(paths, contains('/api/v1/pos/shifts/s2'));
        expect(paths, contains('/api/v1/pos/shifts/s2/cash-movements'));
      },
    );
  });

  group('a drawer another cashier holds, and who may see it', () {
    test('an owner may: the figures are read, and nobody is asked what the '
        'owner may do', () async {
      final (:controller, :transport) = rig(membership: owner);
      opening(transport, shift: shiftJson(cashierId: 'someone_else'));

      await controller.load();

      expect(controller.isHeldByOther, isTrue);
      expect(controller.canOverride, isTrue);
      expect(transport.requests, hasLength(4));
    });

    test('a cashier the server granted the override may: it is asked for once, '
        'before the figures', () async {
      final (:controller, :transport) = rig();
      transport.respond(ok(shiftJson(cashierId: 'someone_else')));
      transport.respond(ok(['pos.shift.override']));
      transport.respond(ok(summaryJson()));
      transport.respond(ok(<Object?>[]));
      transport.respond(page([]));

      await controller.load();

      expect(uriOf(transport.requests[1]).path, '/api/v1/team/my-permissions');
      expect(controller.canOverride, isTrue);
      expect(transport.requests, hasLength(5));
    });

    test('a permission read the server refused, or nobody answered, is no '
        'override, and does not throw', () async {
      final refusedRig = rig();
      refusedRig.transport
        ..respond(ok(shiftJson(cashierId: 'someone_else')))
        ..respond(refused(500, 'Gagal'));
      await refusedRig.controller.load();
      expect(refusedRig.controller.canOverride, isFalse);
      expect(refusedRig.transport.requests, hasLength(2));

      final silentRig = rig();
      silentRig.transport
        ..respond(ok(shiftJson(cashierId: 'someone_else')))
        ..fail(TransportException('offline'));
      await silentRig.controller.load();
      expect(silentRig.controller.canOverride, isFalse);
      expect(silentRig.transport.requests, hasLength(2));
    });
  });
}
