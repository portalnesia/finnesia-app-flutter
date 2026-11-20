/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pos/till/quick_create.dart';

// The part adding a customer and adding a product share: one create at a time, and a failure
// read the way the till words it. Extracted from `TransactionDetailController.create`, whose
// tests still cover it through the customer flow; these pin it down on its own.

ApiError failure(int status, String message) =>
    ApiError(message, status: status);

void main() {
  group('running a create', () {
    test('hands back what was created', () async {
      final outcome = await QuickCreateRunner<String>().run(() async => 'p1');

      expect((outcome as QuickCreateOk<String>).created, 'p1');
    });

    test('a 4xx is a refusal, in the server\'s words', () async {
      final outcome = await QuickCreateRunner<String>().run(
        () async => throw failure(422, 'Nama sudah dipakai'),
      );

      expect(
        (outcome as QuickCreateRejected<String>).message,
        'Nama sudah dipakai',
      );
    });

    test('a 5xx is not a refusal: it may have been saved', () async {
      final outcome = await QuickCreateRunner<String>().run(
        () async => throw failure(503, 'unavailable'),
      );

      expect(outcome, isA<QuickCreateUnavailable<String>>());
    });

    test('no answer at all is unavailable', () async {
      final outcome = await QuickCreateRunner<String>().run(
        () async => throw TransportException('offline'),
      );

      expect(outcome, isA<QuickCreateUnavailable<String>>());
    });

    test('a bug is not swallowed as a failure to show', () async {
      final running = QuickCreateRunner<String>().run(
        () async => throw StateError('bug'),
      );

      await expectLater(running, throwsStateError);
    });

    test(
      'a second call while one is out sends nothing and shares the answer',
      () async {
        final runner = QuickCreateRunner<String>();
        final answer = Completer<String>();
        var sent = 0;
        Future<String> send() {
          sent++;
          return answer.future;
        }

        final first = runner.run(send);
        final second = runner.run(send);
        answer.complete('p1');

        expect(identical(first, second), isTrue);
        await first;
        expect(sent, 1);
      },
    );

    test('once one has finished, the next is sent', () async {
      final runner = QuickCreateRunner<String>();
      var sent = 0;

      await runner.run(() async => '${++sent}');
      await runner.run(() async => '${++sent}');

      expect(sent, 2);
    });
  });

  group('a field the cashier left alone', () {
    test('is absent when empty or only spaces', () {
      expect(orAbsent(''), isNull);
      expect(orAbsent('   '), isNull);
    });

    test('is trimmed when filled in', () {
      expect(orAbsent(' 0812 '), '0812');
    });
  });
}
