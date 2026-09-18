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
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/printer_fake.dart';
import 'package:pn_types/src/native/printer_port.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/printer/printer_service.dart';
import 'package:pos/screens/menu/menu_screen.dart';
import 'package:pos/screens/queue/pending_sales_screen.dart';
import 'package:pos/session/session_holder.dart';

import '../../support/boot_rig.dart';

// S14. Run inside the real `PosApp`, so the gate that decides a signed-in device belongs at the
// till — and therefore that this screen is reachable at all — is the one under test too.
//
// C10 is built in stages. This is the first: the account, the device, the language, the theme,
// and **signing out**. The shift actions, the printer, and the debug inspector follow; nothing
// here pretends to be them.

Widget _elsewhere(BuildContext _) => const Text('elsewhere');

/// A paired tablet with Budi signed in, and a device name — what the gate sends to the till.
final signedIn = paired.copyWith(
  user: const SessionUser(id: 'user_1', name: 'Budi'),
  deviceName: 'Tablet Kasir',
);

PosApp appWith(Rig rig, PublicHttpPort http) => PosApp(
  boot: () => rig.bootWith(http: http),
  language: rig.language,
  theme: rig.theme,
  screens: (
    pairing: _elsewhere,
    login: _elsewhere,
    till: (_) => const MenuScreen(),
  ),
);

/// A backend for a signed-in device: the two reads the Menu makes.
class MenuHttp implements PublicHttpPort {
  MenuHttp({
    this.outletStatus = 200,
    this.shiftStatus = 200,
    this.shiftOpen = true,
  });

  final int outletStatus;
  final int shiftStatus;

  /// False answers `null` for the active shift, which is what the server says when the drawer is
  /// shut. A separate flag and not a nullable body: `null` there would mean both "not given" and
  /// "no shift", and the test that wants the second would silently get the first.
  final bool shiftOpen;

  final calls = <TransportRequest>[];

  /// Set by [holdShift]: while non-null, a read of the active shift waits on this instead of
  /// answering — what a genuinely slow read looks like, for a test to check what the screen
  /// shows while it is still out.
  Completer<TransportResponse>? _heldShift;
  Completer<TransportResponse>? _heldOutlet;

  /// The next read of the active shift does not answer until [releaseShift] is called.
  void holdShift() => _heldShift = Completer<TransportResponse>();

  void releaseShift() => _heldShift!.complete(_shiftAnswer());

  /// The next read of the outlet does not answer until [releaseOutlet] is called.
  void holdOutlet() => _heldOutlet = Completer<TransportResponse>();

  void releaseOutlet() => _heldOutlet!.complete(
    _answer(outletStatus, {'id': 'out_1', 'name': 'Outlet Pusat'}),
  );

  TransportResponse _shiftAnswer() => _answer(
    shiftStatus,
    shiftOpen
        ? {
            'id': 'shift_1',
            'number': 'SH-0001',
            'cashier_id': 'user_1',
            'outlet_id': 'out_1',
            'opened_at': '2026-09-20T01:00:00Z',
            'opening_cash': 150000,
            'total_sales': 0,
            'total_transactions': 0,
          }
        : null,
  );

  @override
  Future<TransportResponse> send(
    String baseUrl,
    TransportRequest request,
  ) async {
    calls.add(request);
    if (request.path.startsWith('/api/v1/outlets/')) {
      final held = _heldOutlet;
      return held != null
          ? held.future
          : _answer(outletStatus, {'id': 'out_1', 'name': 'Outlet Pusat'});
    }
    if (request.path.startsWith('/api/v1/pos/shifts/active')) {
      final held = _heldShift;
      return held != null ? held.future : _shiftAnswer();
    }
    final path = request.path.split('?').first;
    // What the shift screen reads once it is opened from here.
    if (path == '/api/v1/pos/shifts/shift_1') {
      return _answer(200, {
        'shift_id': 'shift_1',
        'number': 'SH-0001',
        'status': 'OPEN',
        'outlet_id': 'out_1',
        'cashier_id': 'user_1',
        'opened_at': '2026-09-20T01:00:00Z',
        'total_transactions': 0,
        'total_sales': 0,
        'opening_cash': 150000,
        'expected_cash': 150000,
        'cash_in': 0,
        'cash_out': 0,
        'cash_drop': 0,
      });
    }
    if (path == '/api/v1/pos/shifts/shift_1/cash-movements') {
      return _answer(200, <Object?>[]);
    }
    // The shift history, when it is opened from here: nothing to list.
    if (path == '/api/v1/pos/shifts') {
      return TransportResponse(
        status: 200,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'data': <Object?>[],
          'meta': {'next_cursor': null},
        }),
      );
    }
    if (path == '/api/v1/pos/sales') {
      return TransportResponse(
        status: 200,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'data': <Object?>[],
          'meta': {'next_cursor': null},
        }),
      );
    }
    throw StateError('MenuHttp: no answer for ${request.path}');
  }

  TransportResponse _answer(int status, Object? data) => TransportResponse(
    status: status,
    headers: const {'content-type': 'application/json'},
    body: status == 200
        ? jsonEncode({'data': data})
        : jsonEncode({
            'error': {'message': 'Ditolak server'},
          }),
  );
}

