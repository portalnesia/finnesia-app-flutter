/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_transaction_detail.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pos/screens/till/transaction_detail_sheet.dart';
import 'package:pos/till/transaction_detail_controller.dart';

import '../../support/app_harness.dart';

// S8. Behaviour from `transaction-detail-dialog.tsx` and `quick-add-contact-dialog.tsx`; the
// shape is this app's own (a bottom sheet, not a centred dialog, so the basket stays readable
// while the detail is filled in).
//
// The controller's own rules are covered by `transaction_detail_controller_test.dart`; this is
// what the cashier sees and taps.

const _json = {'content-type': 'application/json'};

TransportResponse ok(Object? data) => TransportResponse(
  status: 200,
  headers: _json,
  body: jsonEncode({'data': data}),
);

TransportResponse page(List<Map<String, Object?>> items) => TransportResponse(
  status: 200,
  headers: _json,
  body: jsonEncode({
    'data': items,
    'meta': {'next_cursor': null},
  }),
);

Map<String, Object?> contactJson(String id, String name) => {
  'id': id,
  'name': name,
  'type': 'CUSTOMER',
};

/// The customers the picker reads when the sheet opens.
void opening(
  FakeApiTransport transport, {
  List<Map<String, Object?>>? customers,
}) => transport.respond(page(customers ?? [contactJson('c1', 'Budi')]));

({TransactionDetailController controller, FakeApiTransport transport}) rig({
  bool showTableNumber = false,
  bool showQueueNumber = false,
  bool canCreateContact = true,
  String? defaultCustomerId,
}) {
  final transport = FakeApiTransport();
  final controller = TransactionDetailController(
    client: ApiClient(transport: transport, language: () => 'id'),
    outletId: 'out_1',
    showTableNumber: showTableNumber,
    showQueueNumber: showQueueNumber,
    canCreateContact: canCreateContact,
    defaultCustomerId: defaultCustomerId,
    debounce: Duration.zero,
  );
  addTearDown(controller.dispose);
  return (controller: controller, transport: transport);
}

/// The till's summary row, rebuilt from the controller the way the cart pane does it.
Widget rowOn(TransactionDetailController controller) => harness(
  Scaffold(
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TransactionDetailRow(
        detail: controller.detail,
        isDefaultCustomer:
            controller.defaultCustomerId != null &&
            controller.detail.customerId == controller.defaultCustomerId,
        showTableNumber: controller.showTableNumber,
        showQueueNumber: controller.showQueueNumber,
        onOpen: () =>
            showTransactionDetailSheet(context, controller: controller),
      ),
    ),
  ),
);

Future<void> openSheet(
  WidgetTester tester,
  TransactionDetailController c,
) async {
  await tester.pumpWidget(rowOn(c));
  await tester.tap(find.byKey(const Key('transaction-detail-row')));
  await tester.pumpAndSettle();
}

/// Opens the customer picker from the field in the sheet.
///
/// The picker is a dialog of its own, not a list drawn in the sheet, so that a long list cannot
/// push the fields below it off the screen.
Future<void> openPicker(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('customer-field')));
  await tester.pumpAndSettle();
}

