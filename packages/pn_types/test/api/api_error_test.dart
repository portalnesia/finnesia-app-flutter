/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/api/api_error.dart';
import 'package:test/test.dart';

// `parseRetryAfter` is not exported by the source (`api.base.ts`), so it has no oracle;
// these tests are new, and the expected values were checked against the TypeScript
// function itself — see `plan/api-client/findings.md`.

ApiErrorTypes parseError(String json) =>
    ApiErrorTypes.fromJson(jsonDecode(json) as Map<String, dynamic>);

void main() {
  group('ApiErrorTypes.fromJson', () {
    test('reads every field of a validation error', () {
      final e = parseError('''
        {"name":"ValidationError","code":422,"message":"Invalid","description":"Amount is required",
         "details":[{"field":"amount","message":"required"}]}''');

      expect(e.name, 'ValidationError');
      expect(e.code, 422);
      expect(e.message, 'Invalid');
      expect(e.description, 'Amount is required');
      expect(e.details, hasLength(1));
      expect(e.details?.single.field, 'amount');
      expect(e.details?.single.message, 'required');
    });

    // A `document_settled` rejection points at a blocking record, not a form field, so the
    // detail carries an `id` and no `field`.
    test('reads a detail that names a document instead of a field', () {
      final e = parseError(
        '{"details":[{"id":"doc-7","message":"Already settled by PAY-1"}]}',
      );

      expect(e.details?.single.id, 'doc-7');
      expect(e.details?.single.field, isNull);
    });

    test('leaves every field null for an empty error object', () {
      final e = parseError('{}');

      expect(e.name, isNull);
      expect(e.code, isNull);
      expect(e.message, isNull);
      expect(e.description, isNull);
      expect(e.details, isNull);
    });

    test('keeps an empty details list distinct from an absent one', () {
      expect(parseError('{"details":[]}').details, isEmpty);
      expect(parseError('{}').details, isNull);
    });

    // The i18n key the server used to build `description`. It is the only machine-readable part
    // of an error: `code` is shared between unrelated failures (422/720 covers the device limit
    // and six Postgres conditions alike), so a client cannot branch on it.
    test('reads the i18n key', () {
      final e = parseError('{"key":"pos_device_unregistered"}');

      expect(e.key, 'pos_device_unregistered');
    });

    test('reads the params that go with the key', () {
      final e = parseError(
        '{"key":"pos_device_limit_reached","params":{"limit":10}}',
      );

      expect(e.params, {'limit': 10});
    });

    // A backend that predates the key sends none, and every error before that change looks
    // like this. It is absence, not an empty key.
    test('leaves the key and params null when the response carries none', () {
      final e = parseError('{"name":"authorization","code":137}');

      expect(e.key, isNull);
      expect(e.params, isNull);
    });

    test('rejects a detail without a message', () {
      expect(
        () => parseError('{"details":[{"field":"amount"}]}'),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('ApiError', () {
    test('defaults to status 500 with nothing attached', () {
      final e = ApiError('boom');

      expect(e.message, 'boom');
      expect(e.status, 500);
      expect(e.data, isNull);
      expect(e.errorData, isNull);
      expect(e.retryAfter, isNull);
    });

    test(
      'carries the status, body, parsed error and retry delay it is given',
      () {
        const detail = ApiErrorTypes(name: 'RateLimit', code: 429);
        final e = ApiError(
          'slow down',
          status: 429,
          data: {'a': 1},
          errorData: detail,
          retryAfter: 30,
        );

        expect(e.status, 429);
        expect(e.data, {'a': 1});
        expect(e.errorData, detail);
        expect(e.retryAfter, 30);
      },
    );

    test('is an Exception, so a caller can catch it as one', () {
      expect(ApiError('x'), isA<Exception>());
    });

    test('isRateLimit is true only for an ApiError with status 429', () {
      expect(ApiError.isRateLimit(ApiError('x', status: 429)), isTrue);
      expect(ApiError.isRateLimit(ApiError('x', status: 500)), isFalse);
      expect(ApiError.isRateLimit(ApiError('x')), isFalse);
    });

    test('isRateLimit is false for anything that is not an ApiError', () {
      expect(ApiError.isRateLimit(Exception('429')), isFalse);
      expect(ApiError.isRateLimit('429'), isFalse);
      expect(ApiError.isRateLimit(429), isFalse);
      expect(ApiError.isRateLimit(null), isFalse);
    });

    test('prints the status and message', () {
      expect(ApiError('slow down', status: 429).toString(), contains('429'));
      expect(
        ApiError('slow down', status: 429).toString(),
        contains('slow down'),
      );
    });

    // The response body can carry customer names and amounts. An exception that reaches a
    // crash report or a log line must not drag it along (`security.md` §1).
    test('does not print the response body', () {
      final e = ApiError('x', status: 400, data: {'customer': 'Budi Santoso'});

      expect(e.toString(), isNot(contains('Budi')));
    });
  });

  // The `error` object of a raw response body. `ApiClient` builds an `ApiError` for the
  // authenticated path; the public calls (pairing, device reset) read the body themselves, so
  // they need the same parsing without an `ApiError` around it.
  group('errorObjectOf', () {
    test('reads the error object of an API envelope', () {
      final error = errorObjectOf(
        '{"data":null,"error":{"name":"authorization","code":137,"key":"k"}}',
      );

      expect(error?.name, 'authorization');
      expect(error?.code, 137);
      expect(error?.key, 'k');
    });

    test('reads the params of a keyed error', () {
      final error = errorObjectOf(
        '{"error":{"key":"pos_device_limit_reached","params":{"limit":10}}}',
      );

      expect(deviceLimitFrom(error), 10);
    });

    // Every one of these is a body the API did not promise, and the code that reads it is the
    // code that handles failures. It must read as "no error object", never throw.
    final unusable = <String, String?>{
      'no body': null,
      'not JSON': 'upstream connect error',
      'a JSON array': '[1,2]',
      'a JSON string': '"boom"',
      'no error key': '{"data":null}',
      'error is not an object': '{"error":"boom"}',
      'error is null': '{"error":null}',
      'error fields of the wrong type': '{"error":{"code":"137"}}',
    };

    for (final MapEntry(key: what, value: body) in unusable.entries) {
      test('is null for $what', () {
        expect(errorObjectOf(body), isNull);
      });
    }
  });

  group('deviceLimitFrom', () {
    // JSON numbers arrive as `int` or `double` depending on whether they have a fraction, so a
    // server that sends `10.0` must not break the message.
    test('reads a whole-number limit', () {
      expect(deviceLimitFrom(const ApiErrorTypes(params: {'limit': 10})), 10);
    });

    test('reads a limit that arrived as a double', () {
      expect(deviceLimitFrom(const ApiErrorTypes(params: {'limit': 10.0})), 10);
    });

    // Absent means the caller uses its own wording rather than printing a placeholder.
    test('is null when there are no params', () {
      expect(deviceLimitFrom(const ApiErrorTypes()), isNull);
      expect(deviceLimitFrom(null), isNull);
    });

    test('is null when the limit is not a number', () {
      expect(
        deviceLimitFrom(const ApiErrorTypes(params: {'limit': 'ten'})),
        isNull,
      );
    });
  });

  // The tablet is cut off from the server when an admin deletes it from the dashboard, and the
  // only signal is this error. Getting it wrong in either direction is expensive: missing it
  // leaves a deleted tablet transacting, and over-triggering sends a working tablet back to the
  // pairing screen mid-shift.
  group('isDeviceUnregistered', () {
    ApiError withError(ApiErrorTypes? errorData, {int status = 401}) =>
        ApiError('x', status: status, errorData: errorData);

    test('is true when the server names the key', () {
      expect(
        ApiError.isDeviceUnregistered(
          withError(const ApiErrorTypes(key: 'pos_device_unregistered')),
        ),
        isTrue,
      );
    });

    // Before the backend sends `key`, the status and code are all there is. In the POS chain
    // 401/137 is emitted only by the device middleware, so this reading is correct — but it is
    // a fallback, not the intended contract.
    test('falls back to 401 with code 137 when there is no key', () {
      expect(
        ApiError.isDeviceUnregistered(
          withError(const ApiErrorTypes(code: 137)),
        ),
        isTrue,
      );
    });

    // 144 is `UnauthorizedLogin` — the cashier, not the device. Sending the tablet to pairing
    // over a signed-out cashier would lose the pairing for no reason.
    test('is false for the login 401', () {
      expect(
        ApiError.isDeviceUnregistered(
          withError(const ApiErrorTypes(code: 144)),
        ),
        isFalse,
      );
    });

    test('is false for a 401 with no code and no key', () {
      expect(ApiError.isDeviceUnregistered(withError(null)), isFalse);
    });

    // The key is authoritative: it decides even when the status is not 401, so a future
    // backend that answers 403 for the same condition does not slip through.
    test('trusts the key over the status', () {
      expect(
        ApiError.isDeviceUnregistered(
          withError(
            const ApiErrorTypes(key: 'pos_device_unregistered'),
            status: 403,
          ),
        ),
        isTrue,
      );
    });

    // A different keyed error is not this one, whatever its status.
    test('is false for another keyed error at 401', () {
      expect(
        ApiError.isDeviceUnregistered(
          withError(const ApiErrorTypes(key: 'pos_device_limit_reached')),
        ),
        isFalse,
      );
    });

    test('is false for anything that is not an ApiError', () {
      expect(ApiError.isDeviceUnregistered(Exception('x')), isFalse);
      expect(ApiError.isDeviceUnregistered(null), isFalse);
    });
  });

  // The device limit is what a cashier hits at tablet 11. `422` with code 720 is shared with
  // six Postgres conditions, so `key` is the only way to tell them apart.
  group('isDeviceLimitReached', () {
    test('is true when the server names the key', () {
      expect(
        ApiError.isDeviceLimitReached(
          ApiError(
            'x',
            status: 422,
            errorData: const ApiErrorTypes(key: 'pos_device_limit_reached'),
          ),
        ),
        isTrue,
      );
    });

    // Deliberately no fallback: 422/720 is ambiguous, so guessing would tell a cashier the
    // outlet is full when the real problem was a duplicate fingerprint.
    test('is false for a 422 that carries no key', () {
      expect(
        ApiError.isDeviceLimitReached(
          ApiError('x', status: 422, errorData: const ApiErrorTypes(code: 720)),
        ),
        isFalse,
      );
    });

    test('is false for anything that is not an ApiError', () {
      expect(ApiError.isDeviceLimitReached('422'), isFalse);
    });
  });

  group('parseRetryAfter', () {
    test('reads delta-seconds from a 429', () {
      expect(parseRetryAfter(status: 429, header: '30'), 30);
    });

    // Retry-After also rides on 503. The source only honours it for a rate limit, and
    // the cashier's "wait N seconds" behaviour must match the web app.
    test('ignores the header on any other status', () {
      expect(parseRetryAfter(status: 503, header: '30'), isNull);
      expect(parseRetryAfter(status: 200, header: '30'), isNull);
    });

    test('is null when the header is absent or empty', () {
      expect(parseRetryAfter(status: 429), isNull);
      expect(parseRetryAfter(status: 429, header: ''), isNull);
    });

    test('accepts zero — retry immediately is a real answer', () {
      expect(parseRetryAfter(status: 429, header: '0'), 0);
    });

    test('rejects a negative or non-numeric value', () {
      expect(parseRetryAfter(status: 429, header: '-1'), isNull);
      expect(parseRetryAfter(status: 429, header: 'abc'), isNull);
    });

    // RFC 7231 also allows an HTTP-date. The source does not parse it, so neither do we.
    test('does not understand the HTTP-date form', () {
      expect(
        parseRetryAfter(status: 429, header: 'Wed, 21 Oct 2026 07:28:00 GMT'),
        isNull,
      );
    });

    // JavaScript's parseInt reads a numeric prefix and skips leading whitespace, so a
    // header the strict parser would refuse still yields a number in the web app.
    test('reads a numeric prefix the way parseInt does', () {
      expect(parseRetryAfter(status: 429, header: '30abc'), 30);
      expect(parseRetryAfter(status: 429, header: '  30'), 30);
      expect(parseRetryAfter(status: 429, header: '3.7'), 3);
      expect(parseRetryAfter(status: 429, header: '+5'), 5);
    });

    test('is null for a value too large to represent', () {
      expect(
        parseRetryAfter(status: 429, header: '99999999999999999999'),
        isNull,
      );
    });
  });
}
