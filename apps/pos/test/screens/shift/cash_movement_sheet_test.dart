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
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/shift/cash_movement_sheet.dart';

import '../../support/boot_rig.dart';
import '../../support/routed_http.dart';

// S13. Money that enters or leaves the drawer without a sale. Behaviour from
// `cash-movement-dialog.tsx`; the shape is this app's own: a sheet, the amount on the on-screen
// keypad, and the account chosen from a list of its own rather than a combobox.
//
// The rules (what may be submitted, and when) are in `cash_movement_controller_test.dart`; what is
// tested here is what the cashier sees and taps. The list of movements already recorded is not
// here: it is the shift screen's "Cash movements" tab.
//
// Words come from the generated `L10n`, not from literals.

final l10n = lookupL10n(const Locale('id'));

const settingsRoute = '/api/v1/pos/settings';
const coaPath = '/api/v1/master/coa';
const movementPath = '/api/v1/pos/shifts/s1/cash-movement';

Map<String, Object?> account(String id, String code, String name) => {
  'id': id,
  'code': code,
  'name': name,
};

/// What the sheet reads when it opens.
void backend(
  RoutedHttp http, {
  String? cashAccountId,
  List<Map<String, Object?>>? accounts,
}) {
  http.respond(
    settingsRoute,
    ok({'require_shift': true, 'cash_account_id': ?cashAccountId}),
  );
  http.respond(
    coaPath,
    ok(
      accounts ??
          [
            account('a1', '1-1000', 'Kas Kecil'),
            account('a2', '5-2000', 'Beban Operasional'),
          ],
    ),
  );
}

final signedIn = paired.copyWith(
  user: const SessionUser(id: 'user_1', name: 'Budi'),
);

/// Reports what the sheet answered, so the caller's side of it can be looked at.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool? recorded;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: () async {
              final result = await showCashMovementSheet(
                context,
                shiftId: 's1',
              );
              setState(() => recorded = result);
            },
            child: const Text('open sheet'),
          ),
          Text('recorded: $recorded'),
        ],
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

Future<void> openSheet(
  WidgetTester tester,
  RoutedHttp http, {
  Size size = const Size(1280, 1000),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  bool settle = true,
}) async {
  useSize(tester, size, textScale);
  final rig = Rig(storedSession(signedIn));
  await rig.theme.select(theme);
  await tester.pumpWidget(appWith(rig, http));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open sheet'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
}

int asked(RoutedHttp http, String path) =>
    http.calls.where((c) => c.path.split('?').first == path).length;

void main() {
  keyboard();
  shape();
  saving();
  searchingAccounts();
  choosingAnAccount();
  filling();
  group('opening it', () {
    testWidgets('reads the settings and the first page of accounts, once '
        'each', (tester) async {
      final http = RoutedHttp();
      backend(http);

      await openSheet(tester, http);

      expect(asked(http, settingsRoute), 1);
      expect(asked(http, coaPath), 1);
    });

    testWidgets('offers the three kinds, with cash out chosen', (tester) async {
      final http = RoutedHttp();
      backend(http);

      await openSheet(tester, http);

      expect(find.text(l10n.shiftDetailCashIn), findsOneWidget);
      expect(find.text(l10n.shiftDetailCashOut), findsOneWidget);
      expect(find.text(l10n.shiftDetailCashDrop), findsOneWidget);
      final chosen = tester
          .widget<SegmentedButton<CashMovementType>>(
            find.byType(SegmentedButton<CashMovementType>),
          )
          .selected;
      expect(chosen, {CashMovementType.cashOut});
    });
  });
}

Finder get saveButton => find.widgetWithText(FilledButton, l10n.commonSave);

Future<void> typeAmount(WidgetTester tester, List<String> keys) async {
  for (final key in keys) {
    await tester.tap(find.widgetWithText(OutlinedButton, key).first);
    await tester.pump();
  }
}

void filling() {
  group('filling it in', () {
    testWidgets('choosing another kind selects it', (tester) async {
      final http = RoutedHttp();
      backend(http);
      await openSheet(tester, http);

      await tester.tap(find.text(l10n.shiftDetailCashDrop));
      await tester.pump();

      final chosen = tester
          .widget<SegmentedButton<CashMovementType>>(
            find.byType(SegmentedButton<CashMovementType>),
          )
          .selected;
      expect(chosen, {CashMovementType.drop});
    });

    testWidgets('says the reason is required, since saving waits for it', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      await openSheet(tester, http);

      expect(find.text(l10n.cashMovementReasonRequired), findsOneWidget);
    });

    testWidgets(
      'draws the save button differently while it cannot be pressed',
      (tester) async {
        final http = RoutedHttp();
        backend(http);
        await openSheet(tester, http);
        Color? fill() => tester
            .widget<Material>(
              find.descendant(of: saveButton, matching: find.byType(Material)),
            )
            .color;
        final waiting = fill();

        await fillAmountAndReason(tester);
        await tester.pumpAndSettle();

        expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
        expect(fill(), isNot(waiting));
      },
    );

    testWidgets('cannot be saved without an amount and a reason', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      await openSheet(tester, http);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

      await typeAmount(tester, ['5', '00', '0']);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('movement-reason')),
        'Beli galon',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    });
  });
}

