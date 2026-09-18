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
import 'package:pos/menu/menu_controller.dart';
import 'package:pos/state/loadable.dart';

// C10: what the Menu reads.
//
// The Menu is the one screen that is not a sale, and its rule is the opposite of the till's:
// every row is a courtesy, and a row that cannot be read must not take the screen down. A
// cashier whose outlet name failed to load still has to be able to sign out.

const _json = {'content-type': 'application/json'};

TransportResponse ok(Object? data) => TransportResponse(
  status: 200,
  headers: _json,
  body: jsonEncode({'data': data}),
);

TransportResponse refused(int status, String message) => TransportResponse(
  status: status,
  headers: _json,
  body: jsonEncode({
    'error': {'message': message},
  }),
);

Map<String, Object?> outletJson({
  String id = 'out_1',
  String name = 'Outlet Pusat',
}) => {'id': id, 'name': name};

Map<String, Object?> shiftJson({
  String id = 'shift_1',
  String number = 'SH-0001',
  num openingCash = 100000,
}) => {
  'id': id,
  'number': number,
  'outlet_id': 'out_1',
  'cashier_id': 'user_1',
  'opened_at': '2026-09-20T01:00:00Z',
  'opening_cash': openingCash,
  'total_sales': 250000,
  'total_transactions': 3,
  'status': 'OPEN',
};

/// A device paired to [outletId], with one answer queued for each read the Menu makes.
({MenuScreenController menu, FakeApiTransport transport}) rig({
  String outletId = 'out_1',
  bool withShift = true,
}) {
  final transport = FakeApiTransport();
  final menu = MenuScreenController(
    client: ApiClient(transport: transport, language: () => 'id'),
    outletId: outletId,
  );
  addTearDown(menu.dispose);
  if (outletId.isNotEmpty) {
    transport.respond(ok(outletJson(id: outletId)));
    transport.respond(ok(withShift ? shiftJson() : null));
  }
  return (menu: menu, transport: transport);
}

Iterable<String> pathsOf(FakeApiTransport t) =>
    t.requests.map((r) => r.path.split('?').first);

/// The value of a load that finished, or null while it has not (or failed).
T? valueOf<T>(Loadable<T> loadable) => switch (loadable.state) {
  Ready(:final data) => data,
  _ => null,
};

void main() {
  group('reading the menu', () {
    test('asks for the outlet and the open shift, once each', () async {
      final (:menu, :transport) = rig();

      await menu.load();

      expect(
        pathsOf(transport),
        unorderedEquals(['/api/v1/outlets/out_1', '/api/v1/pos/shifts/active']),
      );
    });

    test('keeps the outlet name the server sent', () async {
      final (:menu, :transport) = rig();

      await menu.load();

      expect(valueOf(menu.outlet)?.name, 'Outlet Pusat');
    });

    test('a shift that is not open is an answer, not a failure', () async {
      final (:menu, :transport) = rig(withShift: false);

      await menu.load();

      // `null` is what the server says when the drawer is closed. Reading it as a failure would
      // put an error on a screen where nothing went wrong.
      expect(menu.shift.state, isA<Ready<POSShift?>>());
      expect(valueOf(menu.shift), isNull);
    });
  });

  group('when a read fails', () {
    test('the outlet failing leaves the shift readable', () async {
      final transport = FakeApiTransport();
      transport.respond(refused(403, 'Tidak diizinkan'));
      transport.respond(ok(shiftJson()));
      final menu = MenuScreenController(
        client: ApiClient(transport: transport, language: () => 'id'),
        outletId: 'out_1',
      );
      addTearDown(menu.dispose);

      await menu.load();

      // The two reads are separate on purpose (README §5.1). A cashier who cannot see the
      // outlet name can still see the shift, and can still sign out.
      expect(menu.outlet.state, isA<Failed<Outlet?>>());
      expect(valueOf(menu.shift)?.number, 'SH-0001');
    });

    test('the refusal keeps the server\'s own sentence', () async {
      final transport = FakeApiTransport();
      transport.respond(refused(403, 'Tidak diizinkan'));
      transport.respond(ok(null));
      final menu = MenuScreenController(
        client: ApiClient(transport: transport, language: () => 'id'),
        outletId: 'out_1',
      );
      addTearDown(menu.dispose);

      await menu.load();

      final error = (menu.outlet.state as Failed<Outlet?>).error;
      expect(error, isA<ApiError>());
      expect((error as ApiError).message, 'Tidak diizinkan');
    });
  });

  group('a session with no outlet', () {
    test('asks for nothing at all', () async {
      final (:menu, :transport) = rig(outletId: '');

      await menu.load();

      // A device that is paired always has an outlet, but a session written by an older build
      // may not. `/outlets/` is not a request; it is a wasted round trip that answers 404.
      expect(transport.requests, isEmpty);
    });

    test('reports no outlet rather than an error', () async {
      final (:menu, :transport) = rig(outletId: '');

      await menu.load();

      expect(menu.outlet.state, isA<Ready<Outlet?>>());
      expect(valueOf(menu.outlet), isNull);
    });
  });
}