/// Taps [finder] after scrolling it into view.
///
/// The new-customer form is taller than the sheet, so its Save button sits below the fold. A
/// plain `tap` on an off-screen widget warns and does nothing, which would make a test pass by
/// never pressing anything.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// A tablet, so the new-customer form fits without scrolling.
///
/// The default test viewport is 800x600, which is smaller than any tablet this app targets and
/// short enough that the form's buttons fall outside the sheet. A tap on an off-screen widget
/// warns and does nothing, so a test written at that size would pass by pressing nothing.
void useTablet(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('the summary row', () {
    testWidgets('invites the cashier to add a detail when there is none', (
      tester,
    ) async {
      final (:controller, :transport) = rig();

      await tester.pumpWidget(rowOn(controller));
      await tester.pumpAndSettle();

      expect(find.text('Tambah detail transaksi'), findsOneWidget);
    });

    testWidgets('names the customer once one is picked', (tester) async {
      final (:controller, :transport) = rig();
      controller.pickCustomer(
        const TransactionDetail(customerId: 'c1', customerName: 'Budi'),
      );

      await tester.pumpWidget(rowOn(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pelanggan: Budi'), findsOneWidget);
    });

    testWidgets('puts the note in the customer parentheses for the default', (
      tester,
    ) async {
      // The owner's rule (2026-09-21): the note is folded for the company's nominated walk-in,
      // and stands on its own for anyone else.
      final (:controller, :transport) = rig(defaultCustomerId: 'c1');
      controller.pickCustomer(
        const TransactionDetail(customerId: 'c1', customerName: 'UMUM'),
      );
      controller.setMemo('meja 4');

      await tester.pumpWidget(rowOn(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pelanggan: UMUM (meja 4)'), findsOneWidget);
      // Not twice: the note has its own row only for a picked customer.
      expect(find.textContaining('Catatan:'), findsNothing);
    });

    testWidgets('keeps the note on its own row for a picked customer', (
      tester,
    ) async {
      final (:controller, :transport) = rig(defaultCustomerId: 'c1');
      controller.pickCustomer(
        const TransactionDetail(customerId: 'c2', customerName: 'Siti'),
      );
      controller.setMemo('meja 4');

      await tester.pumpWidget(rowOn(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pelanggan: Siti'), findsOneWidget);
      expect(find.textContaining('Catatan: meja 4'), findsOneWidget);
    });

    testWidgets('shows a table that was filled in even when unasked', (
      tester,
    ) async {
      // The preference decides what the **sheet** offers, not what the row reports: a table
      // number that is on the sale is a fact about the sale, and the source's `DetailRow` prints
      // every field it has (`cart-panel.tsx:288-304`).
      final (:controller, :transport) = rig();
      controller.setTableNumber('12');

      await tester.pumpWidget(rowOn(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Meja: 12'), findsOneWidget);
    });

    testWidgets('shows the table and the queue when the outlet asks', (
      tester,
    ) async {
      final (:controller, :transport) = rig(
        showTableNumber: true,
        showQueueNumber: true,
      );
      controller.setTableNumber('12');
      controller.setQueueNumber('45');

      await tester.pumpWidget(rowOn(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Meja: 12'), findsOneWidget);
      expect(find.textContaining('Antrian: 45'), findsOneWidget);
    });

    testWidgets('shows an empty slot for a table the outlet asks for', (
      tester,
    ) async {
      // The row used to print only what was filled in, so a cashier at a dine-in outlet saw
      // "Pelanggan: UMUM" and had no hint that a table number belonged anywhere.
      final (:controller, :transport) = rig(
        showTableNumber: true,
        showQueueNumber: true,
        defaultCustomerId: 'c1',
      );
      controller.pickCustomer(
        const TransactionDetail(customerId: 'c1', customerName: 'UMUM'),
      );

      await tester.pumpWidget(rowOn(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pelanggan: UMUM'), findsOneWidget);
      expect(find.textContaining('Meja: -'), findsOneWidget);
      expect(find.textContaining('Antrian: -'), findsOneWidget);
    });

    testWidgets('has no empty slot once the table is filled in', (
      tester,
    ) async {
      final (:controller, :transport) = rig(showTableNumber: true);
      controller.setTableNumber('12');

      await tester.pumpWidget(rowOn(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Meja: 12'), findsOneWidget);
      expect(find.textContaining('Meja: -'), findsNothing);
    });

    testWidgets('has no empty slot for a field the outlet does not ask for', (
      tester,
    ) async {
      final (:controller, :transport) = rig();

      await tester.pumpWidget(rowOn(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Meja: -'), findsNothing);
      expect(find.textContaining('Antrian: -'), findsNothing);
      expect(find.text('Tambah detail transaksi'), findsOneWidget);
    });
  });

  group('the sheet', () {
    testWidgets('opens from the row and closes with Done', (tester) async {
      final (:controller, :transport) = rig();
      opening(transport);

      await openSheet(tester, controller);

      expect(find.text('Detail Transaksi'), findsOneWidget);

      await tester.tap(find.byKey(const Key('detail-done')));
      await tester.pumpAndSettle();

      expect(find.text('Detail Transaksi'), findsNothing);
    });

    testWidgets('keeps Done clear of the system navigation bar', (
      tester,
    ) async {
      // `useSafeArea` on a modal sheet guards the top and the sides, not the bottom. On a tablet
      // with three-button navigation the bar covered the Done button.
      const bar = 48.0;
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: bar);
      tester.view.viewPadding = const FakeViewPadding(bottom: bar);
      addTearDown(tester.view.reset);
      final (:controller, :transport) = rig();
      opening(transport);

      await openSheet(tester, controller);

      expect(
        tester.getBottomLeft(find.byKey(const Key('detail-done'))).dy,
        lessThanOrEqualTo(800 - bar),
      );
    });

    testWidgets('closes on Escape', (tester) async {
      // A sheet the keyboard cannot dismiss is a sheet a keyboard user is stuck behind (R-32).
      final (:controller, :transport) = rig();
      opening(transport);
      await openSheet(tester, controller);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Detail Transaksi'), findsNothing);
    });

    testWidgets('shows only the fields the outlet asked for', (tester) async {
      final (:controller, :transport) = rig();
      opening(transport);

      await openSheet(tester, controller);

      expect(find.text('Pelanggan'), findsWidgets);
      expect(find.text('Catatan Pelanggan'), findsOneWidget);
      expect(find.text('No. Meja'), findsNothing);
      expect(find.text('No. Antrian'), findsNothing);
    });

    testWidgets('shows the table and queue fields when the outlet asks', (
      tester,
    ) async {
      final (:controller, :transport) = rig(
        showTableNumber: true,
        showQueueNumber: true,
      );
      opening(transport);

      await openSheet(tester, controller);

      expect(find.text('No. Meja'), findsOneWidget);
      expect(find.text('No. Antrian'), findsOneWidget);
    });

    testWidgets('the customer is one row until it is tapped', (tester) async {
      final (:controller, :transport) = rig();
      opening(transport);

      await openSheet(tester, controller);

      expect(find.byKey(const Key('customer-field')), findsOneWidget);
      expect(find.text('Pilih pelanggan'), findsOneWidget);
      expect(find.byKey(const Key('customer-search')), findsNothing);
    });

    testWidgets('picks the customer tapped, and closes the picker', (
      tester,
    ) async {
      final (:controller, :transport) = rig();
      opening(
        transport,
        customers: [contactJson('c1', 'Budi'), contactJson('c2', 'Siti')],
      );

      await openSheet(tester, controller);
      await openPicker(tester);
      await tester.tap(find.byKey(const ValueKey('customer-c2')));
      await tester.pumpAndSettle();

      expect(controller.detail.customerId, 'c2');
      expect(controller.detail.customerName, 'Siti');
      expect(find.byKey(const Key('customer-search')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('customer-field')),
          matching: find.text('Siti'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the fields below do not move when a customer is picked', (
      tester,
    ) async {
      // The picker used to be drawn in the sheet, above the fields, so every customer it listed
      // pushed them further down.
      final (:controller, :transport) = rig();
      opening(transport);
      await openSheet(tester, controller);
      final before = tester.getTopLeft(find.byType(TextField).last);

      await openPicker(tester);
      await tester.tap(find.byKey(const ValueKey('customer-c1')));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byType(TextField).last), before);
    });

    testWidgets('builds only the rows in view, however many there are', (
      tester,
    ) async {
      final (:controller, :transport) = rig();
      opening(
        transport,
        customers: [
          for (var i = 0; i < 60; i++) contactJson('c$i', 'Pelanggan $i'),
        ],
      );
      await openSheet(tester, controller);
      await openPicker(tester);

      expect(find.byKey(const ValueKey('customer-c0')), findsOneWidget);
      expect(find.byKey(const ValueKey('customer-c59')), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('customer-c59')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('customer-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.byKey(const ValueKey('customer-c59')), findsOneWidget);
    });

    testWidgets('leaves the customer alone when it is closed without picking', (
      tester,
    ) async {
      final (:controller, :transport) = rig(defaultCustomerId: 'c1');
      opening(transport);
      await openSheet(tester, controller);
      await openPicker(tester);

      await tester.tap(find.byKey(const Key('customer-picker-close')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('customer-picker')), findsNothing);
      expect(controller.detail.customerId, 'c1');
    });

    testWidgets('clears the customer from the field', (tester) async {
      final (:controller, :transport) = rig(defaultCustomerId: 'c1');
      opening(transport);
      await openSheet(tester, controller);

      await tester.tap(find.byKey(const Key('customer-clear')));
      await tester.pumpAndSettle();

      expect(controller.detail.customerId, isEmpty);
      expect(find.text('Pilih pelanggan'), findsOneWidget);
    });

    testWidgets('marks the customer that is on the sale in the list', (
      tester,
    ) async {
      final (:controller, :transport) = rig(defaultCustomerId: 'c1');
      opening(
        transport,
        customers: [contactJson('c1', 'Budi'), contactJson('c2', 'Siti')],
      );

      await openSheet(tester, controller);
      await openPicker(tester);

      Finder tick(String id) => find.descendant(
        of: find.byKey(ValueKey('customer-$id')),
        matching: find.byIcon(Icons.check),
      );
      expect(tick('c1'), findsOneWidget);
      expect(tick('c2'), findsNothing);
    });

    testWidgets('says so when the search found nobody', (tester) async {
      final (:controller, :transport) = rig();
      opening(transport, customers: []);

      await openSheet(tester, controller);
      await openPicker(tester);

      expect(find.text('Tidak ada pelanggan ditemukan.'), findsOneWidget);
    });

    testWidgets('a list that could not be read is not an empty list', (
      tester,
    ) async {
      // A shop with customers must never be shown "nobody found" because the request failed.
      final (:controller, :transport) = rig();
      transport.fail(TransportException('offline'));

      await openSheet(tester, controller);
      await openPicker(tester);

      expect(find.text('Tidak ada pelanggan ditemukan.'), findsNothing);
      expect(
        find.text(
          'Belum bisa membaca daftar pelanggan. Periksa koneksi lalu coba lagi.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the note typed into the sheet reaches the row', (
      tester,
    ) async {
      final (:controller, :transport) = rig();
      opening(transport);
      await openSheet(tester, controller);

      await tester.enterText(find.byType(TextField).last, 'tanpa gula');
      await tester.pump();

      expect(controller.detail.customerMemo, 'tanpa gula');
    });
  });

  group('adding a customer from the till', () {
    testWidgets('is not offered when the cashier may not create one', (
      tester,
    ) async {
      // `POST /master/contacts` needs `master.contact.manage`, which the seeded cashier role does
      // not hold. A button the server refuses is worse than no button (R-26).
      useTablet(tester);
      final (:controller, :transport) = rig(canCreateContact: false);
      opening(transport);

      await openSheet(tester, controller);
      await openPicker(tester);

      expect(find.byKey(const Key('add-customer')), findsNothing);
    });

    testWidgets('is offered, and posts what was typed', (tester) async {
      useTablet(tester);
      final (:controller, :transport) = rig();
      opening(transport);
      await openSheet(tester, controller);
      await openPicker(tester);

      await tester.tap(find.byKey(const Key('add-customer')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('new-customer-name')),
        'Sari',
      );
      transport.respond(ok(contactJson('c9', 'Sari')));
      await tapVisible(tester, find.byKey(const Key('save-customer')));

      final posted = transport.requests.singleWhere(
        (r) => r.method.wire == 'POST',
      );
      expect(jsonDecode(posted.body!), {
        'name': 'Sari',
        'type': 'CUSTOMER',
        'is_active': true,
      });
      // Picked straight away: the cashier made this customer to use them.
      expect(controller.detail.customerId, 'c9');
      expect(controller.detail.customerName, 'Sari');
      // And the picker is done: nothing is left to choose.
      expect(find.byKey(const Key('customer-picker')), findsNothing);
    });

    testWidgets('an empty name is refused without asking the server', (
      tester,
    ) async {
      useTablet(tester);
      final (:controller, :transport) = rig();
      opening(transport);
      await openSheet(tester, controller);
      await openPicker(tester);

      await tester.tap(find.byKey(const Key('add-customer')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('new-customer-name')), '   ');
      await tapVisible(tester, find.byKey(const Key('save-customer')));

      expect(find.text('Nama pelanggan belum diisi.'), findsOneWidget);
      expect(transport.requests.where((r) => r.method.wire == 'POST'), isEmpty);
    });

    testWidgets('a refusal from the server is shown in its own words', (
      tester,
    ) async {
      useTablet(tester);
      final (:controller, :transport) = rig();
      opening(transport);
      await openSheet(tester, controller);
      await openPicker(tester);

      await tester.tap(find.byKey(const Key('add-customer')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('new-customer-name')),
        'Sari',
      );
      transport.respond(
        TransportResponse(
          status: 422,
          headers: _json,
          body: jsonEncode({
            'error': {'message': 'Nama sudah dipakai'},
          }),
        ),
      );
      await tapVisible(tester, find.byKey(const Key('save-customer')));

      expect(find.text('Nama sudah dipakai'), findsOneWidget);
    });
  });

  group('the layout', () {
    for (final entry in tabletSizes.entries) {
      testWidgets('fits ${entry.key} at text 1.3x', (tester) async {
        // The sheet carries up to six fields and a list; a layout that only fits the size it was
        // drawn at is not a layout (R-03).
        final (:controller, :transport) = rig(
          showTableNumber: true,
          showQueueNumber: true,
        );
        opening(transport);
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await openSheet(tester, controller);
        expect(tester.takeException(), isNull);

        await openPicker(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
