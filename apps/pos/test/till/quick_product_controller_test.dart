/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_quick_create.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/master_data.dart';
import 'package:pn_types/src/product.dart';
import 'package:pos/till/quick_create.dart';
import 'package:pos/till/quick_product_controller.dart';

// The behaviour of `pos-quick-add-product-dialog.tsx` (finnesia-monorepo), without its widgets:
// the unit picker always starts on PCS, and the product is posted with a name, a price, and a
// unit only when the cashier picked a real one.

const _json = {'content-type': 'application/json'};

TransportResponse ok(Object? data) => TransportResponse(
  status: 200,
  headers: _json,
  body: jsonEncode({'data': data}),
);

Map<String, Object?> unitJson(String id, String name, String symbol) => {
  'id': id,
  'company_id': 'co1',
  'name': name,
  'symbol': symbol,
  'conversion_ratio': 1,
  'is_base': true,
};

Map<String, Object?> productJson(String id, String name, num price) => {
  'id': id,
  'name': name,
  'unit_id': 'u-pcs',
  'sell_price': price,
  'type': 'NON_INVENTORY',
};

const pcs = Unit(id: 'u-pcs', name: 'Pieces', symbol: 'PCS');
const box = Unit(id: 'u-box', name: 'Kotak', symbol: 'BOX');

/// What opening the form reads, in the order it reads it: the PCS lookup, then the page.
void opening(
  FakeApiTransport transport, {
  List<Map<String, Object?>> pcsFound = const [],
  List<Map<String, Object?>> page = const [],
}) {
  transport
    ..respond(ok(pcsFound))
    ..respond(ok(page));
}

({QuickProductController controller, FakeApiTransport transport}) rig() {
  final transport = FakeApiTransport();
  final controller = QuickProductController(
    client: ApiClient(transport: transport, language: () => 'id'),
  );
  addTearDown(controller.dispose);
  return (controller: controller, transport: transport);
}

Uri uriOf(TransportRequest request) => Uri.parse(request.path);

Iterable<TransportRequest> posts(FakeApiTransport t) =>
    t.requests.where((r) => r.method.wire == 'POST');

