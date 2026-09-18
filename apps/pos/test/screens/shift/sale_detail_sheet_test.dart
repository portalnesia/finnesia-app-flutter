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
import 'package:pn_pos/src/format.dart';
import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/screens/shift/sale_detail_sheet.dart';

import '../../support/boot_rig.dart';
import '../../support/routed_http.dart';

// S11. What a cashier reads when a sale in the shift's list is tapped: the goods, the payments and
// the totals of one recorded sale. Behaviour from `pos-receipt.tsx` (what a receipt lists and
// when it lists it); the shape is this app's own, a sheet rather than a page, so the list the
// cashier came from stays where it was.
//
// Words come from the generated `L10n`, not from literals: the test should break when a sentence
// stops being shown, not when it is reworded.

final l10n = lookupL10n(const Locale('id'));

const salePath = '/api/v1/pos/sales/x1';
const outletPath = '/api/v1/outlets/out_1';

const kitchen = PrinterDevice(address: 'AA:BB', name: 'Dapur');

Map<String, Object?> line(
  String id, {
  String? name,
  String? description,
  num quantity = 1,
  num price = 15000,
  num? subtotal,
  num? total,
}) => {
  'id': id,
  'quantity': quantity,
  'price': price,
  'line_subtotal': subtotal ?? quantity * price,
  'line_total': total ?? subtotal ?? quantity * price,
  'description': ?description,
  if (name != null) 'product': {'id': 'p_$id', 'name': name},
};

Map<String, Object?> payment(String method, num amount, {String? reference}) =>
    {
      'id': 'pay_$method',
      'method': method,
      'amount': amount,
      'reference': ?reference,
    };

Map<String, Object?> sale({
  String status = 'POSTED',
  List<Map<String, Object?>>? items,
  List<Map<String, Object?>>? payments,
  num subtotal = 30000,
  num discount = 0,
  num tax = 0,
  num total = 30000,
  num tendered = 50000,
  num change = 20000,
  String? tableNumber,
  String? queueNumber,
  String? notes,
  bool invoice = true,
}) => {
  'id': 'x1',
  'number': 'POS-0001',
  'shift_id': 's1',
  'outlet_id': 'out_1',
  'cashier_id': 'user_1',
  'transaction_date': '2026-09-20',
  'subtotal': subtotal,
  'discount_amount': discount,
  'tax_amount': tax,
  'grand_total': total,
  'tendered_amount': tendered,
  'change_amount': change,
  'status': status,
  'created_at': '2026-09-20T03:00:00Z',
  'cashier': {'id': 'user_1', 'name': 'Budi'},
  'payments': payments ?? [payment('CASH', 30000)],
  'table_number': ?tableNumber,
  'queue_number': ?queueNumber,
  'notes': ?notes,
  if (invoice)
    'invoice': {
      'items': items ?? [line('i1', name: 'Kopi Susu', quantity: 2)],
    },
};

final signedIn = paired.copyWith(
  user: const SessionUser(id: 'user_1', name: 'Budi'),
);

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: FilledButton(
          onPressed: () => showSaleDetailSheet(context, saleId: 'x1'),
          child: const Text('open sale'),
        ),
      ),
    ),
  );
}

Widget appWith(Rig rig, RoutedHttp http) => PosApp(
  boot: () => rig.bootWith(http: http),
  language: rig.language,
  theme: rig.theme,
  screens: (
    pairing: (_) => const Text('pairing'),
    login: (_) => const Text('login'),
    till: (_) => const _Host(),
  ),
);

