/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_tender.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pos/checkout/payment_controller.dart';

// S6/S7. The rules are `pn_pos`'s (`buildPOSTenders`, `tenderSummary`); this is the state
// around them: which row the cashier is editing, what the button says, and what happens to
// the basket afterwards. There is no test to port: the state and the confirm handler are one
// page's concern.

PaymentController open({num total = 15000}) =>
    PaymentController(grandTotal: total);

/// Unwraps a successful build, failing loudly on the other branch. `TenderBuildResult` is
/// sealed, so this is the pattern `pos_tender_test.dart` uses instead of a `!` on the money
/// path.
List<POSTenderDTO> tendersOf(TenderBuildResult r) => switch (r) {
  TenderBuildOk(:final tenders) => tenders,
  TenderBuildFailed(:final problem) => fail(
    'expected tenders, got problem: ${problem.name}',
  ),
};

/// The reason a build failed.
TenderProblem problemOf(TenderBuildResult r) => switch (r) {
  TenderBuildOk(:final tenders) => fail(
    'expected a problem, got ${tenders.length} tender(s)',
  ),
  TenderBuildFailed(:final problem) => problem,
};

void main() {
  group('opening the payment', () {
    test('starts with one cash row holding the exact total', () {
      final c = open();

      expect(c.tenders, hasLength(1));
      expect(c.tenders.single.method, POSTenderMethod.cash);
      // Most sales are one method, paid exactly, and typing the total again is the
      // commonest thing a cashier would otherwise have to do.
      expect(c.tenders.single.amount, 15000);
    });

    test('is ready to confirm straight away, and says why when it is not', () {
      expect(open().canConfirm, isTrue);
      // The reason is shown, not just the disabled button: a button that refuses without
      // saying why is the cashier's problem to guess.
      expect(open().problem, isNull);
    });

    test('cannot confirm an empty basket', () {
      final c = open(total: 0);

      expect(c.canConfirm, isFalse);
      expect(c.problem, TenderProblem.emptyCart);
    });
  });

  group('editing a row', () {
    test('a cash row below the total leaves a remainder', () {
      final c = open();
      c.setAmount(c.tenders.single.id, 10000);

      expect(c.summary.remaining, 5000);
      expect(c.canConfirm, isFalse);
      expect(c.problem, TenderProblem.insufficient);
    });

    test('a cash row above the total gives change', () {
      final c = open();
      c.setAmount(c.tenders.single.id, 20000);

      expect(c.summary.change, 5000);
      expect(c.canConfirm, isTrue);
    });

    test(
      'changing the method to a non-cash one clamps the amount to the total',
      () {
        final c = open();
        c.setAmount(c.tenders.single.id, 20000);
        c.setMethod(c.tenders.single.id, POSTenderMethod.transfer);

        // Only the drawer gives change, so an amount above the bill on a transfer is an
        // unallocated receipt this flow does not create (`pos_tender.dart`).
        expect(c.tenders.single.amount, 15000);
        expect(c.summary.change, 0);
        expect(c.canConfirm, isTrue);
      },
    );

    test('a non-cash row above the total is refused', () {
      final c = open();
      c.setMethod(c.tenders.single.id, POSTenderMethod.transfer);
      c.setAmount(c.tenders.single.id, 20000);

      expect(c.problem, TenderProblem.overpaidNonCash);
      expect(c.canConfirm, isFalse);
    });

    test('a reference is kept for a non-cash row and dropped for cash', () {
      final c = open();
      final id = c.tenders.single.id;

      c.setMethod(id, POSTenderMethod.transfer);
      c.setReference(id, 'TRX-99');
      expect(c.tenders.single.reference, 'TRX-99');

      c.setMethod(id, POSTenderMethod.cash);
      // A cash row has no reference field, so a stale one must not be sent.
      expect(c.tenders.single.reference, isNull);
    });

    test('a row left at zero is not a payment', () {
      final c = open();
      c.addRow();
      // The new row starts at what is left, which is nothing: the first row already
      // covers the bill.
      expect(c.tenders, hasLength(2));
      expect(c.canConfirm, isTrue);
      expect(tendersOf(c.buildTenders()), hasLength(1));
    });

    test('editing a row that is gone does nothing', () {
      final c = open();
      c.setAmount('nope', 5000);

      expect(c.tenders.single.amount, 15000);
    });
  });

  group('more than one method', () {
    test('adds a non-cash row for whatever is left', () {
      final c = open();
      c.setAmount(c.tenders.single.id, 5000);
      c.addRow();

      expect(c.tenders, hasLength(2));
      expect(c.tenders.last.method, POSTenderMethod.transfer);
      expect(c.tenders.last.amount, 10000);
      expect(c.canConfirm, isTrue);
    });

    test('splitting cash and transfer covers the bill between them', () {
      final c = open();
      c.setAmount(c.tenders.single.id, 5000);
      c.addRow();
      c.setAmount(c.tenders.last.id, 10000);

      expect(c.summary.paid, 15000);
      expect(c.summary.remaining, 0);
      expect(c.canConfirm, isTrue);
      expect(tendersOf(c.buildTenders()), hasLength(2));
    });

    test('removes a row, and refuses to remove the last one', () {
      final c = open();
      c.addRow();
      c.removeRow(c.tenders.last.id);
      expect(c.tenders, hasLength(1));

      // A payment with no rows has nothing to edit and no way back to a row: the screen
      // would be stuck with no field to type in.
      c.removeRow(c.tenders.single.id);
      expect(c.tenders, hasLength(1));
    });
  });

  group('the exact-amount button', () {
    test('fills a cash row with what is still owed on it', () {
      final c = open();
      final id = c.tenders.single.id;
      c.setAmount(id, 1000);
      c.fillExact(id);

      expect(c.tenders.single.amount, 15000);
      expect(c.canConfirm, isTrue);
    });

    test('does not turn a transfer into change-giving', () {
      final c = open();
      c.setAmount(c.tenders.single.id, 5000);
      c.addRow();
      c.fillExact(c.tenders.last.id);

      // The remainder after the cash row, not the whole bill: filling the whole bill
      // would leave the cash row as change on a transfer.
      expect(c.tenders.last.amount, 10000);
      expect(c.summary.change, 0);
    });
  });

  group('building the payload', () {
    test('names the problem instead of throwing when it cannot be built', () {
      final c = open();
      c.setAmount(c.tenders.single.id, 1000);

      expect(problemOf(c.buildTenders()), TenderProblem.insufficient);
    });

    test('sends the rows that were filled in, and their references', () {
      final c = open();
      c.setAmount(c.tenders.single.id, 5000);
      c.addRow();
      c.setReference(c.tenders.last.id, '  TRX-99  ');

      final tenders = tendersOf(c.buildTenders());

      expect(tenders, hasLength(2));
      expect(tenders.first.method, POSTenderMethod.cash);
      expect(tenders.first.amount, 5000);
      // Trimmed, and a whitespace-only reference is absent rather than empty: the
      // server reads an empty string as a value, not as "no reference".
      expect(tenders.last.reference, 'TRX-99');
    });
  });
}
