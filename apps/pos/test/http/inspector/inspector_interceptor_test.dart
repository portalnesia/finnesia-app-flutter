/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/http/inspector/inspector_interceptor.dart';
import 'package:pos/http/inspector/request_inspector.dart';

import '../../support/dio_fakes.dart';

const host = 'https://apps.finnesia.com';

/// A [Dio] wired the way the app wires it, with the inspector installed.
class Rig {
  Rig(
    Future<ResponseBody> Function(RequestOptions) handler, {
    DateTime Function()? now,
  }) : adapter = FakeAdapter(handler) {
    dio = Dio(BaseOptions(baseUrl: host))..httpClientAdapter = adapter;
    dio.interceptors.add(
      InspectorInterceptor(inspector, now: now ?? DateTime.now),
    );
  }

  final FakeAdapter adapter;
  final inspector = RequestInspector();
  late final Dio dio;
}

void main() {
  group('a request that succeeds', () {
    test('is recorded with its method, URL, status and body', () async {
      final rig = Rig(
        (_) async => json({
          'data': {'total': 1500},
        }),
      );

      await rig.dio.get<Object?>('/api/v1/pos/stock');

      final entry = rig.inspector.entries.single;
      expect(entry.method, 'GET');
      expect(entry.url, '$host/api/v1/pos/stock');
      expect(entry.statusCode, 200);
      expect(entry.responseBody, {
        'data': {'total': 1500},
      });
      expect(entry.error, isNull);
    });

    test(
      'has its headers and bodies redacted, on the way in and on the way out',
      () async {
        final rig = Rig(
          (_) async => json(
            {
              'data': {'status': 'ready', 'session_token': 'sess_tok_secret'},
            },
            headers: {
              'x-session-token': ['tok_rotated_secret'],
              'x-session-expires': ['2030-01-01T00:00:00Z'],
            },
          ),
        );

        await rig.dio.post<Object?>(
          '/api/auth/mobile/poll',
          data: '{"request_id":"req_secret","password":"hunter2"}',
          options: Options(
            headers: {
              'Authorization': 'Bearer tok_secret_value',
              'X-Company-ID': 'comp_1',
            },
          ),
        );

        final entry = rig.inspector.entries.single;
        expect(entry.requestHeaders['Authorization'], 'Bearer ***');
        expect(entry.requestBody, {'request_id': '***', 'password': '***'});
        expect(entry.responseHeaders?['x-session-token'], '***');
        expect(entry.responseBody, {
          'data': {'status': 'ready', 'session_token': '***'},
        });
      },
    );

    // README §14.5 no. 2, and the easy one to get wrong: a test that only looks at the
    // Authorization header passes while the token sits in the URL, a body or an error.
    test('leaves no credential anywhere in what it recorded', () async {
      final rig = Rig(
        (_) async => json(
          {
            'data': {'session_token': 'sess_tok_secret', 'ok': true},
          },
          headers: {
            'x-session-token': ['tok_rotated_secret'],
          },
        ),
      );

      await rig.dio.post<Object?>(
        '/api/auth/refresh',
        data: {'refresh_token': 'refresh_secret_value'},
        options: Options(headers: {'Authorization': 'Bearer tok_secret_value'}),
      );

      final everything = rig.inspector.entries.toString();
      for (final secret in [
        'tok_secret_value',
        'refresh_secret_value',
        'sess_tok_secret',
        'tok_rotated_secret',
      ]) {
        expect(everything, isNot(contains(secret)), reason: secret);
      }
    });

    // Not a credential, and the header that is wrong most often.
    test('still shows X-Company-ID', () async {
      final rig = Rig((_) async => json({}));

      await rig.dio.get<Object?>(
        '/api/v1/x',
        options: Options(headers: {'X-Company-ID': 'comp_1'}),
      );

      expect(
        rig.inspector.entries.single.requestHeaders['X-Company-ID'],
        'comp_1',
      );
    });

    // Redaction is for the copy on the screen. The request itself has to go out as it was.
    test('does not change what is sent', () async {
      final rig = Rig((_) async => json({}));

      await rig.dio.post<Object?>(
        '/api/auth/refresh',
        data: {'refresh_token': 'refresh_secret_value'},
        options: Options(headers: {'Authorization': 'Bearer tok_secret_value'}),
      );

      final sent = rig.adapter.sent.single;
      expect(sent.headers['Authorization'], 'Bearer tok_secret_value');
      expect(sent.data, {'refresh_token': 'refresh_secret_value'});
    });

    test('hands the caller the response as it came', () async {
      final rig = Rig((_) async => json({'ok': true}, status: 201));

      final response = await rig.dio.get<Object?>('/api/v1/x');

      expect(response.statusCode, 201);
      expect(response.data, {'ok': true});
    });

    test('joins a header that came with several values', () async {
      final rig = Rig(
        (_) async => json(
          {},
          headers: {
            'x-note': ['a', 'b'],
          },
        ),
      );

      await rig.dio.get<Object?>('/api/v1/x');

      expect(rig.inspector.entries.single.responseHeaders?['x-note'], 'a, b');
    });

    test('records when it started, and how long it took', () async {
      var clock = DateTime(2026, 9, 19, 10);
      final rig = Rig((_) async {
        clock = clock.add(const Duration(milliseconds: 240));
        return json({});
      }, now: () => clock);

      await rig.dio.get<Object?>('/api/v1/x');

      final entry = rig.inspector.entries.single;
      expect(entry.at, DateTime(2026, 9, 19, 10));
      expect(entry.duration, const Duration(milliseconds: 240));
    });

    test('shows only the type of a response that is bytes', () async {
      final rig = Rig((_) async => ResponseBody.fromBytes([1, 2, 3], 200));

      await rig.dio.get<Object?>(
        '/api/v1/x',
        options: Options(responseType: ResponseType.bytes),
      );

      expect(
        rig.inspector.entries.single.responseBody,
        isNot(anyOf([1, 2, 3])),
      );
      expect(rig.inspector.entries.single.responseBody, startsWith('<'));
    });

    test('keeps two requests in flight at once apart', () async {
      final slow = Completer<void>();
      final rig = Rig((options) async {
        if (options.path.endsWith('/slow')) await slow.future;
        return json({'path': options.path});
      });

      final first = rig.dio.get<Object?>('/api/v1/slow');
      final second = rig.dio.get<Object?>('/api/v1/fast');
      await second;
      slow.complete();
      await first;

      final byUrl = {for (final e in rig.inspector.entries) e.url: e};
      expect(byUrl['$host/api/v1/fast']?.responseBody, {
        'path': '/api/v1/fast',
      });
      expect(byUrl['$host/api/v1/slow']?.responseBody, {
        'path': '/api/v1/slow',
      });
    });
  });

  // README §14.2: `onError` is not optional. The failing path is the one that most needs
  // looking at on a tablet, and an interceptor that only handles success looks fine until a
  // real problem.
  group('a request that fails', () {
    test(
      'is recorded with its status, its body, and what went wrong',
      () async {
        final rig = Rig((_) async => json({'error': 'nope'}, status: 500));

        await expectLater(
          rig.dio.get<Object?>('/api/v1/pos/stock'),
          throwsA(isA<DioException>()),
        );

        final entry = rig.inspector.entries.single;
        expect(entry.statusCode, 500);
        expect(entry.responseBody, {'error': 'nope'});
        expect(entry.error, 'badResponse');
      },
    );

    test('is recorded when nothing came back at all', () async {
      final rig = Rig((options) async {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'no route to host',
        );
      });

      await expectLater(
        rig.dio.get<Object?>('/api/v1/pos/stock'),
        throwsA(isA<DioException>()),
      );

      final entry = rig.inspector.entries.single;
      expect(entry.statusCode, isNull);
      expect(entry.responseBody, isNull);
      expect(entry.error, 'connectionError');
    });

    // The exception's own text carries the request and, for some failures, the URL. What is
    // stored is a short code.
    test('stores a code for the failure, not the exception text', () async {
      final rig = Rig((options) async {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'lookup of apps.finnesia.com failed',
        );
      });

      await expectLater(
        rig.dio.get<Object?>('/api/v1/customers?search=budi'),
        throwsA(isA<DioException>()),
      );

      final entry = rig.inspector.entries.single;
      expect(entry.error, isNot(contains('lookup')));
      expect(entry.error, isNot(contains('budi')));
    });

    test('has its response redacted too', () async {
      final rig = Rig(
        (_) async => json(
          {'session_token': 'sess_tok_secret'},
          status: 401,
          headers: {
            'x-session-token': ['tok_rotated_secret'],
          },
        ),
      );

      await expectLater(
        rig.dio.get<Object?>('/api/v1/x'),
        throwsA(isA<DioException>()),
      );

      expect(
        rig.inspector.entries.toString(),
        allOf(
          isNot(contains('sess_tok_secret')),
          isNot(contains('tok_rotated_secret')),
        ),
      );
    });

    test('still throws what the caller would have got without it', () async {
      final rig = Rig((_) async => json({}, status: 422));

      await expectLater(
        rig.dio.get<Object?>('/api/v1/x'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            422,
          ),
        ),
      );
    });
  });
  // A debugging aid must not be able to fail a sale. Whatever goes wrong while it watches a
  // request, the request goes on and the caller gets exactly what it would have got without it.
  group('an inspector that goes wrong', () {
    test('does not fail a request that succeeded', () async {
      final rig = Rig((_) async => json({'ok': true}));
      final broken = InspectorInterceptor(_BrokenInspector());
      rig.dio.interceptors
        ..clear()
        ..add(broken);

      final response = await rig.dio.get<Object?>('/api/v1/x');

      expect(response.data, {'ok': true});
    });

    test(
      'does not swap the error of a request that failed for its own',
      () async {
        final rig = Rig((_) async => json({}, status: 500));
        rig.dio.interceptors
          ..clear()
          ..add(InspectorInterceptor(_BrokenInspector()));

        await expectLater(
          rig.dio.get<Object?>('/api/v1/x'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              500,
            ),
          ),
        );
      },
    );

    test('does not fail a request it could not read a header of', () async {
      final rig = Rig((_) async => json({'ok': true}));

      final response = await rig.dio.get<Object?>(
        '/api/v1/x',
        options: Options(headers: {'X-Odd': _Unprintable()}),
      );

      expect(response.data, {'ok': true});
    });

    // Another interceptor can answer before the request is sent (a cache, a stub). Ours then
    // sees a response for a request it never saw go out.
    test('records a response to a request it did not see go out', () async {
      final rig = Rig((_) async => json({}));
      rig.dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: {'from': 'cache'},
            ),
            true, // let the interceptors after this one see the response
          ),
        ),
      );

      final response = await rig.dio.get<Object?>('/api/v1/x');

      expect(response.data, {'from': 'cache'});
      expect(rig.inspector.entries, hasLength(1));
    });

    // security.md §1, and README §14.4: a log line is readable by other tools on the device.
    test('prints nothing', () async {
      final printed = <String>[];
      final rig = Rig((_) async => json({'session_token': 'sess_tok_secret'}));

      await runZoned(
        () async {
          await rig.dio.post<Object?>(
            '/api/auth/refresh',
            data: {'refresh_token': 'refresh_secret_value'},
            options: Options(
              headers: {'Authorization': 'Bearer tok_secret_value'},
            ),
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => printed.add(line),
        ),
      );

      expect(printed, isEmpty);
    });
  });

  group('installInspector', () {
    test('installs the interceptor, and records, when it is enabled', () async {
      final adapter = FakeAdapter((_) async => json({}));
      final dio = Dio(BaseOptions(baseUrl: host))..httpClientAdapter = adapter;
      final inspector = RequestInspector();

      final installed = installInspector(dio, inspector, enabled: true);
      await dio.get<Object?>('/api/v1/x');

      expect(installed, isTrue);
      expect(inspector.entries, hasLength(1));
    });

    // A parameter and not a constant, so the release case can be tested: under `flutter test`
    // `isDebugApp` is always true (README §13.6).
    test(
      'installs nothing, and records nothing, when it is not enabled',
      () async {
        final adapter = FakeAdapter((_) async => json({}));
        final dio = Dio(BaseOptions(baseUrl: host))
          ..httpClientAdapter = adapter;
        final before = dio.interceptors.length;
        final inspector = RequestInspector();

        final installed = installInspector(dio, inspector, enabled: false);
        await dio.get<Object?>('/api/v1/x');

        expect(installed, isFalse);
        expect(dio.interceptors, hasLength(before));
        expect(inspector.entries, isEmpty);
      },
    );

    test('is enabled by default in a debug app', () {
      final dio = Dio();

      // The tests run as JIT, where `isDebugApp` is true. The release branch cannot be reached
      // from here; it is proved on the APK instead (README §13.7 and §15).
      expect(installInspector(dio, RequestInspector()), isTrue);
    });
  });
}

class _BrokenInspector extends RequestInspector {
  @override
  void record(InspectedRequest entry) =>
      throw StateError('the inspector broke');
}

/// A header value whose text cannot be read.
class _Unprintable {
  @override
  String toString() => throw StateError('cannot be printed');
}
