/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/native/device_info_fake.dart';
import 'package:pn_types/src/native/notification_webview_fake.dart';
import 'package:pn_types/src/native/opener_fake.dart';
import 'package:pn_types/src/native/push_messaging_fake.dart';
import 'package:pn_types/src/native/push_messaging_port.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/notifications/notification_inbox_controller.dart';
import 'package:pos/notifications/push_lifecycle_controller.dart';
import 'package:pos/screens/notifications/notification_inbox_screen.dart';
import 'package:pos/session/session_holder.dart';

import '../../support/boot_rig.dart';

TransportResponse _answer(Object? data) => TransportResponse(
  status: 200,
  headers: const {'content-type': 'application/json'},
  body: jsonEncode({'data': data}),
);

Map<String, Object?> _itemJson({
  String id = 'recipient_1',
  String notificationId = 'notification_1',
  String? companyId = 'comp_1',
  String? link,
  List<Object?> buttons = const [],
}) => {
  'id': id,
  'notification_id': notificationId,
  'type': 'announcement',
  'category': 'system',
  'title': 'Laporan siap',
  'body': 'Laporan mingguan dapat dibuka.',
  'link': link,
  'ref': null,
  'company_id': companyId,
  'actor': null,
  'icon': null,
  'image': null,
  'image_ratio': null,
  'buttons': buttons,
  'read_at': null,
  'created_at': '2026-10-28T01:02:03Z',
};

Widget _screenApp({
  required NotificationInboxController controller,
  required FakeNotificationWebViewPort webView,
  required FakeOpener opener,
  PushLifecycleController? pushController,
  String? initialNotificationId,
  String? initialCompanyId,
}) => MaterialApp(
  theme: pnTheme(Brightness.light),
  localizationsDelegates: L10n.localizationsDelegates,
  supportedLocales: L10n.supportedLocales,
  locale: const Locale('id'),
  home: NotificationInboxScreen(
    controller: controller,
    session: paired,
    webView: webView,
    opener: opener,
    pushController: pushController,
    initialNotificationId: initialNotificationId,
    initialCompanyId: initialCompanyId,
  ),
);

