/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/native_update_fake.dart';
import 'package:pn_types/src/native/native_update_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/native/updater_fake.dart';
import 'package:pn_types/src/native/updater_port.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/contrast.dart';
import 'package:pn_ui/src/theme/palette.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/boot_screens.dart';
import 'package:pos/app/gate.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/login/native_login.dart';
import 'package:pos/preferences/app_preferences.dart';

import '../support/boot_rig.dart';

/// A sale Q6's queue sync has to drain, typed by [paired]'s cashier below.
PendingSale pendingSale() => PendingSale(
  clientRef: 'REF-1',
  companyId: paired.companyId,
  outletId: paired.outletId,
  cashierId: 'user_1',
  status: PendingSaleStatus.pending,
  paidAt: '2026-09-22T03:00:00.000Z',
  createdAt: '2026-09-22T03:00:00.000Z',
  payload: const POSCheckoutDTO(
    outletId: 'out_1',
    transactionDate: '2026-09-22',
    items: [
      POSCheckoutItemDTO(
        productId: 'p1',
        unitId: 'u1',
        quantity: 1,
        price: 15000,
      ),
    ],
    payments: [POSTenderDTO(method: POSTenderMethod.cash, amount: 15000)],
  ),
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

/// What `/pos/shifts/active` answers when no shift is open.
TransportResponse activeShiftResponse() => TransportResponse(
  status: 200,
  headers: const {'content-type': 'application/json'},
  body: '{"data":null}',
);

/// What `POST /pos/sales/checkout` answers for [pendingSale].
TransportResponse saleResponse() => TransportResponse(
  status: 200,
  headers: const {'content-type': 'application/json'},
  body: jsonEncode({
    'data': {
      'id': 'x1',
      'number': 'POS-0001',
      'shift_id': 's1',
      'outlet_id': 'out_1',
      'cashier_id': 'user_1',
      'transaction_date': '2026-09-22',
      'subtotal': 15000,
      'discount_amount': 0,
      'tax_amount': 0,
      'grand_total': 15000,
      'tendered_amount': 15000,
      'change_amount': 0,
      'status': 'POSTED',
      'created_at': '2026-09-22T03:00:00Z',
    },
  }),
);

const _screens = (pairing: _pairing, login: _login, till: _till);
Widget _pairing(BuildContext _) => const Text('pairing screen');
Widget _login(BuildContext _) => const Text('login screen');
Widget _till(BuildContext _) => const Text('till screen');

PosApp appOver(
  Rig rig, {
  UpdaterPort? updater,
  NativeUpdatePort? nativeUpdate,
}) => PosApp(
  boot: rig.boot,
  language: rig.language,
  theme: rig.theme,
  screens: _screens,
  updater: updater,
  nativeUpdate: nativeUpdate,
);

Brightness brightnessOf(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Gate))).brightness;

/// The colour the words of [text] are actually drawn in, and the colour of the bar behind them.
///
/// A banner is a `Material` with a `Text` on it, and the two are chosen by two different slots:
/// the bar by a container slot, the words by the text theme. Reading both back is the only way
/// to catch a bar whose two halves came out the same colour.
(Color, Color) bannerColours(WidgetTester tester, String text) {
  final finder = find.text(text);
  final bar = tester.widget<Material>(
    find.ancestor(of: finder, matching: find.byType(Material)).first,
  );
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  return (paragraph.text.style!.color!, bar.color!);
}

