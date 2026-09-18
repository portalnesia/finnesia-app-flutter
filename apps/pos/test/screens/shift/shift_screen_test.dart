/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/queue/pending_sales_screen.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/screens/shift/cash_movement_sheet.dart';
import 'package:pos/screens/shift/close_shift_screen.dart';
import 'package:pos/screens/shift/shift_screen.dart';

import '../../support/boot_rig.dart';
import '../../support/routed_http.dart';

// S10. What a cashier reads to explain a variance: the drawer's figures, and behind them the
// individual sales and the cash that moved in and out. Behaviour from `shift-page.tsx`; the shape
// is this app's own: the figures beside the lists on a wide tablet, and one column at a time
// (behind three tabs) on a narrow one.
//
// It is read-only. Closing the shift and recording cash movements are C9, and nothing here
// pretends to be them.
//
// Words come from the generated `L10n`, not from literals.

final l10n = lookupL10n(const Locale('id'));

const summaryPath = '/api/v1/pos/shifts/s1';
const movementsPath = '/api/v1/pos/shifts/s1/cash-movements';
const salesPath = '/api/v1/pos/sales';
const permissionsPath = '/api/v1/team/my-permissions';
const settingsPathRoute = '/api/v1/pos/settings';
const coaPathRoute = '/api/v1/master/coa';
const movementPostPath = '/api/v1/pos/shifts/s1/cash-movement';

String money(num v) => formatCurrency(v);

TransportResponse page(List<Map<String, Object?>> items, {String? next}) =>
    TransportResponse(
      status: 200,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'data': items,
        'meta': {'next_cursor': next},
      }),
    );

Map<String, Object?> shiftBody({
  String cashierId = 'user_1',
  String? cashierName = 'Budi',
}) => {
  'id': 's1',
  'number': 'SH-0001',
  'cashier_id': cashierId,
  'outlet_id': 'out_1',
  'opened_at': '2026-09-20T01:00:00Z',
  'opening_cash': 150000,
  'total_sales': 200000,
  'total_transactions': 3,
  'cashier': ?(cashierName == null
      ? null
      : {'id': cashierId, 'name': cashierName}),
};

Map<String, Object?> summaryBody({
  String status = 'OPEN',
  Map<String, Object?>? byMethod,
  num? counted,
  num? variance,
  String? notes,
  String? closedAt,
  String cashierId = 'user_1',
  String cashierName = 'Budi',
}) => {
  'shift_id': 's1',
  'number': 'SH-0001',
  'status': status,
  'outlet_id': 'out_1',
  'cashier_id': cashierId,
  'cashier_name': cashierName,
  'outlet_name': 'Outlet Pusat',
  'opened_at': '2026-09-20T01:00:00Z',
  'closed_at': ?closedAt,
  'notes': ?notes,
  'total_transactions': 3,
  'total_sales': 200000,
  'opening_cash': 150000,
  'expected_cash': 275000,
  'counted_cash': ?counted,
  'cash_variance': ?variance,
  'cash_in': 20000,
  'cash_out': 5000,
  'cash_drop': 10000,
  'sales_by_method': byMethod ?? {'CASH': 120000, 'QRIS': 80000},
  'non_cash_tenders': <Object?>[],
  'product_sales': <Object?>[],
};

Map<String, Object?> saleBody(
  String id, {
  String status = 'POSTED',
  num total = 75000,
}) => {
  'id': id,
  'number': 'POS-$id',
  'shift_id': 's1',
  'outlet_id': 'out_1',
  'cashier_id': 'user_1',
  'transaction_date': '2026-09-20',
  'subtotal': total,
  'discount_amount': 0,
  'tax_amount': 0,
  'grand_total': total,
  'tendered_amount': total,
  'change_amount': 0,
  'status': status,
  'created_at': '2026-09-20T03:00:00Z',
};

Map<String, Object?> movementBody(
  String id,
  String type,
  num amount,
  String reason,
) => {
  'id': id,
  'shift_id': 's1',
  'type': type,
  'amount': amount,
  'reason': reason,
  'created_at': '2026-09-20T04:00:00Z',
  'creator': {'id': 'user_1', 'name': 'Budi'},
};

