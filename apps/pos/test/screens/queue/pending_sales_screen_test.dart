/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/branding/company_avatar.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/queue/pending_sales_screen.dart';

import '../../support/boot_rig.dart';

// S17: every sale this tablet has taken money for and not yet had confirmed
// (`plan/offline-queue/README.md` §7). Reached through a button on a stand-in till screen, the
// way it is really reached through the Menu card and the status strip item — both of which push
// this same screen and are tested where they live.
//
// The store is seeded **after** the app has booted and settled, never before: Q6's queue sync
// runs one pass the moment `PosApp` comes up (`plan/offline-queue/findings.md` F17), and a row
// written before that pass would already be in flight, or already sent and gone, before this
// screen ever opens — for a reason that has nothing to do with what these tests are about. That
// pass's own behaviour is `queue_sync_test.dart`'s to cover, not this file's.

final l10n = lookupL10n(const Locale('id'));

final signedIn = paired.copyWith(user: const SessionUser(id: 'user_1'));

const draft = POSCheckoutDTO(
  outletId: 'out_1',
  transactionDate: '2026-09-20',
  items: [
    POSCheckoutItemDTO(
      productId: 'p1',
      unitId: 'u1',
      quantity: 1,
      price: 15000,
    ),
  ],
  payments: [POSTenderDTO(method: POSTenderMethod.cash, amount: 15000)],
);

PendingSale entry({
  String ref = 'REF-1',
  PendingSaleStatus status = PendingSaleStatus.pending,
  String? error,
  String paidAt = '2026-09-20T03:00:00.000Z',
}) => PendingSale(
  clientRef: ref,
  companyId: 'comp_1',
  outletId: 'out_1',
  cashierId: 'user_1',
  status: status,
  error: error,
  paidAt: paidAt,
  createdAt: paidAt,
  payload: draft,
  receipt: const PendingSaleReceipt(
    subtotal: 15000,
    discountAmount: 0,
    taxAmount: 0,
    grandTotal: 15000,
    tenderedAmount: 15000,
    changeAmount: 0,
    items: [],
  ),
);

Widget _openButton(BuildContext context) => Center(
  child: TextButton(
    onPressed: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PendingSalesScreen())),
    child: const Text('open pending sales'),
  ),
);