void main() {
  group('starting up', () {
    testWidgets('shows the boot screen until the app is up', (tester) async {
      final gate = Completer<BootResult>();
      final rig = Rig();

      await tester.pumpWidget(
        PosApp(
          boot: () => gate.future,
          language: rig.language,
          theme: rig.theme,
          screens: _screens,
        ),
      );

      expect(find.byType(BootScreen), findsOneWidget);
    });

    testWidgets('lands on pairing for a device nobody has paired', (
      tester,
    ) async {
      await tester.pumpWidget(appOver(Rig()));
      await tester.pumpAndSettle();

      expect(find.text('pairing screen'), findsOneWidget);
    });

    testWidgets('lands on the till for a paired device with a cashier', (
      tester,
    ) async {
      await tester.pumpWidget(appOver(Rig(storedSession(paired))));
      await tester.pumpAndSettle();

      expect(find.text('till screen'), findsOneWidget);
    });

    testWidgets('picks up a login that was left behind, once', (tester) async {
      final rig = Rig({...storedSession(paired), pendingLoginKey: 'req_abc'})
        ..http.respond(readyResponse());

      await tester.pumpWidget(appOver(rig));
      await tester.pumpAndSettle();

      expect(rig.http.calls, hasLength(1));
      expect(rig.http.calls.single.request.path, '/api/auth/mobile/poll');
    });

    testWidgets('refreshes a session close to its end, once', (tester) async {
      final rig = Rig(storedSession(endingAt(DateTime.utc(2026, 9, 21, 12))))
        ..http.respond(refreshedResponse());

      await tester.pumpWidget(appOver(rig));
      await tester.pumpAndSettle();

      expect(rig.http.calls, hasLength(1));
      expect(rig.http.calls.single.request.path, '/api/auth/refresh');
    });

    // D-Q8: the app coming up is also a moment to try the offline queue.
    testWidgets('drains a sale left queued from the last time it ran', (
      tester,
    ) async {
      final rig = Rig(
        storedSession(paired.copyWith(user: const SessionUser(id: 'user_1'))),
      );
      await rig.pendingSaleStore.enqueue(pendingSale());
      rig.http
        ..respond(activeShiftResponse())
        ..respond(saleResponse());

      await tester.pumpWidget(appOver(rig));
      await tester.pumpAndSettle();

      expect(await rig.pendingSaleStore.readAll(), isEmpty);
    });
  });

  group('when the storage cannot be read', () {
    Rig failing() => Rig(storedSession(paired))
      ..store.failNext(StoreException('the stored value could not be read'));

    testWidgets('says so with a retry, not with the pairing screen', (
      tester,
    ) async {
      await tester.pumpWidget(appOver(failing()));
      await tester.pumpAndSettle();

      expect(find.byType(BootFailedScreen), findsOneWidget);
      expect(find.text('pairing screen'), findsNothing);
    });

    testWidgets('comes up when the retry finds the storage working', (
      tester,
    ) async {
      await tester.pumpWidget(appOver(failing()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('till screen'), findsOneWidget);
    });
  });

  group('the screens', () {
    testWidgets('follow the session: pairing saves one and the app moves on', (
      tester,
    ) async {
      final rig = Rig()..http.respond(activatedResponse());
      await tester.pumpWidget(appOver(rig));
      await tester.pumpAndSettle();
      final services = AppScope.of(tester.element(find.byType(Gate)));

      await services.session.save(paired.copyWith(sessionToken: ''));
      await tester.pumpAndSettle();

      expect(find.text('login screen'), findsOneWidget);
    });

    testWidgets('see the services from a route pushed on top of them', (
      tester,
    ) async {
      await tester.pumpWidget(appOver(Rig()));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Gate));
      AppServices? seen;

      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) {
              seen = AppScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(seen, isNotNull);
    });
  });

  group('the theme', () {
    testWidgets('is dark when the cashier chose dark', (tester) async {
      final rig = Rig();
      await rig.theme.select(ThemeMode.dark);

      await tester.pumpWidget(appOver(rig));
      await tester.pumpAndSettle();

      expect(brightnessOf(tester), Brightness.dark);
    });

    testWidgets('changes at once when the cashier picks another', (
      tester,
    ) async {
      final rig = Rig();
      await rig.theme.select(ThemeMode.light);
      await tester.pumpWidget(appOver(rig));
      await tester.pumpAndSettle();

      await rig.theme.select(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(brightnessOf(tester), Brightness.dark);
    });

    testWidgets('paints the system bars to match, icons contrasting', (
      tester,
    ) async {
      final rig = Rig();
      await tester.pumpWidget(appOver(rig));
      await tester.pumpAndSettle();
      SystemUiOverlayStyle bar() => tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find
                .descendant(
                  of: find.byType(MaterialApp),
                  matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
                )
                .first,
          )
          .value;

      await rig.theme.select(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(
        bar().systemNavigationBarColor,
        pnTheme(Brightness.light).scaffoldBackgroundColor,
      );
      expect(bar().systemNavigationBarIconBrightness, Brightness.dark);
      expect(bar().statusBarIconBrightness, Brightness.dark);

      await rig.theme.select(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(
        bar().systemNavigationBarColor,
        pnTheme(Brightness.dark).scaffoldBackgroundColor,
      );
      expect(bar().systemNavigationBarIconBrightness, Brightness.light);
      expect(bar().statusBarIconBrightness, Brightness.light);
    });

    testWidgets('is the app theme, with its palette available', (tester) async {
      await tester.pumpWidget(appOver(Rig()));
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(Gate)));
      expect(theme.colorScheme.primary, const Color(0xFFFF9900));
    });
  });

  group('the Shorebird update banner', () {
    // The measurement above only means something if it can fail. It reads two slots that Material
    // fills in for you, so the same code is run over a scheme that leaves them unset: that is
    // what this app shipped before, and the words come out the same colour as the bar.
    testWidgets(
      'is measured in a way that can tell a legible bar from one that is not',
      (tester) async {
        const text = 'Pembaruan siap.';
        final p = PnPalette.light;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme(
                brightness: Brightness.light,
                primary: p.accent,
                onPrimary: p.onAccent,
                // Exactly the old shape: one neutral in `secondary`, and the container slots left
                // unset so Material falls back to it.
                secondary: p.ink,
                onSecondary: p.background,
                error: p.error,
                onError: p.onError,
                surface: p.surface,
                onSurface: p.ink,
              ),
            ),
            home: Builder(
              builder: (context) => Material(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        );

        final (words, bar) = bannerColours(tester, text);

        expect(words, bar, reason: 'the probe must reproduce the old fallback');
        expect(contrastRatio(words, bar), lessThan(4.5));
      },
    );

    testWidgets('shows once Shorebird says a restart is needed', (
      tester,
    ) async {
      await tester.pumpWidget(
        appOver(
          Rig(storedSession(paired)),
          updater: FakeUpdater(status: UpdaterStatus.restartRequired),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Pembaruan siap. Restart aplikasi untuk menerapkannya.'),
        findsOneWidget,
      );
    });

    testWidgets('says nothing while the app is already up to date', (
      tester,
    ) async {
      await tester.pumpWidget(
        appOver(
          Rig(storedSession(paired)),
          updater: FakeUpdater(status: UpdaterStatus.upToDate),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Pembaruan siap. Restart aplikasi untuk menerapkannya.'),
        findsNothing,
      );
    });

    testWidgets('checks nothing when the app is given no updater', (
      tester,
    ) async {
      await tester.pumpWidget(appOver(Rig(storedSession(paired))));
      await tester.pumpAndSettle();

      expect(
        find.text('Pembaruan siap. Restart aplikasi untuk menerapkannya.'),
        findsNothing,
      );
    });

    // The bar and its words are two different slots, and only one of them was ever set. Material
    // falls back: an unset `secondaryContainer` is `secondary`, and an unset `onSecondaryContainer`
    // is `onSecondary`. With `secondary` painted in ink, the words were ink on ink.
    for (final brightness in Brightness.values) {
      testWidgets(
        'draws words the cashier can read on the bar behind them, in ${brightness.name}',
        (tester) async {
          final rig = Rig(storedSession(paired));
          await rig.theme.select(
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          );
          await tester.pumpWidget(
            appOver(
              rig,
              updater: FakeUpdater(status: UpdaterStatus.restartRequired),
            ),
          );
          await tester.pumpAndSettle();

          final (words, bar) = bannerColours(
            tester,
            'Pembaruan siap. Restart aplikasi untuk menerapkannya.',
          );

          expect(
            contrastRatio(words, bar),
            greaterThanOrEqualTo(4.5),
            reason: 'words $words on bar $bar',
          );
        },
      );
    }
  });

  group('the native update banner', () {
    testWidgets('shows once Play says a native update is ready to install', (
      tester,
    ) async {
      await tester.pumpWidget(
        appOver(
          Rig(storedSession(paired)),
          nativeUpdate: FakeNativeUpdate(
            status: NativeUpdateStatus.readyToInstall,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Versi baru siap dipasang.'), findsOneWidget);
    });

    testWidgets('installs it once the cashier taps the action', (tester) async {
      final nativeUpdate = FakeNativeUpdate(
        status: NativeUpdateStatus.readyToInstall,
      );
      await tester.pumpWidget(
        appOver(Rig(storedSession(paired)), nativeUpdate: nativeUpdate),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pasang'));
      await tester.pumpAndSettle();

      expect(nativeUpdate.completeCount, 1);
    });

    testWidgets('says nothing while the app is already up to date', (
      tester,
    ) async {
      await tester.pumpWidget(
        appOver(
          Rig(storedSession(paired)),
          nativeUpdate: FakeNativeUpdate(status: NativeUpdateStatus.upToDate),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Versi baru siap dipasang.'), findsNothing);
    });

    testWidgets('checks nothing when the app is given no native updater', (
      tester,
    ) async {
      await tester.pumpWidget(appOver(Rig(storedSession(paired))));
      await tester.pumpAndSettle();

      expect(find.text('Versi baru siap dipasang.'), findsNothing);
    });

    // Same two slots as the Shorebird bar above, and the same trap: the action on this one is a
    // `TextButton`, which takes its words from `colorScheme.primary`.
    for (final brightness in Brightness.values) {
      testWidgets(
        'draws words and an action the cashier can read on it, in ${brightness.name}',
        (tester) async {
          final rig = Rig(storedSession(paired));
          await rig.theme.select(
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          );
          await tester.pumpWidget(
            appOver(
              rig,
              nativeUpdate: FakeNativeUpdate(
                status: NativeUpdateStatus.readyToInstall,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final (words, bar) = bannerColours(
            tester,
            'Versi baru siap dipasang.',
          );
          final action = tester.renderObject<RenderParagraph>(
            find.text('Pasang'),
          );

          expect(
            contrastRatio(words, bar),
            greaterThanOrEqualTo(4.5),
            reason: 'words $words on bar $bar',
          );
          expect(
            contrastRatio(action.text.style!.color!, bar),
            greaterThanOrEqualTo(4.5),
            reason: 'action on bar $bar',
          );
        },
      );
    }

    // The point of the port split (§`native_update_port.dart`): a Shorebird patch never
    // changes the installed app's versionCode, so it cannot ever surface here — proven by
    // driving the Shorebird side to `restartRequired` and checking the native banner (with
    // no native updater given at all) still shows nothing.
    testWidgets('never shows for a Shorebird (Dart-only) update', (
      tester,
    ) async {
      await tester.pumpWidget(
        appOver(
          Rig(storedSession(paired)),
          updater: FakeUpdater(status: UpdaterStatus.restartRequired),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Versi baru siap dipasang.'), findsNothing);
    });
  });

  group('the language', () {
    Rig failingBoot() => Rig(storedSession(paired))
      ..store.failNext(StoreException('the stored value could not be read'));

    testWidgets('is Indonesian by default', (tester) async {
      await tester.pumpWidget(appOver(failingBoot()));
      await tester.pumpAndSettle();

      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('is English when the cashier chose English', (tester) async {
      final rig = failingBoot();
      await rig.language.select(AppLanguage.en);

      await tester.pumpWidget(appOver(rig));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('changes at once when the cashier picks another', (
      tester,
    ) async {
      final rig = failingBoot();
      await tester.pumpWidget(appOver(rig));
      await tester.pumpAndSettle();

      await rig.language.select(AppLanguage.en);
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
