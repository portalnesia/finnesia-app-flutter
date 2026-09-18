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
import 'package:pn_types/src/master_data.dart';
import 'package:pn_types/src/native/analytics_fake.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/shift/cash_movement_controller.dart';
import 'package:pos/state/loadable.dart';

// Written new. `cash-movement-dialog.tsx` keeps this in `useState` and four `useQuery`s. What is
// ported is the rules it states and the reasons it gives: the account is required once the
// company has a drawer account (there is no safe default for the other side of the journal), and
// the form may not be submitted while the setting that decides that is still being read.

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

Map<String, Object?> accountJson(String id, String code, String name) => {
  'id': id,
  'code': code,
  'name': name,
};

/// What opening the form reads, in the order it starts the reads.
void opening(
  FakeApiTransport transport, {
  String? cashAccountId,
  List<Map<String, Object?>>? accounts,
}) {
  transport.respond(
    ok({'require_shift': true, 'cash_account_id': ?cashAccountId}),
  );
  transport.respond(ok(accounts ?? [accountJson('a1', '1-1000', 'Kas Kecil')]));
}

({
  CashMovementController controller,
  FakeApiTransport transport,
  FakeAnalytics analytics,
})
rig({Duration debounce = Duration.zero}) {
  final transport = FakeApiTransport();
  final analytics = FakeAnalytics();
  final controller = CashMovementController(
    client: ApiClient(transport: transport, language: () => 'id'),
    shiftId: 's1',
    debounce: debounce,
    analytics: analytics,
  );
  addTearDown(controller.dispose);
  return (controller: controller, transport: transport, analytics: analytics);
}

Uri uriOf(TransportRequest request) => Uri.parse(request.path);

void main() {
  rules();
  searching();
  submitting();
  group('opening the form', () {
    test(
      'reads the settings and the first page of accounts, once each',
      () async {
        final (:controller, :transport, analytics: _) = rig();
        opening(transport);

        await controller.open();

        final paths = transport.requests.map((r) => uriOf(r).path).toList();
        expect(paths, ['/api/v1/pos/settings', '/api/v1/master/coa']);
        expect(uriOf(transport.requests[1]).queryParameters, {
          'page_size': '50',
        });
        expect(controller.settings.state, isA<Ready<dynamic>>());
        expect(controller.accounts.state, isA<Ready<dynamic>>());
      },
    );
  });
}

void rules() {
  group('when it may be submitted', () {
    test('tells its listeners when the settings arrive, since whether it '
        'may be submitted depends on them', () async {
      final (:controller, :transport, analytics: _) = rig();
      opening(transport);
      var told = 0;
      controller.addListener(() => told++);

      await controller.open();

      expect(told, greaterThan(0));
    });

    test('starts as cash out, the most common of the three', () {
      final (:controller, transport: _, analytics: _) = rig();

      expect(controller.type, CashMovementType.cashOut);

      controller.setType(CashMovementType.drop);
      expect(controller.type, CashMovementType.drop);
    });

    test('needs an amount above zero and a reason', () async {
      final (:controller, :transport, analytics: _) = rig();
      opening(transport);
      await controller.open();
      expect(controller.canSubmit, isFalse);

      controller.setAmount(5000);
      expect(controller.canSubmit, isFalse); // no reason yet

      controller.setReason('Beli galon');
      expect(controller.canSubmit, isTrue);

      controller.setAmount(0);
      expect(controller.canSubmit, isFalse);
    });

    test('a reason of spaces is no reason', () async {
      final (:controller, :transport, analytics: _) = rig();
      opening(transport);
      await controller.open();
      controller.setAmount(5000);

      controller.setReason('   ');

      expect(controller.canSubmit, isFalse);
    });

    test('waits for the settings: while the account looks optional, '
        'submitting would be refused after everything was typed', () {
      final (:controller, transport: _, analytics: _) = rig();
      controller.setAmount(5000);
      controller.setReason('Beli galon');

      // Not opened, so the setting that decides whether an account is required is unread.
      expect(controller.canSubmit, isFalse);
    });

    test('once the company has a drawer account, the other side of the journal '
        'has to be picked', () async {
      final (:controller, :transport, analytics: _) = rig();
      opening(transport, cashAccountId: 'drawer');
      await controller.open();
      controller.setAmount(5000);
      controller.setReason('Beli galon');

      expect(controller.requireAccount, isTrue);
      expect(controller.canSubmit, isFalse);

      controller.pickAccount(
        ChartOfAccount.fromJson(accountJson('a1', '1-1000', 'Kas Kecil')),
      );
      expect(controller.canSubmit, isTrue);

      controller.pickAccount(null);
      expect(controller.canSubmit, isFalse);
    });

    test('a company with no drawer account does not require one', () async {
      final (:controller, :transport, analytics: _) = rig();
      opening(transport);
      await controller.open();

      expect(controller.requireAccount, isFalse);
    });

    test('settings that could not be read mean it cannot be submitted: not '
        'knowing is not "optional"', () async {
      final (:controller, :transport, analytics: _) = rig();
      transport.respond(refused(500, 'Gagal'));
      transport.respond(ok(<Object?>[]));
      await controller.open();
      controller.setAmount(5000);
      controller.setReason('Beli galon');

      expect(controller.canSubmit, isFalse);
    });
  });
}