Future<void> fillAmountAndReason(WidgetTester tester) async {
  await typeAmount(tester, ['5', '00', '0']);
  await tester.enterText(
    find.byKey(const Key('movement-reason')),
    'Beli galon',
  );
  await tester.pump();
}

void choosingAnAccount() {
  group('the account', () {
    testWidgets('is optional for a company with no drawer account', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);

      await openSheet(tester, http);
      await fillAmountAndReason(tester);

      expect(find.text(l10n.cashMovementAccount), findsOneWidget);
      expect(find.text(l10n.cashMovementAccountRequired), findsNothing);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    });

    testWidgets('is required once the company has a drawer account, and '
        'saving waits for it', (tester) async {
      final http = RoutedHttp();
      backend(http, cashAccountId: 'drawer');
      await openSheet(tester, http);

      await fillAmountAndReason(tester);

      expect(find.text(l10n.cashMovementAccountRequired), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
    });

    testWidgets('is picked from a list of its own, and shown once picked', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http, cashAccountId: 'drawer');
      await openSheet(tester, http);
      await fillAmountAndReason(tester);

      await tester.tap(find.byKey(const Key('movement-account')));
      await tester.pumpAndSettle();
      expect(find.text('1-1000 - Kas Kecil'), findsOneWidget);
      expect(find.text('5-2000 - Beban Operasional'), findsOneWidget);

      await tester.tap(find.text('5-2000 - Beban Operasional'));
      await tester.pumpAndSettle();

      // The list closes, the choice shows in the field, and saving is allowed.
      expect(find.text(l10n.cashMovementAccountSearch), findsNothing);
      expect(find.text('5-2000 - Beban Operasional'), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    });
  });
}

void searchingAccounts() {
  group('searching the accounts', () {
    Future<void> openPicker(WidgetTester tester, RoutedHttp http) async {
      await openSheet(tester, http);
      await tester.tap(find.byKey(const Key('movement-account')));
      await tester.pumpAndSettle();
    }

    // A field that takes focus by itself raises the tablet's keyboard over the list the cashier
    // opened it to read.
    testWidgets('opens without raising the keyboard', (tester) async {
      final http = RoutedHttp();
      backend(http);
      await openPicker(tester, http);

      expect(find.byKey(const Key('account-search')), findsOneWidget);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('asks the server for what was typed, once the typing stops', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      await openPicker(tester, http);
      http.respond(coaPath, ok([account('a3', '1-1100', 'Kas Besar')]));

      await tester.enterText(find.byKey(const Key('account-search')), 'kas');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(asked(http, coaPath), 2);
      final search = http.calls.where((c) => c.path.startsWith(coaPath)).last;
      expect(search.path, contains('q=kas'));
      expect(find.text('1-1100 - Kas Besar'), findsOneWidget);
      expect(find.text('1-1000 - Kas Kecil'), findsNothing);
    });

    testWidgets('a search with no result says so', (tester) async {
      final http = RoutedHttp();
      backend(http);
      await openPicker(tester, http);
      http.respond(coaPath, ok(<Object?>[]));

      await tester.enterText(find.byKey(const Key('account-search')), 'zzz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text(l10n.cashMovementAccountEmpty), findsOneWidget);
    });

    testWidgets('a failed read says so and can be read again', (tester) async {
      final http = RoutedHttp();
      backend(http);
      await openPicker(tester, http);
      http.respond(coaPath, refused(500, 'Gagal'));
      await tester.enterText(find.byKey(const Key('account-search')), 'kas');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Gagal'), findsOneWidget);

      http.respond(coaPath, ok([account('a3', '1-1100', 'Kas Besar')]));
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(find.text('1-1100 - Kas Besar'), findsOneWidget);
    });

    testWidgets('cancel closes it and leaves the account as it was', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      await openPicker(tester, http);

      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('account-picker')), findsNothing);
      expect(find.text(l10n.cashMovementAccountNone), findsOneWidget);
    });
  });
}

