/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/product.dart';
import 'package:pos/checkout/checkout_service.dart';
import 'package:pos/screens/payment/done_screen.dart';
import 'package:pos/screens/payment/payment_screen.dart';

import '../../support/app_harness.dart';

// S6 and S7. Behaviour from `payment-dialog.tsx` and `change-dialog.tsx`; the layout is this
// app's own (a full screen with the keypad in it, not a dialog over the catalogue).
//
// The controller's own rules are covered by `payment_controller_test.dart`; this is what the
// cashier sees and taps.

const saleJson = '''
{"id":"x1","number":"POS-0001","shift_id":"s1","outlet_id":"o1","cashier_id":"u1",
 "transaction_date":"2026-09-20","subtotal":15000,"discount_amount":0,"tax_amount":0,
 "grand_total":15000,"tendered_amount":20000,"change_amount":5000,
 "status":"POSTED","created_at":"2026-09-20T03:00:00Z"}''';

final sale = POSSale.fromJson(jsonDecode(saleJson) as Map<String, dynamic>);

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

/// A queued sale, as `buildPendingSale` would write it at the moment of payment.
///
/// The ref is 26 characters so the short code below it can be checked: the last six are what
/// goes on the slip.
const queuedEntry = PendingSale(
  clientRef: '01J00000000000000000ABCDE',
  companyId: 'comp_1',
  outletId: 'o1',
  cashierId: 'u1',
  shiftId: 's1',
  status: PendingSaleStatus.pending,
  paidAt: '2026-09-20T03:00:00.000Z',
  createdAt: '2026-09-20T03:00:00.000Z',
  payload: POSCheckoutDTO(
    outletId: 'o1',
    transactionDate: '2026-09-20',
    items: [],
    payments: [POSTenderDTO(method: POSTenderMethod.cash, amount: 20000)],
  ),
  receipt: PendingSaleReceipt(
    outletName: 'Outlet Pusat',
    cashierName: 'Putu',
    subtotal: 15000,
    discountAmount: 0,
    taxAmount: 0,
    grandTotal: 15000,
    tenderedAmount: 20000,
    changeAmount: 5000,
    items: [],
  ),
);

/// A payment screen over a controller, with [submit] standing in for the network.
///
/// The date is given, not read from the clock: a test that built a payload on the wall clock
/// would produce a different sale every day it ran.
Widget paymentScreen({
  num total = 15000,
  Future<CheckoutOutcome> Function(
    POSCheckoutDTO payload, {
    required PendingSale Function(String clientRef) entry,
  })?
  submit,
  void Function(POSCheckoutDTO payload)? onSent,
  void Function(CheckoutOutcome outcome)? onDone,
}) => harness(
  PaymentScreen(
    grandTotal: total,
    lines: lines,
    shiftId: 's1',
    outletId: 'o1',
    companyId: 'comp_1',
    cashierId: 'user_1',
    outletName: 'Outlet Pusat',
    cashierName: 'Putu',
    transactionDate: '2026-09-20',
    onCancel: () {},
    submit: submit ?? (payload, {required entry}) async => CheckoutSynced(sale),
    onSent: onSent,
    onDone: onDone,
  ),
);

/// Types digits into the payment keypad, the way a cashier does.
Future<void> type(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.widgetWithText(InkWell, d).first);
    await tester.pump();
  }
}

