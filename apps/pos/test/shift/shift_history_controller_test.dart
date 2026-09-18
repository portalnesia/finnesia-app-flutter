/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pos/shift/shift_history_controller.dart';
import 'package:pos/state/loadable.dart';

// Written new. `pos-shifts-page.tsx` is a table with five filters and its own paging; what is kept
// is what it asks the server (the outlet, the status, a cursor) and that every filter is the
// server's: narrowing the page already downloaded would hide the rows that match on any page but
// the first.

const _json = {'content-type': 'application/json'};

TransportResponse page(List<Map<String, Object?>> items, {String? next}) =>
    TransportResponse(
      status: 200,
      headers: _json,
      body: jsonEncode({
        'data': items,
        'meta': {'next_cursor': next},
      }),
    );

Map<String, Object?> shiftJson(String id, {String status = 'CLOSED'}) => {
  'id': id,
  'number': 'SH-$id',
  'cashier_id': 'u1',
  'outlet_id': 'out_1',
  'opened_at': '2026-09-20T01:00:00Z',
  'opening_cash': 100000,
  'total_sales': 250000,
  'total_transactions': 4,
  'status': status,
};

({ShiftHistoryController controller, FakeApiTransport transport}) rig({
  String outletId = 'out_1',
}) {
  final transport = FakeApiTransport();
  final controller = ShiftHistoryController(
    client: ApiClient(transport: transport, language: () => 'id'),
    outletId: outletId,
  );
  addTearDown(controller.dispose);
  return (controller: controller, transport: transport);
}

Uri uriOf(TransportRequest request) => Uri.parse(request.path);

List<String> idsOf(ShiftHistoryController controller) =>
    switch (controller.shifts.state) {
      Ready(:final data) => [for (final s in data.items) s.id],
      _ => throw StateError('not ready: ${controller.shifts.state}'),
    };

void main() {
  group('reading the history', () {
    test('asks for the shifts of the paired outlet, newest first as the server '
        'gives them', () async {
      final (:controller, :transport) = rig();
      transport.respond(page([shiftJson('b'), shiftJson('a')]));

      await controller.load();

      final asked = uriOf(transport.requests.single);
      expect(asked.path, '/api/v1/pos/shifts');
      expect(asked.queryParameters['outlet_id'], 'out_1');
      expect(asked.queryParameters['page_size'], '25');
      // Every status until the cashier narrows it.
      expect(asked.queryParameters.containsKey('status'), isFalse);
      expect(idsOf(controller), ['b', 'a']);
    });

    test(
      'with no outlet asks for nothing, rather than for every outlet',
      () async {
        final (:controller, :transport) = rig(outletId: '');

        await controller.load();

        // The server would answer with other outlets' shifts, which is worse than showing none.
        expect(transport.requests, isEmpty);
        expect(idsOf(controller), isEmpty);
      },
    );

    test('asks for the next page with the cursor of the one before', () async {
      final (:controller, :transport) = rig();
      transport.respond(page([shiftJson('b')], next: 'cur_2'));
      transport.respond(page([shiftJson('a')]));

      await controller.load();
      await controller.shifts.loadMore();

      expect(
        uriOf(transport.requests.last).queryParameters['next_cursor'],
        'cur_2',
      );
      expect(idsOf(controller), ['b', 'a']);
    });
  });

  group('narrowing it', () {
    test(
      'a status is the server\'s to filter, and starts again from the top',
      () async {
        final (:controller, :transport) = rig();
        transport.respond(
          page([shiftJson('b', status: 'OPEN')], next: 'cur_2'),
        );
        transport.respond(page([shiftJson('a')]));

        await controller.load();
        await controller.setFilter(ShiftHistoryFilter.closed);

        final asked = uriOf(transport.requests.last);
        expect(asked.queryParameters['status'], 'CLOSED');
        // A cursor points into the result the old filter made.
        expect(asked.queryParameters.containsKey('next_cursor'), isFalse);
        expect(idsOf(controller), ['a']);
      },
    );

    test('back to all drops the status again', () async {
      final (:controller, :transport) = rig();
      transport.respond(page([shiftJson('a')]));
      transport.respond(page([shiftJson('a')]));
      transport.respond(page([shiftJson('b'), shiftJson('a')]));

      await controller.load();
      await controller.setFilter(ShiftHistoryFilter.open);
      await controller.setFilter(ShiftHistoryFilter.all);

      expect(
        uriOf(transport.requests.last).queryParameters.containsKey('status'),
        isFalse,
      );
      expect(controller.filter, ShiftHistoryFilter.all);
    });

    test('the same filter again reads nothing', () async {
      final (:controller, :transport) = rig();
      transport.respond(page([shiftJson('a')]));

      await controller.load();
      await controller.setFilter(ShiftHistoryFilter.all);

      expect(transport.requests, hasLength(1));
    });
  });
}