void saving() {
  group('saving it', () {
    testWidgets('sends the movement, closes the sheet, and tells the caller '
        'it was recorded', (tester) async {
      final http = RoutedHttp();
      backend(http);
      http.respond(movementPath, ok(null));
      await openSheet(tester, http);
      await tester.tap(find.text(l10n.shiftDetailCashIn));
      await tester.pump();
      await fillAmountAndReason(tester);

      await tester.tap(saveButton);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      final sent = http.calls.firstWhere((c) => c.path == movementPath);
      final body = jsonDecode(sent.body!) as Map<String, Object?>;
      expect(body, {'type': 'CASH_IN', 'amount': 5000, 'reason': 'Beli galon'});
      expect(find.text('recorded: true'), findsOneWidget);
      expect(find.byType(CashMovementSheet), findsNothing);
    });

    testWidgets('says it is saving, and cannot be pressed again', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      await openSheet(tester, http);
      await fillAmountAndReason(tester);
      http.hold(movementPath);

      await tester.tap(saveButton);
      await tester.pump();

      final saving = find.widgetWithText(FilledButton, l10n.commonSaving);
      expect(saving, findsOneWidget);
      expect(tester.widget<FilledButton>(saving).onPressed, isNull);

      http.release(movementPath, ok(null));
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });

    testWidgets('a refusal shows what the server said, and stays with '
        'everything kept', (tester) async {
      final http = RoutedHttp();
      backend(http);
      http.respond(movementPath, refused(422, 'Akun tidak valid'));
      await openSheet(tester, http);
      await fillAmountAndReason(tester);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Akun tidak valid'), findsOneWidget);
      expect(find.byType(CashMovementSheet), findsOneWidget);
      expect(find.text('Rp 5.000'), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    });

    testWidgets('no answer says it may already be saved', (tester) async {
      final http = RoutedHttp();
      backend(http);
      http.fail(movementPath);
      await openSheet(tester, http);
      await fillAmountAndReason(tester);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text(l10n.cashMovementUncertain), findsOneWidget);
      expect(find.byType(CashMovementSheet), findsOneWidget);
    });
  });

  group('the settings', () {
    testWidgets('while they are being read, it cannot be saved', (
      tester,
    ) async {
      final http = RoutedHttp()..hold(settingsRoute);
      http.respond(coaPath, ok(<Object?>[]));
      await openSheet(tester, http, settle: false);
      // Long enough for the sheet to slide up; not `pumpAndSettle`, which the open read would hold.
      await tester.pump(const Duration(milliseconds: 500));
      await fillAmountAndReason(tester);

      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

      http.release(settingsRoute, ok({'require_shift': true}));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    });

    testWidgets('unreadable, it says so, cannot be saved, and reads again', (
      tester,
    ) async {
      final http = RoutedHttp();
      http.respond(settingsRoute, refused(500, 'Gagal'));
      http.respond(coaPath, ok(<Object?>[]));
      await openSheet(tester, http);
      await fillAmountAndReason(tester);

      expect(find.text('Gagal'), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

      http.respond(settingsRoute, ok({'require_shift': true}));
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(find.text('Gagal'), findsNothing);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    });
  });

  group('closing it', () {
    testWidgets('the close button leaves without sending anything', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      await openSheet(tester, http);
      await fillAmountAndReason(tester);

      await tester.tap(find.byTooltip(l10n.commonClose));
      await tester.pumpAndSettle();

      expect(find.text('recorded: false'), findsOneWidget);
      expect(asked(http, movementPath), 0);
    });

    testWidgets('Escape leaves too', (tester) async {
      final http = RoutedHttp();
      backend(http);
      await openSheet(tester, http);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(CashMovementSheet), findsNothing);
    });
  });
}

void shape() {
  group('its shape', () {
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
            'fits a $name at text ${scale}x in the ${theme.name} theme, with a '
            'long account and a refusal showing',
            (tester) async {
              final http = RoutedHttp();
              backend(
                http,
                cashAccountId: 'drawer',
                accounts: [
                  account(
                    'a1',
                    '1-1000-0001',
                    'Nama akun yang cukup panjang sampai membungkus ke baris kedua',
                  ),
                ],
              );
              http.respond(
                movementPath,
                refused(
                  422,
                  'Kalimat penolakan dari server yang cukup panjang untuk membungkus',
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

              await tester.scrollUntilVisible(
                find.widgetWithText(OutlinedButton, '5').first,
                200,
                scrollable: find.byType(Scrollable).first,
              );
              await fillAmountAndReason(tester);
              await tester.scrollUntilVisible(
                find.byKey(const Key('movement-account')),
                200,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.tap(find.byKey(const Key('movement-account')));
              await tester.pumpAndSettle();
              await tester.tap(find.textContaining('1-1000-0001'));
              await tester.pumpAndSettle();
              await tester.tap(saveButton);
              await tester.pumpAndSettle();

              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });
}

void keyboard() {
  group('the tablet keyboard', () {
    testWidgets('does not cover the save button when it opens for the reason', (
      tester,
    ) async {
      final http = RoutedHttp();
      backend(http);
      await openSheet(tester, http, size: const Size(1280, 800));

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(tester.getRect(saveButton).bottom, lessThanOrEqualTo(800 - 300));
    });
  });
}
