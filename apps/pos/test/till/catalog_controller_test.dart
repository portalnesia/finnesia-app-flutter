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
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/paged_loadable.dart';
import 'package:pos/till/catalog_controller.dart';

// Written new. The product grid holds three queries and a debounced value in one component, and
// the scan lookup lives in the page; there is no object to port. The behaviours are: one page of
// 50 that scrolls, the server does the searching, stock is one request for the whole grid, and a
// scan asks the server for the exact code.

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

TransportResponse ok(Object? data) => TransportResponse(
  status: 200,
  headers: _json,
  body: jsonEncode({'data': data}),
);

Map<String, Object?> productJson(
  String id, {
  String? sku,
  String? barcode,
  bool? active,
}) => {
  'id': id,
  'name': 'Produk $id',
  'unit_id': 'unit_1',
  'sell_price': 10000,
  'sku': sku,
  'barcode': barcode,
  'is_active': active,
};

/// What opening the catalogue reads, in the order it reads it.
void opening(
  FakeApiTransport transport, {
  List<Map<String, Object?>>? products,
  String? next,
}) {
  transport.respond(
    ok([
      {'id': 'cat_1', 'name': 'Minuman'},
    ]),
  );
  transport.respond(page(products ?? [productJson('a')], next: next));
  transport.respond(ok({'a': 5}));
}

Uri uriOf(TransportRequest request) => Uri.parse(request.path);

({
  CatalogController catalog,
  FakeApiTransport transport,
  FakeAnalytics analytics,
})
rig({Duration debounce = const Duration(milliseconds: 20)}) {
  final transport = FakeApiTransport();
  final analytics = FakeAnalytics();
  final catalog = CatalogController(
    client: ApiClient(transport: transport, language: () => 'id'),
    outletId: 'out_1',
    debounce: debounce,
    analytics: analytics,
  );
  addTearDown(catalog.dispose);
  return (catalog: catalog, transport: transport, analytics: analytics);
}

