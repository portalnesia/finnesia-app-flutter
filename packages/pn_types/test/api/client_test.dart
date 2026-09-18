/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/page.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:test/test.dart';

TransportResponse json(String body, {int status = 200}) => TransportResponse(
  status: status,
  headers: {'Content-Type': 'application/json; charset=utf-8'},
  body: body,
);

// Builds a client over a fake that answers every request with `{"data":null}`, so a test
// about the *request* is not distracted by the response.
({ApiClient client, FakeApiTransport transport}) makeClient({
  String Function()? language,
  int answers = 1,
}) {
  final transport = FakeApiTransport();
  for (var i = 0; i < answers; i++) {
    transport.respond(json('{"data":null}'));
  }
  return (
    client: ApiClient(transport: transport, language: language ?? () => 'id'),
    transport: transport,
  );
}

Future<void> get(
  ApiClient client,
  String path, {
  Map<String, Object?>? query,
}) => client.request<Object?>(
  method: HttpMethod.get,
  path: path,
  query: query,
  parse: (data) => data,
);

// The rows and the cursor of the next page, from one response. `request` drops `meta`, which
// is right for a single record and wrong for a list the cashier scrolls.
Future<CursorPage<String>> readPage(String body, {int status = 200}) {
  final transport = FakeApiTransport()..respond(json(body, status: status));
  final client = ApiClient(transport: transport, language: () => 'id');
  return client.requestPaged<String>(
    method: HttpMethod.get,
    path: '/x',
    parse: (data) => [for (final e in data as List<Object?>) e as String],
  );
}

