/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_tender.dart';
import 'package:pn_types/src/pos.dart';
import 'package:test/test.dart';

// Oracle port of `finnesia-monorepo/packages/shared/src/pos/pos-tender.test.ts`.
// Inputs and expectations copied unchanged. 26 cases.
TenderDraft cash(num amount) =>
    TenderDraft(id: 't1', method: POSTenderMethod.cash, amount: amount);

TenderDraft transfer(num amount, [String id = 't2']) =>
    TenderDraft(id: id, method: POSTenderMethod.transfer, amount: amount);

/// Unwraps a successful build, failing loudly on the other branch.
///
/// `TenderBuildResult` is a sealed class, so this replaces the `built.tenders!` the
/// TypeScript tests could not have written either — there is no null to assert on.
List<POSTenderDTO> ok(TenderBuildResult r) => switch (r) {
      TenderBuildOk(:final tenders) => tenders,
      TenderBuildFailed(:final problem) =>
        fail('expected tenders, got problem: ${problem.name}'),
    };

/// Unwraps a failed build, failing loudly on the other branch.
TenderProblem failed(TenderBuildResult r) => switch (r) {
      TenderBuildOk(:final tenders) =>
        fail('expected a problem, got ${tenders.length} tender(s)'),
      TenderBuildFailed(:final problem) => problem,
    };

