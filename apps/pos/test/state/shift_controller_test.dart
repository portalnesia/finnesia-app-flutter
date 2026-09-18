/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/shift_gate.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/shift_controller.dart';

// Written new: the decision is spread over a page (two queries and a `useSyncExternalStore`)
// and the gate's open form, so there is no single source to port. What is ported is the rule
// (`resolveShiftGate`, in `pn_pos`) and the reason the resume decision is kept in memory only
// (`plan/ui/findings.md` F6).

String shiftJson({String id = 's1', String cashierId = 'u1'}) => jsonEncode({
  'id': id,
  'number': 'SH-0001',
  'cashier_id': cashierId,
  'outlet_id': 'out_1',
  'opened_at': '2026-09-20T01:00:00Z',
  'opening_cash': 100000,
  'total_sales': 0,
  'total_transactions': 0,
});

TransportResponse ok(String data) => TransportResponse(
  status: 200,
  headers: {'content-type': 'application/json'},
  body: '{"data":$data}',
);

TransportResponse failure(int status, String message) => TransportResponse(
  status: status,
  headers: {'content-type': 'application/json'},
  body: jsonEncode({
    'error': {'message': message},
  }),
);

TransportResponse settings({bool requireShift = true}) =>
    ok('{"require_shift":$requireShift}');

/// What the till reads when it opens: the active shift, then the settings.
void answer(
  FakeApiTransport transport, {
  String? shift,
  bool requireShift = true,
}) {
  transport.respond(ok(shift ?? 'null'));
  transport.respond(settings(requireShift: requireShift));
}

({
  ShiftController controller,
  FakeApiTransport transport,
  FakeAnalytics analytics,
})
rig({String userId = 'u1'}) {
  final transport = FakeApiTransport();
  final analytics = FakeAnalytics();
  final controller = ShiftController(
    client: ApiClient(transport: transport, language: () => 'id'),
    outletId: 'out_1',
    userId: userId,
    analytics: analytics,
  );
  addTearDown(controller.dispose);
  return (controller: controller, transport: transport, analytics: analytics);
}