/// Everything the screen reads when it opens.
void backend(
  RoutedHttp http, {
  Map<String, Object?>? shift,
  Map<String, Object?>? summary,
  List<Map<String, Object?>>? sales,
  String? nextSales,
  List<Map<String, Object?>>? movements,
}) {
  http.respond(activePath, ok(shift ?? shiftBody()));
  http.respond(summaryPath, ok(summary ?? summaryBody()));
  http.respond(
    movementsPath,
    ok(
      movements ??
          [
            movementBody('m1', 'CASH_IN', 20000, 'Tambah kembalian'),
            movementBody('m2', 'CASH_OUT', 5000, 'Beli galon'),
            movementBody('m3', 'DROP', 10000, 'Setor ke brankas'),
          ],
    ),
  );
  http.respond(
    salesPath,
    page(
      sales ?? [saleBody('a'), saleBody('b', status: 'VOID', total: 40000)],
      next: nextSales,
    ),
  );
}

const _queueDraft = POSCheckoutDTO(
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

PendingSale queueEntry({
  String ref = 'REF-1',
  PendingSaleStatus status = PendingSaleStatus.pending,
}) => PendingSale(
  clientRef: ref,
  companyId: 'comp_1',
  outletId: 'out_1',
  cashierId: 'user_1',
  status: status,
  paidAt: '2026-09-20T03:00:00.000Z',
  createdAt: '2026-09-20T03:00:00.000Z',
  payload: _queueDraft,
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

const ownerMembership = UserCompany(
  id: 'uc_1',
  userId: 'user_1',
  companyId: 'comp_1',
  role: 'owner',
  isActive: true,
);

final signedIn = paired.copyWith(
  user: const SessionUser(id: 'user_1', name: 'Budi'),
);

/// A screen under the shift screen, so going back has somewhere to go.
class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const ShiftScreen())),
          child: const Text('open shift screen'),
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

Future<Rig> pumpShift(
  WidgetTester tester,
  RoutedHttp http, {
  Size size = const Size(1280, 800),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  bool settle = true,
  PosSession? session,
}) async {
  useSize(tester, size, textScale);
  final rig = Rig(storedSession(session ?? signedIn));
  await rig.theme.select(theme);
  await tester.pumpWidget(appWith(rig, http));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open shift screen'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return rig;
}

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
}

/// How often [path] was asked for, exactly: `RoutedHttp.count` matches by prefix, and the
/// summary's path is the start of the movements' path.
int asked(RoutedHttp http, String path) =>
    http.calls.where((c) => c.path.split('?').first == path).length;

