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
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/shift/close_shift_controller.dart';

// Written new. `close-shift-dialog.tsx` keeps this in `useState` and calls `shiftCloseState`
// (ported to `pn_pos`, and tested there) for the rule. What is tested here is what the controller
// does with the rule: what it lets the cashier submit, what it sends, and what it says when the
// answer is not a plain yes.

const _json = {'content-type': 'application/json'};

TransportResponse ok(Object? data) => TransportResponse(
  status: 200,
  headers: _json,
  body: jsonEncode({'data': data}),
);

TransportResponse refused(int status, String message) => TransportResponse(
  status: status,
  headers: _json,
  body: jsonEncode({
    'error': {'message': message},
  }),
);

ShiftSummaryResponse summary({num expected = 275000}) =>
    ShiftSummaryResponse.fromJson({
      'shift_id': 's1',
      'number': 'SH-0001',
      'status': 'OPEN',
      'outlet_id': 'out_1',
      'cashier_id': 'u1',
      'opened_at': '2026-09-20T01:00:00Z',
      'total_transactions': 3,
      'total_sales': 200000,
      'opening_cash': 150000,
      'expected_cash': expected,
      'cash_in': 20000,
      'cash_out': 5000,
      'cash_drop': 10000,
    });

Map<String, Object?> closedShift() => {
  'id': 's1',
  'number': 'SH-0001',
  'cashier_id': 'u1',
  'outlet_id': 'out_1',
  'opened_at': '2026-09-20T01:00:00Z',
  'opening_cash': 150000,
  'total_sales': 200000,
  'total_transactions': 3,
};

({
  CloseShiftController controller,
  FakeApiTransport transport,
  FakeAnalytics analytics,
})
rig({bool isOverride = false, num expected = 275000}) {
  final transport = FakeApiTransport();
  final analytics = FakeAnalytics();
  final controller = CloseShiftController(
    client: ApiClient(transport: transport, language: () => 'id'),
    summary: summary(expected: expected),
    isOverride: isOverride,
    analytics: analytics,
  );
  addTearDown(controller.dispose);
  return (controller: controller, transport: transport, analytics: analytics);
}

void main() {
  closing();
  group('what the count comes to', () {
    test('starts from an uncounted drawer: the whole expected cash is missing, '
        'and that needs a note', () {
      final (:controller, transport: _, analytics: _) = rig();

      expect(controller.countedCash, 0);
      expect(controller.close.variance, -275000);
      expect(controller.close.needsNote, isTrue);
      expect(controller.close.canClose, isFalse);
    });

    test('a counted drawer that matches needs no note', () {
      final (:controller, transport: _, analytics: _) = rig();

      controller.setCountedCash(275000);

      expect(controller.close.variance, 0);
      expect(controller.close.canClose, isTrue);
    });

    test('a surplus is a variance too, and shown as it falls', () {
      final (:controller, transport: _, analytics: _) = rig();

      controller.setCountedCash(300000);

      expect(controller.close.variance, 25000);
      expect(controller.close.canClose, isFalse);
    });

    test('a note lets a variance close', () {
      final (:controller, transport: _, analytics: _) = rig();
      controller.setCountedCash(270000);

      controller.setNotes('Uang receh hilang');

      expect(controller.close.canClose, isTrue);
    });

    test('a note of spaces is no note', () {
      final (:controller, transport: _, analytics: _) = rig();
      controller.setCountedCash(270000);

      controller.setNotes('   ');

      expect(controller.close.canClose, isFalse);
    });

    test(
      'closing the drawer of another cashier needs a note even when it matches',
      () {
        final (:controller, transport: _, analytics: _) = rig(isOverride: true);
        controller.setCountedCash(275000);

        expect(controller.close.canClose, isFalse);

        controller.setNotes('Kasir pulang, laci ditutup atasan');
        expect(controller.close.canClose, isTrue);
      },
    );

    test('tells whoever is listening when the count changes', () {
      final (:controller, transport: _, analytics: _) = rig();
      var told = 0;
      controller.addListener(() => told++);

      controller.setCountedCash(1000);
      controller.setNotes('x');

      expect(told, 2);
    });
  });
}

Map<String, Object?> bodyOf(TransportRequest request) =>
    jsonDecode(request.body!) as Map<String, Object?>;

