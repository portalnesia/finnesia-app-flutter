/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/format.dart';
import 'package:pn_pos/src/pos_cart.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_types/src/product.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/shift/close_shift_screen.dart';

import '../../support/boot_rig.dart';
import '../../support/routed_http.dart';

// S12. Counting the drawer and closing it. Behaviour from `close-shift-dialog.tsx`; the shape is
// this app's own: a whole screen (the count is a deliberate end to a session, and a dialog is
// dismissed by a stray tap), the figures first and the counting after, on the on-screen keypad.
//
// The rule (`shiftCloseState`) is tested in `pn_pos`, and what the controller does with it in
// `close_shift_controller_test.dart`; what is tested here is what the cashier sees and taps.
//
// Words come from the generated `L10n`, not from literals.

final l10n = lookupL10n(const Locale('id'));

const summaryPath = '/api/v1/pos/shifts/s1';
const closePath = '/api/v1/pos/shifts/s1/close';

String money(num v) => formatCurrency(v);

Map<String, Object?> summaryBody({
  num expected = 275000,
  String cashierId = 'user_1',
  String? cashierName = 'Budi',
}) => {
  'shift_id': 's1',
  'number': 'SH-0001',
  'status': 'OPEN',
  'outlet_id': 'out_1',
  'cashier_id': cashierId,
  'cashier_name': ?cashierName,
  'opened_at': '2026-09-20T01:00:00Z',
  'total_transactions': 3,
  'total_sales': 200000,
  'opening_cash': 150000,
  'expected_cash': expected,
  'cash_in': 20000,
  'cash_out': 5000,
  'cash_drop': 10000,
};

final signedIn = paired.copyWith(
  user: const SessionUser(id: 'user_1', name: 'Budi'),
);

/// A screen under the close screen, so going back, and closing, have somewhere to land.
class _Host extends StatelessWidget {
  const _Host({required this.isOverride});

  final bool isOverride;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  CloseShiftScreen(shiftId: 's1', isOverride: isOverride),
            ),
          ),
          child: const Text('open close screen'),
        ),
      ),
    ),
  );
}

Widget appWith(Rig rig, RoutedHttp http, {bool isOverride = false}) => PosApp(
  boot: () => rig.bootWith(http: http),
  language: rig.language,
  theme: rig.theme,
  screens: (
    pairing: (_) => const Text('pairing'),
    login: (_) => const Text('login'),
    till: (_) => _Host(isOverride: isOverride),
  ),
);