void main() {
  actions();
  group('reading it', () {
    testWidgets('reads the shift of the paired outlet, then its figures, '
        'movements and sales, once each', (tester) async {
      final http = RoutedHttp();
      backend(http);

      await pumpShift(tester, http);

      expect(asked(http, activePath), 1);
      expect(asked(http, summaryPath), 1);
      expect(asked(http, movementsPath), 1);
      expect(asked(http, salesPath), 1);
      final active = http.calls.firstWhere(
        (c) => c.path.startsWith(activePath),
      );
      expect(active.path, contains('outlet_id=out_1'));
      final sales = http.calls.firstWhere((c) => c.path.startsWith(salesPath));
      expect(sales.path, contains('shift_id=s1'));
    });

    testWidgets('says it is loading while the shift is being read', (
      tester,
    ) async {
      final http = RoutedHttp()..hold(activePath);

      await pumpShift(tester, http, settle: false);

      expect(find.text(l10n.commonLoading), findsOneWidget);

      http.release(activePath, ok(null));
      await tester.pumpAndSettle();
    });

    testWidgets('a failed shift read is a failure with a way to try again, '
        'not "no shift is open"', (tester) async {
      final http = RoutedHttp()..respond(activePath, refused(500, 'Gagal'));
      await pumpShift(tester, http);

      // The server's sentence, not this screen's own: a refusal is the server's to explain.
      expect(find.text('Gagal'), findsOneWidget);
      expect(find.text(l10n.shiftDetailNone), findsNothing);

      backend(http);
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(find.text('SH-0001'), findsWidgets);
    });

    testWidgets('no shift open: says so, and asks for nothing more', (
      tester,
    ) async {
      final http = RoutedHttp()..respond(activePath, ok(null));

      await pumpShift(tester, http);

      expect(find.text(l10n.shiftDetailNone), findsOneWidget);
      expect(http.calls, hasLength(1));
    });

    testWidgets('another cashier\'s shift: says whose it is, shows no figures '
        'and reads none', (tester) async {
      final http = RoutedHttp()
        ..respond(
          activePath,
          ok(shiftBody(cashierId: 'user_9', cashierName: 'Andi')),
        )
        ..respond(permissionsPath, ok(<String>[]));

      await pumpShift(tester, http);

      expect(find.text(l10n.shiftHeldTitle), findsOneWidget);
      expect(
        find.text(l10n.shiftDetailHeldDesc('SH-0001', 'Andi')),
        findsOneWidget,
      );
      expect(find.text(l10n.shiftDetailExpectedCash), findsNothing);
      // The shift, and what this cashier may do; none of the drawer's figures.
      expect(http.calls, hasLength(2));
    });

    testWidgets('an owner sees the figures of a shift another cashier holds', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(
        http,
        shift: shiftBody(cashierId: 'user_9', cashierName: 'Andi'),
      );

      await pumpShift(
        tester,
        http,
        session: signedIn.copyWith(companies: [ownerMembership]),
      );

      expect(find.text(l10n.shiftHeldTitle), findsNothing);
      expect(find.text(l10n.shiftDetailExpectedCash), findsOneWidget);
    });

    testWidgets('another cashier with no name on record is named by a word, '
        'not left blank', (tester) async {
      final http = RoutedHttp()
        ..respond(
          activePath,
          ok(shiftBody(cashierId: 'user_9', cashierName: null)),
        )
        ..respond(permissionsPath, ok(<String>[]));

      await pumpShift(tester, http);

      expect(
        find.text(
          l10n.shiftDetailHeldDesc('SH-0001', l10n.shiftUnknownCashier),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the back button leaves the screen', (tester) async {
      final http = RoutedHttp();
      backend(http);
      await pumpShift(tester, http);

      await tester.tap(find.byTooltip(l10n.menuBack));
      await tester.pumpAndSettle();

      expect(find.text('open shift screen'), findsOneWidget);
    });
  });

  group('the figures', () {
    testWidgets('names the shift, who has it, where, and since when', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);

      await pumpShift(tester, http);

      expect(find.text(l10n.shiftDetailTitle), findsOneWidget);
      expect(find.text('SH-0001'), findsOneWidget);
      expect(find.text('Budi'), findsWidgets);
      expect(find.text('Outlet Pusat'), findsOneWidget);
      expect(find.textContaining('20 Sep 2026'), findsWidgets);
    });

    testWidgets('says the shift is open, in words', (tester) async {
      final http = RoutedHttp();
      backend(http);

      await pumpShift(tester, http);

      expect(find.text(l10n.shiftDetailOpen), findsOneWidget);
    });

    testWidgets('says a closed shift is closed, and when', (tester) async {
      final http = RoutedHttp();
      backend(
        http,
        summary: summaryBody(
          status: 'CLOSED',
          closedAt: '2026-09-20T09:00:00Z',
        ),
      );

      await pumpShift(tester, http);

      expect(find.text(l10n.shiftDetailClosed), findsWidgets);
      expect(find.text(l10n.shiftDetailClosedAtLabel), findsOneWidget);
    });

    testWidgets('lists every term of the drawer and the figure it is counted '
        'against', (tester) async {
      final http = RoutedHttp();
      backend(http);

      await pumpShift(tester, http);

      expect(find.text(l10n.shiftDetailTransactions), findsOneWidget);
      expect(find.text(l10n.shiftDetailTotalSales), findsOneWidget);
      expect(find.text(money(200000)), findsOneWidget);
      expect(find.text(l10n.shiftDetailOpeningCash), findsOneWidget);
      expect(find.text(money(150000)), findsOneWidget);
      expect(find.text(l10n.shiftDetailCashIn), findsOneWidget);
      expect(find.text(money(20000)), findsWidgets);
      expect(find.text(l10n.shiftDetailExpectedCash), findsOneWidget);
      expect(find.text(money(275000)), findsOneWidget);
    });

    testWidgets('cash out and drops are one row, as the printed report has '
        'them', (tester) async {
      final http = RoutedHttp();
      backend(http);

      await pumpShift(tester, http);

      expect(find.text(l10n.shiftDetailCashOutAndDrop), findsOneWidget);
      expect(find.text(money(15000)), findsOneWidget);
    });

    testWidgets('an open shift has no counted cash and no variance', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);

      await pumpShift(tester, http);

      expect(find.text(l10n.shiftDetailCountedCash), findsNothing);
      expect(find.text(l10n.shiftDetailVarianceLabel), findsNothing);
    });

    testWidgets('a closed shift with a shortfall says short, in words', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(
        http,
        summary: summaryBody(
          status: 'CLOSED',
          counted: 270000,
          variance: -5000,
        ),
      );

      // Tall, so the figures list builds down to the last row: it is lazy, like every long list.
      await pumpShift(tester, http, size: const Size(1280, 1600));

      expect(find.text(l10n.shiftDetailCountedCash), findsOneWidget);
      expect(find.text(money(270000)), findsOneWidget);
      expect(
        find.text(l10n.shiftDetailVarianceShort(money(5000))),
        findsOneWidget,
      );
    });

    testWidgets('a surplus says over', (tester) async {
      final http = RoutedHttp();
      backend(
        http,
        summary: summaryBody(status: 'CLOSED', counted: 277000, variance: 2000),
      );

      // Tall, so the figures list builds down to the last row: it is lazy, like every long list.
      await pumpShift(tester, http, size: const Size(1280, 1600));

      expect(
        find.text(l10n.shiftDetailVarianceOver(money(2000))),
        findsOneWidget,
      );
    });

    testWidgets('an exact drawer says exact', (tester) async {
      final http = RoutedHttp();
      backend(
        http,
        summary: summaryBody(status: 'CLOSED', counted: 275000, variance: 0),
      );

      // Tall, so the figures list builds down to the last row: it is lazy, like every long list.
      await pumpShift(tester, http, size: const Size(1280, 1600));

      expect(find.text(l10n.shiftDetailVarianceNone), findsOneWidget);
    });

    testWidgets('sales by method: each method named, an old one as it is', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(
        http,
        summary: summaryBody(
          byMethod: {'CASH': 120000, 'QRIS': 60000, 'GIRO': 20000},
        ),
      );

      // Tall, so the figures list builds down to the last row: it is lazy, like every long list.
      await pumpShift(tester, http, size: const Size(1280, 1600));

      expect(find.text(l10n.posTenderMethodCASH), findsOneWidget);
      expect(find.text(l10n.posTenderMethodQRIS), findsOneWidget);
      expect(find.text('GIRO'), findsOneWidget);
      expect(find.text(money(120000)), findsOneWidget);
      expect(find.text(money(20000)), findsWidgets);
    });

    testWidgets('no sales by method: says there are none yet', (tester) async {
      final http = RoutedHttp();
      backend(http, summary: summaryBody(byMethod: {}));

      // Tall, so the figures list builds down to its last row: it is lazy, like every long list.
      await pumpShift(tester, http, size: const Size(1280, 1600));

      expect(find.text(l10n.shiftDetailNoSales), findsWidgets);
    });

    testWidgets('shows the shift\'s note when it has one', (tester) async {
      final http = RoutedHttp();
      backend(http, summary: summaryBody(notes: 'Laci sempat macet'));

      await pumpShift(tester, http, size: const Size(1280, 1600));

      expect(find.text('Laci sempat macet'), findsOneWidget);
    });

    testWidgets('a failed summary says so and can be read again, while the '
        'sales are still there', (tester) async {
      final http = RoutedHttp();
      http.respond(activePath, ok(shiftBody()));
      http.respond(summaryPath, refused(500, 'Gagal'));
      http.respond(movementsPath, ok(<Object?>[]));
      http.respond(salesPath, page([saleBody('a')]));

      await pumpShift(tester, http);

      expect(find.text('Gagal'), findsOneWidget);
      expect(find.text('POS-a'), findsOneWidget);

      http.respond(summaryPath, ok(summaryBody()));
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(find.text(l10n.shiftDetailExpectedCash), findsOneWidget);
    });
  });

  group('the sales', () {
    testWidgets('lists each sale with its number and its total', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);

      await pumpShift(tester, http);

      expect(find.text('POS-a'), findsOneWidget);
      expect(find.text('POS-b'), findsOneWidget);
      expect(find.text(money(75000)), findsOneWidget);
      expect(find.text(money(40000)), findsOneWidget);
    });

    testWidgets('a voided sale says so in words', (tester) async {
      final http = RoutedHttp();
      backend(http);

      await pumpShift(tester, http);

      expect(find.text(l10n.shiftDetailSaleVoided), findsOneWidget);
    });

    testWidgets('a shift with no sales says so', (tester) async {
      final http = RoutedHttp();
      backend(
        http,
        sales: [],
        summary: summaryBody(byMethod: {'CASH': 1}),
      );

      await pumpShift(tester, http);

      expect(find.text(l10n.shiftDetailNoSales), findsOneWidget);
    });

    testWidgets('a failed sales read says so and can be read again, and the '
        'figures are still there', (tester) async {
      final http = RoutedHttp();
      http.respond(activePath, ok(shiftBody()));
      http.respond(summaryPath, ok(summaryBody()));
      http.respond(movementsPath, ok(<Object?>[]));
      http.respond(salesPath, refused(500, 'Gagal'));

      await pumpShift(tester, http);

      expect(find.text('Gagal'), findsOneWidget);
      expect(find.text(l10n.shiftDetailExpectedCash), findsOneWidget);

      http.respond(salesPath, page([saleBody('a')]));
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(find.text('POS-a'), findsOneWidget);
    });

    testWidgets('tapping a sale opens it, and reads that sale', (tester) async {
      final http = RoutedHttp();
      backend(http);
      http.respond(
        '$salesPath/a',
        ok({
          ...saleBody('a'),
          'cashier': {'id': 'user_1', 'name': 'Budi'},
          'invoice': {
            'items': [
              {
                'id': 'i1',
                'quantity': 1,
                'price': 75000,
                'line_subtotal': 75000,
                'line_total': 75000,
                'product': {'id': 'p1', 'name': 'Kopi Susu'},
              },
            ],
          },
        }),
      );
      await pumpShift(tester, http);

      await tester.tap(find.text('POS-a'));
      await tester.pumpAndSettle();

      expect(asked(http, '$salesPath/a'), 1);
      expect(find.text(l10n.saleDetailTitle), findsOneWidget);
      expect(find.text('Kopi Susu'), findsOneWidget);
    });

    testWidgets('scrolling to the end asks for the next page, once', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(
        http,
        sales: [for (var i = 0; i < 30; i++) saleBody('s$i')],
        nextSales: 'c2',
      );
      await pumpShift(tester, http);
      expect(asked(http, salesPath), 1);

      http.respond(salesPath, page([saleBody('more')]));
      // A drag long enough to reach the end of the list.
      await tester.drag(
        find.byKey(const Key('sales-list')),
        const Offset(0, -4000),
      );
      await tester.pumpAndSettle();

      expect(asked(http, salesPath), 2);
      final next = http.calls.where((c) => c.path.startsWith(salesPath)).last;
      expect(next.path, contains('next_cursor=c2'));
    });

    testWidgets('a failed next page says so, keeps the sales, and a tap tries '
        'again', (tester) async {
      final http = RoutedHttp();
      backend(
        http,
        sales: [for (var i = 0; i < 30; i++) saleBody('s$i')],
        nextSales: 'c2',
      );
      await pumpShift(tester, http);

      http.respond(salesPath, refused(500, 'Gagal'));
      await tester.drag(
        find.byKey(const Key('sales-list')),
        const Offset(0, -4000),
      );
      await tester.pumpAndSettle();

      final retry = find.text('Gagal');
      expect(retry, findsOneWidget);
      expect(
        find.text('POS-s0'),
        findsNothing,
      ); // scrolled past, but not dropped

      http.respond(salesPath, page([saleBody('more')]));
      // The message appears just under the last row, and the cashier scrolls the last bit to it.
      await tester.drag(
        find.byKey(const Key('sales-list')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(find.text('Gagal'), findsNothing);
      expect(asked(http, salesPath), 3);
    });
  });

  group('the cash movements', () {
    testWidgets('lists each with its kind, its reason and which way the '
        'money went', (tester) async {
      final http = RoutedHttp();
      backend(http);
      await pumpShift(tester, http);

      await tapTab(tester, l10n.shiftDetailTabMovements);
      await tester.pumpAndSettle();

      expect(find.text('Tambah kembalian'), findsOneWidget);
      expect(find.text('Beli galon'), findsOneWidget);
      expect(find.text('Setor ke brankas'), findsOneWidget);
      expect(find.text('+${money(20000)}'), findsOneWidget);
      expect(find.text('-${money(5000)}'), findsOneWidget);
      // A drop leaves the drawer, and reads like it.
      expect(find.text('-${money(10000)}'), findsOneWidget);
      expect(find.text(l10n.shiftDetailCashDrop), findsOneWidget);
    });

    testWidgets('none yet: says so', (tester) async {
      final http = RoutedHttp();
      backend(http, movements: []);
      await pumpShift(tester, http);

      await tapTab(tester, l10n.shiftDetailTabMovements);
      await tester.pumpAndSettle();

      expect(find.text(l10n.shiftDetailNoMovements), findsOneWidget);
    });

    testWidgets('a failed read says so and can be read again', (tester) async {
      final http = RoutedHttp();
      http.respond(activePath, ok(shiftBody()));
      http.respond(summaryPath, ok(summaryBody()));
      http.respond(movementsPath, refused(500, 'Gagal'));
      http.respond(salesPath, page([saleBody('a')]));
      await pumpShift(tester, http);
      await tapTab(tester, l10n.shiftDetailTabMovements);
      await tester.pumpAndSettle();

      expect(find.text('Gagal'), findsOneWidget);

      http.respond(
        movementsPath,
        ok([movementBody('m1', 'CASH_IN', 1000, 'Modal')]),
      );
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(find.text('Modal'), findsOneWidget);
    });
  });

  group('its shape', () {
    testWidgets('on a wide tablet the figures and the sales are side by '
        'side, and there is no tab for the figures', (tester) async {
      final http = RoutedHttp();
      backend(http);

      await pumpShift(tester, http, size: const Size(1280, 800));

      expect(find.text(l10n.shiftDetailExpectedCash), findsOneWidget);
      expect(find.text('POS-a'), findsOneWidget);
      expect(find.text(l10n.shiftDetailTabFigures), findsNothing);
    });

    testWidgets('on a narrow tablet it is one column at a time, the figures '
        'first', (tester) async {
      final http = RoutedHttp();
      backend(http);

      await pumpShift(tester, http, size: const Size(600, 960));

      expect(find.text(l10n.shiftDetailExpectedCash), findsOneWidget);
      expect(find.text('POS-a'), findsNothing);

      await tapTab(tester, l10n.shiftDetailTabSales);
      await tester.pumpAndSettle();

      expect(find.text('POS-a'), findsOneWidget);
      expect(find.text(l10n.shiftDetailExpectedCash), findsNothing);
    });

    testWidgets('switching tabs does not read anything again', (tester) async {
      final http = RoutedHttp();
      backend(http);
      await pumpShift(tester, http, size: const Size(600, 960));
      final before = http.calls.length;

      await tapTab(tester, l10n.shiftDetailTabSales);
      await tester.pumpAndSettle();
      await tapTab(tester, l10n.shiftDetailTabMovements);
      await tester.pumpAndSettle();
      await tapTab(tester, l10n.shiftDetailTabFigures);
      await tester.pumpAndSettle();

      expect(http.calls.length, before);
    });

    const shapes = {
      '360 dp phone': Size(360, 740),
      '600 dp tablet, portrait': Size(600, 960),
      '800 dp tablet, portrait': Size(800, 1280),
      '1024 dp tablet': Size(1024, 768),
      '1280 dp tablet, landscape': Size(1280, 800),
    };
    for (final MapEntry(key: name, value: size) in shapes.entries) {
      for (final scale in [1.0, 1.3]) {
        for (final theme in [ThemeMode.light, ThemeMode.dark]) {
          testWidgets(
            'fits a $name at text ${scale}x in the ${theme.name} theme, on every tab',
            (tester) async {
              final http = RoutedHttp();
              backend(
                http,
                summary: summaryBody(
                  status: 'CLOSED',
                  counted: 270000,
                  variance: -1234567.89,
                  notes: 'Catatan yang cukup panjang untuk membungkus ke baris kedua',
                  byMethod: {
                    'CASH': 1234567890,
                    'QRIS': 60000,
                    'GIRO': 20000,
                    'TRANSFER': 5,
                    'EDC': 5,
                  },
                ),
                sales: [
                  for (var i = 0; i < 8; i++)
                    saleBody('s$i', total: 1234567890),
                ],
                movements: [
                  movementBody(
                    'm1',
                    'CASH_OUT',
                    1234567,
                    'Beli galon air minum dan perlengkapan kebersihan untuk dapur',
                  ),
                ],
              );

              await pumpShift(
                tester,
                http,
                size: size,
                textScale: scale,
                theme: theme,
              );
              expect(tester.takeException(), isNull);

              final compact = size.width < 840;
              if (compact) await tapTab(tester, l10n.shiftDetailTabSales);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);

              await tapTab(tester, l10n.shiftDetailTabMovements);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.textContaining('Beli galon'), findsOneWidget);
            },
          );
        }
      }
    }
  });
}

