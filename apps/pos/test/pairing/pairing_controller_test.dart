/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/pairing/pairing_controller.dart';

import '../support/boot_rig.dart';

// The state behind the pairing screen: what was typed, whether a request is out, and why the
// last one failed. `pairDevice` itself is tested in `pairing_test.dart`; this is what the screen
// does with its answers.

Future<(Rig, AppServices, PairingController)> setUp() async {
  final rig = Rig();
  final services = await rig.ready();
  return (
    rig,
    services,
    PairingController(
      () => services.pairingDeps,
      analytics: services.analytics,
    ),
  );
}

void main() {
  group('typing the code', () {
    test('keeps it in capitals, without separators', () async {
      final (_, _, c) = await setUp();

      c.setCode('ab3-k7m');

      expect(c.code, 'AB3K7M');
    });

    test('refuses a seventh character, and keeps what was there', () async {
      final (_, _, c) = await setUp();
      c.setCode('AB3K7M');

      c.setCode('AB3K7MX');

      expect(c.code, 'AB3K7M');
    });

    test('tells its listeners', () async {
      final (_, _, c) = await setUp();
      var notified = 0;
      c.addListener(() => notified++);

      c.setCode('A');

      expect(notified, 1);
    });
  });

  group('a scanned code', () {
    test('is entered and paired with, without a tap on Pasangkan', () async {
      final (rig, services, c) = await setUp();
      rig.http.respond(activatedResponse());

      final used = c.useScannedCode('AB3K7M');
      await pumpEventQueue();

      expect(used, isTrue);
      expect(c.code, 'AB3K7M');
      expect(services.session.current, isNotNull);
    });

    test(
      'is read the way a typed one is: capitals, no stray characters',
      () async {
        final (rig, _, c) = await setUp();
        rig.http.respond(activatedResponse());

        c.useScannedCode(' ab3k7m\n');
        await pumpEventQueue();

        final body = jsonDecode(
          rig.http.calls.single.request.body!,
        ) as Map<String, dynamic>;
        expect(body['code'], 'AB3K7M');
      },
    );

    test(
      'that is not a pairing code is refused, and nothing is sent',
      () async {
        final (rig, _, c) = await setUp();
        c.setCode('XY');

        final used = c.useScannedCode('https://example.com/menu');

        expect(used, isFalse);
        expect(rig.http.calls, isEmpty);
        expect(c.code, 'XY');
      },
    );

    test('is ignored while a request is out', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(activatedResponse());
      c.setCode('AB3K7M');
      final first = c.submit();

      final used = c.useScannedCode('CD4M8N');
      await first;

      expect(used, isFalse);
      expect(rig.http.calls, hasLength(1));
    });
  });

  group('pairing', () {
    test('saves the session, and says nothing was wrong', () async {
      final (rig, services, c) = await setUp();
      rig.http.respond(activatedResponse());
      c.setCode('AB3K7M');

      await c.submit();

      expect(services.session.current, isNotNull);
      expect(c.problem, isNull);
      expect(c.isSubmitting, isFalse);
    });

    test('sends the device name that was typed, and the code', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(activatedResponse());
      c.setDeviceName('Kasir Depan');
      c.setCode('AB3K7M');

      await c.submit();

      final body = jsonDecode(
        rig.http.calls.single.request.body!,
      ) as Map<String, dynamic>;
      expect(body['device_name'], 'Kasir Depan');
      expect(body['code'], 'AB3K7M');
    });

    test('says it is submitting while the request is out', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(activatedResponse());
      c.setCode('AB3K7M');
      final states = <bool>[];
      c.addListener(() => states.add(c.isSubmitting));

      await c.submit();

      expect(states, [true, false]);
    });

    test(
      'sends one request however many times it is asked while it is out',
      () async {
        final (rig, _, c) = await setUp();
        rig.http.respond(activatedResponse());
        c.setCode('AB3K7M');

        await Future.wait([c.submit(), c.submit(), c.submit()]);

        expect(rig.http.calls, hasLength(1));
      },
    );
  });

  group('a pairing that does not work', () {
    test('says the code cannot be one, and sends nothing', () async {
      final (rig, services, c) = await setUp();
      c.setCode('AB3');

      await c.submit();

      expect(c.problem, PairingProblem.invalidCode);
      expect(rig.http.calls, isEmpty);
      expect(services.session.current, isNull);
    });

    test('says the server did not accept the code', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(TransportResponse(status: 401, body: '{}'));
      c.setCode('AB3K7M');

      await c.submit();

      expect(c.problem, PairingProblem.codeRejected);
    });

    test('says the server could not be reached', () async {
      final (rig, _, c) = await setUp();
      rig.http.fail(TransportException('down'));
      c.setCode('AB3K7M');

      await c.submit();

      expect(c.problem, PairingProblem.unavailable);
    });

    test('says the device storage failed, not that the server did', () async {
      final (rig, _, c) = await setUp();
      rig.store.failNext(StoreException('the value could not be read'));
      c.setCode('AB3K7M');

      await c.submit();

      expect(c.problem, PairingProblem.storage);
      expect(c.isSubmitting, isFalse);
    });

    test('can be tried again, and a success clears the problem', () async {
      final (rig, services, c) = await setUp();
      rig.http.fail(TransportException('down'));
      c.setCode('AB3K7M');
      await c.submit();

      rig.http.respond(activatedResponse());
      await c.submit();

      expect(c.problem, isNull);
      expect(services.session.current, isNotNull);
    });

    test('forgets the problem as soon as the cashier edits the code', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(TransportResponse(status: 401, body: '{}'));
      c.setCode('AB3K7M');
      await c.submit();

      c.setCode('AB3K7');

      expect(c.problem, isNull);
    });

    test('forgets the problem as soon as the cashier edits the name', () async {
      final (rig, _, c) = await setUp();
      c.setCode('AB3');
      await c.submit();

      c.setDeviceName('Kasir');

      expect(c.problem, isNull);
    });

    // The one problem the controller carries a value for: the screen puts the number in the
    // sentence, and a generic wording would be less useful than the real one.
    test('reports the outlet limit, and how many tablets it allows', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(
        TransportResponse(
          status: 422,
          headers: const {'Content-Type': 'application/json'},
          body:
              '{"data":null,"error":{"code":720,'
              '"key":"pos_device_limit_reached","params":{"limit":10}}}',
        ),
      );
      c.setCode('AB3K7M');

      await c.submit();

      expect(c.problem, PairingProblem.deviceLimitReached);
      expect(c.deviceLimit, 10);
      expect(c.isSubmitting, isFalse);
    });

    // Without the number the screen uses its own wording, so the value has to be absent rather
    // than zero: a zero would print "batas 0 tablet".
    test(
      'reports the outlet limit with no number when the server sent none',
      () async {
        final (rig, _, c) = await setUp();
        rig.http.respond(
          TransportResponse(
            status: 422,
            headers: const {'Content-Type': 'application/json'},
            body:
                '{"data":null,"error":{"code":720,'
                '"key":"pos_device_limit_reached"}}',
          ),
        );
        c.setCode('AB3K7M');

        await c.submit();

        expect(c.problem, PairingProblem.deviceLimitReached);
        expect(c.deviceLimit, isNull);
      },
    );

    // A limit left over from a previous attempt would be shown against a different problem.
    test('forgets the limit when the cashier edits the code', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(
        TransportResponse(
          status: 422,
          headers: const {'Content-Type': 'application/json'},
          body:
              '{"data":null,"error":{"code":720,'
              '"key":"pos_device_limit_reached","params":{"limit":10}}}',
        ),
      );
      c.setCode('AB3K7M');
      await c.submit();

      c.setCode('AB3K7');

      expect(c.deviceLimit, isNull);
    });

    test('forgets the limit when the cashier edits the name', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(
        TransportResponse(
          status: 422,
          headers: const {'Content-Type': 'application/json'},
          body:
              '{"data":null,"error":{"code":720,'
              '"key":"pos_device_limit_reached","params":{"limit":10}}}',
        ),
      );
      c.setCode('AB3K7M');
      await c.submit();

      c.setDeviceName('Kasir');

      expect(c.deviceLimit, isNull);
    });

    // A later failure of another kind must not keep the old number.
    test('clears the limit when another attempt fails differently', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(
        TransportResponse(
          status: 422,
          headers: const {'Content-Type': 'application/json'},
          body:
              '{"data":null,"error":{"code":720,'
              '"key":"pos_device_limit_reached","params":{"limit":10}}}',
        ),
      );
      c.setCode('AB3K7M');
      await c.submit();

      rig.http.fail(TransportException('down'));
      await c.submit();

      expect(c.problem, PairingProblem.unavailable);
      expect(c.deviceLimit, isNull);
    });
  });

  group('a controller that is disposed', () {
    test('does not notify when the answer arrives after', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(activatedResponse());
      c.setCode('AB3K7M');

      final pairing = c.submit();
      c.dispose();

      await expectLater(pairing, completes);
    });
  });

  group('analytics', () {
    test('logs pairing_started then pairing_succeeded', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(activatedResponse());
      c.setCode('AB3K7M');

      await c.submit();

      expect(rig.analytics.logged.map((e) => e.$1), [
        'pairing_started',
        'pairing_succeeded',
      ]);
    });

    test(
      'logs pairing_failed with the reason, not the server sentence',
      () async {
        final (rig, _, c) = await setUp();
        rig.http.respond(TransportResponse(status: 401, body: '{}'));
        c.setCode('AB3K7M');

        await c.submit();

        expect(rig.analytics.logged.map((e) => e.$1), [
          'pairing_started',
          'pairing_failed',
        ]);
        expect(rig.analytics.logged.last.$2, {'reason': 'codeRejected'});
      },
    );

    test(
      'logs pairing_started even for a code that never reaches the server',
      () async {
        final (rig, _, c) = await setUp();
        c.setCode('AB3');

        await c.submit();

        expect(rig.analytics.logged.map((e) => e.$1), [
          'pairing_started',
          'pairing_failed',
        ]);
        expect(rig.analytics.logged.last.$2, {'reason': 'invalidCode'});
      },
    );

    test('does not start a second attempt while one is out', () async {
      final (rig, _, c) = await setUp();
      rig.http.respond(activatedResponse());
      c.setCode('AB3K7M');

      await Future.wait([c.submit(), c.submit(), c.submit()]);

      expect(
        rig.analytics.logged.where((e) => e.$1 == 'pairing_started'),
        hasLength(1),
      );
    });
  });
}