/// A store that reads everything but the saved printer, which it cannot: the disk answering for
/// the session and refusing for one key is enough to tell "nothing saved" from "cannot read".
class _PrinterUnreadableStore extends FakeStorePort {
  _PrinterUnreadableStore(super.initial);

  @override
  Future<String?> read(String key) async {
    if (key == printerKey) throw StoreException('keystore');
    return super.read(key);
  }
}

/// A paired tablet with Budi signed in, showing [screen]. Gives back the rig, so a test can look
/// at what went through the fake ports.
///
/// [savedPrinter] is a printer this tablet was already paired with.
Future<Rig> pumpMenu(
  WidgetTester tester, {
  MenuHttp? http,
  Size size = const Size(1280, 800),
  double textScale = 1,
  PosSession? session,
  bool versionKnown = true,
  PrinterDevice? savedPrinter,
  FakePrinter? printer,
  bool printerUnreadable = false,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final stored = {
    ...storedSession(session ?? signedIn),
    if (savedPrinter != null)
      printerKey: jsonEncode({
        'address': savedPrinter.address,
        'name': savedPrinter.name,
      }),
  };
  final rig = Rig(
    stored,
    printerUnreadable ? _PrinterUnreadableStore(stored) : null,
  );
  if (!versionKnown) rig.appInfo.answer = null;
  if (printer != null) rig.printer = printer;
  await tester.pumpWidget(appWith(rig, http ?? MenuHttp()));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return rig;
}

Finder get signOutButton => find.widgetWithText(FilledButton, 'Keluar');
Finder get confirmSignOut => find.widgetWithText(FilledButton, 'Ya, keluar');

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

PendingSale queueEntry(
  String ref, {
  String cashierId = 'user_1',
  PendingSaleStatus status = PendingSaleStatus.pending,
}) => PendingSale(
  clientRef: ref,
  companyId: 'comp_1',
  outletId: 'out_1',
  cashierId: cashierId,
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

void main() {
  group('what the menu shows', () {
    testWidgets('who is signed in, and which tablet this is', (tester) async {
      await pumpMenu(tester);

      expect(find.text('Budi'), findsOneWidget);
      expect(find.text('Tablet Kasir'), findsOneWidget);
    });

    testWidgets('the outlet name, not its id', (tester) async {
      await pumpMenu(tester);

      // The session stores the outlet id. A cashier checking where this tablet is pointed must
      // not be shown a ULID.
      expect(find.text('Outlet Pusat'), findsOneWidget);
      expect(find.text('out_1'), findsNothing);
    });

    testWidgets('the open shift, by number', (tester) async {
      await pumpMenu(tester);

      expect(find.text('SH-0001'), findsOneWidget);
    });

    testWidgets(
      'a cashier with no name is "Tidak diketahui", not a blank row',
      (tester) async {
        await pumpMenu(
          tester,
          session: signedIn.copyWith(user: const SessionUser(id: 'user_1')),
        );

        // Always drawn, never conditional: a card with no cashier row at all reads as "nobody is
        // signed in" rather than "unknown" (`menu-page.tsx`).
        expect(find.text('Tidak diketahui'), findsOneWidget);
      },
    );

    testWidgets('a shift that is not open says so, and is not an error', (
      tester,
    ) async {
      await pumpMenu(tester, http: MenuHttp(shiftOpen: false));

      expect(find.text('Tidak ada shift terbuka'), findsOneWidget);
    });
  });

  group('the app version', () {
    final l10n = lookupL10n(const Locale('id'));

    testWidgets('is shown with its build number', (tester) async {
      await pumpMenu(tester);

      expect(find.text(l10n.menuVersion('1.4.2', '37')), findsOneWidget);
    });

    testWidgets('says it is unknown when the platform cannot tell, and is '
        'not a blank', (tester) async {
      await pumpMenu(tester, versionKnown: false);

      expect(find.text(l10n.menuVersionUnknown), findsOneWidget);
    });
  });

  group('the printer', () {
    const kitchen = PrinterDevice(address: 'AA:BB', name: 'Dapur');

    testWidgets('says there is none, and offers to connect one', (
      tester,
    ) async {
      await pumpMenu(tester);

      expect(find.text('Belum ada printer'), findsOneWidget);
      expect(find.text('Sambungkan printer'), findsOneWidget);
      // Nothing to change or forget yet: buttons for what does not exist have no place.
      expect(find.text('Lupakan printer'), findsNothing);
    });

    testWidgets(
      'names the one that is saved, and offers to change or forget it',
      (tester) async {
        await pumpMenu(tester, savedPrinter: kitchen);

        expect(find.text('Dapur'), findsOneWidget);
        expect(find.text('Ganti printer'), findsOneWidget);
        expect(find.text('Lupakan printer'), findsOneWidget);
        expect(find.text('Belum ada printer'), findsNothing);
      },
    );

    // "No printer" is a claim: a cashier told so pairs one that is in fact paired.
    testWidgets('a saved printer that cannot be read is not "none"', (
      tester,
    ) async {
      await pumpMenu(tester, printerUnreadable: true);

      expect(find.text('Belum ada printer'), findsNothing);
      expect(find.text('Printer tersimpan tidak bisa dibaca'), findsOneWidget);
      // Pairing overwrites what is there, so it is still the way out.
      expect(find.text('Sambungkan printer'), findsOneWidget);
    });

    testWidgets('forgetting asks first, and cancelling keeps it', (
      tester,
    ) async {
      final rig = await pumpMenu(tester, savedPrinter: kitchen);

      await tester.ensureVisible(find.text('Lupakan printer'));
      await tester.tap(find.text('Lupakan printer'));
      await tester.pumpAndSettle();
      expect(find.text('Lupakan printer ini?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Batal'));
      await tester.pumpAndSettle();

      expect(await readSavedPrinter(rig.store), kitchen);
      expect(find.text('Dapur'), findsOneWidget);
    });

    testWidgets('a forget the tablet could not carry out says so', (
      tester,
    ) async {
      final rig = await pumpMenu(tester, savedPrinter: kitchen);

      await tester.ensureVisible(find.text('Lupakan printer'));
      await tester.tap(find.text('Lupakan printer'));
      await tester.pumpAndSettle();
      rig.store.failNext(StoreException('disk'));
      await tester.tap(find.widgetWithText(FilledButton, 'Ya, lupakan'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal melupakan printer. Coba lagi.'), findsOneWidget);
      // Still saved, and the Menu still says so.
      expect(await readSavedPrinter(rig.store), kitchen);
      expect(find.text('Dapur'), findsOneWidget);
    });

    testWidgets('forgetting drops the link and the saved printer', (
      tester,
    ) async {
      final rig = await pumpMenu(tester, savedPrinter: kitchen);
      await rig.printer.connect(kitchen.address);

      await tester.ensureVisible(find.text('Lupakan printer'));
      await tester.tap(find.text('Lupakan printer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Ya, lupakan'));
      await tester.pumpAndSettle();

      expect(await readSavedPrinter(rig.store), isNull);
      expect(rig.printer.connectedAddress, isNull);
      expect(find.text('Belum ada printer'), findsOneWidget);
      expect(find.text('Sambungkan printer'), findsOneWidget);
    });
  });

  group('the request inspector', () {
    final l10n = lookupL10n(const Locale('id'));

    Future<void> tapVersion(WidgetTester tester, int times) async {
      final version = find.text(l10n.menuVersion('1.4.2', '37'));
      await tester.ensureVisible(version);
      for (var i = 0; i < times; i++) {
        await tester.tap(version);
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('is hidden: nothing on the menu names it', (tester) async {
      await pumpMenu(tester);

      expect(find.text(l10n.inspectorTitle), findsNothing);
    });

    testWidgets('opens after the version is tapped seven times', (
      tester,
    ) async {
      await pumpMenu(tester);

      await tapVersion(tester, 7);

      expect(find.text(l10n.inspectorTitle), findsOneWidget);
    });

    testWidgets('does not open after six', (tester) async {
      await pumpMenu(tester);

      await tapVersion(tester, 6);

      expect(find.text(l10n.inspectorTitle), findsNothing);
    });
  });

  group('the shift detail', () {
    final l10n = lookupL10n(const Locale('id'));

    testWidgets('is offered when a shift is open', (tester) async {
      await pumpMenu(tester);

      expect(find.text(l10n.menuShiftDetail), findsOneWidget);
    });

    testWidgets('is not offered when no shift is open', (tester) async {
      await pumpMenu(tester, http: MenuHttp(shiftOpen: false));

      expect(find.text(l10n.menuShiftDetail), findsNothing);
    });

    testWidgets('is not offered when the shift could not be read: there is '
        'nothing known to open', (tester) async {
      await pumpMenu(tester, http: MenuHttp(shiftStatus: 500));

      expect(find.text(l10n.menuShiftDetail), findsNothing);
    });

    testWidgets('opens the shift screen', (tester) async {
      await pumpMenu(tester);

      await tester.tap(find.text(l10n.menuShiftDetail));
      await tester.pumpAndSettle();

      expect(find.text(l10n.shiftDetailTitle), findsOneWidget);
    });
  });

  // A read still out is not the same fact as "no shift is open" — the same distinction the
  // screen already draws for a *failed* read (`shift_gate_screen.dart` makes it too). Collapsing
  // "loading" into "no shift" tells a cashier their drawer is shut while the app simply has not
  // heard back yet, which on a slow connection can sit on screen for a long time.
  group('the shift while the read is still out', () {
    final l10n = lookupL10n(const Locale('id'));

    testWidgets('says loading, not that none is open', (tester) async {
      final http = MenuHttp()..holdShift();

      await pumpMenu(tester, http: http, settle: false);

      expect(find.text(l10n.menuNoShift), findsNothing);
      expect(find.text(l10n.commonLoading), findsWidgets);

      // Cleans up the completer the fake is still holding, so the timer/future does not leak
      // into the next test.
      http.releaseShift();
      await tester.pumpAndSettle();
    });

    testWidgets('shows the shift once the read comes back', (tester) async {
      final http = MenuHttp()..holdShift();
      await pumpMenu(tester, http: http, settle: false);

      http.releaseShift();
      // Two plain frames, not `pumpAndSettle`: this has to be the read's own notification
      // reaching the screen, not some other, unrelated rebuild papering over a missing one.
      await tester.pump();
      await tester.pump();

      expect(find.text('SH-0001'), findsOneWidget);
      expect(find.text(l10n.menuNoShift), findsNothing);
    });
  });

  // Same bug, the outlet's own `Loadable`: the fix has to cover both reads, not just the one
  // the first regression test happened to use.
  group('the outlet while the read is still out', () {
    testWidgets('shows the name once the read comes back, on its own', (
      tester,
    ) async {
      final http = MenuHttp()..holdOutlet();
      await pumpMenu(tester, http: http, settle: false);

      http.releaseOutlet();
      await tester.pump();
      await tester.pump();

      expect(find.text('Outlet Pusat'), findsOneWidget);
    });
  });

  group('the shift history', () {
    testWidgets('is reachable with no shift open, which is when it is needed', (
      tester,
    ) async {
      await pumpMenu(tester, http: MenuHttp(shiftOpen: false));

      expect(find.text('Riwayat shift'), findsOneWidget);
      // The detail of the open shift has nothing to show without one; the history does.
      expect(find.text('Detail shift'), findsNothing);
    });

    testWidgets('opens the list of shifts', (tester) async {
      final http = MenuHttp(shiftOpen: false);
      await pumpMenu(tester, http: http);

      await tester.ensureVisible(find.text('Riwayat shift'));
      await tester.tap(find.text('Riwayat shift'));
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Shift'), findsOneWidget);
      expect(
        http.calls.any((c) => c.path.startsWith('/api/v1/pos/shifts?')),
        isTrue,
      );
    });
  });

  group('the pending sales card', () {
    final pendingEntry = queueEntry;

    testWidgets('says every sale is sent when the queue is empty', (
      tester,
    ) async {
      await pumpMenu(tester);

      expect(find.text('Semua sudah terkirim.'), findsOneWidget);
    });

    testWidgets('says how many are waiting once the queue has something', (
      tester,
    ) async {
      final rig = await pumpMenu(tester);
      final services = AppScope.of(tester.element(find.byType(MenuScreen)));
      await rig.pendingSaleStore.enqueue(pendingEntry('REF-1'));
      await rig.pendingSaleStore.enqueue(pendingEntry('REF-2'));
      await services.queueSync.refreshCounts();
      await tester.pump();

      expect(find.text('2 menunggu dikirim'), findsOneWidget);
    });

    testWidgets('opens the pending sales screen', (tester) async {
      await pumpMenu(tester);
      final button = find.widgetWithText(OutlinedButton, 'Penjualan tertunda');

      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(PendingSalesScreen), findsOneWidget);
    });
  });

  group('when a read fails', () {
    testWidgets(
      'the outlet failing still shows the shift and the sign-out button',
      (tester) async {
        await pumpMenu(tester, http: MenuHttp(outletStatus: 500));

        // The whole point of the two reads being separate: a cashier whose outlet name failed can
        // still see their shift, and can still sign out.
        expect(find.text('SH-0001'), findsOneWidget);
        expect(find.text('Ditolak server'), findsOneWidget);
        expect(signOutButton, findsOneWidget);
      },
    );

    testWidgets('a failed shift read does not claim the drawer is shut', (
      tester,
    ) async {
      await pumpMenu(tester, http: MenuHttp(shiftStatus: 500));

      // "No shift is open" is a fact about the drawer. A read that failed is not that fact, and
      // telling a cashier their drawer is shut while it is open is worse than saying nothing.
      expect(find.text('Tidak ada shift terbuka'), findsNothing);
      expect(find.text('Ditolak server'), findsOneWidget);
    });
  });

  group('signing out', () {
    testWidgets('asks first, and says the pairing stays', (tester) async {
      await pumpMenu(tester);

      await tester.ensureVisible(signOutButton);
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari akun ini?'), findsOneWidget);
      // The sentence is the only place a cashier can learn they will not have to pair again.
      expect(find.textContaining('tidak perlu pairing ulang'), findsOneWidget);
    });

    testWidgets('cancelling leaves the cashier signed in', (tester) async {
      final rig = Rig(storedSession(signedIn));
      final http = MenuHttp();
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(appWith(rig, http));
      await tester.pumpAndSettle();

      await tester.ensureVisible(signOutButton);
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Batal'));
      await tester.pumpAndSettle();

      // The token is what the gate reads. Cancelling must not have touched it.
      final stored = await rig.store.read(sessionKey);
      expect(stored, contains('tok_secret_value'));
    });

    testWidgets('confirming clears the token but keeps the pairing', (
      tester,
    ) async {
      final rig = Rig(storedSession(signedIn));
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(appWith(rig, MenuHttp()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(signOutButton);
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();
      await tester.tap(confirmSignOut);
      await tester.pumpAndSettle();

      final stored = await rig.store.read(sessionKey);
      expect(stored, isNotNull);

      final session = PosSession.fromJson(
        jsonDecode(stored!) as Map<String, dynamic>,
      );
      // The credential goes, including the refresh token: leaving it would let a signed-out
      // tablet renew itself silently.
      expect(session.sessionToken, isEmpty);
      expect(session.sessionRefreshToken, isNull);
      // The pairing stays: the tablet is still registered to its outlet, so the next cashier
      // only has to sign in. This is the difference between sign-out and Reset Perangkat.
      expect(session.baseUrl, 'https://erp.perusahaan.com');
      expect(session.outletId, 'out_1');
    });

    // D-Q1: only the cashier who typed a sale may send it, so signing out while one of theirs
    // is still queued would leave nobody able to attribute it — Keluar refuses instead.
    testWidgets(
      'is refused while this cashier still has a queued sale, and offers the queue screen',
      (tester) async {
        final rig = await pumpMenu(tester);
        await rig.pendingSaleStore.enqueue(queueEntry('REF-1'));

        await tester.ensureVisible(signOutButton);
        await tester.tap(signOutButton);
        await tester.pumpAndSettle();
        await tester.tap(confirmSignOut);
        await tester.pumpAndSettle();

        final stored = await rig.store.read(sessionKey);
        expect(stored, contains('tok_secret_value'));
        expect(find.textContaining('belum terkirim'), findsOneWidget);

        await tester.tap(find.widgetWithText(TextButton, 'Penjualan tertunda'));
        await tester.pumpAndSettle();
        expect(find.byType(PendingSalesScreen), findsOneWidget);
      },
    );

    testWidgets('is not refused by another cashier\'s queued sale', (
      tester,
    ) async {
      final rig = await pumpMenu(tester);
      await rig.pendingSaleStore.enqueue(
        queueEntry('REF-1', cashierId: 'someone_else'),
      );

      await tester.ensureVisible(signOutButton);
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();
      await tester.tap(confirmSignOut);
      await tester.pumpAndSettle();

      final stored = await rig.store.read(sessionKey);
      final session = PosSession.fromJson(
        jsonDecode(stored!) as Map<String, dynamic>,
      );
      expect(session.sessionToken, isEmpty);
    });

    // An unreadable queue is never treated as empty (`pos_pending_sale_store.dart`): letting a
    // cashier sign out over one that cannot be proven clear is the exact mistake D-Q1 prevents.
    testWidgets('is refused when the queue cannot be read', (tester) async {
      final rig = await pumpMenu(tester);
      rig.pendingSaleStore.failRead = true;

      await tester.ensureVisible(signOutButton);
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();
      await tester.tap(confirmSignOut);
      await tester.pumpAndSettle();

      final stored = await rig.store.read(sessionKey);
      expect(stored, contains('tok_secret_value'));
    });
  });

  group('the layout', () {
    testWidgets('every card and the sign-out button fill the width', (
      tester,
    ) async {
      await pumpMenu(tester, size: const Size(1280, 800));
      await tester.ensureVisible(signOutButton);

      // The screen's 16 dp padding on each side, and nothing narrower: a button that shrinks to
      // its label and sits in the middle beside cards that fill the row reads as a mistake.
      expect(tester.getSize(signOutButton).width, 1280 - 32);
      final language = find.ancestor(
        of: find.text('Bahasa'),
        matching: find.byType(DecoratedBox),
      );
      expect(tester.getSize(language.first).width, 1280 - 32);
    });

    testWidgets('fits a small tablet in portrait, with text at 1.3x', (
      tester,
    ) async {
      await pumpMenu(tester, size: const Size(600, 960), textScale: 1.3);

      expect(tester.takeException(), isNull);
      expect(signOutButton, findsOneWidget);
    });

    testWidgets('fits a landscape tablet, dark', (tester) async {
      await pumpMenu(tester);

      expect(tester.takeException(), isNull);
      // A mis-tap on sign-out is a shift change, so it gets the primary touch size.
      expect(
        tester.getSize(signOutButton).height,
        greaterThanOrEqualTo(PnTouch.primary),
      );
    });
  });

  group('the language and theme pickers', () {
    testWidgets('picking a language applies it at once', (tester) async {
      final rig = Rig(storedSession(signedIn));
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(appWith(rig, MenuHttp()));
      await tester.pumpAndSettle();
      expect(find.text('Menu'), findsOneWidget);

      await tester.ensureVisible(find.text('English'));
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // The screen is redrawn in the language that was just picked, without a restart.
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Keluar'), findsNothing);
    });

    testWidgets('picking a theme applies it at once', (tester) async {
      final rig = Rig(storedSession(signedIn));
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(appWith(rig, MenuHttp()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Gelap'));
      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MenuScreen));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('picking a language logs language_changed', (tester) async {
      final rig = await pumpMenu(tester);

      await tester.ensureVisible(find.text('English'));
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(rig.analytics.logged.single.$1, 'language_changed');
    });

    testWidgets('tapping the language already shown logs nothing', (
      tester,
    ) async {
      final rig = await pumpMenu(tester);

      await tester.ensureVisible(find.text('Indonesia'));
      await tester.tap(find.text('Indonesia'));
      await tester.pumpAndSettle();

      expect(rig.analytics.logged, isEmpty);
    });

    testWidgets('picking a theme logs theme_changed', (tester) async {
      final rig = await pumpMenu(tester);

      await tester.ensureVisible(find.text('Gelap'));
      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();

      expect(rig.analytics.logged.single.$1, 'theme_changed');
    });
  });
}
