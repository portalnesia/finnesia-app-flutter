/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_checkout.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_tender.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/product.dart';
import 'package:pos/checkout/checkout_service.dart';
import 'package:pos/checkout/payment_controller.dart';

// The seam between the payment screen and `CheckoutService`: what the cashier sees when the
// sale is recorded, refused, or queued. `CheckoutService`'s own rules are covered by
// `checkout_service_test.dart`; this is what the screen does with its answer.

/// A queued entry, for the outcome's own tests. The row's contents are the till's business and
/// are covered where it is built (`buildPendingSale`); what matters here is that the outcome
/// carries one.
PendingSale entryFor(String ref) => PendingSale(
  clientRef: ref,
  companyId: 'comp_1',
  outletId: 'o1',
  cashierId: 'u1',
  shiftId: 's1',
  status: PendingSaleStatus.pending,
  paidAt: '2026-09-20T03:00:00.000Z',
  createdAt: '2026-09-20T03:00:00.000Z',
  payload: const POSCheckoutDTO(
    outletId: 'o1',
    transactionDate: '2026-09-20',
    items: [],
    payments: [],
  ),
  receipt: const PendingSaleReceipt(
    subtotal: 15000,
    discountAmount: 0,
    taxAmount: 0,
    grandTotal: 15000,
    tenderedAmount: 20000,
    changeAmount: 5000,
    items: [],
  ),
);

final lines = [
  CartLine(
    id: 'line_1',
    product: const Product(
      id: 'p1',
      name: 'Kopi',
      unitId: 'u1',
      sellPrice: 15000,
    ),
    qty: 1,
  ),
];

const sale = POSSale(
  id: 'x1',
  number: 'POS-0001',
  shiftId: 's1',
  outletId: 'o1',
  cashierId: 'u1',
  transactionDate: '2026-09-20',
  subtotal: 15000,
  discountAmount: 0,
  taxAmount: 0,
  grandTotal: 15000,
  tenderedAmount: 20000,
  changeAmount: 5000,
  status: POSSaleStatus.posted,
  createdAt: '2026-09-20T03:00:00Z',
);

/// Unwraps a successful build, failing loudly on the other branch (sealed, so there is no
/// null to assert on).
List<POSTenderDTO> tendersOf(TenderBuildResult r) => switch (r) {
  TenderBuildOk(:final tenders) => tenders,
  TenderBuildFailed(:final problem) => fail(
    'expected tenders, got problem: ${problem.name}',
  ),
};

POSCheckoutDTO payloadFor({
  required List<TenderDraft> tenders,
  num total = 15000,
}) => buildCheckoutPayload(
  shiftId: 's1',
  outletId: 'o1',
  customerId: '',
  notes: '',
  tableNumber: '',
  queueNumber: '',
  discountAmount: 0,
  transactionDate: '2026-09-20',
  lines: lines,
  payments: tendersOf(buildPOSTenders(tenders, total)),
);

void main() {
  group('a sale the server records', () {
    test('hands back the sale, with the change the drawer owes', () async {
      final c = PaymentController(grandTotal: 15000);
      c.setAmount(c.tenders.single.id, 20000);

      final outcome = await c.submit(
        submit: (_) async => CheckoutSynced(sale),
        payload: payloadFor(tenders: c.tenders),
      );

      expect(outcome, isA<CheckoutSynced>());
      // The change the cashier reads out is the server's figure, not a local subtraction:
      // if the two ever disagree, the drawer is short and the app must not hide it.
      expect((outcome as CheckoutSynced).sale.changeAmount, 5000);
    });

    test('is not paying any more once it is done', () async {
      final c = PaymentController(grandTotal: 15000);

      await c.submit(
        submit: (_) async => CheckoutSynced(sale),
        payload: payloadFor(tenders: c.tenders),
      );

      expect(c.isPaying, isFalse);
    });
  });

  group('a sale the server refuses', () {
    test('keeps the rows so the cashier can fix what was refused', () async {
      final c = PaymentController(grandTotal: 15000);
      final id = c.tenders.single.id;
      c.setAmount(id, 20000);

      final outcome = await c.submit(
        submit: (_) async =>
            CheckoutRejected('Akun TRANSFER belum dipetakan', 422),
        payload: payloadFor(tenders: c.tenders),
      );

      expect(outcome, isA<CheckoutRejected>());
      expect(c.tenders.single.amount, 20000);
      expect(c.isPaying, isFalse);
      // Nothing was recorded, so the button is usable again at once.
      expect(c.canConfirm, isTrue);
    });
  });

  group('a sale nobody can confirm', () {
    test('says so without claiming the money was lost', () async {
      final c = PaymentController(grandTotal: 15000);

      final outcome = await c.submit(
        submit: (_) async => CheckoutQueued(entryFor('REF-1')),
        payload: payloadFor(tenders: c.tenders),
      );

      // The distinction is the whole point of the three outcomes: the cashier has taken
      // money and has to know whether it is recorded (`checkout_service.dart`).
      expect(outcome, isA<CheckoutQueued>());
      expect(c.isPaying, isFalse);
    });

    test(
      'stops paying even when the call throws something nobody expected',
      () async {
        final c = PaymentController(grandTotal: 15000);

        await expectLater(
          c.submit(
            submit: (_) async => throw StateError('bug'),
            payload: payloadFor(tenders: c.tenders),
          ),
          throwsA(isA<StateError>()),
        );

        // A bug must stay loud, but the screen may not be left stuck on "Memproses…".
        expect(c.isPaying, isFalse);
      },
    );
  });

  group('the payload it sends', () {
    test(
      'carries the rows the cashier confirmed, not the ones before the edit',
      () async {
        final c = PaymentController(grandTotal: 15000);
        c.setAmount(c.tenders.single.id, 5000);
        c.addRow();
        c.setReference(c.tenders.last.id, 'TRX-1');
        POSCheckoutDTO? sent;

        await c.submit(
          submit: (payload) async {
            sent = payload;
            return CheckoutSynced(sale);
          },
          payload: payloadFor(tenders: c.tenders),
        );

        expect(sent!.payments, hasLength(2));
        expect(sent!.payments.last.reference, 'TRX-1');
        expect(sent!.payments.fold<num>(0, (sum, p) => sum + p.amount), 15000);
      },
    );

    test('refuses to send a basket that does not add up', () async {
      final c = PaymentController(grandTotal: 15000);
      c.setAmount(c.tenders.single.id, 1000);
      var called = false;

      // The payload is built by the caller, so it is built here for a basket that is short.
      // `payloadFor` unwraps the builder, which would fail first and hide what is being
      // tested; the short basket is expressed with a payload that simply exists.
      final short = payloadFor(
        tenders: [
          TenderDraft(id: 't', method: POSTenderMethod.cash, amount: 15000),
        ],
      );

      await expectLater(
        c.submit(
          submit: (_) async {
            called = true;
            return CheckoutSynced(sale);
          },
          payload: short,
        ),
        throwsA(isA<StateError>()),
      );

      // The screen disables the button in this state; reaching here is a bug, and it must
      // not be turned into a sale that is short by 14.000.
      expect(called, isFalse);
    });
  });

  group('an error that is not an answer from the server', () {
    test('is not turned into an outcome', () async {
      final c = PaymentController(grandTotal: 15000);

      await expectLater(
        c.submit(
          submit: (_) async => throw ApiError('not JSON at all', status: 200),
          payload: payloadFor(tenders: c.tenders),
        ),
        throwsA(isA<ApiError>()),
      );
    });
  });
}
