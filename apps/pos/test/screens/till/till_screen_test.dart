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
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/product.dart' as model;
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/queue/pending_sales_screen.dart';
import 'package:pos/screens/till/cart_pane.dart';
import 'package:pos/screens/till/catalog_pane.dart';
import 'package:pos/screens/till/till_screen.dart';
import 'package:pos/screens/payment/done_screen.dart';
import 'package:pos/screens/payment/payment_screen.dart';

import '../../support/boot_rig.dart';
import '../../support/routed_http.dart';

// S5. Run inside the real `PosApp`, so the boot, the theme and the language are the ones the
// cashier gets. The behaviour of the grid, the cart panel and the till bar is the contract; the
// layout, the keypad-free flow, undo and the scanner are this app's own.

const categoriesPath = '/api/v1/master/categories';
const productsPath = '/api/v1/products';
const stockPath = '/api/v1/pos/stock';

Map<String, Object?> product(
  String id,
  String name,
  num price, {
  String type = 'INVENTORY',
  String? sku,
  String? barcode,
}) => {
  'id': id,
  'name': name,
  'unit_id': 'unit_1',
  'sell_price': price,
  'type': type,
  'sku': sku,
  'barcode': barcode,
};

TransportResponse page(List<Map<String, Object?>> items, {String? next}) =>
    TransportResponse(
      status: 200,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'data': items,
        'meta': {'next_cursor': next},
      }),
    );

final kopi = product('a', 'Kopi', 15000, sku: 'KOPI-1', barcode: '8991234');
final teh = product('b', 'Teh', 8000);
final jasa = product('c', 'Jasa antar', 5000, type: 'NON_INVENTORY');

/// What opening the till reads: the categories, one page of products, and the stock.
void catalog(
  RoutedHttp http, {
  List<Map<String, Object?>>? products,
  String? next,
  Map<String, num> stock = const {'a': 5, 'b': 0},
}) {
  http.respond(
    categoriesPath,
    ok([
      {'id': 'cat_1', 'name': 'Minuman'},
    ]),
  );
  http.respond(productsPath, page(products ?? [kopi, teh, jasa], next: next));
  http.respond(stockPath, ok(stock));
}

final signedIn = paired.copyWith(
  user: const SessionUser(id: 'user_1', name: 'Budi'),
);

const shift = POSShift(
  id: 's1',
  number: 'SH-0001',
  cashierId: 'user_1',
  outletId: 'out_1',
  openedAt: '2026-09-20T01:00:00Z',
  openingCash: 100000,
  totalSales: 0,
  totalTransactions: 0,
);

Widget appWith(Rig rig, RoutedHttp http, {Duration Function()? clock}) =>
    PosApp(
      boot: () => rig.bootWith(http: http),
      language: rig.language,
      theme: rig.theme,
      screens: (
        pairing: (_) => const Text('pairing'),
        login: (_) => const Text('login'),
        till: (_) => TillScreen(shift: shift, clock: clock),
      ),
    );

