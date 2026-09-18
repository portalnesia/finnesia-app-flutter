/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoint.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:test/test.dart';

// These are the endpoint *classes*. The registry of real endpoints has its own test
// (`registry_test.dart`), so every value here is a local one.

TransportResponse answer(String body) => TransportResponse(
  status: 200,
  headers: {'content-type': 'application/json'},
  body: body,
);

({ApiClient client, FakeApiTransport transport}) makeClient(String body) {
  final transport = FakeApiTransport()..respond(answer(body));
  return (
    client: ApiClient(transport: transport, language: () => 'id'),
    transport: transport,
  );
}

int parseCount(Object? data) => (data as Map<String, dynamic>)['count'] as int;

List<String> parseNames(Object? data) => [
  for (final e in data as List<Object?>) e as String,
];

void main() {
  group('PagedEndpoint', () {
    const names = PagedEndpoint<String>('/api/v1/things', parseNames);

    test('is a GET', () {
      expect(names.method, HttpMethod.get);
    });

    test('returns the rows and the next cursor of the first page', () async {
      final t = makeClient('{"data":["a","b"],"meta":{"next_cursor":"cur_2"}}');

      final page = await names(t.client);

      expect(page.items, ['a', 'b']);
      expect(page.nextCursor, 'cur_2');
      expect(t.transport.requests.single.path, '/api/v1/things');
    });

    test('asks for the page after the cursor it is given', () async {
      final t = makeClient('{"data":["c"],"meta":{"next_cursor":null}}');

      await names(t.client, cursor: 'cur_2', query: {'page_size': 50});

      expect(
        t.transport.requests.single.path,
        '/api/v1/things?page_size=50&next_cursor=cur_2',
      );
    });
  });

  group('ReadEndpoint', () {
    const count = ReadEndpoint<int>('/api/v1/things', parseCount);

    test('is a GET', () {
      expect(count.method, HttpMethod.get);
    });

    test(
      'sends a GET to its path and returns what parse makes of the data',
      () async {
        final t = makeClient('{"data":{"count":7}}');

        final n = await count(t.client);

        expect(n, 7);
        expect(t.transport.requests.single.method, HttpMethod.get);
        expect(t.transport.requests.single.path, '/api/v1/things');
        expect(t.transport.requests.single.body, isNull);
      },
    );

    test('passes the query through', () async {
      final t = makeClient('{"data":{"count":1}}');

      await count(t.client, query: {'page_size': 50, 'q': 'kopi'});

      expect(
        t.transport.requests.single.path,
        '/api/v1/things?page_size=50&q=kopi',
      );
    });

    test('surfaces a payload that does not fit as an ApiError', () async {
      final t = makeClient('{"data":{"count":"seven"}}');

      await expectLater(count(t.client), throwsA(isA<ApiError>()));
    });
  });

  group('ReadEndpointP', () {
    final one = ReadEndpointP<ById, int>(
      (p) => '/api/v1/things/${p.id}',
      parseCount,
    );

    test('is a GET', () {
      expect(one.method, HttpMethod.get);
    });

    // The point of the record: a path parameter that is not given is a compile error, so
    // no request can go out to a literal `/things/:id`.
    test('builds its path from the record it is given', () async {
      final t = makeClient('{"data":{"count":3}}');

      final n = await one(t.client, (id: 'abc'));

      expect(n, 3);
      expect(t.transport.requests.single.method, HttpMethod.get);
      expect(t.transport.requests.single.path, '/api/v1/things/abc');
    });

    test('passes the query through after the built path', () async {
      final t = makeClient('{"data":{"count":1}}');

      await one(t.client, (id: 'abc'), query: {'shift_id': 's1'});

      expect(
        t.transport.requests.single.path,
        '/api/v1/things/abc?shift_id=s1',
      );
    });
  });

  group('WriteEndpoint', () {
    // A typed request value, so `encode` has something to turn into the wire shape.
    Object? encodeItem(({String name, int qty}) item) => {
      'name': item.name,
      'quantity': item.qty,
    };

    final create = WriteEndpoint<({String name, int qty}), int>(
      HttpMethod.post,
      '/api/v1/things',
      parseCount,
      encodeItem,
    );

    test(
      'sends its method and path with the encoded body, and returns what parse makes',
      () async {
        final t = makeClient('{"data":{"count":9}}');

        final n = await create(t.client, (name: 'kopi', qty: 2));

        expect(n, 9);
        final sent = t.transport.requests.single;
        expect(sent.method, HttpMethod.post);
        expect(sent.path, '/api/v1/things');
        expect(sent.body, '{"name":"kopi","quantity":2}');
        expect(sent.headers['Content-Type'], 'application/json');
      },
    );

    test('carries whichever method it was declared with', () async {
      for (final method in [
        HttpMethod.post,
        HttpMethod.put,
        HttpMethod.patch,
        HttpMethod.delete,
      ]) {
        final t = makeClient('{"data":{"count":1}}');
        final endpoint = WriteEndpoint<({String name, int qty}), int>(
          method,
          '/api/v1/things',
          parseCount,
          encodeItem,
        );

        await endpoint(t.client, (name: 'a', qty: 1));

        expect(t.transport.requests.single.method, method);
        expect(endpoint.method, method);
      }
    });

    test('passes the query through', () async {
      final t = makeClient('{"data":{"count":1}}');

      await create(t.client, (name: 'a', qty: 1), query: {'dry_run': true});

      expect(t.transport.requests.single.path, '/api/v1/things?dry_run=true');
    });

    test('surfaces a payload that does not fit as an ApiError', () async {
      final t = makeClient('{"data":{"count":null}}');

      await expectLater(
        create(t.client, (name: 'a', qty: 1)),
        throwsA(isA<ApiError>()),
      );
    });
  });

  group('WriteEndpointP', () {
    final close = WriteEndpointP<ById, Map<String, Object?>, int>(
      HttpMethod.post,
      (p) => '/api/v1/things/${p.id}/close',
      parseCount,
      (data) => data,
    );

    test('builds its path from the record and sends the body', () async {
      final t = makeClient('{"data":{"count":4}}');

      final n = await close(t.client, (id: 'abc'), {'counted': 1000});

      expect(n, 4);
      final sent = t.transport.requests.single;
      expect(sent.method, HttpMethod.post);
      expect(sent.path, '/api/v1/things/abc/close');
      expect(sent.body, '{"counted":1000}');
      expect(close.method, HttpMethod.post);
    });

    test('passes the query through after the built path', () async {
      final t = makeClient('{"data":{"count":4}}');

      await close(t.client, (id: 'abc'), {}, query: {'force': false});

      expect(
        t.transport.requests.single.path,
        '/api/v1/things/abc/close?force=false',
      );
    });
  });
}