void main() {
  group('reading a page', () {
    test('returns the rows and the cursor of the next page', () async {
      final page = await readPage(
        '{"data":["a","b"],"meta":{"next_cursor":"cur_2","page_size":2}}',
      );

      expect(page.items, ['a', 'b']);
      expect(page.nextCursor, 'cur_2');
    });

    test(
      'has no next cursor on the last page: null, empty, or no meta at all',
      () async {
        for (final body in [
          '{"data":["a"],"meta":{"next_cursor":null}}',
          '{"data":["a"],"meta":{"next_cursor":""}}',
          '{"data":["a"],"meta":{}}',
          '{"data":["a"]}',
        ]) {
          expect((await readPage(body)).nextCursor, isNull, reason: body);
        }
      },
    );

    test('fails like a plain request when the server refuses', () async {
      await expectLater(
        readPage('{"message":"Forbidden"}', status: 403),
        throwsA(
          isA<ApiError>()
              .having((e) => e.status, 'status', 403)
              .having((e) => e.message, 'message', 'Forbidden'),
        ),
      );
    });

    test('is an ApiError, not a crash, when meta is not an object', () async {
      await expectLater(
        readPage('{"data":["a"],"meta":"oops"}'),
        throwsA(isA<ApiError>().having((e) => e.status, 'status', 200)),
      );
    });

    test('lets a network failure through unchanged', () async {
      final transport = FakeApiTransport()..fail(TransportException('down'));
      final client = ApiClient(transport: transport, language: () => 'id');

      await expectLater(
        client.requestPaged<String>(
          method: HttpMethod.get,
          path: '/x',
          parse: (_) => const [],
        ),
        throwsA(isA<TransportException>()),
      );
    });

    test('sends the query it is given', () async {
      final transport = FakeApiTransport()
        ..respond(json('{"data":[],"meta":{"next_cursor":null}}'));
      final client = ApiClient(transport: transport, language: () => 'id');

      await client.requestPaged<String>(
        method: HttpMethod.get,
        path: '/x',
        query: {'page_size': 50, 'next_cursor': 'cur_2'},
        parse: (_) => const [],
      );

      expect(
        transport.requests.single.path,
        '/x?page_size=50&next_cursor=cur_2',
      );
    });
  });

  group('building the request', () {
    test(
      'sends the method and path, with Accept and Accept-Language',
      () async {
        final t = makeClient();

        await get(t.client, '/api/v1/pos/stock');

        expect(
          t.transport.requests.single,
          const TransportRequest(
            method: HttpMethod.get,
            path: '/api/v1/pos/stock',
            headers: {'Accept': 'application/json', 'Accept-Language': 'id'},
          ),
        );
      },
    );

    // The client never holds a credential or a host: the transport adds both. A header
    // here would be one the transport cannot override.
    test('sets no Authorization and no tenant header of its own', () async {
      final t = makeClient();

      await get(t.client, '/x');

      final names = t.transport.requests.single.headers.keys.map(
        (k) => k.toLowerCase(),
      );
      expect(names, unorderedEquals(['accept', 'accept-language']));
    });

    test(
      'reads the language on every request, not once at construction',
      () async {
        var lang = 'id';
        final t = makeClient(language: () => lang, answers: 2);

        await get(t.client, '/x');
        lang = 'en';
        await get(t.client, '/x');

        expect(t.transport.requests.map((r) => r.headers['Accept-Language']), [
          'id',
          'en',
        ]);
      },
    );

    test('appends the query string to the path', () async {
      final t = makeClient();

      await get(
        t.client,
        '/api/v1/products',
        query: {'q': 'kopi susu', 'page': 0},
      );

      expect(
        t.transport.requests.single.path,
        '/api/v1/products?q=kopi+susu&page=0',
      );
    });

    test('joins with & when the path already has a query', () async {
      final t = makeClient();

      await get(t.client, '/x?a=1', query: {'b': 2});

      expect(t.transport.requests.single.path, '/x?a=1&b=2');
    });

    test(
      'leaves the path alone when the query is null, empty or all-blank',
      () async {
        final t = makeClient(answers: 3);

        await get(t.client, '/x');
        await get(t.client, '/x', query: {});
        await get(t.client, '/x', query: {'q': '', 'c': null});

        expect(t.transport.requests.map((r) => r.path), ['/x', '/x', '/x']);
      },
    );
  });

  group('building the body', () {
    Future<void> post(ApiClient client, Object? body) =>
        client.request<Object?>(
          method: HttpMethod.post,
          path: '/x',
          body: body,
          parse: (data) => data,
        );

    test('encodes a body as JSON and says so in Content-Type', () async {
      final t = makeClient();

      await post(t.client, {
        'total': 1000,
        'items': [
          {'id': 'p1'},
        ],
      });

      final sent = t.transport.requests.single;
      expect(sent.body, '{"total":1000,"items":[{"id":"p1"}]}');
      expect(sent.headers['Content-Type'], 'application/json');
    });

    test(
      'sends neither a body nor Content-Type when the body is null',
      () async {
        final t = makeClient();

        await post(t.client, null);

        final sent = t.transport.requests.single;
        expect(sent.body, isNull);
        expect(
          sent.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('content-type')),
        );
      },
    );

    // The source's test is `!== undefined && !== null`, so an empty object is a body.
    test('sends an empty object as a body', () async {
      final t = makeClient();

      await post(t.client, <String, Object?>{});

      expect(t.transport.requests.single.body, '{}');
    });
  });

  group('reading a success', () {
    // Answers one request with [response] and returns what `parse` is handed.
    Future<Object?> handedToParse(TransportResponse response) async {
      final transport = FakeApiTransport()..respond(response);
      final client = ApiClient(transport: transport, language: () => 'id');
      return client.request<Object?>(
        method: HttpMethod.get,
        path: '/x',
        parse: (data) => data,
      );
    }

    test(
      'unwraps the data of the envelope and returns what parse makes of it',
      () async {
        final transport = FakeApiTransport()
          ..respond(json('{"data":{"a":41}}'));
        final client = ApiClient(transport: transport, language: () => 'id');

        final n = await client.request<int>(
          method: HttpMethod.get,
          path: '/x',
          parse: (data) => (data as Map<String, dynamic>)['a'] as int,
        );

        expect(n, 41);
      },
    );

    test('passes a null data on to parse', () async {
      expect(await handedToParse(json('{"data":null}')), isNull);
    });

    // The source asks `'data' in json`, not "is it truthy" — a legitimate 0, false, ''
    // or empty list must not be mistaken for a missing envelope.
    test('passes a falsy data on to parse untouched', () async {
      expect(await handedToParse(json('{"data":0}')), 0);
      expect(await handedToParse(json('{"data":false}')), false);
      expect(await handedToParse(json('{"data":""}')), '');
      expect(await handedToParse(json('{"data":[]}')), isEmpty);
    });

    test('hands the whole body to parse when there is no data key', () async {
      expect(await handedToParse(json('{"id":"x","total":3}')), {
        'id': 'x',
        'total': 3,
      });
    });

    test('hands a top-level array to parse as it is', () async {
      expect(await handedToParse(json('[1,2,3]')), [1, 2, 3]);
    });

    test('accepts every 2xx, including one with no body', () async {
      expect(
        await handedToParse(TransportResponse(status: 201, body: '')),
        isNull,
      );
      expect(await handedToParse(TransportResponse(status: 204)), isNull);
    });

    // Content-Type decides whether the body is read at all. A proxy's HTML page must not
    // be parsed as though it were the API's answer.
    test('ignores a body that is not declared as JSON', () async {
      final html = TransportResponse(
        status: 200,
        headers: {'content-type': 'text/html'},
        body: '{"data":1}',
      );

      expect(await handedToParse(html), isNull);
    });

    test(
      'treats a body that is declared JSON but is not, as no body',
      () async {
        expect(await handedToParse(json('<html>oops</html>')), isNull);
      },
    );
  });

  group('reading a failure', () {
    // Sends one request that is answered with [response] and returns the ApiError.
    Future<ApiError> failureOf(TransportResponse response) async {
      final transport = FakeApiTransport()..respond(response);
      final client = ApiClient(transport: transport, language: () => 'id');
      try {
        await client.request<Object?>(
          method: HttpMethod.get,
          path: '/x',
          parse: (data) => data,
        );
      } on ApiError catch (e) {
        return e;
      }
      throw StateError('expected an ApiError, the request succeeded');
    }

    TransportResponse failing(
      String body, {
      int status = 400,
      String statusText = '',
      Map<String, String> headers = const {'content-type': 'application/json'},
    }) => TransportResponse(
      status: status,
      statusText: statusText,
      headers: headers,
      body: body,
    );

    test('throws an ApiError carrying the status of any non-2xx', () async {
      for (final status in [301, 400, 401, 404, 409, 422, 500, 503]) {
        expect((await failureOf(failing('{}', status: status))).status, status);
      }
    });

    test('never hands a failed response to parse', () async {
      var parsed = false;
      final transport = FakeApiTransport()..respond(failing('{"data":1}'));
      final client = ApiClient(transport: transport, language: () => 'id');

      await expectLater(
        client.request<Object?>(
          method: HttpMethod.get,
          path: '/x',
          parse: (data) {
            parsed = true;
            return data;
          },
        ),
        throwsA(isA<ApiError>()),
      );

      expect(parsed, isFalse);
    });

    group('message', () {
      // The source's `||` chain: body message, then error.description, then error.message,
      // then the HTTP status text, then a fixed fallback. Empty strings fall through.
      const all =
          '{"message":"from body","error":{"description":"from description","message":"from error"}}';

      test('prefers the body message', () async {
        final e = await failureOf(failing(all, statusText: 'Bad Request'));
        expect(e.message, 'from body');
      });

      test('then error.description', () async {
        const body =
            '{"error":{"description":"from description","message":"from error"}}';
        final e = await failureOf(failing(body, statusText: 'Bad Request'));
        expect(e.message, 'from description');
      });

      test('then error.message', () async {
        const body = '{"error":{"message":"from error"}}';
        final e = await failureOf(failing(body, statusText: 'Bad Request'));
        expect(e.message, 'from error');
      });

      test('then the HTTP status text', () async {
        final e = await failureOf(failing('{}', statusText: 'Bad Request'));
        expect(e.message, 'Bad Request');
      });

      test('then a fixed fallback', () async {
        expect((await failureOf(failing('{}'))).message, 'Request failed');
      });

      test('skips empty strings, as the source does with ||', () async {
        const body =
            '{"message":"","error":{"description":"","message":"from error"}}';
        expect((await failureOf(failing(body))).message, 'from error');
      });

      test('ignores a message that is not a string', () async {
        const body =
            '{"message":{"x":1},"error":{"description":7,"message":"from error"}}';
        expect((await failureOf(failing(body))).message, 'from error');
      });
    });

    test('keeps the whole body as data and parses the error object', () async {
      const body =
          '{"message":"m","error":{"name":"ValidationError","code":422}}';
      final e = await failureOf(failing(body, status: 422));

      expect(e.data, {
        'message': 'm',
        'error': {'name': 'ValidationError', 'code': 422},
      });
      expect(e.errorData?.name, 'ValidationError');
      expect(e.errorData?.code, 422);
    });

    // The carry-over from `ApiErrorTypes.fromJson`, which throws on a wrong shape where
    // the source only casts. Losing the real status and message to a TypeError while
    // shaping the error would hide exactly what the cashier needs to see.
    test('survives an error object of the wrong shape', () async {
      const body = '{"error":{"message":"from error","details":"not a list"}}';
      final e = await failureOf(failing(body, status: 422));

      expect(e.status, 422);
      expect(e.message, 'from error');
      expect(e.errorData, isNull);
    });

    test('ignores an error that is not an object', () async {
      final e = await failureOf(
        failing('{"error":"boom"}', statusText: 'Bad Request'),
      );

      expect(e.message, 'Bad Request');
      expect(e.errorData, isNull);
    });

    test(
      'reads a non-JSON failure (a proxy page) by its status text',
      () async {
        final e = await failureOf(
          failing(
            '<html>Bad Gateway</html>',
            status: 502,
            statusText: 'Bad Gateway',
            headers: {'content-type': 'text/html'},
          ),
        );

        expect(e.status, 502);
        expect(e.message, 'Bad Gateway');
        expect(e.data, isNull);
        expect(e.errorData, isNull);
      },
    );

    test('reads Retry-After on a 429 only', () async {
      const withRetry = {
        'content-type': 'application/json',
        'Retry-After': '30',
      };
      final limited = await failureOf(
        failing('{}', status: 429, headers: withRetry),
      );
      final unavailable = await failureOf(
        failing('{}', status: 503, headers: withRetry),
      );
      final bare = await failureOf(failing('{}', status: 429));

      expect(limited.retryAfter, 30);
      expect(ApiError.isRateLimit(limited), isTrue);
      expect(unavailable.retryAfter, isNull);
      expect(bare.retryAfter, isNull);
    });
  });

  group('when there is no answer', () {
    // "No response" and "the server said no" are different facts to the offline queue.
    // Wrapping the first in an ApiError would make a dropped connection look like a
    // rejection, and the sale would not be retried.
    test('lets a TransportException through unchanged', () async {
      final failure = TransportException('offline');
      final transport = FakeApiTransport()..fail(failure);
      final client = ApiClient(transport: transport, language: () => 'id');

      await expectLater(
        client.request<Object?>(
          method: HttpMethod.get,
          path: '/x',
          parse: (data) => data,
        ),
        throwsA(same(failure)),
      );
    });
  });

  group('when parse rejects a success', () {
    Future<Object?> parsing(String body, Object? Function(Object?) parse) {
      final transport = FakeApiTransport()..respond(json(body));
      final client = ApiClient(transport: transport, language: () => 'id');
      return client.request<Object?>(
        method: HttpMethod.get,
        path: '/x',
        parse: parse,
      );
    }

    // A 200 whose payload no longer fits the model is a server the app is out of step
    // with. It must reach the caller as an ApiError it can show, not as a TypeError that
    // becomes a red screen (`security.md` §2).
    test(
      'turns a TypeError into an ApiError that keeps the status and body',
      () async {
        final result = parsing(
          '{"data":[1]}',
          (data) => (data as Map<String, dynamic>)['a'],
        );

        await expectLater(
          result,
          throwsA(
            isA<ApiError>()
                .having((e) => e.status, 'status', 200)
                .having((e) => e.data, 'data', {
                  'data': [1],
                })
                .having(
                  (e) => e.message,
                  'message',
                  'Unexpected response from server',
                ),
          ),
        );
      },
    );

    test('does the same for a FormatException and an ArgumentError', () async {
      await expectLater(
        parsing('{"data":1}', (_) => throw const FormatException('bad')),
        throwsA(isA<ApiError>()),
      );
      await expectLater(
        parsing(
          '{"data":1}',
          (_) => throw ArgumentError('not one of the values'),
        ),
        throwsA(isA<ApiError>()),
      );
    });

    // Only the three ways bad *data* fails are translated. A StateError is a bug in the
    // parser, and hiding it behind an ApiError would send the developer looking at the
    // server instead.
    test('does not hide a bug in the parser', () async {
      await expectLater(
        parsing('{"data":1}', (_) => throw StateError('parser bug')),
        throwsA(isA<StateError>()),
      );
    });
  });
}