void main() {
  group('NotificationInboxScreen', () {
    late FakeApiTransport transport;
    late NotificationInboxController controller;
    late FakeNotificationWebViewPort webView;
    late FakeOpener opener;

    setUp(() {
      transport = FakeApiTransport();
      controller = NotificationInboxController(
        client: ApiClient(transport: transport, language: () => 'id'),
      );
      webView = FakeNotificationWebViewPort();
      opener = FakeOpener();
    });

    tearDown(() => controller.dispose());

    testWidgets(
      'asks for push permission only after the inbox action is tapped',
      (tester) async {
        final pushTransport = FakeApiTransport();
        final messaging = FakePushMessaging()
          ..permissionResult = PushAuthorizationStatus.authorized;
        final sessionHolder = SessionHolder(
          FakeStorePort(storedSession(paired)),
        );
        await sessionHolder.hydrate();
        final pushController = PushLifecycleController(
          client: ApiClient(transport: pushTransport, language: () => 'id'),
          messaging: messaging,
          session: sessionHolder,
          deviceInfo: FakeDeviceInfo(),
          locale: () => 'id',
        );
        addTearDown(pushController.dispose);
        addTearDown(messaging.dispose);
        await pushController.start();
        transport.respond(_answer({'items': [], 'next_cursor': ''}));

        await tester.pumpWidget(
          _screenApp(
            controller: controller,
            webView: webView,
            opener: opener,
            pushController: pushController,
          ),
        );
        await tester.pump();
        expect(messaging.requestPermissionCalls, 0);
        expect(find.text('Aktifkan notifikasi'), findsOneWidget);

        pushTransport.respond(
          TransportResponse(status: 204, headers: const {}, body: null),
        );
        await tester.tap(find.text('Aktifkan notifikasi'));
        await tester.pump();
        await tester.pump();

        expect(messaging.requestPermissionCalls, 1);
        expect(pushTransport.requests.single.path, '/api/v1/push-tokens');
      },
    );

    testWidgets('shows the server inbox items', (tester) async {
      transport.respond(
        _answer({
          'items': [_itemJson()],
          'next_cursor': '',
        }),
      );

      await tester.pumpWidget(
        _screenApp(controller: controller, webView: webView, opener: opener),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Kotak Masuk Notifikasi'), findsOneWidget);
      expect(find.text('Laporan siap'), findsOneWidget);
      expect(find.text('Laporan mingguan dapat dibuka.'), findsOneWidget);
    });

    testWidgets('waits for server open before opening the resolved URL', (
      tester,
    ) async {
      final item = _itemJson(link: '/reports/weekly');
      const destination = 'https://apps-dev.finnesia.com/reports/weekly';
      transport.respond(
        _answer({
          'items': [item],
          'next_cursor': '',
        }),
      );
      transport.hold();
      transport.respond(_answer({'items': [], 'next_cursor': ''}));
      transport.respond(_answer({'total': 0}));

      await tester.pumpWidget(
        _screenApp(controller: controller, webView: webView, opener: opener),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Laporan siap'));
      await tester.pump();

      expect(transport.requests.map((request) => request.path), [
        '/api/v1/notifications?page_size=20&unread=false',
        '/api/v1/notifications/open',
      ]);
      expect(webView.opened, isEmpty);

      transport.release(
        _answer({'company_id': 'comp_1', 'link': destination, 'item': item}),
      );
      await tester.pump();
      await tester.pump();

      expect(webView.opened.single.destination, Uri.parse(destination));
      expect(
        webView.opened.single.allowsNavigation(
          Uri.parse('https://accounts.portalnesia.com/authorize'),
        ),
        isTrue,
      );
      expect(
        webView.opened.single.allowsNavigation(
          Uri.parse('https://attacker.example/steal'),
        ),
        isFalse,
      );
      expect(opener.opened, isEmpty);
    });

    testWidgets('shows an announcement and safe CTA when open has no link', (
      tester,
    ) async {
      final item = _itemJson(
        buttons: [
          {
            'label': 'Lihat laporan',
            'link': 'https://erp.perusahaan.com/reports/weekly',
            'style': 'primary',
          },
        ],
      );
      transport.respond(
        _answer({
          'items': [item],
          'next_cursor': '',
        }),
      );
      transport.respond(
        _answer({'company_id': 'comp_1', 'link': '', 'item': item}),
      );
      transport.respond(_answer({'items': [], 'next_cursor': ''}));
      transport.respond(_answer({'total': 0}));

      await tester.pumpWidget(
        _screenApp(controller: controller, webView: webView, opener: opener),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Laporan siap'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Laporan mingguan dapat dibuka.'), findsWidgets);
      expect(find.text('Lihat laporan'), findsOneWidget);
      expect(webView.opened, isEmpty);
      expect(transport.requests.map((request) => request.path).take(2), [
        '/api/v1/notifications?page_size=20&unread=false',
        '/api/v1/notifications/open',
      ]);

      await tester.tap(find.text('Lihat laporan'));
      await tester.pump();

      expect(
        webView.opened.single.destination,
        Uri.parse('https://erp.perusahaan.com/reports/weekly'),
      );
    });

    testWidgets('opens a push tap only after the server resolves it', (
      tester,
    ) async {
      webView.available = false;
      const destination = 'https://erp.perusahaan.com/reports/weekly';
      final item = _itemJson(
        id: 'recipient_42',
        notificationId: 'notification_42',
        link: destination,
      );
      transport.respond(_answer({'items': [], 'next_cursor': ''}));
      transport.respond(
        _answer({'company_id': 'comp_1', 'link': destination, 'item': item}),
      );
      transport.respond(_answer({'items': [], 'next_cursor': ''}));
      transport.respond(_answer({'total': 0}));

      await tester.pumpWidget(
        _screenApp(
          controller: controller,
          webView: webView,
          opener: opener,
          initialNotificationId: 'notification_42',
          initialCompanyId: 'comp_1',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(transport.requests.map((request) => request.path).take(2), [
        '/api/v1/notifications?page_size=20&unread=false',
        '/api/v1/notifications/open',
      ]);
      expect(jsonDecode(transport.requests[1].body!), {
        'notification_id': 'notification_42',
        'company_id': 'comp_1',
      });
      expect(webView.opened, hasLength(1));
      expect(webView.opened.single.destination, Uri.parse(destination));
      expect(opener.opened, [destination]);
    });

    testWidgets('does not open an untrusted server destination', (
      tester,
    ) async {
      final item = _itemJson();
      transport.respond(
        _answer({
          'items': [item],
          'next_cursor': '',
        }),
      );
      transport.respond(
        _answer({
          'company_id': 'comp_1',
          'link': 'https://attacker.example/steal',
          'item': item,
        }),
      );
      transport.respond(_answer({'items': [], 'next_cursor': ''}));
      transport.respond(_answer({'total': 0}));

      await tester.pumpWidget(
        _screenApp(controller: controller, webView: webView, opener: opener),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Laporan siap'));
      await tester.pump();
      await tester.pump();

      expect(webView.opened, isEmpty);
      expect(opener.opened, isEmpty);
      expect(
        find.text('Tautan notifikasi tidak aman atau tidak tersedia.'),
        findsOneWidget,
      );
    });

    testWidgets('uses the system browser if embedded WebView is unavailable', (
      tester,
    ) async {
      webView.available = false;
      final item = _itemJson();
      transport.respond(
        _answer({
          'items': [item],
          'next_cursor': '',
        }),
      );
      transport.respond(
        _answer({
          'company_id': 'comp_1',
          'link': 'https://erp.perusahaan.com/reports/weekly',
          'item': item,
        }),
      );
      transport.respond(_answer({'items': [], 'next_cursor': ''}));
      transport.respond(_answer({'total': 0}));

      await tester.pumpWidget(
        _screenApp(controller: controller, webView: webView, opener: opener),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Laporan siap'));
      await tester.pump();
      await tester.pump();

      expect(opener.opened, ['https://erp.perusahaan.com/reports/weekly']);
    });
  });
}