Map<String, Object?> bodyOf(TransportRequest request) =>
    jsonDecode(request.body!) as Map<String, Object?>;

Future<CashMovementController> ready(
  FakeApiTransport transport,
  CashMovementController controller, {
  String? cashAccountId,
}) async {
  opening(transport, cashAccountId: cashAccountId);
  await controller.open();
  controller.setAmount(5000);
  controller.setReason('  Beli galon ');
  if (cashAccountId != null) {
    controller.pickAccount(
      ChartOfAccount.fromJson(accountJson('a1', '1-1000', 'Kas Kecil')),
    );
  }
  return controller;
}

void submitting() {
  group('recording it', () {
    test('sends the movement to that shift, with the reason trimmed and no '
        'account when none was picked', () async {
      final (:controller, :transport, analytics: _) = rig();
      await ready(transport, controller);
      transport.respond(ok(null));

      await controller.submit();

      final request = transport.requests.last;
      expect(request.method.wire, 'POST');
      expect(request.path, '/api/v1/pos/shifts/s1/cash-movement');
      expect(bodyOf(request), {
        'type': 'CASH_OUT',
        'amount': 5000,
        'reason': 'Beli galon',
      });
      expect(controller.isRecorded, isTrue);
    });

    test('sends the picked account', () async {
      final (:controller, :transport, analytics: _) = rig();
      await ready(transport, controller, cashAccountId: 'drawer');
      transport.respond(ok(null));

      await controller.submit();

      expect(bodyOf(transport.requests.last)['account_id'], 'a1');
    });

    test('refuses to send what the rules do not allow: the button is disabled, '
        'so getting here is a bug', () async {
      final (:controller, :transport, analytics: _) = rig();
      opening(transport);
      await controller.open();

      await expectLater(controller.submit(), throwsStateError);

      expect(transport.requests, hasLength(2)); // only the opening reads
      expect(controller.isRecorded, isFalse);
    });

    test('asked again while it is sending, it sends nothing more: a double '
        'tap must not record twice', () async {
      final (:controller, :transport, analytics: _) = rig();
      await ready(transport, controller);
      transport.respond(ok(null));

      final first = controller.submit();
      expect(controller.isSubmitting, isTrue);
      final second = controller.submit();
      await Future.wait([first, second]);

      expect(
        transport.requests.where((r) => r.method.wire == 'POST'),
        hasLength(1),
      );
      expect(controller.isSubmitting, isFalse);
    });

    test('a refusal is a problem in the words the server gave, and nothing is '
        'recorded', () async {
      final (:controller, :transport, analytics: _) = rig();
      await ready(transport, controller);
      transport.respond(refused(422, 'Akun tidak valid'));

      await controller.submit();

      expect(controller.isRecorded, isFalse);
      expect(controller.problem?.message, 'Akun tidak valid');
      expect(controller.problem?.mayHaveSucceeded, isFalse);
    });

    test('no answer, or a server error, may have recorded it', () async {
      final silent = rig();
      await ready(silent.transport, silent.controller);
      silent.transport.fail(TransportException('offline'));
      await silent.controller.submit();
      expect(silent.controller.problem?.mayHaveSucceeded, isTrue);
      expect(silent.controller.problem?.message, isNull);

      final broken = rig();
      await ready(broken.transport, broken.controller);
      broken.transport.respond(refused(500, 'Gagal'));
      await broken.controller.submit();
      expect(broken.controller.problem?.mayHaveSucceeded, isTrue);
    });

    test(
      'trying again after a failure sends again and forgets the problem',
      () async {
        final (:controller, :transport, analytics: _) = rig();
        await ready(transport, controller);
        transport.respond(refused(422, 'Ditolak'));
        transport.respond(ok(null));
        await controller.submit();

        await controller.submit();

        expect(controller.problem, isNull);
        expect(controller.isRecorded, isTrue);
      },
    );
  });

  group('analytics', () {
    test('logs cash_movement_recorded with the type', () async {
      final (:controller, :transport, :analytics) = rig();
      await ready(transport, controller);
      transport.respond(ok(null));

      await controller.submit();

      expect(analytics.logged.map((e) => e.$1), ['cash_movement_recorded']);
      expect(analytics.logged.single.$2, {'type': 'cashOut'});
    });

    test('logs nothing when the server refuses', () async {
      final (:controller, :transport, :analytics) = rig();
      await ready(transport, controller);
      transport.respond(refused(422, 'Akun tidak valid'));

      await controller.submit();

      expect(analytics.logged, isEmpty);
    });
  });
}