Future<void> settle([int ms = 60]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

List<TransportRequest> productRequests(FakeApiTransport t) =>
    t.requests.where((r) => uriOf(r).path == '/api/v1/products').toList();

void main() {
  group('opening the catalogue', () {
    test(
      'reads the categories, the first page and the stock, once each',
      () async {
        final (:catalog, :transport, analytics: _) = rig();
        opening(transport);

        await catalog.load();

        expect(transport.requests, hasLength(3));
        expect(
          transport.requests.map((r) => uriOf(r).path),
          unorderedEquals([
            '/api/v1/master/categories',
            '/api/v1/products',
            '/api/v1/pos/stock',
          ]),
        );
      },
    );

    test('asks only for what is sold, fifty at a time', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);

      await catalog.load();

      final query = uriOf(productRequests(transport).single).queryParameters;
      expect(query['sellable'], 'true');
      expect(query['page_size'], '50');
      expect(query.containsKey('q'), isFalse);
      expect(query.containsKey('category_id'), isFalse);
    });

    test('shows only the categories a till shows', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);

      await catalog.load();

      final request = transport.requests.singleWhere(
        (r) => uriOf(r).path == '/api/v1/master/categories',
      );
      expect(uriOf(request).queryParameters['pos_visible'], 'true');
    });

    test('asks the stock of the outlet it sells from', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);

      await catalog.load();

      final request = transport.requests.singleWhere(
        (r) => uriOf(r).path == '/api/v1/pos/stock',
      );
      expect(uriOf(request).queryParameters['outlet_id'], 'out_1');
    });

    test('has the answers to hand once they are in', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);

      await catalog.load();

      expect(catalog.sellable.map((p) => p.id), ['a']);
      expect(catalog.categories.state, isA<Ready<List<dynamic>>>());
      expect(catalog.stock.state, isA<Ready<Map<String, num>>>());
    });

    test(
      'a catalogue that could not be read says so, and is not empty',
      () async {
        final (:catalog, :transport, analytics: _) = rig();
        transport.respond(ok([]));
        transport.respond(
          TransportResponse(
            status: 500,
            headers: _json,
            body: '{"error":{"message":"boom"}}',
          ),
        );
        transport.respond(ok({}));

        await catalog.load();

        // "No products" would read to a cashier as "we do not sell this".
        expect(catalog.products.state, isA<Failed<PagedItems<Object?>>>());
      },
    );

    test('a failed stock read does not take the products with it', () async {
      final (:catalog, :transport, analytics: _) = rig();
      transport.respond(ok([]));
      transport.respond(page([productJson('a')]));
      transport.respond(
        TransportResponse(
          status: 500,
          headers: _json,
          body: '{"error":{"message":"boom"}}',
        ),
      );

      await catalog.load();

      expect(catalog.sellable, hasLength(1));
      expect(catalog.stock.state, isA<Failed<Map<String, num>>>());
    });
  });

  group('a deactivated product', () {
    test('is listed by the server and not shown', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(
        transport,
        products: [
          productJson('a'),
          productJson('b', active: false),
          productJson('c', active: true),
        ],
      );

      await catalog.load();

      expect(catalog.sellable.map((p) => p.id), ['a', 'c']);
    });
  });

  group('scrolling on', () {
    test('asks for the page after the last one, and appends', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport, next: 'cur_2');
      await catalog.load();
      transport.respond(page([productJson('b')]));

      await catalog.loadMore();

      final asked = uriOf(productRequests(transport).last).queryParameters;
      expect(asked['next_cursor'], 'cur_2');
      expect(catalog.sellable.map((p) => p.id), ['a', 'b']);
    });

    test('has no page to ask for at the end', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);
      await catalog.load();

      await catalog.loadMore();

      expect(productRequests(transport), hasLength(1));
    });
  });

  group('choosing a category', () {
    test(
      'starts the products again from the first page, for that category',
      () async {
        final (:catalog, :transport, analytics: _) = rig();
        opening(transport, next: 'cur_2');
        await catalog.load();
        transport.respond(page([productJson('z')]));

        await catalog.selectCategory('cat_1');

        final asked = uriOf(productRequests(transport).last).queryParameters;
        expect(asked['category_id'], 'cat_1');
        expect(asked.containsKey('next_cursor'), isFalse);
        expect(catalog.sellable.map((p) => p.id), ['z']);
        expect(catalog.categoryId, 'cat_1');
      },
    );

    test('does not read the categories or the stock again', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);
      await catalog.load();
      transport.respond(page([]));

      await catalog.selectCategory('cat_1');

      expect(transport.requests, hasLength(4));
    });

    test('is a no-op when it is already the one chosen', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);
      await catalog.load();
      transport.respond(page([]));
      await catalog.selectCategory('cat_1');

      await catalog.selectCategory('cat_1');

      expect(transport.requests, hasLength(4));
    });

    test('going back to all drops the filter', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);
      await catalog.load();
      transport.respond(page([]));
      await catalog.selectCategory('cat_1');
      transport.respond(page([productJson('a')]));

      await catalog.selectCategory(null);

      final asked = uriOf(productRequests(transport).last).queryParameters;
      expect(asked.containsKey('category_id'), isFalse);
    });

    test('logs category_selected, but not for a no-op re-selection', () async {
      final (:catalog, :transport, :analytics) = rig();
      opening(transport);
      await catalog.load();
      transport.respond(page([]));

      await catalog.selectCategory('cat_1');
      await catalog.selectCategory('cat_1');

      expect(analytics.logged.map((e) => e.$1), ['category_selected']);
      expect(analytics.logged.single.$2, {'category_id': 'cat_1'});
    });

    test('logs category_selected with "all" for the cleared filter', () async {
      final (:catalog, :transport, :analytics) = rig();
      opening(transport);
      await catalog.load();
      transport.respond(page([]));
      await catalog.selectCategory('cat_1');
      transport.respond(page([productJson('a')]));

      await catalog.selectCategory(null);

      expect(analytics.logged.last.$2, {'category_id': 'all'});
    });
  });

  group('searching', () {
    test('many keystrokes are one request, for the last text', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);
      await catalog.load();
      transport.respond(page([productJson('k')]));

      catalog.setSearch('k');
      catalog.setSearch('ki');
      catalog.setSearch('kit');
      await settle();

      expect(productRequests(transport), hasLength(2));
      expect(
        uriOf(productRequests(transport).last).queryParameters['q'],
        'kit',
      );
    });

    test('is remembered at once, while the request waits', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);
      await catalog.load();
      transport.respond(page([]));

      catalog.setSearch('kit');

      expect(catalog.search, 'kit');
      expect(productRequests(transport), hasLength(1));
      await settle();
    });

    test('starts from the first page, whatever was scrolled to', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport, next: 'cur_2');
      await catalog.load();
      transport.respond(page([]));

      catalog.setSearch('kit');
      await settle();

      final asked = uriOf(productRequests(transport).last).queryParameters;
      expect(asked.containsKey('next_cursor'), isFalse);
    });

    test('a space is not a new search', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);
      await catalog.load();
      transport.respond(page([]));
      catalog.setSearch('kit');
      await settle();

      catalog.setSearch('kit ');
      await settle();

      expect(productRequests(transport), hasLength(2));
    });

    test('clearing it goes back to everything', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);
      await catalog.load();
      transport.respond(page([]));
      catalog.setSearch('kit');
      await settle();
      transport.respond(page([productJson('a')]));

      catalog.setSearch('');
      await settle();

      final asked = uriOf(productRequests(transport).last).queryParameters;
      expect(asked.containsKey('q'), isFalse);
    });

    test(
      'a screen that is gone does not send the request that was waiting',
      () async {
        final transport = FakeApiTransport();
        final catalog = CatalogController(
          client: ApiClient(transport: transport, language: () => 'id'),
          outletId: 'out_1',
          debounce: const Duration(milliseconds: 20),
          analytics: FakeAnalytics(),
        );
        opening(transport);
        await catalog.load();

        catalog.setSearch('kit');
        catalog.dispose();
        await settle();

        expect(productRequests(transport), hasLength(1));
      },
    );
  });

  group('finding a code', () {
    test('asks the server for it, and rings up the exact match', () async {
      final (:catalog, :transport, analytics: _) = rig();
      transport.respond(page([productJson('a', sku: 'ABC-1')]));

      final found = await catalog.findByCode('ABC-1');

      expect(found?.id, 'a');
      final asked = uriOf(transport.requests.single).queryParameters;
      expect(asked['q'], 'ABC-1');
      expect(asked['sellable'], 'true');
      expect(asked['page_size'], '5');
    });

    test(
      'matches a barcode, whatever its case or the whitespace round it',
      () async {
        final (:catalog, :transport, analytics: _) = rig();
        transport.respond(page([productJson('a', barcode: 'abc123')]));

        final found = await catalog.findByCode('  ABC123\n');

        expect(found?.id, 'a');
      },
    );

    test(
      'a near miss is not a match, or the till sells the wrong thing',
      () async {
        final (:catalog, :transport, analytics: _) = rig();
        // The server searches with LIKE, so it answers a partial code with a product.
        transport.respond(page([productJson('a', sku: 'ABC-12')]));

        final found = await catalog.findByCode('ABC-1');

        expect(found, isNull);
      },
    );

    test('a blank code asks nothing', () async {
      final (:catalog, :transport, analytics: _) = rig();

      final found = await catalog.findByCode('   ');

      expect(found, isNull);
      expect(transport.requests, isEmpty);
    });

    test('a deactivated product does not ring up', () async {
      final (:catalog, :transport, analytics: _) = rig();
      transport.respond(page([productJson('a', sku: 'ABC-1', active: false)]));

      final found = await catalog.findByCode('ABC-1');

      expect(found, isNull);
    });

    test('a failure is the screen\'s to report, not an empty answer', () async {
      final (:catalog, :transport, analytics: _) = rig();
      transport.respond(
        TransportResponse(
          status: 500,
          headers: _json,
          body: '{"error":{"message":"boom"}}',
        ),
      );

      await expectLater(catalog.findByCode('ABC-1'), throwsA(isA<ApiError>()));
    });

    test('does not disturb the grid on screen', () async {
      final (:catalog, :transport, analytics: _) = rig();
      opening(transport);
      await catalog.load();
      transport.respond(page([]));

      await catalog.findByCode('ABC-1');

      expect(catalog.sellable.map((p) => p.id), ['a']);
      expect(productRequests(transport), hasLength(2));
    });
  });
}
