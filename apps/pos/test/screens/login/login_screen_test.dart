/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pn_pos/src/pos_hold.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/file_ref.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/app/finnesia_logo.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/bootstrap.dart';
import 'package:pos/login/native_login.dart';
import 'package:pos/preferences/app_preferences.dart';
import 'package:pos/screens/login/login_screen.dart';
import 'package:pos/session/session_holder.dart';

import '../../support/boot_rig.dart';

// S3. Run inside the real `PosApp`, so what is tested is what the cashier gets: the boot, the
// gate deciding a paired device with no credential belongs here, the theme and the language.

Widget _elsewhere(BuildContext _) => const Text('elsewhere');

PosApp appWith(Rig rig, Future<BootResult> Function() boot) => PosApp(
  boot: boot,
  language: rig.language,
  theme: rig.theme,
  screens: (
    pairing: _elsewhere,
    login: (_) => const LoginScreen(),
    till: _elsewhere,
  ),
);

/// A paired device with nobody signed in: what the gate sends to the login screen.
PosSession signedOut([PosSession session = paired]) =>
    session.copyWith(sessionToken: '', sessionRefreshToken: null, user: null);

/// The store of a device that was paired and never signed in.
Map<String, String> pairedButSignedOut() => storedSession(signedOut());

void useSize(WidgetTester tester, Size size, double textScale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> pumpScreen(
  WidgetTester tester,
  Rig rig, {
  Size size = const Size(1280, 800),
  double textScale = 1,
}) async {
  useSize(tester, size, textScale);
  await tester.pumpWidget(appWith(rig, rig.boot));
  await tester.pumpAndSettle();
}

/// Advances frames without waiting for the app to be idle.
///
/// The waiting state has a `CircularProgressIndicator`, which animates forever, so
/// `pumpAndSettle` can never settle while a login is running. A test that wants to look at that
/// state has to drive the frames itself.
Future<void> tick(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder get submit => find.byType(FilledButton);
Finder get cancel => find.widgetWithText(TextButton, 'Batal');
HeldOrder _basket(String id) => HeldOrder(
  id: id,
  label: 'Meja $id',
  outletId: 'out_1',
  headerDiscount: 0,
  lines: const [],
  heldAt: '2026-09-21T03:00:00Z',
);

Finder get reset => find.widgetWithText(OutlinedButton, 'Reset perangkat');

const _draft = POSCheckoutDTO(
  outletId: 'out_1',
  transactionDate: '2026-09-21',
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

PendingSale _queuedSale() => PendingSale(
  clientRef: 'REF-1',
  companyId: 'comp_1',
  outletId: 'out_1',
  cashierId: 'user_1',
  status: PendingSaleStatus.pending,
  paidAt: '2026-09-21T03:00:00.000Z',
  createdAt: '2026-09-21T03:00:00.000Z',
  payload: _draft,
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

const pendingBody = '{"data":{"status":"pending"}}';

String startBody() => jsonEncode({
  'data': {'request_id': 'req_abc', 'login_url': loginUrl, 'expires_in': 300},
});

/// A `ready` poll answer, for the held-poll tests that need the login to finish.
String readyBody() => jsonEncode({
  'data': {
    'status': 'ready',
    'session_token': 'sess_tok',
    'session_refresh_token': 'sess_ref',
    'expires_at': '2026-09-24T10:00:00Z',
    'user': {'id': 'user_1', 'name': 'Budi'},
    'companies': [
      {
        'id': 'uc_1',
        'user_id': 'user_1',
        'company_id': 'comp_1',
        'role': 'cashier',
        'is_active': true,
      },
    ],
  },
});

/// The wait between two polls, ended only when the test says so.
///
/// The alternative, `() async {}`, turns the poll loop into a busy loop that consumes queued
/// answers faster than a test can look at the screen, and it is the loop *waiting* that the
/// waiting state is about.
class ManualWait {
  final _waiting = <Completer<void>>[];

  Future<void> call() {
    final turn = Completer<void>();
    _waiting.add(turn);
    return turn.future;
  }

  /// Ends the wait the loop is in, so it polls again.
  void release() {
    if (_waiting.isEmpty) return;
    _waiting.removeAt(0).complete();
  }

  /// Whether the loop is sitting in a wait right now.
  bool get isWaiting => _waiting.any((turn) => !turn.isCompleted);
}

/// A backend that answers the start call and every poll, and whose poll answers can be held so
/// a test can look at the screen while a login is running.
///
/// The wait between two polls is [ManualWait]: that is where the poll loop sits for two seconds
/// at a time, and therefore where a cashier's Batal lands.
class HeldPollHttp implements PublicHttpPort {
  HeldPollHttp({this.holdPolls = false});

  /// When true, polls are answered by the test through [answerHeld] rather than from the queue.
  final bool holdPolls;

  final calls = <TransportRequest>[];
  final _answers = <TransportResponse>[];
  final _held = <Completer<TransportResponse>>[];

  /// Queues the next poll's answer.
  void respond(TransportResponse response) => _answers.add(response);

  @override
  Future<TransportResponse> send(String baseUrl, TransportRequest request) {
    calls.add(request);
    if (request.path.endsWith('/mobile/start')) {
      return Future.value(TransportResponse(status: 200, body: startBody()));
    }
    if (holdPolls || _answers.isEmpty) {
      final held = Completer<TransportResponse>();
      _held.add(held);
      return held.future;
    }
    return Future.value(_answers.removeAt(0));
  }

  /// Answers a poll that is being held.
  void answerHeld(TransportResponse response) {
    if (_held.isEmpty) return;
    _held.removeAt(0).complete(response);
  }

  /// Whether a poll is on the wire right now.
  bool get isPolling => _held.isNotEmpty;
}

void main() {
  group('what the cashier sees', () {
    testWidgets('the tenant name and one way in', (tester) async {
      final rig = Rig(
        storedSession(
          signedOut().copyWith(
            branding: const PosBranding(
              appName: 'Toko Budi',
              accountMode: 'self_service',
            ),
          ),
        ),
      );

      await pumpScreen(tester, rig);

      expect(find.text('Toko Budi'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
    });

    // `logo_url` empty means the Finnesia logo: the backend's own contract
    // (`dto/pos.go`: "Empty means the default Finnesia logo"), and the owner's K8.
    testWidgets('the Finnesia logo for a tenant with no logo of its own', (
      tester,
    ) async {
      final rig = Rig(
        storedSession(
          signedOut().copyWith(
            branding: const PosBranding(
              appName: 'Toko Budi',
              accountMode: 'self_service',
            ),
          ),
        ),
      );

      await pumpScreen(tester, rig);

      expect(find.byType(FinnesiaLogo), findsOneWidget);
    });

    // Most tenants never configure branding, and the product name is the documented fallback
    // rather than an error path.
    testWidgets('the product name when the tenant never configured one', (
      tester,
    ) async {
      final rig = Rig(storedSession(signedOut().copyWith(branding: null)));

      await pumpScreen(tester, rig);

      expect(find.text('Finnesia POS'), findsOneWidget);
      expect(find.byType(FinnesiaLogo), findsOneWidget);
    });

    testWidgets('says which tablet this is', (tester) async {
      final rig = Rig(
        storedSession(signedOut().copyWith(deviceName: 'Kasir Depan')),
      );

      await pumpScreen(tester, rig);

      expect(find.text('Kasir Depan'), findsOneWidget);
    });

    testWidgets('speaks English when the cashier chose English', (
      tester,
    ) async {
      final rig = Rig(pairedButSignedOut());
      await rig.language.select(AppLanguage.en);

      await pumpScreen(tester, rig);

      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    });

    testWidgets('offers no Batal until there is something to cancel', (
      tester,
    ) async {
      // R-26: a button that does nothing is not shipped.
      await pumpScreen(tester, Rig(pairedButSignedOut()));

      expect(cancel, findsNothing);
    });
  });

  // The banner is one frame at a fixed 4:1 whether it shows the tenant's logo or the
  // Finnesia fallback, so the identity block does not jump between a tall image and a short
  // one as a tenant configures its branding.
  group('the identity banner', () {
    const attached = FileRef(
      id: 'f1',
      name: 'logo.png',
      status: 'attached',
      url: 'https://cdn.example.com/logo.png',
    );

    Rig rigWith(FileRef? logo) => Rig(
      storedSession(
        signedOut().copyWith(
          branding: PosBranding(
            appName: 'Toko Budi',
            logo: logo,
            accountMode: 'self_service',
          ),
        ),
      ),
    );

    /// The width of the one 4:1 frame on the screen.
    Future<Size> bannerFrame(WidgetTester tester) async {
      final frame = find.byWidgetPredicate(
        (widget) => widget is AspectRatio && widget.aspectRatio == 4 / 1,
        description: 'the 4:1 identity banner',
      );
      expect(frame, findsOneWidget);
      return tester.getSize(frame);
    }

    // The frame, not the image inside it: the image is letterboxed by `contain`, so its
    // painted size is the source's ratio, not the frame's.
    testWidgets('the tenant logo sits in a 4:1 frame', (tester) async {
      await pumpScreen(tester, rigWith(attached));

      final size = await bannerFrame(tester);
      expect(size.width / size.height, closeTo(4, 0.01));
    });

    testWidgets('the Finnesia fallback fills the same 4:1 frame', (
      tester,
    ) async {
      await pumpScreen(tester, rigWith(null));

      final size = await bannerFrame(tester);
      expect(size.width / size.height, closeTo(4, 0.01));
      expect(
        find.descendant(
          of: find.byType(AspectRatio),
          matching: find.byType(FinnesiaLogo),
        ),
        findsWidgets,
      );
    });

    // A detached or half-uploaded file must not reach an Image.network at all: `renderableUrl`
    // is null, so the banner is the fallback rather than a broken image.
    testWidgets('a logo that is not attached yet falls back', (tester) async {
      await pumpScreen(
        tester,
        rigWith(
          const FileRef(
            id: 'f1',
            name: 'logo.png',
            status: 'detached',
            url: 'https://cdn.example.com/logo.png',
          ),
        ),
      );

      // The Finnesia fallback is an `Image` too, so what must not be there is a network one.
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is NetworkImage,
          description: 'a tenant logo fetched over the network',
        ),
        findsNothing,
      );
      expect(find.byType(FinnesiaLogo), findsOneWidget);
      expect(await bannerFrame(tester), const Size(440, 110));
    });

    // A url that 404s at runtime: the widget is built, the fetch fails, and the frame keeps its
    // shape because the fallback is drawn into it rather than beside it.
    testWidgets('a logo that fails to load falls back inside the same frame', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        rigWith(
          const FileRef(
            id: 'f1',
            name: 'logo.png',
            status: 'attached',
            url: 'https://cdn.example.com/not-there.png',
          ),
        ),
      );

      expect(find.byType(FinnesiaLogo), findsOneWidget);
      expect(await bannerFrame(tester), const Size(440, 110));
    });
  });

  group('signing in', () {
    testWidgets('opens the browser, and says what is happening', (
      tester,
    ) async {
      final rig = Rig(pairedButSignedOut());
      final wait = ManualWait();
      final held = HeldPollHttp(holdPolls: true);
      rig.delay = wait.call;
      useSize(tester, const Size(1280, 800), 1);
      await tester.pumpWidget(appWith(rig, () => rig.bootWith(http: held)));
      await tester.pumpAndSettle();

      await tester.tap(submit);
      await tick(tester);

      // The OIDC session lives in the browser's cookie jar and never in this app's, so this URL
      // has to leave the app.
      expect(rig.opener.opened, [loginUrl]);
      expect(
        find.text(
          'Selesaikan login di browser yang terbuka. Halaman ini akan lanjut sendiri setelah selesai.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FilledButton, 'Menunggu login…'),
        findsOneWidget,
      );

      held.answerHeld(TransportResponse(status: 200, body: readyBody()));
      await tick(tester);
    });

    testWidgets('cannot be started twice while it is waiting', (tester) async {
      final rig = Rig(pairedButSignedOut());
      final wait = ManualWait();
      final held = HeldPollHttp(holdPolls: true);
      rig.delay = wait.call;
      useSize(tester, const Size(1280, 800), 1);
      await tester.pumpWidget(appWith(rig, () => rig.bootWith(http: held)));
      await tester.pumpAndSettle();

      await tester.tap(submit);
      await tick(tester);
      await tester.tap(submit, warnIfMissed: false);
      await tick(tester);

      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      // One login, so one request id: the backend hands a session out once, and a second poll
      // loop for the same id would sit out the full timeout and then fail.
      expect(
        held.calls.where((c) => c.path.endsWith('/mobile/start')),
        hasLength(1),
      );

      held.answerHeld(TransportResponse(status: 200, body: readyBody()));
      await tick(tester);
    });

    testWidgets('the gate moves on once the browser finishes', (tester) async {
      final rig = Rig(pairedButSignedOut());
      final wait = ManualWait();
      final held = HeldPollHttp(holdPolls: true);
      rig.delay = wait.call;
      useSize(tester, const Size(1280, 800), 1);
      await tester.pumpWidget(appWith(rig, () => rig.bootWith(http: held)));
      await tester.pumpAndSettle();

      await tester.tap(submit);
      await tick(tester);
      held.answerHeld(readyResponse());
      await tick(tester);

      expect(find.text('elsewhere'), findsOneWidget);
    });

    testWidgets('a login the app was killed in the middle of is collected', (
      tester,
    ) async {
      final rig = Rig({...pairedButSignedOut(), pendingLoginKey: 'req_abc'})
        ..http.respond(readyResponse());

      await pumpScreen(tester, rig);

      // No button was tapped: the boot picked up what was left behind, and the cashier never
      // had to walk to the dashboard again.
      expect(rig.http.calls.single.request.path, '/api/auth/mobile/poll');
    });

    // A resumed login can run for minutes. Nobody asked for it, so it must be stoppable.
    testWidgets('a collected login can still be given up on', (tester) async {
      final rig = Rig({...pairedButSignedOut(), pendingLoginKey: 'req_abc'});
      final wait = ManualWait();
      // The poll is held, so the loop is genuinely in the wait between two polls when the
      // cashier taps Batal — which is where a Batal lands in production too.
      final held = HeldPollHttp(holdPolls: true);
      rig.delay = wait.call;
      useSize(tester, const Size(1280, 800), 1);
      await tester.pumpWidget(appWith(rig, () => rig.bootWith(http: held)));
      await tick(tester);

      expect(
        find.widgetWithText(FilledButton, 'Menunggu login…'),
        findsOneWidget,
      );
      expect(cancel, findsOneWidget);

      held.answerHeld(TransportResponse(status: 200, body: pendingBody));
      await tick(tester);
      expect(wait.isWaiting, isTrue);

      await tester.tap(cancel);
      await tick(tester);

      expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
      expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
    });
  });

  group('giving up', () {
    /// Starts a login, answers its first poll as pending, and leaves the loop sitting in the wait
    /// between two polls: where a cashier's Batal actually lands.
    Future<(Rig, ManualWait, HeldPollHttp)> waitingBetweenPolls(
      WidgetTester tester,
    ) async {
      final rig = Rig(pairedButSignedOut());
      final wait = ManualWait();
      // The first poll is held and answered as pending by the test, so the loop is genuinely in
      // the wait between two polls when the cashier taps Batal. Answering from a queue instead
      // would let the loop reach the *next* poll before the tap lands.
      final held = HeldPollHttp(holdPolls: true);
      rig.delay = wait.call;
      useSize(tester, const Size(1280, 800), 1);
      await tester.pumpWidget(appWith(rig, () => rig.bootWith(http: held)));
      await tester.pumpAndSettle();
      await tester.tap(submit);
      // `tick`, not `pumpAndSettle`: the waiting state has a spinner that never stops, so
      // settling would time out rather than show it.
      await tick(tester);
      held.answerHeld(TransportResponse(status: 200, body: pendingBody));
      await tick(tester);
      return (rig, wait, held);
    }

    testWidgets('goes back to the button it started from', (tester) async {
      final (rig, wait, held) = await waitingBetweenPolls(tester);
      expect(wait.isWaiting, isTrue);
      final pollsBefore = held.calls.length;

      await tester.tap(cancel);
      await tick(tester);

      expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
      expect(cancel, findsNothing);
      // And the request is forgotten: left behind, the next launch would sign the cashier in to
      // a login they walked away from.
      expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
      // It stopped rather than polling again on its way out.
      expect(held.calls.length, pollsBefore);
    });

    testWidgets('leaves the tablet paired', (tester) async {
      final (rig, _, _) = await waitingBetweenPolls(tester);

      await tester.tap(cancel);
      await tick(tester);

      // Giving up on a login is not resetting the device: the host and the outlet stay, so the
      // cashier can sign in again without a new pairing code.
      final stored = (await SessionHolder(rig.store).hydrate())!;
      expect(stored.baseUrl, paired.baseUrl);
      expect(stored.outletId, paired.outletId);
      expect(find.text('elsewhere'), findsNothing);
    });

    testWidgets('says nothing about it', (tester) async {
      await waitingBetweenPolls(tester);

      await tester.tap(cancel);
      await tick(tester);

      // The cashier decided. An apology under the button they deliberately walked away from
      // would be noise.
      expect(find.textContaining('Belum bisa menghubungi'), findsNothing);
      expect(find.textContaining('kedaluwarsa'), findsNothing);
      expect(find.textContaining('Waktu login habis'), findsNothing);
    });

    // The request itself cannot be aborted — the HTTP port has no abort, and `api-client`
    // deliberately left cancellation out — so a Batal that lands while a poll is on the wire is
    // read when that poll answers. On a healthy connection that is milliseconds; the ceiling is
    // the transport's own receive timeout. The alternative, racing the cancel against the poll,
    // would leave a session the backend hands out once unclaimed.
    testWidgets('a Batal during a poll lands when that poll answers', (
      tester,
    ) async {
      final rig = Rig(pairedButSignedOut());
      final wait = ManualWait();
      final held = HeldPollHttp(holdPolls: true);
      rig.delay = wait.call;
      useSize(tester, const Size(1280, 800), 1);
      await tester.pumpWidget(appWith(rig, () => rig.bootWith(http: held)));
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tick(tester);
      expect(held.isPolling, isTrue);

      await tester.tap(cancel);
      await tick(tester);
      // Still on the wire, so the screen has not changed yet.
      expect(
        find.widgetWithText(FilledButton, 'Menunggu login…'),
        findsOneWidget,
      );

      held.answerHeld(TransportResponse(status: 200, body: pendingBody));
      await tick(tester);

      expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
      expect(rig.store.values.containsKey(pendingLoginKey), isFalse);
    });

    // The ordinary path: the cashier finishes in the browser and comes back. Waiting out the
    // rest of the interval first is two seconds of spinner over an answer that is already there.
    testWidgets('the browser coming back is polled at once', (tester) async {
      final (_, wait, held) = await waitingBetweenPolls(tester);
      final pollsBefore = held.calls.length;

      expect(wait.isWaiting, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tick(tester);

      // The wait was cut short, so the next poll went out without the interval elapsing.
      expect(held.calls.length, greaterThan(pollsBefore));
      held.answerHeld(readyResponse());
      await tick(tester);
      expect(find.text('elsewhere'), findsOneWidget);
    });

    testWidgets('a return that was not asked for changes nothing', (
      tester,
    ) async {
      final (rig, _, _) = await waitingBetweenPolls(tester);
      await tester.tap(cancel);
      await tick(tester);
      final callsBefore = rig.http.calls.length;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tick(tester);

      // No login is running, so there is nothing to wake.
      expect(rig.http.calls.length, callsBefore);
    });
  });

  group('when signing in does not work', () {
    Future<void> failWith(
      WidgetTester tester,
      Rig rig,
      TransportResponse response,
    ) async {
      await pumpScreen(tester, rig);
      rig.http.respond(response);
      await tester.tap(submit);
      await tester.pumpAndSettle();
    }

    testWidgets('says the server could not be reached', (tester) async {
      await failWith(
        tester,
        Rig(pairedButSignedOut()),
        TransportResponse(status: 500, body: '{}'),
      );

      expect(
        find.text(
          'Belum bisa menghubungi server. Periksa koneksi lalu coba lagi.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('says the request is gone, and offers the way back', (
      tester,
    ) async {
      final rig = Rig(pairedButSignedOut());
      await pumpScreen(tester, rig);
      // The start call succeeds; it is the poll that finds the request gone from Redis.
      rig.http.respond(TransportResponse(status: 200, body: startBody()));
      rig.http.respond(TransportResponse(status: 404, body: '{}'));

      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(
        find.text('Permintaan login sudah kedaluwarsa. Coba masuk lagi.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Coba lagi'), findsOneWidget);
    });

    testWidgets('says the wait ran out', (tester) async {
      final rig = Rig(pairedButSignedOut())..pollTimeout = Duration.zero;
      rig.http.respond(TransportResponse(status: 200, body: startBody()));
      rig.http.respond(TransportResponse(status: 200, body: pendingBody));

      await pumpScreen(tester, rig);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Waktu login habis. Coba masuk lagi.'), findsOneWidget);
    });

    testWidgets('a storage that cannot be read is not the server to blame', (
      tester,
    ) async {
      final rig = Rig(pairedButSignedOut());
      await pumpScreen(tester, rig);
      rig.http.respond(TransportResponse(status: 200, body: startBody()));
      rig.store.failNext(StoreException('disk full'));

      await tester.tap(submit);
      await tester.pumpAndSettle();

      // "Check the connection" would send the cashier the wrong way: the server answered fine.
      expect(
        find.text(
          'Belum bisa menghubungi server. Periksa koneksi lalu coba lagi.',
        ),
        findsOneWidget,
      );
    });

    // The message is about the attempt that failed, so the next attempt takes it away.
    testWidgets('the message goes when the cashier tries again', (
      tester,
    ) async {
      final rig = Rig(pairedButSignedOut());
      await failWith(tester, rig, TransportResponse(status: 500, body: '{}'));

      rig.http.respond(TransportResponse(status: 200, body: startBody()));
      rig.http.respond(readyResponse());
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.textContaining('Belum bisa menghubungi'), findsNothing);
      expect(find.text('elsewhere'), findsOneWidget);
    });

    testWidgets('is announced to a screen reader when it appears', (
      tester,
    ) async {
      await failWith(
        tester,
        Rig(pairedButSignedOut()),
        TransportResponse(status: 500, body: '{}'),
      );

      final data = tester
          .getSemantics(find.textContaining('Belum bisa menghubungi'))
          .getSemanticsData();
      expect(data.flagsCollection.isLiveRegion, isTrue);
    });
  });

  group('resetting the device', () {
    testWidgets('asks first, and says what it does not do', (tester) async {
      await pumpScreen(tester, Rig(pairedButSignedOut()));

      await tester.tap(reset);
      await tester.pumpAndSettle();

      expect(find.text('Reset perangkat?'), findsOneWidget);
      // R-36: the dialog says what is true. The tablet now tells the server to drop its row,
      // so the copy no longer claims the dashboard is the only way out.
      expect(find.textContaining('dihapus dari dashboard'), findsOneWidget);
      expect(find.text('Ya, reset'), findsOneWidget);
    });

    // What is lost is said before it is lost: a parked basket is a customer who is coming back.
    testWidgets('says how many parked baskets it will delete', (tester) async {
      final rig = Rig(pairedButSignedOut());
      await rig.holdStore.writeAll([_basket('a'), _basket('b')]);
      await pumpScreen(tester, rig);

      await tester.tap(reset);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('2 keranjang tertahan ikut dihapus.'),
        findsOneWidget,
      );
    });

    testWidgets('says nothing about baskets when there are none', (
      tester,
    ) async {
      await pumpScreen(tester, Rig(pairedButSignedOut()));

      await tester.tap(reset);
      await tester.pumpAndSettle();

      expect(find.textContaining('keranjang tertahan'), findsNothing);
    });

    testWidgets('deletes them when confirmed, and keeps them when not', (
      tester,
    ) async {
      final rig = Rig(pairedButSignedOut());
      rig.http.respond(TransportResponse(status: 200, body: '{"data":{}}'));
      await rig.holdStore.writeAll([_basket('a')]);
      await pumpScreen(tester, rig);

      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(await rig.holdStore.readAll(), hasLength(1));

      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, reset'));
      await tester.pumpAndSettle();
      expect(await rig.holdStore.readAll(), isEmpty);
    });

    testWidgets('does nothing when the cashier backs out', (tester) async {
      final rig = Rig(pairedButSignedOut());
      await pumpScreen(tester, rig);

      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(await SessionHolder(rig.store).hydrate(), isNotNull);
      expect(find.text('elsewhere'), findsNothing);
    });

    // The device token is what identifies this tablet to the server, and the row it points at
    // is about to be deleted. The call has to go out BEFORE the token is cleared, or there is
    // nothing left to authenticate it with and the row survives.
    testWidgets('tells the server to drop the device, then unpairs', (
      tester,
    ) async {
      final rig = Rig(pairedButSignedOut());
      rig.http.respond(TransportResponse(status: 200, body: '{"data":{}}'));
      await pumpScreen(tester, rig);

      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, reset'));
      await tester.pumpAndSettle();

      final call = rig.http.calls.single;
      expect(call.request.method, HttpMethod.delete);
      expect(call.request.path, '/api/v1/pos/devices/me');
      expect(call.request.headers['X-Device-Token'], 'dev_tok_1');
      expect(await SessionHolder(rig.store).hydrate(), isNull);
    });

    // The device is already gone from the server, or its token no longer resolves. The cashier
    // asked to unpair and the outcome is what they asked for, so this is not an error to show.
    testWidgets('treats an already-unregistered device as done', (
      tester,
    ) async {
      final rig = Rig(pairedButSignedOut());
      rig.http.respond(
        TransportResponse(
          status: 401,
          headers: const {'Content-Type': 'application/json'},
          body:
              '{"data":null,"error":{"name":"authorization","code":137,'
              '"key":"pos_device_unregistered"}}',
        ),
      );
      await pumpScreen(tester, rig);

      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, reset'));
      await tester.pumpAndSettle();

      expect(await SessionHolder(rig.store).hydrate(), isNull);
      expect(find.text('elsewhere'), findsOneWidget);
    });

    // The tablet is unreachable, or the server is unhappy. The cashier's request is still
    // honoured locally — a tablet stuck on the login screen cannot be recovered by anyone but
    // the admin who can already delete the row — but they are told the server may still hold it.
    testWidgets(
      'still unpairs when the server cannot be reached, and says so',
      (tester) async {
        final rig = Rig(pairedButSignedOut());
        rig.http.fail(TransportException('no connection'));
        await pumpScreen(tester, rig);

        await tester.tap(reset);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ya, reset'));
        await tester.pumpAndSettle();

        expect(await SessionHolder(rig.store).hydrate(), isNull);
        expect(find.textContaining('mungkin masih terdaftar'), findsOneWidget);
      },
    );

    testWidgets('closes when the keyboard says Escape', (tester) async {
      final rig = Rig(pairedButSignedOut());
      await pumpScreen(tester, rig);

      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Reset perangkat?'), findsNothing);
      expect(await SessionHolder(rig.store).hydrate(), isNotNull);
    });

    // README §6: money already on this tablet is not this dialog's to discard. The reset does
    // not even reach the server.
    testWidgets('is refused while a sale is still queued, and says so', (
      tester,
    ) async {
      final rig = Rig(pairedButSignedOut());
      await rig.pendingSaleStore.enqueue(_queuedSale());
      await pumpScreen(tester, rig);

      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, reset'));
      await tester.pumpAndSettle();

      expect(rig.http.calls, isEmpty);
      expect(await SessionHolder(rig.store).hydrate(), isNotNull);
      expect(find.textContaining('belum terkirim'), findsOneWidget);
    });
  });

  group('the layout', () {
    testWidgets('has a main button big enough to hit', (tester) async {
      await pumpScreen(tester, Rig(pairedButSignedOut()));

      expect(
        tester.getSize(submit).height,
        greaterThanOrEqualTo(PnTouch.primary),
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
            'fits a $name at text ${scale}x in the ${brightness.name} theme, with a message showing',
            (tester) async {
              final rig = Rig(pairedButSignedOut());
              await rig.theme.select(
                brightness == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
              );
              await pumpScreen(tester, rig, size: size, textScale: scale);
              rig.http.respond(TransportResponse(status: 500, body: '{}'));
              await tester.ensureVisible(submit);
              await tester.tap(submit);
              await tester.pumpAndSettle();

              expect(tester.takeException(), isNull);
              expect(
                find.textContaining('Belum bisa menghubungi'),
                findsOneWidget,
              );
            },
          );
        }
      }
    }
  });
}