void useSize(WidgetTester tester, Size size, double textScale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> pumpTill(
  WidgetTester tester,
  RoutedHttp http, {
  Rig? rig,
  Size size = const Size(1280, 800),
  double textScale = 1,
  Duration Function()? clock,
}) async {
  useSize(tester, size, textScale);
  await tester.pumpWidget(
    appWith(rig ?? Rig(storedSession(signedIn)), http, clock: clock),
  );
  await tester.pumpAndSettle();
}

Finder card(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(ProductCard));

Finder line(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(CartLineTile));

Finder get cartTotal => find.descendant(
  of: find.byKey(const Key('cart-total')),
  matching: find.byType(Text),
);

final l10n = lookupL10n(const Locale('id'));

Future<void> tapProduct(WidgetTester tester, String name) async {
  await tester.tap(card(name));
  await tester.pump();
}

void main() {
  group('the catalogue', () {
    testWidgets('shows what can be sold, with its price', (tester) async {
      final http = RoutedHttp();
      catalog(http);

      await pumpTill(tester, http);

      expect(card('Kopi'), findsOneWidget);
      expect(
        find.descendant(of: card('Kopi'), matching: find.text('Rp 15.000')),
        findsOneWidget,
      );
      expect(card('Teh'), findsOneWidget);
    });

    testWidgets('has a strip of categories, starting with all of them', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);

      await pumpTill(tester, http);

      expect(find.widgetWithText(ChoiceChip, 'Semua'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Minuman'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Semua'))
            .selected,
        isTrue,
      );
    });

    testWidgets('says what is left of a counted product, and when it is gone', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);

      await pumpTill(tester, http);

      expect(
        find.descendant(of: card('Kopi'), matching: find.text('5')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card('Teh'), matching: find.text('Habis')),
        findsOneWidget,
      );
    });

    testWidgets('says nothing of stock for a service', (tester) async {
      final http = RoutedHttp();
      catalog(http);

      await pumpTill(tester, http);

      expect(
        find.descendant(of: card('Jasa antar'), matching: find.text('Habis')),
        findsNothing,
      );
      expect(
        find.descendant(of: card('Jasa antar'), matching: find.text('0')),
        findsNothing,
      );
    });

    testWidgets('a catalogue that could not be read is not an empty shop', (
      tester,
    ) async {
      final http = RoutedHttp();
      http.respond(categoriesPath, ok([]));
      http.respond(productsPath, refused(500, 'boom'));
      http.respond(stockPath, ok({}));

      await pumpTill(tester, http);

      expect(find.text('boom'), findsOneWidget);
      expect(find.text('Tidak ada produk'), findsNothing);

      catalog(http);
      await tester.tap(find.widgetWithText(FilledButton, 'Coba lagi'));
      await tester.pumpAndSettle();
      expect(card('Kopi'), findsOneWidget);
    });

    // Stock is a separate read. Failing to make it must not turn every counted product into
    // "Habis": a cashier would send customers away from goods that are on the shelf.
    testWidgets('a stock that could not be read says nothing, not Habis', (
      tester,
    ) async {
      final http = RoutedHttp();
      http.respond(categoriesPath, ok([]));
      http.respond(productsPath, page([kopi, teh]));
      http.respond(stockPath, refused(500, 'boom'));

      await pumpTill(tester, http);

      expect(card('Kopi'), findsOneWidget);
      expect(find.text('Habis'), findsNothing);
    });

    testWidgets('says so when there is nothing to sell', (tester) async {
      final http = RoutedHttp();
      catalog(http, products: []);

      await pumpTill(tester, http);

      expect(find.text('Tidak ada produk'), findsOneWidget);
    });

    testWidgets('a deactivated product is not offered', (tester) async {
      final http = RoutedHttp();
      catalog(
        http,
        products: [
          kopi,
          {...teh, 'is_active': false},
        ],
      );

      await pumpTill(tester, http);

      expect(card('Teh'), findsNothing);
    });

    testWidgets('choosing a category asks for it, and marks it chosen', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      http.respond(productsPath, page([teh]));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Minuman'));
      await tester.pumpAndSettle();

      final asked = http.calls
          .where((c) => c.path.startsWith(productsPath))
          .last;
      expect(Uri.parse(asked.path).queryParameters['category_id'], 'cat_1');
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Minuman'))
            .selected,
        isTrue,
      );
      expect(card('Kopi'), findsNothing);
    });

    testWidgets('typing in the search asks the server, once they stop', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      http.respond(productsPath, page([teh]));

      await tester.enterText(find.byType(TextField), 'te');
      await tester.enterText(find.byType(TextField), 'teh');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final searches = http.calls
          .where(
            (c) => c.path.startsWith(productsPath) && c.path.contains('q='),
          )
          .toList();
      expect(searches, hasLength(1));
      expect(Uri.parse(searches.single.path).queryParameters['q'], 'teh');
    });

    testWidgets('scrolling to the end asks for the next page', (tester) async {
      final http = RoutedHttp();
      final many = [
        for (var i = 0; i < 40; i++) product('p$i', 'Barang $i', 1000),
      ];
      catalog(http, products: many, next: 'cur_2');
      await pumpTill(tester, http);
      http.respond(
        productsPath,
        page([product('last', 'Barang terakhir', 1000)]),
      );

      await tester.fling(find.byType(GridView), const Offset(0, -6000), 3000);
      await tester.pumpAndSettle();

      final asked = http.calls
          .where((c) => c.path.startsWith(productsPath))
          .last;
      expect(Uri.parse(asked.path).queryParameters['next_cursor'], 'cur_2');
    });
  });

  group('the cart', () {
    testWidgets('starts empty, and says how to fill it', (tester) async {
      final http = RoutedHttp();
      catalog(http);

      await pumpTill(tester, http);

      expect(find.text('Keranjang kosong'), findsOneWidget);
      expect(line('Kopi'), findsNothing);
    });

    testWidgets('a tap on a product puts it in, with what it comes to', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);

      await tapProduct(tester, 'Kopi');

      expect(line('Kopi'), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget);
      expect(tester.widget<Text>(cartTotal).data, 'Rp 15.000');
      expect(find.text('Keranjang kosong'), findsNothing);
    });

    testWidgets('the same product again is one more, on one line', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);

      await tapProduct(tester, 'Kopi');
      await tapProduct(tester, 'Kopi');

      expect(line('Kopi'), findsOneWidget);
      expect(find.text('2 item'), findsOneWidget);
      expect(tester.widget<Text>(cartTotal).data, 'Rp 30.000');
    });

    testWidgets('plus and minus change the quantity, and stop at one', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      await tapProduct(tester, 'Kopi');

      await tester.tap(find.byTooltip('Tambah jumlah Kopi'));
      await tester.pump();
      expect(find.text('2 item'), findsOneWidget);

      await tester.tap(find.byTooltip('Kurangi jumlah Kopi'));
      await tester.tap(find.byTooltip('Kurangi jumlah Kopi'));
      await tester.pump();
      // Removing a line is the delete button's job, not a side effect of minus.
      expect(find.text('1 item'), findsOneWidget);
    });

    testWidgets('a removed line goes, and Urungkan brings it back', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      await tapProduct(tester, 'Kopi');
      await tapProduct(tester, 'Teh');

      await tester.tap(find.byTooltip('Hapus Kopi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(line('Kopi'), findsNothing);
      expect(find.text('Kopi dihapus'), findsOneWidget);

      await tester.tap(find.text('Urungkan'));
      await tester.pumpAndSettle();

      expect(line('Kopi'), findsOneWidget);
      // Where it was: first.
      final kopiAt = tester.getTopLeft(line('Kopi')).dy;
      final tehAt = tester.getTopLeft(line('Teh')).dy;
      expect(kopiAt, lessThan(tehAt));
    });

    // The undo notice was a SnackBar at the bottom, which is where Pay is, and a SnackBar with
    // an action never left on its own in this framework version (measured: still on screen after
    // 12 s against a 4 s duration). Both are why it is an overlay at the top now.
    testWidgets('the undo notice stays clear of the Pay button', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      // Two products, so removing one leaves the cart non-empty and Pay on screen: with an
      // empty cart there is no Pay button to compare against, which is how the first version
      // of this test failed.
      await tapProduct(tester, 'Kopi');
      await tapProduct(tester, 'Teh');

      await tester.tap(find.byTooltip('Hapus Kopi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final notice = tester.getRect(find.text('Kopi dihapus'));
      final pay = tester.getRect(find.byKey(const Key('pay')));
      expect(
        notice.bottom,
        lessThan(pay.top),
        reason: 'the notice must not cover the button the till exists for',
      );
    });

    testWidgets('the undo notice goes away on its own', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      await tapProduct(tester, 'Kopi');

      await tester.tap(find.byTooltip('Hapus Kopi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kopi dihapus'), findsOneWidget);

      // Past its four seconds, in frames so the timer can run.
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Kopi dihapus'), findsNothing);
    });

    testWidgets('clearing asks first, and Batal keeps everything', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      await tapProduct(tester, 'Kopi');

      await tester.tap(find.widgetWithText(TextButton, 'Kosongkan'));
      await tester.pumpAndSettle();
      expect(find.text('Kosongkan keranjang?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Batal'));
      await tester.pumpAndSettle();

      expect(line('Kopi'), findsOneWidget);
    });

    testWidgets('clearing empties it when confirmed', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      await tapProduct(tester, 'Kopi');

      await tester.tap(find.widgetWithText(TextButton, 'Kosongkan'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Kosongkan'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keranjang kosong'), findsOneWidget);
    });

    testWidgets('has nothing to clear while it is empty', (tester) async {
      final http = RoutedHttp();
      catalog(http);

      await pumpTill(tester, http);

      expect(find.widgetWithText(TextButton, 'Kosongkan'), findsNothing);
    });
  });

  group('the search field', () {
    testWidgets('Enter on an exact code rings the product up and clears it', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      // The lookup, and the grid asking again for what was typed once they stop.
      http.respond(productsPath, page([kopi]));
      http.respond(productsPath, page([kopi]));

      await tester.enterText(find.byType(TextField), 'KOPI-1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(line('Kopi'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });

    testWidgets('Enter on a partial name adds nothing, and says nothing', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      // The server searches with LIKE, so it answers a partial code with a product.
      http.respond(productsPath, page([kopi]));
      http.respond(productsPath, page([kopi]));

      await tester.enterText(find.byType(TextField), 'KOP');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(line('Kopi'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a lookup that fails says so, and adds nothing', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      http.respond(productsPath, refused(500, 'boom'));
      http.respond(productsPath, page([]));

      await tester.enterText(find.byType(TextField), 'KOPI-1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Belum bisa mencari produk itu'),
        findsOneWidget,
      );
      expect(line('Kopi'), findsNothing);
    });
  });

  group('a barcode scanner', () {
    var now = Duration.zero;
    Duration clock() => now;

    /// Types [code] one key at a time, [gap] apart, then Enter.
    Future<void> scan(WidgetTester tester, String code, Duration gap) async {
      for (final digit in code.split('')) {
        now += gap;
        await tester.sendKeyEvent(_digit[digit]!, character: digit);
      }
      now += gap;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }

    setUp(() => now = Duration.zero);

    testWidgets('rings a product up without touching any field', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http, clock: clock);
      http.respond(productsPath, page([kopi]));

      await scan(tester, '8991234', const Duration(milliseconds: 8));

      expect(line('Kopi'), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget);
    });

    testWidgets('a person typing at their own pace is not a scan', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http, clock: clock);
      final before = http.calls.length;

      await scan(tester, '8991234', const Duration(milliseconds: 300));

      expect(line('Kopi'), findsNothing);
      expect(http.calls.length, before);
    });

    testWidgets('an unknown code says so, since a scan is never habit', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http, clock: clock);
      http.respond(productsPath, page([]));

      await scan(tester, '8990000', const Duration(milliseconds: 8));

      expect(
        find.text('Produk dengan kode 8990000 tidak ditemukan.'),
        findsOneWidget,
      );
      expect(find.text('Keranjang kosong'), findsOneWidget);
    });

    testWidgets('a lookup that fails says so', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http, clock: clock);
      http.respond(productsPath, refused(500, 'boom'));

      await scan(tester, '8991234', const Duration(milliseconds: 8));

      expect(
        find.textContaining('Belum bisa mencari produk itu'),
        findsOneWidget,
      );
    });

    testWidgets('two scans are two lookups, one after the other', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http, clock: clock);
      http.respond(productsPath, page([kopi]));
      http.respond(productsPath, page([kopi]));

      await scan(tester, '8991234', const Duration(milliseconds: 8));
      now += const Duration(seconds: 1);
      await scan(tester, '8991234', const Duration(milliseconds: 8));

      expect(find.text('2 item'), findsOneWidget);
    });

    testWidgets(
      'does nothing while the cashier is typing in the search field',
      (tester) async {
        final http = RoutedHttp();
        catalog(http);
        await pumpTill(tester, http, clock: clock);
        await tester.tap(find.byType(TextField));
        await tester.pump();
        final before = http.calls.length;

        // The field has the keystrokes, and its own Enter does the lookup: the window must not
        // ring the same product up a second time.
        await scan(tester, '8991234', const Duration(milliseconds: 8));

        expect(line('Kopi'), findsNothing);
        expect(http.calls.length, before);
      },
    );

    testWidgets('does not add behind a dialog', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http, clock: clock);
      await tapProduct(tester, 'Teh');
      await tester.tap(find.widgetWithText(TextButton, 'Kosongkan'));
      await tester.pumpAndSettle();
      final before = http.calls.length;

      await scan(tester, '8991234', const Duration(milliseconds: 8));

      expect(http.calls.length, before);
      expect(find.text('1 item'), findsOneWidget);
    });

    testWidgets('logs barcode_scanned with found: true', (tester) async {
      final http = RoutedHttp();
      final rig = Rig(storedSession(signedIn));
      catalog(http);
      await pumpTill(tester, http, rig: rig, clock: clock);
      http.respond(productsPath, page([kopi]));

      await scan(tester, '8991234', const Duration(milliseconds: 8));

      // A found scan also rings the product up, which logs its own event
      // (`cart_controller_test.dart`) — this only checks the scan's own.
      final scanned = rig.analytics.logged.where(
        (e) => e.$1 == 'barcode_scanned',
      );
      expect(scanned.single.$2, {'found': true});
    });

    testWidgets('logs barcode_scanned with found: false for an unknown code', (
      tester,
    ) async {
      final http = RoutedHttp();
      final rig = Rig(storedSession(signedIn));
      catalog(http);
      await pumpTill(tester, http, rig: rig, clock: clock);
      http.respond(productsPath, page([]));

      await scan(tester, '8990000', const Duration(milliseconds: 8));

      expect(rig.analytics.logged.single.$2, {'found': false});
    });

    testWidgets('does not log for the search field\'s own Enter', (
      tester,
    ) async {
      final http = RoutedHttp();
      final rig = Rig(storedSession(signedIn));
      catalog(http);
      await pumpTill(tester, http, rig: rig);
      http.respond(productsPath, page([kopi]));

      await tester.enterText(find.byType(TextField), '8991234');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Rings the product up (`item_added_to_cart`) but is not a scan.
      expect(
        rig.analytics.logged.where((e) => e.$1 == 'barcode_scanned'),
        isEmpty,
      );
    });
  });
  group('who is selling', () {
    testWidgets('names the cashier, always in view', (tester) async {
      final http = RoutedHttp();
      catalog(http);

      await pumpTill(tester, http);

      expect(find.text('Kasir: Budi'), findsOneWidget);
    });

    testWidgets('does not put the shift number on the strip', (tester) async {
      final http = RoutedHttp();
      catalog(http);

      await pumpTill(tester, http);

      // Owner decision 2026-09-20: the shift number is a variable that changes every shift, and
      // it sat directly above the product search where the cashier reads and types all day. It
      // crowded the strip without answering a question anyone asks mid-sale. The shift is still
      // named where it is the subject: the Menu, and the shift gate's own panels.
      expect(find.text('Shift SH-0001'), findsNothing);
      expect(find.textContaining('SH-0001'), findsNothing);
    });
  });

  // C5: the way out of the till. The payment screen has its own tests; this is the join
  // between them, and the one thing the till owns: when the basket may be emptied.
  group('paying', () {
    const checkoutPath = '/api/v1/pos/sales/checkout';

    TransportResponse saleBody() => ok({
      'id': 'x1',
      'number': 'POS-0001',
      'shift_id': 's1',
      'outlet_id': 'out_1',
      'cashier_id': 'user_1',
      'transaction_date': '2026-09-20',
      'subtotal': 15000,
      'discount_amount': 0,
      'tax_amount': 0,
      'grand_total': 15000,
      'tendered_amount': 15000,
      'change_amount': 0,
      'status': 'POSTED',
      'created_at': '2026-09-20T03:00:00Z',
    });

    testWidgets('there is no Pay button until there is something to pay for', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);

      await pumpTill(tester, http);

      // An empty cart has nothing to sell, so the button is absent rather than disabled
      // (R-26: a control that never does anything is not shipped).
      expect(find.byKey(const Key('pay')), findsNothing);
    });

    testWidgets('Pay opens the payment screen for what is in the cart', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      await tapProduct(tester, 'Kopi');

      await tester.tap(find.byKey(const Key('pay')));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentScreen), findsOneWidget);
      // The total it is asking for is the cart's, not something it worked out itself.
      expect(find.byKey(const Key('grand-total')), findsOneWidget);
    });

    testWidgets('a recorded sale shows the change and empties the basket', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      http.respond(checkoutPath, saleBody());
      await pumpTill(tester, http);
      await tapProduct(tester, 'Kopi');

      await tester.tap(find.byKey(const Key('pay')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      // The cashier gets the change screen, with the sale's own number on it.
      expect(find.byType(DoneScreen), findsOneWidget);
      expect(find.text('POS-0001'), findsOneWidget);

      // And the basket is empty behind it — checked after dismissing, because the till is
      // behind the change screen and its texts are not on the screen yet.
      await tester.tap(find.text('Transaksi Baru'));
      await tester.pumpAndSettle();
      expect(find.byType(DoneScreen), findsNothing);
      expect(find.text('Keranjang kosong'), findsOneWidget);
    });

    testWidgets(
      'a refused sale keeps the basket and stays on the payment screen',
      (tester) async {
        final http = RoutedHttp();
        catalog(http);
        http.respond(
          checkoutPath,
          refused(422, 'Akun TRANSFER belum dipetakan'),
        );
        await pumpTill(tester, http);
        await tapProduct(tester, 'Kopi');

        await tester.tap(find.byKey(const Key('pay')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm-payment')));
        await tester.pumpAndSettle();

        // Nothing was recorded, so nothing may be thrown away: the cashier still has a
        // customer in front of them and the goods are still theirs to sell.
        expect(find.byType(DoneScreen), findsNothing);
        expect(find.byType(PaymentScreen), findsOneWidget);
        expect(find.text('Akun TRANSFER belum dipetakan'), findsOneWidget);
      },
    );

    testWidgets(
      'a sale nobody can confirm goes to the change screen and is queued',
      (tester) async {
        final http = RoutedHttp();
        catalog(http);
        http.fail(checkoutPath);
        await pumpTill(tester, http);
        await tapProduct(tester, 'Kopi');

        await tester.tap(find.byKey(const Key('pay')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm-payment')));
        await tester.pumpAndSettle();

        // The sale was written down **before** the send (`security.md` §5), so the customer is
        // served and the queue sends it later. D-Q2 replaced F33 here: the cashier is no longer
        // held on the payment form, because the sale is not lost either way.
        expect(find.byType(DoneScreen), findsOneWidget);
        // No transaction number: only the server issues one (D-Q3).
        expect(find.text('POS-0001'), findsNothing);
        expect(find.text('SEMENTARA'), findsOneWidget);
        expect(find.byKey(const Key('done-not-sent')), findsOneWidget);

        // The goods have left the shop, so the basket is cleared — exactly as for a recorded
        // sale, and after `_hold.paid()` so the held basket is not left behind to be sold twice.
        await tester.tap(find.text('Transaksi Baru'));
        await tester.pumpAndSettle();
        expect(find.byType(DoneScreen), findsNothing);
        expect(find.text('Keranjang kosong'), findsOneWidget);
      },
    );

    testWidgets(
      'the checkout carries the shift, the outlet and one client_ref',
      (tester) async {
        final http = RoutedHttp();
        catalog(http);
        http.respond(checkoutPath, saleBody());
        await pumpTill(tester, http);
        await tapProduct(tester, 'Kopi');

        await tester.tap(find.byKey(const Key('pay')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm-payment')));
        await tester.pumpAndSettle();

        final sent = jsonDecode(http.calls.last.body!) as Map<String, dynamic>;
        expect(sent['shift_id'], 's1');
        expect(sent['outlet_id'], 'out_1');
        expect(sent['transaction_date'], isA<String>());
        // The idempotency key, without which a retry after a lost answer would charge twice
        // (`plan/ui/README.md` §4.3).
        expect(sent['client_ref'], isA<String>());
        expect(sent['payments'], hasLength(1));
        expect(sent['items'], hasLength(1));
      },
    );
  });

  group('on a wide screen', () {
    testWidgets('the catalogue and the cart are side by side', (tester) async {
      final http = RoutedHttp();
      catalog(http);

      await pumpTill(tester, http);

      expect(card('Kopi'), findsOneWidget);
      expect(find.text('Keranjang kosong'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Keranjang kosong')).dx,
        greaterThan(tester.getTopLeft(card('Kopi')).dx),
      );
    });
  });

  group('on a narrow screen', () {
    const narrow = Size(600, 960);

    testWidgets('the cart is a bar with the total, and no second column', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http, size: narrow);

      expect(find.text('Keranjang kosong'), findsNothing);
      expect(find.text('0 item'), findsOneWidget);

      await tapProduct(tester, 'Kopi');

      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Rp 15.000'), findsNWidgets(2)); // the card and the bar
    });

    testWidgets(
      'the bar opens the whole cart, and it can be worked from there',
      (tester) async {
        final http = RoutedHttp();
        catalog(http);
        await pumpTill(tester, http, size: narrow);
        await tapProduct(tester, 'Kopi');

        await tester.tap(find.text('Keranjang'));
        await tester.pumpAndSettle();
        expect(line('Kopi'), findsOneWidget);

        await tester.tap(find.byTooltip('Tambah jumlah Kopi'));
        await tester.pump();
        expect(tester.widget<Text>(cartTotal).data, 'Rp 30.000');
      },
    );

    testWidgets('holding from the cart sheet closes the sheet: the basket is '
        'parked, and what is left to look at is the catalogue', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      final rig = Rig(storedSession(signedIn));
      await pumpTill(tester, http, rig: rig, size: narrow);
      await tapProduct(tester, 'Kopi');
      await tester.tap(find.text('Keranjang'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('hold')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hold-confirm')));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(await rig.holdStore.readAll(), hasLength(1));
      expect(find.byType(CartPane), findsNothing);
    });
  });

  group('what is rebuilt', () {
    testWidgets('adding to the cart does not rebuild the catalogue', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      final rebuilt = <String>[];
      final previous = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (element, builtOnce) =>
          rebuilt.add(element.widget.runtimeType.toString());
      addTearDown(() => debugOnRebuildDirtyWidget = previous);

      await tapProduct(tester, 'Kopi');
      await tapProduct(tester, 'Teh');

      // The grid is the expensive part of the screen, and a tap in it is the most frequent
      // thing a cashier does: it must not redraw every card for a line added to the cart.
      expect(rebuilt, isNot(contains('ProductCard')));
      expect(rebuilt, contains('CartLineTile'));
    });
  });

  group('the layout', () {
    testWidgets('has controls big enough to hit', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      await tapProduct(tester, 'Kopi');

      for (final label in [
        'Tambah jumlah Kopi',
        'Kurangi jumlah Kopi',
        'Hapus Kopi',
      ]) {
        expect(
          tester.getSize(find.byTooltip(label)).shortestSide,
          greaterThanOrEqualTo(PnTouch.min),
          reason: label,
        );
      }
      expect(
        tester.getSize(card('Kopi')).height,
        greaterThanOrEqualTo(PnTouch.min),
      );
    });

    const shapes = {
      '360 dp phone': Size(360, 800),
      '600 dp tablet': Size(600, 960),
      '800 dp tablet, portrait': Size(800, 1280),
      '1024 dp tablet': Size(1024, 768),
      '1280 dp tablet, landscape': Size(1280, 800),
    };
    for (final MapEntry(key: name, value: size) in shapes.entries) {
      for (final scale in [1.0, 1.3]) {
        for (final brightness in Brightness.values) {
          testWidgets(
            'fits a $name at text ${scale}x in the ${brightness.name} theme, with a full cart',
            (tester) async {
              final rig = Rig(storedSession(signedIn));
              await rig.theme.select(
                brightness == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
              );
              final http = RoutedHttp();
              catalog(http);
              await pumpTill(
                tester,
                http,
                rig: rig,
                size: size,
                textScale: scale,
              );
              await tapProduct(tester, 'Kopi');
              await tapProduct(tester, 'Teh');
              await tapProduct(tester, 'Jasa antar');
              await tester.pumpAndSettle();

              expect(tester.takeException(), isNull);

              if (size.width < 840) {
                await tester.tap(find.text('Keranjang'));
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                expect(line('Kopi'), findsOneWidget);
              }
            },
          );
        }
      }
    }
  });

  group('holding a basket', () {
    testWidgets('there is no Hold button until there is something to hold', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);

      await pumpTill(tester, http);

      expect(find.byKey(const Key('hold')), findsNothing);

      await tapProduct(tester, 'Kopi');
      expect(find.byKey(const Key('hold')), findsOneWidget);
    });

    testWidgets('asks for the name without raising the keyboard', (
      tester,
    ) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      await tapProduct(tester, 'Kopi');

      await tester.tap(find.byKey(const Key('hold')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hold-name')), findsOneWidget);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('asks for a name, parks the basket under it, and clears the '
        'till for the next customer', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      final rig = Rig(storedSession(signedIn));
      await pumpTill(tester, http, rig: rig);
      await tapProduct(tester, 'Kopi');
      await tapProduct(tester, 'Kopi');

      await tester.tap(find.byKey(const Key('hold')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('hold-name')), 'Meja 4');
      await tester.tap(find.byKey(const Key('hold-confirm')));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      final held = (await rig.holdStore.readAll()).single;
      expect(held.label, 'Meja 4');
      expect(held.lines.single.qty, 2);
      expect(line('Kopi'), findsNothing);
      expect(find.byKey(const Key('hold')), findsNothing);
    });
  });

  group('the held baskets', () {
    final kopiModel = model.Product(
      id: 'a',
      name: 'Kopi',
      unitId: 'unit_1',
      sellPrice: 15000,
      type: model.ProductType.inventory,
    );

    HeldOrder held(
      String id,
      String label, {
      num qty = 2,
      String heldAt = '2026-09-21T03:00:00.000Z',
    }) => HeldOrder(
      id: id,
      label: label,
      outletId: 'out_1',
      headerDiscount: 0,
      lines: [CartLine(id: 'line_$id', product: kopiModel, qty: qty)],
      heldAt: heldAt,
    );

    Future<Rig> pumpHeld(
      WidgetTester tester, {
      List<HeldOrder> seed = const [],
      Size size = const Size(1280, 800),
    }) async {
      final http = RoutedHttp();
      catalog(http);
      final rig = Rig(storedSession(signedIn));
      await rig.holdStore.writeAll(seed);
      await pumpTill(tester, http, rig: rig, size: size);
      return rig;
    }

    final heldButton = find.byKey(const Key('held-button'));

    testWidgets('the button says how many are waiting', (tester) async {
      await pumpHeld(tester, seed: [held('a', 'Meja 1'), held('b', 'Meja 2')]);

      expect(
        find.descendant(
          of: heldButton,
          matching: find.text(l10n.tillHeldCount(2)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('with none waiting it is just the word', (tester) async {
      await pumpHeld(tester);

      expect(
        find.descendant(of: heldButton, matching: find.text(l10n.tillHeld)),
        findsOneWidget,
      );
    });

    testWidgets('opens a list of what is waiting: its name, what it holds and '
        'what it comes to', (tester) async {
      await pumpHeld(tester, seed: [held('a', 'Meja 1')]);

      await tester.tap(heldButton);
      await tester.pumpAndSettle();

      expect(find.text(l10n.heldTitle), findsOneWidget);
      expect(find.text('Meja 1'), findsOneWidget);
      expect(
        find.textContaining(
          '${l10n.tillItemCount(2)} · ${formatCurrency(30000)}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an empty list says so', (tester) async {
      await pumpHeld(tester);

      await tester.tap(heldButton);
      await tester.pumpAndSettle();

      expect(find.text(l10n.heldEmpty), findsOneWidget);
    });

    testWidgets('resuming puts the basket on the till and closes the list', (
      tester,
    ) async {
      await pumpHeld(tester, seed: [held('a', 'Meja 1')]);
      await tester.tap(heldButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.heldResume));
      await tester.pumpAndSettle();

      expect(find.text(l10n.heldTitle), findsNothing);
      expect(line('Kopi'), findsOneWidget);
      // On the till, so no longer counted as waiting.
      expect(
        find.descendant(of: heldButton, matching: find.text(l10n.tillHeld)),
        findsOneWidget,
      );
    });

    testWidgets('the basket that was on the till is parked when another is '
        'resumed', (tester) async {
      final rig = await pumpHeld(tester, seed: [held('a', 'Meja 1')]);
      await tapProduct(tester, 'Teh');

      await tester.tap(heldButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.heldResume));
      await tester.pumpAndSettle();

      expect((await rig.holdStore.readAll()), hasLength(2));
      expect(line('Teh'), findsNothing);
      expect(
        find.descendant(
          of: heldButton,
          matching: find.text(l10n.tillHeldCount(1)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('discarding asks first, and then the basket is gone', (
      tester,
    ) async {
      final rig = await pumpHeld(tester, seed: [held('a', 'Meja 1')]);
      await tester.tap(heldButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.heldDrop));
      await tester.pumpAndSettle();
      expect(find.text(l10n.heldDropTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, l10n.heldDrop));
      await tester.pumpAndSettle();

      expect(await rig.holdStore.readAll(), isEmpty);
      expect(find.text('Meja 1'), findsNothing);
    });

    testWidgets('changing its mind keeps the basket', (tester) async {
      final rig = await pumpHeld(tester, seed: [held('a', 'Meja 1')]);
      await tester.tap(heldButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.heldDrop));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();

      expect(await rig.holdStore.readAll(), hasLength(1));
      expect(find.text('Meja 1'), findsOneWidget);
    });

    testWidgets('paying for a resumed basket removes it from the queue, and '
        'paying for a fresh one touches nothing', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      http.respond(
        '/api/v1/pos/sales/checkout',
        ok({
          'id': 'x1',
          'number': 'POS-0001',
          'shift_id': 's1',
          'outlet_id': 'out_1',
          'cashier_id': 'user_1',
          'transaction_date': '2026-09-20',
          'subtotal': 30000,
          'discount_amount': 0,
          'tax_amount': 0,
          'grand_total': 30000,
          'tendered_amount': 30000,
          'change_amount': 0,
          'status': 'POSTED',
          'created_at': '2026-09-20T03:00:00Z',
        }),
      );
      final rig = Rig(storedSession(signedIn));
      await rig.holdStore.writeAll([held('a', 'Meja 1'), held('b', 'Meja 2')]);
      await pumpTill(tester, http, rig: rig);
      await tester.tap(heldButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.heldResume).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pay')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-payment')));
      await tester.pumpAndSettle();

      // Only the basket that was paid for is gone.
      expect((await rig.holdStore.readAll()).length, 1);
    });

    testWidgets('holding a resumed basket again does not ask for its name '
        'twice', (tester) async {
      await pumpHeld(tester, seed: [held('a', 'Meja 1')]);
      await tester.tap(heldButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.heldResume));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('hold')));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byKey(const Key('hold-name')),
      );
      expect(field.controller!.text, 'Meja 1');
    });

    testWidgets('a basket the store did not keep says so, and stays on the '
        'till', (tester) async {
      final rig = await pumpHeld(tester);
      await tapProduct(tester, 'Kopi');
      rig.holdStore.failWrite = true;

      await tester.tap(find.byKey(const Key('hold')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hold-confirm')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.tillHoldNotStored), findsOneWidget);
      expect(line('Kopi'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });

    testWidgets('a basket on the till that cannot be parked stops the resume, '
        'and says so', (tester) async {
      final rig = await pumpHeld(tester, seed: [held('a', 'Meja 1')]);
      await tapProduct(tester, 'Teh');
      rig.holdStore.failWrite = true;
      await tester.tap(heldButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.heldResume));
      await tester.pumpAndSettle();

      expect(find.text(l10n.tillResumeNotStored), findsOneWidget);
      expect(line('Teh'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });
  });

  group('the held list fits the screen', () {
    const shapes = {
      '360 dp phone': Size(360, 740),
      '600 dp tablet, portrait': Size(600, 960),
      '800 dp tablet, portrait': Size(800, 1280),
      '1024 dp tablet': Size(1024, 768),
      '1280 dp tablet, landscape': Size(1280, 800),
    };
    for (final MapEntry(key: name, value: size) in shapes.entries) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('a $name at text ${scale}x, with long names and a full '
            'basket', (tester) async {
          final http = RoutedHttp();
          catalog(http);
          final rig = Rig(storedSession(signedIn));
          final big = model.Product(
            id: 'big',
            name: 'Barang mahal',
            unitId: 'unit_1',
            sellPrice: 1234567890,
          );
          await rig.holdStore.writeAll([
            for (var i = 0; i < 6; i++)
              HeldOrder(
                id: 'h$i',
                label:
                    'Meja nomor $i untuk rombongan keluarga besar yang memesan banyak',
                outletId: 'out_1',
                headerDiscount: 0,
                lines: [CartLine(id: 'l$i', product: big, qty: 999)],
                heldAt: '2026-09-21T0$i:00:00.000Z',
              ),
          ]);
          await pumpTill(tester, http, rig: rig, size: size, textScale: scale);
          await tester.tap(find.byKey(const Key('held-button')));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);

          await tester.tap(find.text(l10n.heldDrop).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('the offline queue status item', () {
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

    PendingSale pendingEntry({
      String ref = 'REF-1',
      PendingSaleStatus status = PendingSaleStatus.pending,
    }) => PendingSale(
      clientRef: ref,
      companyId: 'comp_1',
      outletId: 'out_1',
      cashierId: 'user_1',
      status: status,
      error: status == PendingSaleStatus.failed ? 'ditolak' : null,
      paidAt: '2026-09-20T03:00:00.000Z',
      createdAt: '2026-09-20T03:00:00.000Z',
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

    /// Writes [entries] straight to the store — the way a sale already sits there when the
    /// cashier looks up, not the way one gets queued mid-sale — then asks `QueueSync` to count
    /// them again: a store write alone does not, on its own, change what it already read
    /// (`plan/offline-queue/findings.md` F17).
    Future<void> seedQueue(
      WidgetTester tester,
      List<PendingSale> entries,
    ) async {
      final services = AppScope.of(tester.element(find.byType(TillScreen)));
      for (final e in entries) {
        await services.pendingSaleStore.enqueue(e);
      }
      await services.queueSync.refreshCounts();
      await tester.pump();
    }

    testWidgets('is absent when nothing is queued', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);

      expect(find.text(l10n.tillStatusQueue(1)), findsNothing);
    });

    testWidgets('says how many sales are not sent', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);

      await seedQueue(tester, [pendingEntry()]);

      expect(find.text(l10n.tillStatusQueue(1)), findsOneWidget);
    });

    testWidgets('says so when one of them has failed', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);

      await seedQueue(tester, [
        pendingEntry(ref: 'REF-1'),
        pendingEntry(ref: 'REF-2', status: PendingSaleStatus.failed),
      ]);

      expect(find.text(l10n.tillStatusQueueFailed(2)), findsOneWidget);
    });

    testWidgets('opens the pending sales screen when tapped', (tester) async {
      final http = RoutedHttp();
      catalog(http);
      await pumpTill(tester, http);
      await seedQueue(tester, [pendingEntry()]);

      await tester.tap(find.text(l10n.tillStatusQueue(1)));
      await tester.pumpAndSettle();

      expect(find.byType(PendingSalesScreen), findsOneWidget);
    });
  });
}

const _digit = {
  '0': LogicalKeyboardKey.digit0,
  '1': LogicalKeyboardKey.digit1,
  '2': LogicalKeyboardKey.digit2,
  '3': LogicalKeyboardKey.digit3,
  '4': LogicalKeyboardKey.digit4,
  '5': LogicalKeyboardKey.digit5,
  '6': LogicalKeyboardKey.digit6,
  '7': LogicalKeyboardKey.digit7,
  '8': LogicalKeyboardKey.digit8,
  '9': LogicalKeyboardKey.digit9,
};