Finder closeShiftButton() =>
    find.widgetWithText(FilledButton, l10n.closeShiftButton);
Finder cashMovementButton() =>
    find.widgetWithText(OutlinedButton, l10n.cashMovementTitle);

void actions() {
  group('the actions', () {
    testWidgets('an open shift of the cashier offers to record cash and to '
        'close', (tester) async {
      final http = RoutedHttp();
      backend(http);

      await pumpShift(tester, http);

      expect(closeShiftButton(), findsOneWidget);
      expect(cashMovementButton(), findsOneWidget);
    });

    testWidgets('a shift that is closed offers neither: there is no drawer '
        'left to work on', (tester) async {
      final http = RoutedHttp();
      backend(http, summary: summaryBody(status: 'CLOSED'));

      await pumpShift(tester, http);

      expect(closeShiftButton(), findsNothing);
      expect(cashMovementButton(), findsNothing);
    });

    testWidgets('until the figures are in, and when they could not be read, '
        'there is nothing to offer: the status is not known', (tester) async {
      final http = RoutedHttp();
      http.respond(activePath, ok(shiftBody()));
      http.respond(summaryPath, refused(500, 'Gagal'));
      http.respond(movementsPath, ok(<Object?>[]));
      http.respond(salesPath, page([]));

      await pumpShift(tester, http);

      expect(closeShiftButton(), findsNothing);
    });

    testWidgets('an owner is offered them on the shift of another cashier', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(
        http,
        shift: shiftBody(cashierId: 'user_9', cashierName: 'Andi'),
      );

      await pumpShift(
        tester,
        http,
        session: signedIn.copyWith(companies: [ownerMembership]),
      );

      expect(closeShiftButton(), findsOneWidget);
    });

    testWidgets('closing opens the close screen, which reads the figures '
        'itself', (tester) async {
      final http = RoutedHttp();
      backend(http);
      http.respond(summaryPath, ok(summaryBody()));
      await pumpShift(tester, http);

      await tester.tap(closeShiftButton());
      await tester.pumpAndSettle();

      expect(find.byType(CloseShiftScreen), findsOneWidget);
      // Its own read: sales may have come in since this screen was opened, and the drawer is
      // counted against the figures as they are now.
      expect(asked(http, summaryPath), 2);
      expect(find.text(l10n.closeShiftOverrideNotice('Budi')), findsNothing);
    });

    testWidgets(
      'closing the drawer of another cashier opens it as an override',
      (tester) async {
        final other = summaryBody(cashierId: 'user_9', cashierName: 'Andi');
        final http = RoutedHttp();
        backend(
          http,
          shift: shiftBody(cashierId: 'user_9', cashierName: 'Andi'),
          summary: other,
        );
        http.respond(summaryPath, ok(other));
        await pumpShift(
          tester,
          http,
          session: signedIn.copyWith(companies: [ownerMembership]),
        );

        await tester.tap(closeShiftButton());
        await tester.pumpAndSettle();

        expect(
          find.text(l10n.closeShiftOverrideNotice('Andi')),
          findsOneWidget,
        );
      },
    );

    testWidgets('recording cash opens the sheet, and a recorded movement '
        'reads everything again: the expected cash moved with it', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      http.respond(settingsPathRoute, ok({'require_shift': true}));
      http.respond(coaPathRoute, ok(<Object?>[]));
      http.respond(movementPostPath, ok(null));
      // What the screen reads again once the movement is in.
      backend(http);
      await pumpShift(tester, http, size: const Size(1280, 1400));

      await tester.tap(cashMovementButton());
      await tester.pumpAndSettle();
      expect(find.byType(CashMovementSheet), findsOneWidget);
      for (final key in ['5', '00', '0']) {
        await tester.tap(find.widgetWithText(OutlinedButton, key).first);
        await tester.pump();
      }
      await tester.enterText(
        find.byKey(const Key('movement-reason')),
        'Beli galon',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, l10n.commonSave));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byType(CashMovementSheet), findsNothing);
      expect(asked(http, activePath), 2);
      expect(asked(http, summaryPath), 2);
      expect(asked(http, movementsPath), 2);
    });

    testWidgets('closing the sheet without recording reads nothing again', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      http.respond(settingsPathRoute, ok({'require_shift': true}));
      http.respond(coaPathRoute, ok(<Object?>[]));
      await pumpShift(tester, http);
      await tester.tap(cashMovementButton());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(l10n.commonClose));
      await tester.pumpAndSettle();

      expect(asked(http, activePath), 1);
      expect(asked(http, summaryPath), 1);
    });

    testWidgets('printing the report logs shift_report_printed', (
      tester,
    ) async {
      const kitchen = PrinterDevice(address: 'AA:BB', name: 'Dapur');
      final http = RoutedHttp();
      backend(http);
      http.respond(settingsPathRoute, ok({'require_shift': true}));
      useSize(tester, const Size(1280, 800), 1);
      final rig = Rig({
        ...storedSession(signedIn),
        printerKey: jsonEncode({
          'address': kitchen.address,
          'name': kitchen.name,
        }),
      });
      rig.printer = FakePrinter([kitchen]);
      await rig.theme.select(ThemeMode.light);
      await tester.pumpWidget(appWith(rig, http));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open shift screen'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(OutlinedButton, l10n.printerPrintShiftReport),
      );
      await tester.pumpAndSettle();

      expect(rig.analytics.logged.map((e) => e.$1), ['shift_report_printed']);
    });
  });

  // README §6, D-Q7: closing reconciles the drawer against what the server has recorded, and a
  // sale still sitting in this tablet's queue is invisible to that reconciliation.
  group('the offline queue guard', () {
    testWidgets(
      'closing is blocked while this outlet has an unsent sale, and says how many',
      (tester) async {
        final http = RoutedHttp();
        backend(http);
        final rig = await pumpShift(tester, http);
        await rig.pendingSaleStore.enqueue(queueEntry());
        final services = AppScope.of(tester.element(find.byType(ShiftScreen)));
        await services.queueSync.refreshCounts();
        await tester.pump();

        expect(
          tester.widget<FilledButton>(closeShiftButton()).onPressed,
          isNull,
        );
        expect(find.text(l10n.shiftCloseBlockedByQueue(1)), findsOneWidget);
        // Recording cash is a different concern and stays available.
        expect(
          tester.widget<OutlinedButton>(cashMovementButton()).onPressed,
          isNotNull,
        );
      },
    );

    // A failed sale is not the drain loop's problem any more, but the cashier has not decided
    // whether to retry or discard it — the drawer is still short either way.
    testWidgets('a failed sale blocks it too, not only a pending one', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      final rig = await pumpShift(tester, http);
      await rig.pendingSaleStore.enqueue(
        queueEntry(status: PendingSaleStatus.failed),
      );
      final services = AppScope.of(tester.element(find.byType(ShiftScreen)));
      await services.queueSync.refreshCounts();
      await tester.pump();

      expect(tester.widget<FilledButton>(closeShiftButton()).onPressed, isNull);
    });

    testWidgets('the notice opens the pending sales screen', (tester) async {
      final http = RoutedHttp();
      backend(http);
      final rig = await pumpShift(tester, http);
      await rig.pendingSaleStore.enqueue(queueEntry());
      final services = AppScope.of(tester.element(find.byType(ShiftScreen)));
      await services.queueSync.refreshCounts();
      await tester.pump();

      await tester.tap(find.text(l10n.shiftCloseBlockedByQueue(1)));
      await tester.pumpAndSettle();

      expect(find.byType(PendingSalesScreen), findsOneWidget);
    });
  });
}