void closing() {
  group('closing it', () {
    test('sends the count to the close endpoint of that shift, and is closed '
        'once the server says so', () async {
      final (:controller, :transport, analytics: _) = rig();
      transport.respond(ok(closedShift()));
      controller.setCountedCash(275000);

      await controller.submit();

      final request = transport.requests.single;
      expect(request.method.wire, 'POST');
      expect(request.path, '/api/v1/pos/shifts/s1/close');
      expect(bodyOf(request)['counted_cash'], 275000);
      expect(controller.isClosed, isTrue);
    });

    test('sends the note trimmed', () async {
      final (:controller, :transport, analytics: _) = rig();
      transport.respond(ok(closedShift()));
      controller.setCountedCash(270000);
      controller.setNotes('  Uang receh hilang \n');

      await controller.submit();

      expect(bodyOf(transport.requests.single)['notes'], 'Uang receh hilang');
    });

    test('sends no note at all when there is none, not an empty one', () async {
      final (:controller, :transport, analytics: _) = rig();
      transport.respond(ok(closedShift()));
      controller.setCountedCash(275000);

      await controller.submit();

      expect(bodyOf(transport.requests.single).containsKey('notes'), isFalse);
    });

    test('refuses to send a count the rule does not allow: the screen has '
        'disabled the button, so getting here is a bug', () async {
      final (:controller, :transport, analytics: _) = rig();
      controller.setCountedCash(270000); // short, and no note

      await expectLater(controller.submit(), throwsStateError);

      expect(transport.requests, isEmpty);
      expect(controller.isClosed, isFalse);
    });

    test(
      'a refusal is a problem with the words the server gave, and the drawer '
      'is not closed',
      () async {
        final (:controller, :transport, analytics: _) = rig();
        transport.respond(refused(409, 'Shift sudah ditutup'));
        controller.setCountedCash(275000);

        await controller.submit();

        expect(controller.isClosed, isFalse);
        expect(controller.problem?.message, 'Shift sudah ditutup');
        expect(controller.problem?.mayHaveSucceeded, isFalse);
      },
    );

    test('no answer at all: it may have closed, and there is nothing of the '
        "server's to quote", () async {
      final (:controller, :transport, analytics: _) = rig();
      transport.fail(TransportException('offline'));
      controller.setCountedCash(275000);

      await controller.submit();

      expect(controller.isClosed, isFalse);
      expect(controller.problem?.message, isNull);
      expect(controller.problem?.mayHaveSucceeded, isTrue);
    });

    test('a server error may have committed before it failed', () async {
      final (:controller, :transport, analytics: _) = rig();
      transport.respond(refused(500, 'Gagal'));
      controller.setCountedCash(275000);

      await controller.submit();

      expect(controller.problem?.mayHaveSucceeded, isTrue);
    });

    test('asked again while it is closing, it sends nothing more: a double '
        'tap must not close twice', () async {
      final (:controller, :transport, analytics: _) = rig();
      transport.respond(ok(closedShift()));
      controller.setCountedCash(275000);

      final first = controller.submit();
      expect(controller.isClosing, isTrue);
      final second = controller.submit();
      await Future.wait([first, second]);

      expect(transport.requests, hasLength(1));
      expect(controller.isClosing, isFalse);
    });

    test('trying again after a failure sends again, and forgets the old '
        'problem', () async {
      final (:controller, :transport, analytics: _) = rig();
      transport.respond(refused(409, 'Ditolak'));
      transport.respond(ok(closedShift()));
      controller.setCountedCash(275000);
      await controller.submit();
      expect(controller.problem, isNotNull);

      await controller.submit();

      expect(controller.problem, isNull);
      expect(controller.isClosed, isTrue);
    });
  });

  group('analytics', () {
    test('logs shift_closed once the server confirms it', () async {
      final (:controller, :transport, :analytics) = rig();
      transport.respond(ok(closedShift()));
      controller.setCountedCash(275000);

      await controller.submit();

      expect(analytics.logged.map((e) => e.$1), ['shift_closed']);
    });

    test('logs nothing when the server refuses', () async {
      final (:controller, :transport, :analytics) = rig();
      transport.respond(refused(409, 'Shift sudah ditutup'));
      controller.setCountedCash(275000);

      await controller.submit();

      expect(analytics.logged, isEmpty);
    });
  });
}