/// Boots the app on an empty queue and lets it settle, so Q6's boot-time pass has nothing to do
/// and touches no HTTP fake at all.
Future<Rig> bootEmpty(WidgetTester tester) async {
  final rig = Rig(storedSession(signedIn));
  await tester.pumpWidget(
    PosApp(
      boot: rig.boot,
      language: rig.language,
      theme: rig.theme,
      screens: (
        pairing: (_) => const Text('pairing'),
        login: (_) => const Text('login'),
        till: _openButton,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return rig;
}

Future<void> openQueue(WidgetTester tester) async {
  await tester.tap(find.text('open pending sales'));
  await tester.pumpAndSettle();
}

/// Boots empty, writes [seed] straight to the store, then opens the screen so its one load()
/// reads what is already there.
Future<Rig> pumpQueue(
  WidgetTester tester, {
  List<PendingSale> seed = const [],
}) async {
  final rig = await bootEmpty(tester);
  for (final e in seed) {
    await rig.pendingSaleStore.enqueue(e);
  }
  await openQueue(tester);
  return rig;
}

TransportResponse json(int status, String body) => TransportResponse(
  status: status,
  headers: const {'content-type': 'application/json'},
  body: body,
);

/// A `Text` with nothing in it, which is what a reason line with a null/empty reason would
/// render as. Used to prove the widened condition did not add a blank row.
Finder _blankText() => find.byWidgetPredicate(
  (w) =>
      w is Text && (w.data ?? w.textSpan?.toPlainText() ?? '').trim().isEmpty,
);

/// What `/pos/shifts/active` answers: no shift open.
TransportResponse noShift() => json(200, '{"data":null}');

void main() {
  group('what the cashier sees', () {
    testWidgets('says every sale is sent when the queue is empty', (
      tester,
    ) async {
      await pumpQueue(tester);

      expect(find.text(l10n.queueEmpty), findsOneWidget);
    });

    // The avatar went into a trailing slot that already held Kirim sekarang. Wrapping rather
    // than replacing keeps the button a cashier pushes to flush the queue by hand.
    testWidgets('keeps Kirim sekarang beside the company avatar', (
      tester,
    ) async {
      await pumpQueue(tester);

      expect(find.byType(CompanyAvatar), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, l10n.queueSendNow),
        findsOneWidget,
      );
    });

    testWidgets('lists a pending sale: when, how much, and Menunggu', (
      tester,
    ) async {
      await pumpQueue(tester, seed: [entry()]);

      expect(find.textContaining('20 Sep 2026'), findsOneWidget);
      expect(find.text('Rp 15.000'), findsOneWidget);
      expect(find.text(l10n.queueStatusPending), findsOneWidget);
    });

    testWidgets('shows a failed sale with the server sentence, and Gagal', (
      tester,
    ) async {
      await pumpQueue(
        tester,
        seed: [entry(status: PendingSaleStatus.failed, error: 'Stok habis')],
      );

      expect(find.text(l10n.queueStatusFailed), findsOneWidget);
      expect(find.text('Stok habis'), findsOneWidget);
    });

    testWidgets('shows the reason on a pending sale too, without Ulangi', (
      tester,
    ) async {
      // A sale the server blocks (402, or 403 `outlet_inactive`) stays `pending` and is retried
      // by the drain loop, so the cashier never sees `Gagal`. Without the reason here the row
      // says "Menunggu" forever with no explanation of why it is not going through
      // (spec §3a 5). There is no Ulangi: the pass already retries it, and there is nothing to
      // fix from the till.
      await pumpQueue(
        tester,
        seed: [entry(error: 'Masa berlaku langganan telah berakhir')],
      );

      expect(find.text(l10n.queueStatusPending), findsOneWidget);
      expect(
        find.text('Masa berlaku langganan telah berakhir'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, l10n.queueRetry), findsNothing);
    });

    testWidgets('a pending sale with no reason shows no reason line', (
      tester,
    ) async {
      // The regression guard for the widened condition: an ordinary waiting sale must not grow
      // a blank line where the reason would be. Asserted as "no empty Text", which is exactly
      // the shape a wrong condition would produce, without depending on the screen's fixed
      // chrome.
      await pumpQueue(tester, seed: [entry()]);

      expect(find.text(l10n.queueStatusPending), findsOneWidget);
      expect(_blankText(), findsNothing);
    });

    testWidgets('a failed sale keeps its reason and its Ulangi button', (
      tester,
    ) async {
      // The other half of the widened condition: it must not have removed the reason or the
      // button from the case that already worked.
      await pumpQueue(
        tester,
        seed: [entry(status: PendingSaleStatus.failed, error: 'Stok habis')],
      );

      expect(find.text('Stok habis'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, l10n.queueRetry),
        findsOneWidget,
      );
    });

    testWidgets('a failed sale with an empty reason shows no reason line', (
      tester,
    ) async {
      // An empty string is not an explanation, and the condition checks `isNotEmpty` for that
      // reason.
      await pumpQueue(
        tester,
        seed: [entry(status: PendingSaleStatus.failed, error: '')],
      );

      expect(find.text(l10n.queueStatusFailed), findsOneWidget);
      expect(_blankText(), findsNothing);
    });

    testWidgets('offers Ulangi only for a failed sale', (tester) async {
      await pumpQueue(
        tester,
        seed: [
          entry(ref: 'REF-1'),
          entry(ref: 'REF-2', status: PendingSaleStatus.failed, error: 'no'),
        ],
      );

      expect(
        find.widgetWithText(FilledButton, l10n.queueRetry),
        findsOneWidget,
      );
    });

    testWidgets('says the queue could not be read, not that it is empty', (
      tester,
    ) async {
      final rig = await bootEmpty(tester);
      await rig.pendingSaleStore.enqueue(entry());
      rig.pendingSaleStore.failRead = true;

      await openQueue(tester);

      expect(find.text(l10n.queueLoadFailed), findsOneWidget);
      expect(find.text(l10n.queueEmpty), findsNothing);
    });
  });

  group('retrying', () {
    testWidgets('puts a failed sale back to Menunggu', (tester) async {
      await pumpQueue(
        tester,
        seed: [entry(status: PendingSaleStatus.failed, error: 'no')],
      );

      await tester.tap(find.widgetWithText(FilledButton, l10n.queueRetry));
      await tester.pumpAndSettle();

      expect(find.text(l10n.queueStatusPending), findsOneWidget);
      expect(find.text(l10n.queueStatusFailed), findsNothing);
    });
  });

  group('discarding', () {
    testWidgets('asks first', (tester) async {
      await pumpQueue(tester, seed: [entry()]);

      await tester.tap(find.widgetWithText(TextButton, l10n.queueDiscard));
      await tester.pumpAndSettle();

      expect(find.text(l10n.queueDiscardTitle), findsOneWidget);
      // Still there: nothing has been thrown away yet.
      expect(find.text(l10n.queueStatusPending), findsOneWidget);
    });

    testWidgets('keeps the sale when the cashier backs out', (tester) async {
      await pumpQueue(tester, seed: [entry()]);
      await tester.tap(find.widgetWithText(TextButton, l10n.queueDiscard));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, l10n.commonCancel));
      await tester.pumpAndSettle();

      expect(find.text(l10n.queueStatusPending), findsOneWidget);
    });

    testWidgets('removes the sale once confirmed', (tester) async {
      await pumpQueue(tester, seed: [entry()]);
      await tester.tap(find.widgetWithText(TextButton, l10n.queueDiscard));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, l10n.queueDiscard));
      await tester.pumpAndSettle();

      expect(find.text(l10n.queueEmpty), findsOneWidget);
    });
  });

  group('sending now', () {
    testWidgets('drains the queue, and shows what is left', (tester) async {
      final rig = await pumpQueue(tester, seed: [entry()]);
      rig.http
        ..respond(noShift())
        ..respond(
          json(
            200,
            '{"data":{"id":"x1","number":"POS-0001","shift_id":"s1",'
            '"outlet_id":"out_1","cashier_id":"user_1",'
            '"transaction_date":"2026-09-20","subtotal":15000,'
            '"discount_amount":0,"tax_amount":0,"grand_total":15000,'
            '"tendered_amount":15000,"change_amount":0,"status":"POSTED",'
            '"created_at":"2026-09-20T03:00:00Z"}}',
          ),
        );

      await tester.tap(find.widgetWithText(TextButton, l10n.queueSendNow));
      await tester.pumpAndSettle();

      expect(rig.http.calls, hasLength(2));
      expect(find.text(l10n.queueEmpty), findsOneWidget);
    });
  });
}