void useSize(WidgetTester tester, Size size, double textScale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> pumpClose(
  WidgetTester tester,
  RoutedHttp http, {
  Size size = const Size(1280, 800),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  bool isOverride = false,
  bool settle = true,
  Rig? rig,
}) async {
  useSize(tester, size, textScale);
  rig ??= Rig(storedSession(signedIn));
  await rig.theme.select(theme);
  await tester.pumpWidget(appWith(rig, http, isOverride: isOverride));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open close screen'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
}

Map<String, Object?> closedShift() => {
  'id': 's1',
  'number': 'SH-0001',
  'cashier_id': 'user_1',
  'outlet_id': 'out_1',
  'opened_at': '2026-09-20T01:00:00Z',
  'opening_cash': 150000,
  'total_sales': 200000,
  'total_transactions': 3,
};

/// The count that matches [summaryBody]'s expected cash exactly.
Future<void> countExactly(WidgetTester tester) async {
  for (final key in ['2', '7', '5', '00', '0']) {
    await tester.tap(find.widgetWithText(OutlinedButton, key).first);
    await tester.pump();
  }
}

/// How often [path] was asked for, exactly.
int asked(RoutedHttp http, String path) =>
    http.calls.where((c) => c.path.split('?').first == path).length;

void main() {
  group('reading the figures', () {
    testWidgets('reads the summary of that shift, and shows every term of the '
        'expected cash', (tester) async {
      final http = RoutedHttp()..respond(summaryPath, ok(summaryBody()));

      await pumpClose(tester, http);

      expect(asked(http, summaryPath), 1);
      expect(find.text(l10n.shiftDetailOpeningCash), findsOneWidget);
      expect(find.text(money(150000)), findsOneWidget);
      expect(find.text(l10n.shiftDetailTotalSales), findsOneWidget);
      expect(find.text(l10n.shiftDetailCashIn), findsOneWidget);
      expect(find.text(l10n.shiftDetailCashOutAndDrop), findsOneWidget);
      expect(find.text(money(15000)), findsOneWidget);
      expect(find.text(l10n.shiftDetailExpectedCash), findsOneWidget);
      expect(find.text(money(275000)), findsOneWidget);
    });

    testWidgets('says it is loading while they are read', (tester) async {
      final http = RoutedHttp()..hold(summaryPath);

      await pumpClose(tester, http, settle: false);

      expect(find.text(l10n.commonLoading), findsOneWidget);

      http.release(summaryPath, ok(summaryBody()));
      await tester.pumpAndSettle();
    });

    testWidgets('a failed read says so, and reading again shows the figures', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(summaryPath, refused(500, 'Gagal'))
        ..respond(summaryPath, ok(summaryBody()));

      await pumpClose(tester, http);

      expect(find.text('Gagal'), findsOneWidget);
      expect(find.text(l10n.shiftDetailExpectedCash), findsNothing);

      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(find.text(l10n.shiftDetailExpectedCash), findsOneWidget);
    });
  });

  group('counting the drawer', () {
    Future<void> typed(WidgetTester tester, List<String> keys) async {
      for (final key in keys) {
        await tester.tap(find.widgetWithText(OutlinedButton, key).first);
        // A finger leaves a frame between two taps.
        await tester.pump();
      }
    }

    testWidgets('an uncounted drawer is the whole expected cash short', (
      tester,
    ) async {
      final http = RoutedHttp()..respond(summaryPath, ok(summaryBody()));

      await pumpClose(tester, http);

      expect(find.text(l10n.shiftDetailCountedCash), findsOneWidget);
      expect(
        find.text(l10n.shiftDetailVarianceShort(money(275000))),
        findsOneWidget,
      );
    });

    testWidgets('a count that matches is exact', (tester) async {
      final http = RoutedHttp()..respond(summaryPath, ok(summaryBody()));
      await pumpClose(tester, http);

      await typed(tester, ['2', '7', '5', '00', '0']);

      expect(find.text(money(275000)), findsWidgets);
      expect(find.text(l10n.shiftDetailVarianceNone), findsOneWidget);
    });

    testWidgets('a count above the expected cash is over, by how much', (
      tester,
    ) async {
      final http = RoutedHttp()..respond(summaryPath, ok(summaryBody()));
      await pumpClose(tester, http);

      await typed(tester, ['3', '00', '00', '0']);

      expect(
        find.text(l10n.shiftDetailVarianceOver(money(25000))),
        findsOneWidget,
      );
    });
  });

  group('the note, and when the drawer may be closed', () {
    Finder closeButton() =>
        find.widgetWithText(FilledButton, l10n.closeShiftButton);
    Future<void> typed(WidgetTester tester, List<String> keys) async {
      for (final key in keys) {
        await tester.tap(find.widgetWithText(OutlinedButton, key).first);
        await tester.pump();
      }
    }

    testWidgets('an uncounted drawer cannot be closed, and says why beside '
        'the field that would fix it', (tester) async {
      final http = RoutedHttp()..respond(summaryPath, ok(summaryBody()));

      await pumpClose(tester, http);

      expect(tester.widget<FilledButton>(closeButton()).onPressed, isNull);
      expect(find.text(l10n.closeShiftNoteNeededVariance), findsOneWidget);
    });

    testWidgets('a note lets a drawer with a variance close', (tester) async {
      final http = RoutedHttp()..respond(summaryPath, ok(summaryBody()));
      await pumpClose(tester, http);

      await tester.enterText(
        find.byKey(const Key('close-notes')),
        'Uang receh hilang',
      );
      await tester.pump();

      expect(tester.widget<FilledButton>(closeButton()).onPressed, isNotNull);
    });

    testWidgets('a drawer that matches closes with no note, and asks for '
        'none', (tester) async {
      final http = RoutedHttp()..respond(summaryPath, ok(summaryBody()));
      await pumpClose(tester, http);

      await typed(tester, ['2', '7', '5', '00', '0']);

      expect(tester.widget<FilledButton>(closeButton()).onPressed, isNotNull);
      expect(find.text(l10n.closeShiftNoteNeededVariance), findsNothing);
    });
  });

  group("closing another cashier's drawer", () {
    Finder closeButton() =>
        find.widgetWithText(FilledButton, l10n.closeShiftButton);

    testWidgets('says whose it is, and that a note is required', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(
          summaryPath,
          ok(summaryBody(cashierId: 'user_9', cashierName: 'Andi')),
        );

      await pumpClose(tester, http, isOverride: true);

      expect(find.text(l10n.closeShiftOverrideNotice('Andi')), findsOneWidget);
    });

    testWidgets('names a cashier with no name on record by a word', (
      tester,
    ) async {
      final http = RoutedHttp()
        ..respond(
          summaryPath,
          ok(summaryBody(cashierId: 'user_9', cashierName: null)),
        );

      await pumpClose(tester, http, isOverride: true);

      expect(
        find.text(l10n.closeShiftOverrideNotice(l10n.shiftUnknownCashier)),
        findsOneWidget,
      );
    });

    testWidgets('an exact count still needs the note, and says so', (
      tester,
    ) async {
      final http = RoutedHttp()..respond(summaryPath, ok(summaryBody()));
      await pumpClose(tester, http, isOverride: true);

      for (final key in ['2', '7', '5', '00', '0']) {
        await tester.tap(find.widgetWithText(OutlinedButton, key).first);
        await tester.pump();
      }

      expect(find.text(l10n.shiftDetailVarianceNone), findsOneWidget);
      expect(find.text(l10n.closeShiftNoteNeededOverride), findsOneWidget);
      expect(tester.widget<FilledButton>(closeButton()).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('close-notes')),
        'Kasir pulang',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(closeButton()).onPressed, isNotNull);
    });

    testWidgets('your own drawer shows no such notice', (tester) async {
      final http = RoutedHttp()..respond(summaryPath, ok(summaryBody()));

      await pumpClose(tester, http);

      expect(find.textContaining('Andi'), findsNothing);
      expect(find.text(l10n.closeShiftNoteNeededOverride), findsNothing);
    });
  });

  group('closing it', () {
    Finder closeButton() =>
        find.widgetWithText(FilledButton, l10n.closeShiftButton);

    testWidgets('sends the count, tells the app a shift was closed, and '
        'leaves for the screen it came from', (tester) async {
      final http = RoutedHttp()
        ..respond(summaryPath, ok(summaryBody()))
        ..respond(closePath, ok(closedShift()));
      await pumpClose(tester, http);
      await countExactly(tester);

      await tester.tap(closeButton());
      await tester.pumpAndSettle();

      expect(asked(http, closePath), 1);
      final sent = http.calls.firstWhere((c) => c.path == closePath);
      expect(sent.body, contains('"counted_cash":275000'));
      // Back at the screen underneath, which is where the gate lives in the app.
      expect(find.text('open close screen'), findsOneWidget);
      expect(find.byType(CloseShiftScreen), findsNothing);
      final services = AppScope.of(
        tester.element(find.text('open close screen')),
      );
      expect(services.shiftClosed.value, 1);
    });

    testWidgets('forgets the baskets held at this outlet: they were rung up '
        'against a drawer that no longer exists', (tester) async {
      HeldOrder held(String id, String outlet) => HeldOrder(
        id: id,
        label: id,
        outletId: outlet,
        headerDiscount: 0,
        lines: [
          CartLine(
            id: 'l',
            product: const Product(id: 'p', name: 'Kopi', unitId: 'u'),
            qty: 1,
          ),
        ],
        heldAt: '2026-09-21T03:00:00.000Z',
      );
      final rig = Rig(storedSession(signedIn));
      await rig.holdStore.writeAll([
        held('mine', 'out_1'),
        held('elsewhere', 'out_2'),
      ]);
      final http = RoutedHttp()
        ..respond(summaryPath, ok(summaryBody()))
        ..respond(closePath, ok(closedShift()));
      await pumpClose(tester, http, rig: rig);
      await countExactly(tester);

      await tester.tap(closeButton());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Another outlet's baskets are another till's, and are left alone.
      expect((await rig.holdStore.readAll()).map((o) => o.id), ['elsewhere']);
    });

    testWidgets('a close that was refused leaves the baskets where they '
        'are', (tester) async {
      final rig = Rig(storedSession(signedIn));
      await rig.holdStore.writeAll([
        HeldOrder(
          id: 'mine',
          label: 'mine',
          outletId: 'out_1',
          headerDiscount: 0,
          lines: const [],
          heldAt: '2026-09-21T03:00:00.000Z',
        ),
      ]);
      final http = RoutedHttp()
        ..respond(summaryPath, ok(summaryBody()))
        ..respond(closePath, refused(409, 'Ditolak'));
      await pumpClose(tester, http, rig: rig);
      await countExactly(tester);

      await tester.tap(closeButton());
      await tester.pumpAndSettle();

      expect(await rig.holdStore.readAll(), hasLength(1));
    });

    testWidgets('says the shift is closed', (tester) async {
      final http = RoutedHttp()
        ..respond(summaryPath, ok(summaryBody()))
        ..respond(closePath, ok(closedShift()));
      await pumpClose(tester, http);
      await countExactly(tester);

      await tester.tap(closeButton());
      await tester.pump();
      await tester.pump();

      expect(find.text(l10n.closeShiftDone), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });

    testWidgets('while it is closing the button says so, and cannot be '
        'pressed again', (tester) async {
      final http = RoutedHttp()..respond(summaryPath, ok(summaryBody()));
      await pumpClose(tester, http);
      await countExactly(tester);
      http.hold(closePath);

      await tester.tap(closeButton());
      await tester.pump();

      expect(find.text(l10n.closeShiftClosing), findsOneWidget);
      final button = find.widgetWithText(FilledButton, l10n.closeShiftClosing);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      http.release(closePath, ok(closedShift()));
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });

    testWidgets('a refusal shows what the server said, and stays on the '
        'screen with the count kept', (tester) async {
      final http = RoutedHttp()
        ..respond(summaryPath, ok(summaryBody()))
        ..respond(closePath, refused(409, 'Shift sudah ditutup'));
      await pumpClose(tester, http);
      await countExactly(tester);

      await tester.tap(closeButton());
      await tester.pumpAndSettle();

      expect(find.text('Shift sudah ditutup'), findsOneWidget);
      expect(find.byType(CloseShiftScreen), findsOneWidget);
      expect(find.text(l10n.shiftDetailVarianceNone), findsOneWidget);
      expect(tester.widget<FilledButton>(closeButton()).onPressed, isNotNull);
      final services = AppScope.of(tester.element(find.byType(Scaffold).last));
      expect(services.shiftClosed.value, 0);
    });

    testWidgets('no answer says it may already be closed, and does not '
        'leave', (tester) async {
      final http = RoutedHttp()
        ..respond(summaryPath, ok(summaryBody()))
        ..fail(closePath);
      await pumpClose(tester, http);
      await countExactly(tester);

      await tester.tap(closeButton());
      await tester.pumpAndSettle();

      expect(find.text(l10n.closeShiftUncertain), findsOneWidget);
      expect(find.byType(CloseShiftScreen), findsOneWidget);
    });

    testWidgets('a server error is told the same way: it may have committed '
        'before it failed', (tester) async {
      final http = RoutedHttp()
        ..respond(summaryPath, ok(summaryBody()))
        ..respond(closePath, refused(500, 'internal error'));
      await pumpClose(tester, http);
      await countExactly(tester);

      await tester.tap(closeButton());
      await tester.pumpAndSettle();

      expect(find.text(l10n.closeShiftUncertain), findsOneWidget);
      // The server's own words for an error are not a sentence for a cashier.
      expect(find.text('internal error'), findsNothing);
    });
  });

  group('leaving, and its shape', () {
    testWidgets('back leaves without closing anything', (tester) async {
      final http = RoutedHttp()..respond(summaryPath, ok(summaryBody()));
      await pumpClose(tester, http);

      await tester.tap(find.byTooltip(l10n.menuBack));
      await tester.pumpAndSettle();

      expect(find.text('open close screen'), findsOneWidget);
      expect(asked(http, closePath), 0);
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
            'fits a $name at text ${scale}x in the ${theme.name} theme, with '
            'the override notice and a refusal showing',
            (tester) async {
              final http = RoutedHttp()
                ..respond(
                  summaryPath,
                  ok(
                    summaryBody(
                      expected: 1234567890,
                      cashierId: 'user_9',
                      cashierName: 'Nama Kasir Yang Cukup Panjang Sekali',
                    ),
                  ),
                )
                ..respond(
                  closePath,
                  refused(
                    409,
                    'Kalimat penolakan dari server yang cukup panjang untuk membungkus',
                  ),
                );
              await pumpClose(
                tester,
                http,
                size: size,
                textScale: scale,
                theme: theme,
                isOverride: true,
              );
              expect(tester.takeException(), isNull);

              // On a narrow screen the note is below the keypad, and the cashier scrolls to it.
              await tester.scrollUntilVisible(
                find.byKey(const Key('close-notes')),
                300,
                scrollable: find.byType(Scrollable).last,
              );
              await tester.enterText(
                find.byKey(const Key('close-notes')),
                'Catatan yang cukup panjang untuk membungkus ke baris kedua',
              );
              await tester.pump();
              await tester.tap(
                find.widgetWithText(FilledButton, l10n.closeShiftButton),
              );
              await tester.pumpAndSettle();

              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });
}