void useSize(WidgetTester tester, Size size, double textScale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Opens the sheet over the host, with [http] holding the answers.
Future<Rig> openSheet(
  WidgetTester tester,
  RoutedHttp http, {
  Size size = const Size(1280, 800),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  bool settle = true,
  PrinterDevice? savedPrinter,
  FakePrinter? printer,
}) async {
  useSize(tester, size, textScale);
  final stored = {
    ...storedSession(signedIn),
    if (savedPrinter != null)
      printerKey: jsonEncode({
        'address': savedPrinter.address,
        'name': savedPrinter.name,
      }),
  };
  final rig = Rig(stored);
  if (printer != null) rig.printer = printer;
  await rig.theme.select(theme);
  await tester.pumpWidget(appWith(rig, http));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open sale'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return rig;
}

String money(num v) => formatCurrency(v);

void main() {
  group('what the sheet shows', () {
    testWidgets('reads the one sale, once', (tester) async {
      final http = RoutedHttp()..respond(salePath, ok(sale()));

      await openSheet(tester, http);

      expect(http.count(salePath), 1);
    });

    testWidgets('names the sale, when it was made and by whom', (tester) async {
      final http = RoutedHttp()..respond(salePath, ok(sale()));

      await openSheet(tester, http);

      expect(find.text('POS-0001'), findsOneWidget);
      expect(find.text('Budi'), findsOneWidget);
      expect(find.textContaining('20 Sep 2026'), findsOneWidget);
    });

    testWidgets('lists each line with what was bought and what it cost', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(
          salePath,
          ok(
            sale(
              items: [
                line('i1', name: 'Kopi Susu', quantity: 2),
                line('i2', name: 'Roti Bakar', price: 12000),
              ],
              subtotal: 42000,
              total: 42000,
            ),
          ),
        );

      await openSheet(tester, http);

      expect(find.text('Kopi Susu'), findsOneWidget);
      expect(find.text('Roti Bakar'), findsOneWidget);
      expect(find.textContaining('2 x ${money(15000)}'), findsOneWidget);
      // The line's own total, in the amount column.
      expect(find.text(money(30000)), findsWidgets);
      expect(find.text(money(12000)), findsWidgets);
    });

    testWidgets('shows a fractional quantity as it is, not as 1.5.0', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(
          salePath,
          ok(
            sale(
              items: [line('i1', name: 'Gula', quantity: 1.5, price: 10000)],
            ),
          ),
        );

      await openSheet(tester, http);

      expect(find.textContaining('1.5 x ${money(10000)}'), findsOneWidget);
    });

    testWidgets('shows a whole quantity the server sent as 2.0 as 2', (
      tester,
    ) async {
      // JSON `2.0` decodes to a double, and Dart would print `2.0 x`. The web app prints `2 x`.
      final http = RoutedHttp()
        ..respond(
          salePath,
          ok(sale(items: [line('i1', name: 'Kopi', quantity: 2.0)])),
        );

      await openSheet(tester, http);

      expect(find.textContaining('2 x ${money(15000)}'), findsOneWidget);
      expect(find.textContaining('2.0'), findsNothing);
    });

    testWidgets('falls back to the description, then to a word, for a line '
        'with no product name', (tester) async {
      final http = RoutedHttp()
        ..respond(
          salePath,
          ok(
            sale(
              items: [
                // An empty name is not a name: the receipt would print a blank line.
                line('i1', name: '', description: 'Bungkus'),
                line('i2', name: '', description: ''),
              ],
            ),
          ),
        );

      await openSheet(tester, http);

      expect(find.text('Bungkus'), findsOneWidget);
      expect(find.text(l10n.saleDetailUnknownProduct), findsOneWidget);
    });

    testWidgets('a line the customer got a discount on says how much', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(
          salePath,
          ok(
            sale(
              items: [
                line(
                  'i1',
                  name: 'Kopi Susu',
                  quantity: 2,
                  subtotal: 27000, // 30000 less 3000
                  total: 27000,
                ),
              ],
              subtotal: 27000,
              total: 27000,
            ),
          ),
        );

      await openSheet(tester, http);

      expect(find.textContaining('-${money(3000)}'), findsOneWidget);
    });

    testWidgets('says the goods are not available when the sale came without '
        'its invoice', (tester) async {
      final http = RoutedHttp()..respond(salePath, ok(sale(invoice: false)));

      await openSheet(tester, http);

      expect(find.text(l10n.saleDetailNoItems), findsOneWidget);
    });

    testWidgets('shows the table, the queue number and the note only when '
        'there are ones', (tester) async {
      final http = RoutedHttp()..respond(salePath, ok(sale()));
      await openSheet(tester, http);
      expect(find.text(l10n.posTableNumber), findsNothing);
      expect(find.text(l10n.posQueueNumber), findsNothing);
      expect(find.text(l10n.saleDetailNotes), findsNothing);
    });

    testWidgets('shows the table, the queue number and the note when there '
        'are ones', (tester) async {
      final http = RoutedHttp()
        ..respond(
          salePath,
          ok(sale(tableNumber: '12', queueNumber: 'A-45', notes: 'Tanpa es')),
        );

      await openSheet(tester, http);

      expect(find.text('12'), findsOneWidget);
      expect(find.text('A-45'), findsOneWidget);
      expect(find.text('Tanpa es'), findsOneWidget);
    });
  });

  group('the totals', () {
    testWidgets('shows the subtotal and the total, and no discount or tax '
        'row when there is none', (tester) async {
      final http = RoutedHttp()..respond(salePath, ok(sale()));

      await openSheet(tester, http);

      expect(find.text(l10n.tillSubtotal), findsOneWidget);
      expect(find.text(l10n.tillTotal), findsOneWidget);
      expect(find.text(l10n.tillDiscount), findsNothing);
      expect(find.text(l10n.saleDetailTax), findsNothing);
    });

    testWidgets('shows the discount and the tax when they are above zero', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(
          salePath,
          ok(sale(subtotal: 30000, discount: 2000, tax: 3080, total: 31080)),
        );

      await openSheet(tester, http);

      expect(find.text(l10n.tillDiscount), findsOneWidget);
      expect(find.text('-${money(2000)}'), findsOneWidget);
      expect(find.text(l10n.saleDetailTax), findsOneWidget);
      expect(find.text(money(3080)), findsOneWidget);
    });
  });

  group('the payments', () {
    testWidgets('a single cash payment shows what was received and the '
        'change', (tester) async {
      final http = RoutedHttp()..respond(salePath, ok(sale()));

      await openSheet(tester, http);

      expect(find.text(l10n.posTenderMethodCASH), findsOneWidget);
      expect(find.text(l10n.saleDetailTendered), findsOneWidget);
      expect(find.text(money(50000)), findsOneWidget);
      expect(find.text(l10n.posChangeDue), findsOneWidget);
      expect(find.text(money(20000)), findsOneWidget);
    });

    testWidgets('a single transfer shows neither received nor change: the '
        'customer did not hand over cash', (tester) async {
      final http = RoutedHttp()
        ..respond(
          salePath,
          ok(
            sale(
              payments: [payment('TRANSFER', 30000, reference: 'TRX-99')],
              tendered: 30000,
              change: 0,
            ),
          ),
        );

      await openSheet(tester, http);

      expect(find.text(l10n.posTenderMethodTRANSFER), findsOneWidget);
      expect(find.text('TRX-99'), findsOneWidget);
      expect(find.text(l10n.saleDetailTendered), findsNothing);
      expect(find.text(l10n.posChangeDue), findsNothing);
    });

    testWidgets('a split sale lists every payment, and the change once when '
        'cash was one of them', (tester) async {
      final http = RoutedHttp()
        ..respond(
          salePath,
          ok(
            sale(
              payments: [payment('CASH', 10000), payment('QRIS', 20000)],
              tendered: 40000,
              change: 10000,
            ),
          ),
        );

      await openSheet(tester, http);

      expect(find.text(l10n.posTenderMethodCASH), findsOneWidget);
      expect(find.text(l10n.posTenderMethodQRIS), findsOneWidget);
      expect(find.text(money(10000)), findsNWidgets(2)); // cash and change
      expect(find.text(l10n.posChangeDue), findsOneWidget);
      // `tendered_amount` totals every method, so "received" would be a wrong figure here.
      expect(find.text(l10n.saleDetailTendered), findsNothing);
    });

    testWidgets('prints a method this build no longer offers as it is', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(
          salePath,
          ok(
            sale(
              payments: [payment('GIRO', 30000)],
              tendered: 30000,
              change: 0,
            ),
          ),
        );

      await openSheet(tester, http);

      expect(find.text('GIRO'), findsOneWidget);
    });

    testWidgets('a sale with no payments loaded lists none and shows no '
        'change', (tester) async {
      final json = sale()..remove('payments');
      final http = RoutedHttp()..respond(salePath, ok(json));

      await openSheet(tester, http);

      expect(find.text(l10n.saleDetailPayments), findsNothing);
      expect(find.text(l10n.posChangeDue), findsNothing);
    });
  });

  group('a voided sale', () {
    testWidgets('says so in words', (tester) async {
      final http = RoutedHttp()..respond(salePath, ok(sale(status: 'VOID')));

      await openSheet(tester, http);

      expect(find.text(l10n.saleDetailVoided), findsOneWidget);
    });

    testWidgets('a posted sale does not', (tester) async {
      final http = RoutedHttp()..respond(salePath, ok(sale()));

      await openSheet(tester, http);

      expect(find.text(l10n.saleDetailVoided), findsNothing);
    });
  });

  group('while it reads, and when it cannot', () {
    testWidgets('says it is loading', (tester) async {
      final http = RoutedHttp()..hold(salePath);

      await openSheet(tester, http, settle: false);

      expect(find.text(l10n.commonLoading), findsOneWidget);

      http.release(salePath, ok(sale()));
      await tester.pumpAndSettle();
    });

    testWidgets('a failed read says so and offers to try again, and trying '
        'again reads it again', (tester) async {
      final http = RoutedHttp()
        ..respond(salePath, refused(500, 'Gagal'))
        ..respond(salePath, ok(sale()));

      await openSheet(tester, http);

      expect(find.text('Gagal'), findsOneWidget);
      expect(find.text('POS-0001'), findsNothing);

      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(find.text('POS-0001'), findsOneWidget);
      expect(http.count(salePath), 2);
    });

    testWidgets('no answer at all is a failed read, not a crash', (
      tester,
    ) async {
      final http = RoutedHttp()..fail(salePath);

      await openSheet(tester, http);

      expect(find.text(l10n.saleDetailLoadFailed), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('closing it', () {
    testWidgets('the close button takes it away', (tester) async {
      final http = RoutedHttp()..respond(salePath, ok(sale()));
      await openSheet(tester, http);

      await tester.tap(find.byTooltip(l10n.commonClose));
      await tester.pumpAndSettle();

      expect(find.text('POS-0001'), findsNothing);
      expect(find.text('open sale'), findsOneWidget);
    });

    testWidgets('Escape takes it away', (tester) async {
      final http = RoutedHttp()..respond(salePath, ok(sale()));
      await openSheet(tester, http);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('POS-0001'), findsNothing);
    });
  });

  group('printing the receipt', () {
    Finder printButton() => find.widgetWithText(OutlinedButton, 'Cetak struk');
    String paper(Rig rig) => String.fromCharCodes(rig.printer.written.single);

    testWidgets('sends the official receipt to the printer that is paired', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(salePath, ok(sale()))
        ..respond(settingsPath, ok({'require_shift': true}))
        ..respond(outletPath, ok({'id': 'out_1', 'name': 'Outlet Pusat'}));

      final rig = await openSheet(tester, http, savedPrinter: kitchen);
      await tester.tap(printButton());
      await tester.pumpAndSettle();

      final text = paper(rig);
      expect(text, contains('POS-0001'));
      expect(text, contains('Kopi Susu'));
      expect(text, contains('Outlet Pusat'));
      expect(find.text(l10n.receiptSent), findsOneWidget);
    });

    testWidgets('logs receipt_printed', (tester) async {
      final http = RoutedHttp()
        ..respond(salePath, ok(sale()))
        ..respond(settingsPath, ok({'require_shift': true}))
        ..respond(outletPath, ok({'id': 'out_1', 'name': 'Outlet Pusat'}));

      final rig = await openSheet(tester, http, savedPrinter: kitchen);
      await tester.tap(printButton());
      await tester.pumpAndSettle();

      expect(rig.analytics.logged.map((e) => e.$1), ['receipt_printed']);
    });

    // A slip for a cancelled sale still has to say so — the same banner the printed receipt
    // showed the first time, from the same formatter (`receiptVoided`).
    testWidgets('a voided sale reprints with the cancellation banner', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(salePath, ok(sale(status: 'VOID')))
        ..respond(settingsPath, ok({'require_shift': true}))
        ..respond(outletPath, ok({'id': 'out_1', 'name': 'Outlet Pusat'}));

      final rig = await openSheet(tester, http, savedPrinter: kitchen);
      await tester.tap(printButton());
      await tester.pumpAndSettle();

      expect(paper(rig), contains(l10n.receiptVoided));
    });

    testWidgets('with no printer paired it offers one, and prints once it is', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(salePath, ok(sale()))
        ..respond(settingsPath, ok({'require_shift': true}))
        ..respond(outletPath, ok({'id': 'out_1', 'name': 'Outlet Pusat'}));

      final rig = await openSheet(
        tester,
        http,
        printer: FakePrinter([kitchen]),
      );
      await tester.tap(printButton());
      await tester.pumpAndSettle();
      expect(find.text(l10n.printerPairTitle), findsOneWidget);

      await tester.tap(
        find.widgetWithText(FilledButton, l10n.printerScanButton),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dapur'));
      await tester.pumpAndSettle();

      expect(paper(rig), contains('POS-0001'));
    });

    testWidgets('the reason a printer will not connect is said in words', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(salePath, ok(sale()))
        ..respond(settingsPath, ok({'require_shift': true}))
        ..respond(outletPath, ok({'id': 'out_1', 'name': 'Outlet Pusat'}));
      final printer = FakePrinter()
        ..failNext(
          PrinterOp.connect,
          PrinterException(PrinterFailure.bluetoothOff),
        );

      final rig = await openSheet(
        tester,
        http,
        savedPrinter: kitchen,
        printer: printer,
      );
      await tester.tap(printButton());
      await tester.pumpAndSettle();

      expect(find.text(l10n.printerBluetoothOff), findsOneWidget);
      expect(rig.printer.written, isEmpty);
    });
  });

  group('fitting the screen', () {
    const shapes = {
      '360 dp phone': Size(360, 740),
      '600 dp tablet, portrait': Size(600, 960),
      '800 dp tablet, portrait': Size(800, 1280),
      '1280 dp tablet, landscape': Size(1280, 800),
    };
    for (final MapEntry(key: name, value: size) in shapes.entries) {
      for (final scale in [1.0, 1.3]) {
        for (final theme in [ThemeMode.light, ThemeMode.dark]) {
          testWidgets(
            'a full sale fits a $name at text ${scale}x in the ${theme.name} theme',
            (tester) async {
              final http = RoutedHttp()
                ..respond(
                  salePath,
                  ok(
                    sale(
                      items: [
                        line(
                          'i1',
                          name: 'Kopi Susu Gula Aren Dingin Ukuran Besar',
                          quantity: 12.5,
                          price: 1234567,
                        ),
                        line('i2', name: 'Roti'),
                      ],
                      payments: [
                        payment('CASH', 10000),
                        payment(
                          'TRANSFER',
                          20000,
                          reference: 'TRX-REFERENSI-PANJANG-99',
                        ),
                      ],
                      discount: 2000,
                      tax: 3080,
                      tableNumber: '12',
                      queueNumber: 'A-45',
                      notes: 'Catatan yang cukup panjang untuk membungkus ke baris kedua',
                    ),
                  ),
                );

              await openSheet(
                tester,
                http,
                size: size,
                textScale: scale,
                theme: theme,
              );

              expect(tester.takeException(), isNull);
              expect(find.text('POS-0001'), findsOneWidget);
            },
          );
        }
      }
    }
  });
}