void main() {
  group('POS_TENDER_METHODS', () {
    test('offers every method the server accepts', () {
      expect(
        posTenderMethods,
        equals([
          POSTenderMethod.cash,
          POSTenderMethod.transfer,
          POSTenderMethod.edc,
          POSTenderMethod.qris,
          POSTenderMethod.komplimen,
        ]),
      );
    });

    test('treats only cash as cash', () {
      expect(isCashTender(POSTenderMethod.cash), isTrue);
      expect(isCashTender(POSTenderMethod.qris), isFalse);
      expect(isCashTender(POSTenderMethod.edc), isFalse);
      expect(isCashTender(POSTenderMethod.komplimen), isFalse);
    });
  });

  group('hasCashTender', () {
    test('is true when at least one payment is cash', () {
      expect(hasCashTender(const ['TRANSFER', 'CASH']), isTrue);
    });

    test(
        'is false for a pure complimentary sale — no real cash tendered/change to print',
        () {
      expect(hasCashTender(const ['KOMPLIMEN']), isFalse);
    });

    test('is false for a non-cash-only sale (TRANSFER/EDC/QRIS)', () {
      expect(hasCashTender(const ['TRANSFER', 'EDC']), isFalse);
    });

    test('is false for an empty or missing payments list', () {
      expect(hasCashTender(const []), isFalse);
      expect(hasCashTender(null), isFalse);
    });

    // Not in the oracle. The source feeds this function the wire strings from
    // `sales_by_method`, which can carry a GIRO from a shift closed before 2026-09-09 —
    // a method `POSTenderMethod` no longer knows. Routing that through `tryParse` would
    // collapse "unknown" and "not cash" into the same null, and the two are only
    // accidentally equal here: GIRO is genuinely not cash, so the answer must be false
    // rather than a throw or a misread.
    test('treats an unknown historical method (GIRO) as not cash', () {
      expect(hasCashTender(const ['GIRO']), isFalse);
      expect(hasCashTender(const ['GIRO', 'CASH']), isTrue);
    });
  });

  group('tenderSummary', () {
    test('reports what is still owed', () {
      expect(
        tenderSummary([cash(30000)], 50000),
        equals(const TenderSummary(paid: 30000, remaining: 20000, change: 0)),
      );
    });

    test('reports change once the bill is covered', () {
      expect(
        tenderSummary([cash(100000)], 75000),
        equals(const TenderSummary(paid: 100000, remaining: 0, change: 25000)),
      );
    });

    // The point of split payment: part card, part cash.
    test('adds up a split tender', () {
      expect(
        tenderSummary([transfer(50000), cash(30000)], 80000),
        equals(const TenderSummary(paid: 80000, remaining: 0, change: 0)),
      );
    });

    test('ignores blank rows the cashier has not filled in yet', () {
      expect(
        tenderSummary([transfer(50000), cash(0)], 80000).remaining,
        equals(30000),
      );
    });
  });

  group('buildPOSTenders', () {
    test('sends one payment per tender row, in the order they were taken', () {
      final built = buildPOSTenders([transfer(50000), cash(30000)], 80000);
      expect(
        ok(built),
        equals(const [
          POSTenderDTO(method: POSTenderMethod.transfer, amount: 50000),
          POSTenderDTO(method: POSTenderMethod.cash, amount: 30000),
        ]),
      );
    });

    test('keeps a reference when one was typed', () {
      final built = buildPOSTenders(const [
        TenderDraft(
          id: 't1',
          method: POSTenderMethod.transfer,
          amount: 80000,
          reference: 'BCA 8891',
        ),
      ], 80000);
      expect(ok(built).first.reference, equals('BCA 8891'));
    });

    test('refuses a tender that does not cover the bill', () {
      expect(
        failed(buildPOSTenders([cash(30000)], 50000)),
        equals(TenderProblem.insufficient),
      );
    });

    // Change comes out of the drawer. A transfer of more than the bill is not change, it
    // is an unallocated receipt this flow does not create — and the server rejects it, so
    // the button has to know first.
    test('refuses an overpayment that cash cannot cover', () {
      expect(
        failed(buildPOSTenders([transfer(90000)], 80000)),
        equals(TenderProblem.overpaidNonCash),
      );
    });

    test('allows an overpayment as long as the cash part covers the change',
        () {
      expect(
        ok(buildPOSTenders([transfer(50000), cash(50000)], 80000)),
        isNotEmpty,
      );
    });

    test('refuses change larger than the cash taken, even on a split', () {
      // The transfer alone already overshoots the bill, so the drawer would have to hand
      // back more than the cash it took.
      expect(
        failed(buildPOSTenders([transfer(85000), cash(1000)], 80000)),
        equals(TenderProblem.overpaidNonCash),
      );
    });

    test('allows change that the cash part can actually cover on a split', () {
      // Transfer 79.000 + cash 2.000 against an 80.000 bill: 1.000 back out of the 2.000.
      expect(
        ok(buildPOSTenders([transfer(79000), cash(2000)], 80000)),
        isNotEmpty,
      );
    });

    test('drops rows the cashier left at zero', () {
      final built = buildPOSTenders([cash(80000), transfer(0)], 80000);
      expect(ok(built), hasLength(1));
    });

    test('refuses an empty tender', () {
      expect(
        failed(buildPOSTenders(const [], 80000)),
        equals(TenderProblem.insufficient),
      );
    });

    test('refuses a sale with nothing to pay for', () {
      expect(
        failed(buildPOSTenders([cash(0)], 0)),
        equals(TenderProblem.emptyCart),
      );
    });

    // Komplimen is a give-away, not cash in the drawer — it must behave like any other
    // non-cash tender for overpay/change purposes.
    test('accepts a complimentary tender that exactly covers the bill', () {
      final built = buildPOSTenders(const [
        TenderDraft(id: 't1', method: POSTenderMethod.komplimen, amount: 80000),
      ], 80000);
      expect(
        ok(built),
        equals(const [
          POSTenderDTO(method: POSTenderMethod.komplimen, amount: 80000),
        ]),
      );
    });

    test('refuses a complimentary overpayment cash cannot cover', () {
      expect(
        failed(
          buildPOSTenders(const [
            TenderDraft(
              id: 't1',
              method: POSTenderMethod.komplimen,
              amount: 90000,
            ),
          ], 80000),
        ),
        equals(TenderProblem.overpaidNonCash),
      );
    });
  });

  // Shared by the outlet override form and the company-wide POS settings page — both
  // store the same { method: coaId } shape and need identical set/clear behavior.
  group('setTenderMethodAccount', () {
    test('sets the account for a method on an empty map', () {
      expect(
        setTenderMethodAccount(null, POSTenderMethod.transfer, 'coa_1'),
        equals({'TRANSFER': 'coa_1'}),
      );
    });

    test('overwrites only the given method, leaving siblings untouched', () {
      const current = {'TRANSFER': 'coa_1', 'EDC': 'coa_2'};
      expect(
        setTenderMethodAccount(current, POSTenderMethod.edc, 'coa_3'),
        equals({'TRANSFER': 'coa_1', 'EDC': 'coa_3'}),
      );
    });

    test(
        'clears the override back to "use company default" when given an empty id',
        () {
      const current = {'TRANSFER': 'coa_1', 'EDC': 'coa_2'};
      expect(
        setTenderMethodAccount(current, POSTenderMethod.edc, ''),
        equals({'TRANSFER': 'coa_1'}),
      );
    });

    test('is a no-op clearing a method that was never set', () {
      expect(
        setTenderMethodAccount(
            const {'TRANSFER': 'coa_1'}, POSTenderMethod.edc, ''),
        equals({'TRANSFER': 'coa_1'}),
      );
    });
  });
}