void main() {
  group('reading what the till needs', () {
    test(
      'asks for the shift of the paired outlet, and for the settings, once',
      () async {
        final (:controller, :transport, analytics: _) = rig();
        answer(transport);

        await controller.load();

        expect(transport.requests, hasLength(2));
        final active = transport.requests.singleWhere(
          (r) => r.path.startsWith('/api/v1/pos/shifts/active'),
        );
        expect(active.path, contains('outlet_id=out_1'));
        expect(
          transport.requests.where((r) => r.path == '/api/v1/pos/settings'),
          hasLength(1),
        );
      },
    );

    test('has decided nothing until both have answered', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport);

      final loading = controller.load();

      expect(controller.gate, ShiftGateState.loading);
      await loading;
    });

    test('says why it could not read, and reads again when asked', () async {
      final (:controller, :transport, analytics: _) = rig();
      transport.respond(failure(500, 'boom'));
      transport.respond(settings());

      await controller.load();

      expect(controller.state, isA<Failed<ShiftContext>>());
      // Failed is not "no shift": the till must not offer to open one it may already have.
      expect(controller.gate, ShiftGateState.loading);

      answer(transport);
      await controller.load();
      expect(controller.gate, ShiftGateState.shiftRequired);
    });
  });

  group('which screen the cashier gets', () {
    test('a shift is required and none is open', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport);
      await controller.load();

      expect(controller.gate, ShiftGateState.shiftRequired);
    });

    test('no shift is required, so the till is open', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport, requireShift: false);
      await controller.load();

      expect(controller.gate, ShiftGateState.cart);
    });

    test('the cashier own shift is shown first, not sold into', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport, shift: shiftJson());
      await controller.load();

      expect(controller.gate, ShiftGateState.alreadyOpen);
    });

    test('and continuing it opens the till', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport, shift: shiftJson());
      await controller.load();

      controller.resume();

      expect(controller.gate, ShiftGateState.cart);
    });

    test(
      'another cashier drawer stays theirs, whatever was continued',
      () async {
        final (:controller, :transport, analytics: _) = rig();
        answer(transport, shift: shiftJson(cashierId: 'someone_else'));
        await controller.load();

        controller.resume();

        expect(controller.gate, ShiftGateState.heldByOther);
      },
    );

    test('a decision about one shift does not carry to another', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport, shift: shiftJson(id: 'yesterday'));
      await controller.load();
      controller.resume();

      // The shift was closed elsewhere and a new one opened: the answer given to the old one
      // must not open the new one (F6, "silently resume yesterday's shift").
      answer(transport, shift: shiftJson(id: 'today'));
      await controller.load();

      expect(controller.gate, ShiftGateState.alreadyOpen);
    });

    test('a new controller starts with nothing continued', () async {
      final first = rig();
      answer(first.transport, shift: shiftJson());
      await first.controller.load();
      first.controller.resume();

      final second = rig();
      answer(second.transport, shift: shiftJson());
      await second.controller.load();

      // Memory only: a launch, or the next cashier, sees the shift again.
      expect(second.controller.gate, ShiftGateState.alreadyOpen);
    });
  });

  group('opening a shift', () {
    test('sends the outlet and the counted cash', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport);
      await controller.load();
      transport.respond(ok(shiftJson()));
      answer(transport, shift: shiftJson());

      await controller.open(150000);

      final open = transport.requests[2];
      expect(open.method, HttpMethod.post);
      expect(open.path, '/api/v1/pos/shifts/open');
      expect(jsonDecode(open.body!), {
        'outlet_id': 'out_1',
        'opening_cash': 150000,
      });
    });

    test(
      'opens the till without asking to continue what was just opened',
      () async {
        final (:controller, :transport, analytics: _) = rig();
        answer(transport);
        await controller.load();
        transport.respond(ok(shiftJson()));
        answer(transport, shift: shiftJson());

        await controller.open(0);

        // Opening is the decision to continue, already made.
        expect(controller.gate, ShiftGateState.cart);
        expect(controller.openProblem, isNull);
      },
    );

    test('says what the server said when it refuses', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport);
      await controller.load();
      transport.respond(failure(422, 'Shift sudah terbuka di outlet ini'));

      await controller.open(0);

      expect(
        controller.openProblem?.message,
        'Shift sudah terbuka di outlet ini',
      );
      expect(controller.gate, ShiftGateState.shiftRequired);
      // Refused, so there is nothing new to read.
      expect(transport.requests, hasLength(3));
    });

    // A 5xx may have committed before it failed, so "no shift" is not known any more: the
    // cashier who taps again would be told a drawer is open that the screen never showed.
    test('checks the server when a failure may have gone through', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport);
      await controller.load();
      transport.respond(failure(500, 'boom'));
      answer(transport, shift: shiftJson());

      await controller.open(0);

      expect(transport.requests, hasLength(5));
      // The shift is there now, and the cashier did not knowingly continue it.
      expect(controller.gate, ShiftGateState.alreadyOpen);
    });

    test('a refusal is final, so it does not read again', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport);
      await controller.load();
      transport.respond(failure(409, 'nope'));

      await controller.open(0);

      expect(transport.requests, hasLength(3));
    });

    test('says the server could not be reached, without a message', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport);
      await controller.load();
      transport.fail(TransportException('offline'));

      await controller.open(0);

      expect(controller.openProblem, isNotNull);
      expect(controller.openProblem?.message, isNull);
      expect(controller.gate, ShiftGateState.shiftRequired);
    });

    test('forgets the last problem when the cashier tries again', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport);
      await controller.load();
      transport.respond(failure(422, 'nope'));
      await controller.open(0);
      transport.respond(ok(shiftJson()));
      answer(transport, shift: shiftJson());

      await controller.open(0);

      expect(controller.openProblem, isNull);
    });

    test('a double tap opens one shift', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport);
      await controller.load();
      transport.respond(ok(shiftJson()));
      answer(transport, shift: shiftJson());

      final first = controller.open(0);
      final second = controller.open(0);
      await Future.wait([first, second]);

      expect(
        transport.requests.where((r) => r.path == '/api/v1/pos/shifts/open'),
        hasLength(1),
      );
    });

    test('is busy while it is out, so the screen can say so', () async {
      final (:controller, :transport, analytics: _) = rig();
      answer(transport);
      await controller.load();
      transport.respond(ok(shiftJson()));
      answer(transport, shift: shiftJson());

      final opening = controller.open(0);
      expect(controller.isOpening, isTrue);
      await opening;

      expect(controller.isOpening, isFalse);
    });
  });

  test('says nothing after it is disposed', () async {
    final transport = FakeApiTransport();
    final controller = ShiftController(
      client: ApiClient(transport: transport, language: () => 'id'),
      outletId: 'out_1',
      userId: 'u1',
      analytics: FakeAnalytics(),
    );
    answer(transport);

    final loading = controller.load();
    controller.dispose();

    // A screen closed mid-request is `notifyListeners` after `dispose` if this is not guarded.
    await expectLater(loading, completes);
  });

  test('says nothing after it is disposed, even when it was opening', () async {
    final transport = FakeApiTransport();
    final controller = ShiftController(
      client: ApiClient(transport: transport, language: () => 'id'),
      outletId: 'out_1',
      userId: 'u1',
      analytics: FakeAnalytics(),
    );
    answer(transport);
    await controller.load();
    transport.respond(ok(shiftJson()));
    answer(transport, shift: shiftJson());

    // Signing out replaces the screen while the request is out.
    final opening = controller.open(0);
    controller.dispose();

    await expectLater(opening, completes);
  });

  group('analytics', () {
    test('logs shift_opened once a shift is actually opened', () async {
      final (:controller, :transport, :analytics) = rig();
      answer(transport);
      await controller.load();
      transport.respond(ok(shiftJson()));
      answer(transport, shift: shiftJson());

      await controller.open(150000);

      expect(analytics.logged.map((e) => e.$1), ['shift_opened']);
    });

    test('logs nothing when the server refuses to open one', () async {
      final (:controller, :transport, :analytics) = rig();
      answer(transport);
      await controller.load();
      transport.respond(failure(422, 'Shift sudah terbuka di outlet ini'));

      await controller.open(0);

      expect(analytics.logged, isEmpty);
    });

    test(
      'logs shift_open_blocked with already_open for the cashier\'s own drawer',
      () async {
        final (:controller, :transport, :analytics) = rig();
        answer(transport, shift: shiftJson());

        await controller.load();

        // Record equality is field-wise `==`, and `Map` is identity-only — so the parameters are
        // asserted separately (`analytics_test.dart` in `pn_types`).
        expect(analytics.logged.map((e) => e.$1), ['shift_open_blocked']);
        expect(analytics.logged.single.$2, {'reason': 'already_open'});
      },
    );

    test(
      'logs shift_open_blocked with held_by_other for another cashier\'s '
      'drawer, and once only even after a resume that changes nothing',
      () async {
        // Ownership is decided before the resumed check (`shift_gate.dart`), so another
        // cashier's shift is `heldByOther` the moment it is read — `resume()` cannot move it.
        final (:controller, :transport, :analytics) = rig();
        answer(transport, shift: shiftJson(cashierId: 'someone_else'));
        await controller.load();

        controller.resume();

        expect(analytics.logged.map((e) => e.$1), ['shift_open_blocked']);
        expect(analytics.logged.single.$2, {'reason': 'held_by_other'});
      },
    );

    test('does not repeat the event while the gate stays blocked', () async {
      final (:controller, :transport, :analytics) = rig();
      answer(transport, shift: shiftJson());
      await controller.load();

      // Reading again answers with the same gate: the cashier has not done anything new.
      answer(transport, shift: shiftJson());
      await controller.load();

      expect(
        analytics.logged.where((e) => e.$1 == 'shift_open_blocked'),
        hasLength(1),
      );
    });

    test('logs nothing while a shift is required and none is open', () async {
      final (:controller, :transport, :analytics) = rig();
      answer(transport);

      await controller.load();

      expect(analytics.logged, isEmpty);
    });
  });
}