void searching() {
  group('searching the accounts', () {
    test(
      'asks the server once the typing stops, not for every letter',
      () async {
        final (:controller, :transport, analytics: _) = rig();
        opening(transport);
        await controller.open();

        controller.setAccountSearch('k');
        controller.setAccountSearch('ka');
        controller.setAccountSearch('kas');
        transport.respond(ok([accountJson('a2', '1-1100', 'Kas Besar')]));
        await Future<void>.delayed(const Duration(milliseconds: 60));

        final searches = transport.requests.skip(2).toList();
        expect(searches, hasLength(1));
        expect(uriOf(searches.single).queryParameters, {
          'q': 'kas',
          'page_size': '50',
        });
        final found = (controller.accounts.state as Ready<List<dynamic>>).data;
        expect(found.single.name, 'Kas Besar');
      },
    );

    test('clearing the search lists the first page again', () async {
      final (:controller, :transport, analytics: _) = rig();
      opening(transport);
      await controller.open();
      controller.setAccountSearch('kas');
      transport.respond(ok(<Object?>[]));
      await Future<void>.delayed(const Duration(milliseconds: 60));

      controller.setAccountSearch('');
      transport.respond(ok([accountJson('a1', '1-1000', 'Kas Kecil')]));
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(uriOf(transport.requests.last).queryParameters, {
        'page_size': '50',
      });
    });

    test('text that comes to the same thing is not asked for again', () async {
      final (:controller, :transport, analytics: _) = rig();
      opening(transport);
      await controller.open();
      controller.setAccountSearch('kas');
      transport.respond(ok(<Object?>[]));
      await Future<void>.delayed(const Duration(milliseconds: 60));

      controller.setAccountSearch('kas ');
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(transport.requests, hasLength(3));
    });
  });
}
