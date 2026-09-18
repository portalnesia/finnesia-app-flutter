/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos/http/inspector/redaction.dart';

// README §14.1: the inspector is opened on a tablet that belongs to a tenant, and its screen is
// easy to screenshot into a support chat. Whatever is a credential is redacted where it is
// recorded, not hidden in the UI. Redaction that is not tested is redaction that can stop
// working without anyone noticing, so these are also the detector's own tests: every case that
// must be found is checked, and so is every case that must be left alone.

void main() {
  group('redactHeaders', () {
    test('keeps the scheme of Authorization and hides the token', () {
      expect(
        redactHeaders({'Authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9.abc.def'}),
        {'Authorization': 'Bearer ***'},
      );
    });

    test(
      'finds Authorization whatever its case, and keeps the name as written',
      () {
        expect(redactHeaders({'authorization': 'Bearer tok_secret'}), {
          'authorization': 'Bearer ***',
        });
        expect(redactHeaders({'AUTHORIZATION': 'Bearer tok_secret'}), {
          'AUTHORIZATION': 'Bearer ***',
        });
      },
    );

    test(
      'hides a value that has no scheme, or a scheme and nothing after it',
      () {
        expect(redactHeaders({'Authorization': 'tok_secret'}), {
          'Authorization': '***',
        });
        expect(redactHeaders({'Authorization': 'Basic dXNlcjpwYXNz'}), {
          'Authorization': 'Basic ***',
        });
        expect(redactHeaders({'Authorization': 'Bearer'}), {
          'Authorization': '***',
        });
      },
    );

    test('hides the value of every header that carries a credential', () {
      final redacted = redactHeaders({
        'X-Session-Token': 'tok_rotated',
        'X-Session-Expires': '2030-01-01T00:00:00Z',
        'X-Csrf-Token': 'csrf_value',
        'Cookie': '_finid_session=abc',
        'Set-Cookie': '_finid_session=abc; HttpOnly',
        'Proxy-Authorization': 'Basic abc',
      });

      expect(redacted.values, everyElement(anyOf('***', 'Basic ***')));
    });

    test('finds those headers whatever their case', () {
      expect(
        redactHeaders({'x-session-token': 'tok_rotated', 'X-CSRF-TOKEN': 'c'}),
        {'x-session-token': '***', 'X-CSRF-TOKEN': '***'},
      );
    });

    // Not a credential, and the one that is wrong most often: which company a request was for.
    test('leaves X-Company-ID and every other header alone', () {
      final headers = {
        'X-Company-ID': 'comp_1',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      expect(redactHeaders(headers), headers);
    });

    // The device token authenticates the tablet to the server. A log line holding it lets
    // anyone act as that device, and the token cannot be reissued without pairing again
    // (`.claude/rules/security.md` §1).
    test('hides the device token', () {
      expect(redactHeaders({'X-Device-Token': 'dev_tok_secret'}), {
        'X-Device-Token': '***',
      });
    });

    test('hides the device token whatever its case', () {
      expect(redactHeaders({'x-device-token': 'dev_tok_secret'}), {
        'x-device-token': '***',
      });
    });

    test('does not change the map it was given', () {
      final headers = {'Authorization': 'Bearer tok_secret'};

      redactHeaders(headers);

      expect(headers['Authorization'], 'Bearer tok_secret');
    });
  });
  group('redactBody', () {
    test('hides the fields that carry a credential and leaves the rest', () {
      expect(
        redactBody({
          'email': 'budi@perusahaan.com',
          'password': 'hunter2',
          'token': 'tok_a',
          'refresh_token': 'ref_a',
          'amount': 1500,
        }),
        {
          'email': 'budi@perusahaan.com',
          'password': '***',
          'token': '***',
          'refresh_token': '***',
          'amount': 1500,
        },
      );
    });

    // README §14.1 says a response body is shown as it is. But the login poll and the refresh
    // answer with the session itself, and a screenshot of that is the leak this whole section
    // exists to prevent.
    test('hides the session a login or a refresh hands back', () {
      expect(
        redactBody({
          'data': {
            'status': 'ready',
            'session_token': 'sess_tok',
            'session_refresh_token': 'sess_ref',
            'expires_at': '2026-09-24T10:00:00Z',
            'user': {'id': 'user_1', 'name': 'Budi'},
          },
        }),
        {
          'data': {
            'status': 'ready',
            'session_token': '***',
            'session_refresh_token': '***',
            'expires_at': '2026-09-24T10:00:00Z',
            'user': {'id': 'user_1', 'name': 'Budi'},
          },
        },
      );
    });

    // Whoever holds a login's request id can collect its session, and the URL that opens the
    // login carries it.
    test('hides the request id of a login, and the URL that carries it', () {
      expect(
        redactBody({
          'request_id': 'req_abc',
          'login_url': 'https://apps.finnesia.com/api/auth/login?req=req_abc',
          'expires_in': 300,
        }),
        {'request_id': '***', 'login_url': '***', 'expires_in': 300},
      );
    });

    test('finds them inside lists and inside objects inside lists', () {
      expect(
        redactBody({
          'items': [
            {'name': 'a', 'token': 't1'},
            {
              'nested': {'password': 'p'},
            },
            'plain',
            7,
          ],
        }),
        {
          'items': [
            {'name': 'a', 'token': '***'},
            {
              'nested': {'password': '***'},
            },
            'plain',
            7,
          ],
        },
      );
      expect(
        redactBody([
          {'token': 't'},
        ]),
        [
          {'token': '***'},
        ],
      );
    });

    test('finds a field whatever its case', () {
      expect(redactBody({'Password': 'p', 'REFRESH_TOKEN': 'r'}), {
        'Password': '***',
        'REFRESH_TOKEN': '***',
      });
    });

    test(
      'hides a credential that is not a string, and leaves a null as a null',
      () {
        expect(redactBody({'token': 12345, 'password': null}), {
          'token': '***',
          'password': null,
        });
      },
    );

    test('reads a JSON string, since that is how a request body arrives', () {
      expect(redactBody('{"refresh_token":"ref_a","x":1}'), {
        'refresh_token': '***',
        'x': 1,
      });
    });

    test('leaves a string that is not JSON as it is', () {
      expect(redactBody('upstream connect error'), 'upstream connect error');
      expect(redactBody(''), '');
    });

    test('leaves null, numbers and booleans as they are', () {
      expect(redactBody(null), isNull);
      expect(redactBody(42), 42);
      expect(redactBody(true), true);
    });

    test('does not change what it was given', () {
      final body = {
        'token': 'tok',
        'list': [
          {'password': 'p'},
        ],
      };

      redactBody(body);

      expect(body['token'], 'tok');
      expect(((body['list']! as List).single as Map)['password'], 'p');
    });

    // An object that is not JSON (a form, a stream, bytes) could hold a credential in a way
    // that cannot be looked into, so only its type is shown.
    test('shows only the type of a body that is not JSON', () {
      expect(redactBody(DateTime(2026)), '<DateTime>');
      expect(redactBody(Object()), '<Object>');
    });

    // Bytes are a list of numbers to Dart, and to a redactor that walks lists; but there is no
    // field in them to look for, and a download can be megabytes.
    test('shows only the type of bytes, not the bytes', () {
      expect(redactBody(Uint8List.fromList([1, 2, 3])), '<Uint8List>');
    });

    // A structure this deep is not a request body. What matters is that looking at it cannot
    // crash the request it is recording, and that a cycle is not followed forever.
    test(
      'stops at a depth, so a cycle or a very deep body cannot overflow',
      () {
        final cyclic = <String, Object?>{'token': 'tok_secret'};
        cyclic['self'] = cyclic;

        final redacted = redactBody(cyclic);

        expect(redacted.toString(), isNot(contains('tok_secret')));

        Object? deep = 'leaf';
        for (var i = 0; i < 500; i++) {
          deep = {'next': deep};
        }
        expect(() => redactBody(deep), returnsNormally);
      },
    );

    // The inspector keeps the last 50 exchanges of a tablet that runs for days; a product list
    // of thousands of rows, 50 times over, would use up its memory before anyone opens it.
    test('cuts a body that is too long, and says how much was cut', () {
      final body = {'data': 'x' * 100000};

      final redacted = redactBody(body);

      expect(redacted, isA<String>());
      expect((redacted! as String).length, lessThan(25000));
      expect(redacted, contains('more characters'));
    });

    test(
      'redacts before it cuts, so a credential cannot survive in the part kept',
      () {
        final body = {'token': 'tok_secret', 'data': 'x' * 100000};

        expect(redactBody(body).toString(), isNot(contains('tok_secret')));
      },
    );

    test('leaves a body that fits as a structure, not as text', () {
      expect(redactBody({'a': 1}), isA<Map<String, dynamic>>());
    });
  });
}