void main() {
  group('what the cashier sees', () {
    testWidgets('shows the total, and starts on one cash row for it', (
      tester,
    ) async {
      await tester.pumpWidget(paymentScreen());
      await tester.pumpAndSettle();

      expect(find.text('Rp 15.000'), findsWidgets);
      expect(find.text('Tunai'), findsOneWidget);
      // The amount starts at the exact total, so most sales are one tap.
      expect(find.text('Rp 15.000'), findsWidgets);
    });

    testWidgets('says the payment is short, and by how much', (tester) async {
      await tester.pumpWidget(paymentScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tender-amount')));
      await tester.pumpAndSettle();
      await type(tester, '10000');

      // The reason is on screen, not only the disabled button.
      expect(find.textContaining('Rp 5.000'), findsWidgets);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('confirm-payment')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('says a non-cash row cannot exceed the bill', (tester) async {
      await tester.pumpWidget(paymentScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tender-amount')));
      await tester.pumpAndSettle();
      await type(tester, '20000');

      expect(find.textContaining('non-tunai'), findsOneWidget);
    });

    testWidgets('shows the change once the drawer covers the bill', (
      tester,
    ) async {
      // A tablet, because that is what the till runs on: at the default 800x600 test viewport
      // the keypad covers the quick amounts, and the tap would land on the pad instead.
      await tester.useSize(const Size(1280, 800));
      await tester.pumpWidget(paymentScreen());
      await tester.pumpAndSettle();

      // The quick-amount button, not the text: the same string appears in the ledger, and
      // tapping a figure is not how a cashier pays.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Rp 20.000'));
      await tester.pumpAndSettle();

      expect(find.text('Rp 5.000'), findsWidgets);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('confirm-payment')),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('confirming', () {
    testWidgets('sends the rows that were on screen', (tester) async {
      POSCheckoutDTO? sent;
      await tester.pumpWidget(
        paymentScreen(
          submit: (p, {required entry}) async {
            sent = p;
            return CheckoutSynced(sale);
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      expect(sent, isNotNull);
      expect(sent!.outletId, 'o1');
      expect(sent!.shiftId, 's1');
      expect(sent!.payments.single.amount, 15000);
      expect(sent!.items.single.productId, 'p1');
    });

    testWidgets('does not send twice when the button is tapped twice', (
      tester,
    ) async {
      var calls = 0;
      // The request is held open, so a second tap really does land while the first is out.
      final release = Completer<CheckoutOutcome>();
      await tester.pumpWidget(
        paymentScreen(
          submit: (_, {required entry}) {
            calls++;
            return release.future;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm-payment')));
      // A frame, because that is what a finger gives: `tester.tap` twice with no pump in
      // between only ever delivers the first tap, so a test written that way passes with no
      // guard at all (measured: one call, guard removed).
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('confirm-payment')),
        warnIfMissed: false,
      );
      await tester.pump();

      // Two taps must not take the money twice.
      expect(calls, 1);

      release.complete(CheckoutSynced(sale));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'takes the money again after a refusal, but not while one is out',
      (tester) async {
        var calls = 0;
        final first = Completer<CheckoutOutcome>();
        final second = Completer<CheckoutOutcome>();
        await tester.pumpWidget(
          paymentScreen(
            submit: (_, {required entry}) {
              calls++;
              return calls == 1 ? first.future : second.future;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm-payment')));
        await tester.pump();
        // While the first is still out, nothing more is sent.
        expect(calls, 1);

        // The server refused, so nothing was recorded and the cashier may try again.
        first.complete(CheckoutRejected('ditolak', 422));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm-payment')));
        await tester.pump();
        expect(calls, 2);

        second.complete(CheckoutSynced(sale));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('hands the sale on when the server records it', (tester) async {
      CheckoutOutcome? done;
      await tester.pumpWidget(paymentScreen(onDone: (o) => done = o));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      expect(done, isA<CheckoutSynced>());
      expect((done! as CheckoutSynced).sale.number, 'POS-0001');
    });
  });

  group('when the sale is not recorded', () {
    testWidgets('shows the sentence the server wrote, unchanged', (
      tester,
    ) async {
      CheckoutOutcome? done;
      await tester.pumpWidget(
        paymentScreen(
          submit: (_, {required entry}) async => CheckoutRejected(
            'Akun untuk metode TRANSFER belum dipetakan',
            422,
          ),
          onDone: (o) => done = o,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      // The cashier cannot fix an unmapped account; only the server's sentence says what
      // is wrong (F14).
      expect(
        find.text('Akun untuk metode TRANSFER belum dipetakan'),
        findsOneWidget,
      );
      expect(done, isNull);
    });

    testWidgets('keeps the rows so the cashier can fix and try again', (
      tester,
    ) async {
      await tester.pumpWidget(
        paymentScreen(
          submit: (_, {required entry}) async =>
              CheckoutRejected('ditolak', 422),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      // Still on the payment screen, with the money still on it.
      expect(find.byKey(const Key('confirm-payment')), findsOneWidget);
      expect(find.text('Rp 15.000'), findsWidgets);
    });

    testWidgets('moves the cashier on when the sale is written to the queue', (
      tester,
    ) async {
      CheckoutOutcome? done;
      await tester.pumpWidget(
        paymentScreen(
          submit: (payload, {required entry}) async =>
              CheckoutQueued(entry('REF-1')),
          onDone: (o) => done = o,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      // A queued sale is written down, so the customer can be given their change and their
      // receipt while the queue drains: the screen pops rather than leaving the cashier on a
      // form for a sale that has already left the shop.
      expect(find.byKey(const Key('confirm-payment')), findsNothing);
      // `onDone` is not called: that callback is the till's signal that a sale was **recorded**,
      // and a queued sale is not.
      expect(done, isNull);
    });
  });

  group('when the tablet cannot write the sale down at all', () {
    Widget writeFailure() => paymentScreen(
      submit: (_, {required entry}) async =>
          throw PendingSaleStoreException('disk full (fake)'),
    );

    testWidgets('says so, and stays on the payment screen', (tester) async {
      await tester.pumpWidget(writeFailure());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      // Nothing was recorded and nothing was queued: the money is still on the screen, and the
      // cashier may try again once whatever is wrong with the tablet's storage is fixed.
      expect(find.byKey(const Key('confirm-payment')), findsOneWidget);
      expect(find.text('Rp 15.000'), findsWidgets);
      expect(
        find.text(
          'Penjualan tidak bisa disimpan di tablet ini. Uang belum tercatat '
          '— jangan serahkan barang. Coba lagi.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('is announced to a screen reader when it appears', (
      tester,
    ) async {
      await tester.pumpWidget(writeFailure());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find.text(
          'Penjualan tidak bisa disimpan di tablet ini. Uang belum tercatat '
          '— jangan serahkan barang. Coba lagi.',
        ),
      );
      expect(semantics.flagsCollection.isLiveRegion, isTrue);
    });

    testWidgets('goes away once the cashier changes the amount', (
      tester,
    ) async {
      await tester.pumpWidget(writeFailure());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      await type(tester, '1');

      expect(
        find.textContaining('Penjualan tidak bisa disimpan'),
        findsNothing,
      );
    });

    testWidgets('can be tried again', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        paymentScreen(
          submit: (_, {required entry}) async {
            calls++;
            if (calls == 1) throw PendingSaleStoreException('disk full');
            return CheckoutSynced(sale);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.byKey(const Key('confirm-payment')), findsNothing);
    });
  });

  group('the done screen', () {
    Widget done({VoidCallback? onNewSale}) =>
        harness(DoneScreen(sale: sale, onNewSale: onNewSale ?? () {}));

    testWidgets('shows the change, big, and the figures behind it', (
      tester,
    ) async {
      await tester.pumpWidget(done());
      await tester.pumpAndSettle();

      expect(find.text('Rp 5.000'), findsOneWidget);
      expect(find.text('POS-0001'), findsOneWidget);
      expect(find.text('Rp 20.000'), findsOneWidget);
    });

    testWidgets('waits to be dismissed rather than fading away', (
      tester,
    ) async {
      var started = false;
      await tester.pumpWidget(done(onNewSale: () => started = true));

      // Nothing happens on its own: a toast that fades while the cashier is counting out
      // notes is money out of the drawer.
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Rp 5.000'), findsOneWidget);
      expect(started, isFalse);

      await tester.tap(find.text('Transaksi Baru'));
      await tester.pumpAndSettle();
      expect(started, isTrue);
    });
  });

  // D-Q3: a sale that has not been sent still gets a slip, and that slip must not pretend to be
  // a recorded one. The goods and the change come from the copy the till wrote, because there is
  // no server record to read them from.
  group('the done screen, for a sale that is still queued', () {
    Widget queued({VoidCallback? onNewSale}) => harness(
      DoneScreen(pending: queuedEntry, onNewSale: onNewSale ?? () {}),
    );

    testWidgets('shows the change the tablet worked out', (tester) async {
      await tester.pumpWidget(queued());
      await tester.pumpAndSettle();

      expect(find.text('Rp 5.000'), findsOneWidget);
      expect(find.text('Rp 15.000'), findsOneWidget);
      expect(find.text('Rp 20.000'), findsOneWidget);
    });

    testWidgets('never invents a transaction number', (tester) async {
      // Only the server issues numbers, and they are sequential and shared by every tablet: a
      // local "last + 1" would collide with a real sale's, and two slips with one number cannot
      // be told apart afterwards (`plan/offline-queue/README.md` D-Q3).
      await tester.pumpWidget(queued());
      await tester.pumpAndSettle();

      expect(find.text('POS-0001'), findsNothing);
      expect(find.text('SEMENTARA'), findsOneWidget);
    });

    testWidgets('carries a short code that ties the slip to the sale', (
      tester,
    ) async {
      await tester.pumpWidget(queued());
      await tester.pumpAndSettle();

      // The tail of the ref, not the head: a ULID's first ten characters are the millisecond it
      // was minted at, so two sales rung up in the same second would show the same code.
      expect(find.text('0ABCDE'), findsOneWidget);
    });

    testWidgets('says the sale has not been sent', (tester) async {
      await tester.pumpWidget(queued());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('done-not-sent')), findsOneWidget);
    });
  });
}