void main() {
  group('opening the form', () {
    test(
      'asks for the company PCS by symbol, and for one page of units',
      () async {
        final (:controller, :transport) = rig();
        opening(transport);

        await controller.open();

        final queries = [
          for (final r in transport.requests) uriOf(r).queryParameters,
        ];
        expect(transport.requests.map((r) => uriOf(r).path), [
          '/api/v1/master/units',
          '/api/v1/master/units',
        ]);
        // Asked by symbol: a company with many units may not have PCS on the first page.
        expect(queries.first, {'q': 'PCS', 'page_size': '10'});
        expect(queries.last, {'page_size': '50'});
      },
    );

    test('starts on the company PCS, first in the list', () async {
      final (:controller, :transport) = rig();
      opening(
        transport,
        pcsFound: [unitJson('u-pcs', 'Pieces', 'PCS')],
        page: [
          unitJson('u-box', 'Kotak', 'BOX'),
          unitJson('u-pcs', 'Pieces', 'PCS'),
        ],
      );

      await controller.open();

      expect(controller.choices, [
        const QuickUnitExisting(pcs),
        const QuickUnitExisting(box),
      ]);
      expect(controller.unit, const QuickUnitExisting(pcs));
    });

    test('starts on PCS to be created when the company has none', () async {
      final (:controller, :transport) = rig();
      opening(transport, page: [unitJson('u-box', 'Kotak', 'BOX')]);

      await controller.open();

      expect(controller.choices, [
        const QuickUnitPcsNew(),
        const QuickUnitExisting(box),
      ]);
      expect(controller.unit, const QuickUnitPcsNew());
    });

    test('opened twice reads once', () async {
      final (:controller, :transport) = rig();
      opening(transport);

      await controller.open();
      await controller.open();

      expect(transport.requests, hasLength(2));
    });

    test('a unit the cashier picked survives the list arriving', () async {
      final (:controller, :transport) = rig();
      opening(
        transport,
        pcsFound: [unitJson('u-pcs', 'Pieces', 'PCS')],
        page: [unitJson('u-box', 'Kotak', 'BOX')],
      );

      final reading = controller.open();
      controller.pickUnit(const QuickUnitExisting(box));
      await reading;

      expect(controller.unit, const QuickUnitExisting(box));
    });

    test('units that could not be read still leave PCS to save with', () async {
      // Saving without a unit is always safe: the server uses the company PCS, or creates it.
      final (:controller, :transport) = rig();
      transport.fail(TransportException('offline'));

      await controller.open();

      expect(controller.unitsFailed, isTrue);
      expect(controller.choices, [const QuickUnitPcsNew()]);
      expect(controller.unit, const QuickUnitPcsNew());
    });

    test('tells its listeners when the units arrive', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      var heard = 0;
      controller.addListener(() => heard++);

      await controller.open();

      expect(heard, greaterThan(0));
      expect(controller.isLoadingUnits, isFalse);
    });
  });

  group('saving', () {
    test('posts the trimmed name and the price, without a unit for PCS to be '
        'created', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();
      transport.respond(ok(productJson('p9', 'Es Teh', 5000)));

      final outcome = await controller.create(
        name: '  Es Teh ',
        sellPrice: 5000,
      );

      expect(outcome, isA<QuickCreateOk<Product>>());
      expect((outcome as QuickCreateOk<Product>).created.id, 'p9');
      final sent = posts(transport).single;
      expect(uriOf(sent).path, '/api/v1/pos/products');
      expect(jsonDecode(sent.body!), {'name': 'Es Teh', 'sell_price': 5000});
    });

    test('posts the picked unit as unit_id', () async {
      final (:controller, :transport) = rig();
      opening(transport, page: [unitJson('u-box', 'Kotak', 'BOX')]);
      await controller.open();
      controller.pickUnit(const QuickUnitExisting(box));
      transport.respond(ok(productJson('p9', 'Es Teh', 0)));

      await controller.create(name: 'Es Teh', sellPrice: 0);

      expect(jsonDecode(posts(transport).single.body!), {
        'name': 'Es Teh',
        'sell_price': 0,
        'unit_id': 'u-box',
      });
    });

    test('a name of only spaces is not sent', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();

      final outcome = await controller.create(name: '   ', sellPrice: 1000);

      expect(outcome, isA<QuickCreateInvalid<Product>>());
      expect(posts(transport), isEmpty);
    });

    test('the server refusing is reported with its own sentence', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();
      transport.respond(
        TransportResponse(
          status: 402,
          headers: _json,
          body: jsonEncode({
            'error': {'message': 'Kuota produk habis'},
          }),
        ),
      );

      final outcome = await controller.create(name: 'Es Teh', sellPrice: 0);

      expect(
        (outcome as QuickCreateRejected<Product>).message,
        'Kuota produk habis',
      );
    });

    test('a server failure is not a refusal: it may have saved', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();
      transport.respond(
        TransportResponse(
          status: 500,
          headers: _json,
          body: jsonEncode({
            'error': {'message': 'internal'},
          }),
        ),
      );

      final outcome = await controller.create(name: 'Es Teh', sellPrice: 0);

      expect(outcome, isA<QuickCreateUnavailable<Product>>());
    });

    test('no answer at all is a different answer from a refusal', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();
      transport.fail(TransportException('offline'));

      final outcome = await controller.create(name: 'Es Teh', sellPrice: 0);

      expect(outcome, isA<QuickCreateUnavailable<Product>>());
    });

    test('only one product goes out at a time', () async {
      final (:controller, :transport) = rig();
      opening(transport);
      await controller.open();
      transport.respond(ok(productJson('p9', 'Es Teh', 0)));

      await Future.wait([
        controller.create(name: 'Es Teh', sellPrice: 0),
        controller.create(name: 'Es Teh', sellPrice: 0),
      ]);

      expect(posts(transport), hasLength(1));
    });

    test('can be saved before the units have arrived, as PCS', () async {
      final (:controller, :transport) = rig();
      transport.respond(ok(productJson('p9', 'Es Teh', 0)));

      await controller.create(name: 'Es Teh', sellPrice: 0);

      expect(jsonDecode(posts(transport).single.body!), {
        'name': 'Es Teh',
        'sell_price': 0,
      });
    });
  });
}
