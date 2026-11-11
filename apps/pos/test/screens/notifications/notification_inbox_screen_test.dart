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
import 'package:pn_types/src/native/opener_fake.dart';
import 'package:pn_types/src/native/push_messaging_fake.dart';
import 'package:pn_types/src/native/push_messaging_port.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/notifications/notification_inbox_controller.dart';
import 'package:pos/notifications/push_lifecycle_controller.dart';
import 'package:pos/screens/common/screen_header.dart';
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
  String? readAt,
  String? bodyHtml,
  String? subtitle,
  String? image,
  String? imageRatio,
  List<Object?> buttons = const [],
}) => {
  'id': id,
  'notification_id': notificationId,
  'type': 'announcement',
  'category': 'system',
  'title': 'Laporan siap',
  'body': 'Laporan mingguan dapat dibuka.',
  'subtitle': subtitle,
  'body_html': bodyHtml,
  'link': link,
  'ref': null,
  'company_id': companyId,
  'actor': null,
  'icon': null,
  'image': image,
  'image_ratio': imageRatio,
  'buttons': buttons,
  'read_at': readAt,
  'created_at': '2026-10-28T01:02:03Z',
};

Widget _screenApp({
  required NotificationInboxController controller,
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
    late FakeOpener opener;

    setUp(() {
      transport = FakeApiTransport();
      controller = NotificationInboxController(
        client: ApiClient(transport: transport, language: () => 'id'),
      );
      opener = FakeOpener();
    });

    tearDown(() => controller.dispose());

    testWidgets(
      'asks for push permission only after the inbox action is tapped',
      (tester) async {
        final pushTransport = FakeApiTransport();
        final messaging = FakePushMessaging()
          ..permissionResult = PushAuthorizationStatus.authorized;
        final pushStore = FakeStorePort(storedSession(paired));
        final sessionHolder = SessionHolder(pushStore);
        await sessionHolder.hydrate();
        final pushController = PushLifecycleController(
          client: ApiClient(transport: pushTransport, language: () => 'id'),
          messaging: messaging,
          session: sessionHolder,
          store: pushStore,
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
          'items': [
            _itemJson(subtitle: 'Laporan penjualan siap.'),
            _itemJson(id: 'recipient_fallback'),
          ],
          'next_cursor': '',
        }),
      );

      await tester.pumpWidget(
        _screenApp(controller: controller, opener: opener),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Kotak Masuk Notifikasi'), findsOneWidget);
      expect(find.text('Laporan siap'), findsNWidgets(2));
      expect(find.text('Laporan penjualan siap.'), findsOneWidget);
      expect(find.text('Laporan mingguan dapat dibuka.'), findsOneWidget);
      final headerBottom = tester.getBottomLeft(find.byType(ScreenHeader)).dy;
      final firstCardTop = tester.getTopLeft(find.byType(Card).first).dy;
      expect(firstCardTop - headerBottom, 16);
    });

    testWidgets('marks selected unread notifications in one batch', (
      tester,
    ) async {
      transport.respond(
        _answer({
          'items': [
            _itemJson(id: 'recipient_1'),
            _itemJson(id: 'recipient_2'),
            _itemJson(id: 'recipient_read', readAt: '2026-10-27T00:00:00Z'),
          ],
          'next_cursor': '',
        }),
      );
      transport.respond(_answer({'updated': 2}));
      transport.respond(_answer({'items': [], 'next_cursor': ''}));
      transport.respond(_answer({'total': 0}));

      await tester.pumpWidget(
        _screenApp(controller: controller, opener: opener),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pilih'));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('notification-select-recipient_1')),
      );
      await tester.tap(
        find.byKey(const Key('notification-select-recipient_2')),
      );
      await tester.pump();
      expect(find.text('2 dipilih'), findsOneWidget);
      await tester.tap(find.text('Tandai pilihan dibaca'));
      await tester.pumpAndSettle();
      expect(find.text('Tandai 2 notifikasi sebagai dibaca?'), findsOneWidget);
      expect(
        transport.requests.where(
          (request) => request.path == '/api/v1/notifications/mark-read',
        ),
        isEmpty,
      );
      await tester.tap(find.text('Tandai dibaca'));
      await tester.pumpAndSettle();

      final markRequest = transport.requests.singleWhere(
        (request) => request.path == '/api/v1/notifications/mark-read',
      );
      expect(jsonDecode(markRequest.body!), {
        'ids': ['recipient_1', 'recipient_2'],
        'all': false,
      });
    });

    testWidgets('select all selects each loaded unread notification', (
      tester,
    ) async {
      transport.respond(
        _answer({
          'items': [
            _itemJson(id: 'recipient_1'),
            _itemJson(id: 'recipient_2'),
            _itemJson(id: 'recipient_read', readAt: '2026-10-27T00:00:00Z'),
          ],
          'next_cursor': '',
        }),
      );

      await tester.pumpWidget(
        _screenApp(controller: controller, opener: opener),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pilih'));
      await tester.pump();
      await tester.tap(find.text('Pilih semua'));
      await tester.pump();

      expect(find.text('2 dipilih'), findsOneWidget);
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const Key('notification-select-recipient_1')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const Key('notification-select-recipient_2')),
            )
            .value,
        isTrue,
      );
      expect(
        find.byKey(const Key('notification-select-recipient_read')),
        findsNothing,
      );
    });

    testWidgets(
      'marks all notifications read with the global endpoint option',
      (tester) async {
        transport.respond(
          _answer({
            'items': [_itemJson(id: 'recipient_1')],
            'next_cursor': '',
          }),
        );
        transport.respond(_answer({'updated': 1}));
        transport.respond(_answer({'items': [], 'next_cursor': ''}));
        transport.respond(_answer({'total': 0}));

        await tester.pumpWidget(
          _screenApp(controller: controller, opener: opener),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tandai semua sudah dibaca'));
        await tester.pumpAndSettle();
        expect(
          find.text('Tandai SEMUA notifikasi sebagai sudah dibaca?'),
          findsOneWidget,
        );
        expect(
          transport.requests.where(
            (request) => request.path == '/api/v1/notifications/mark-read',
          ),
          isEmpty,
        );
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(
          transport.requests.where(
            (request) => request.path == '/api/v1/notifications/mark-read',
          ),
          isEmpty,
        );
        await tester.tap(find.text('Tandai semua sudah dibaca'));
        await tester.pumpAndSettle();
        expect(
          find.text('Tandai SEMUA notifikasi sebagai sudah dibaca?'),
          findsOneWidget,
        );
        expect(
          transport.requests.where(
            (request) => request.path == '/api/v1/notifications/mark-read',
          ),
          isEmpty,
        );
        await tester.tap(find.text('Tandai dibaca'));
        await tester.pumpAndSettle();

        final markRequest = transport.requests.singleWhere(
          (request) => request.path == '/api/v1/notifications/mark-read',
        );
        expect(jsonDecode(markRequest.body!), {'ids': <String>[], 'all': true});
      },
    );

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
        _screenApp(controller: controller, opener: opener),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Laporan siap'));
      await tester.pump();

      expect(transport.requests.map((request) => request.path), [
        '/api/v1/notifications?page_size=20&unread=false',
        '/api/v1/notifications/open',
      ]);
      expect(opener.opened, isEmpty);

      transport.release(
        _answer({'company_id': 'comp_1', 'link': destination, 'item': item}),
      );
      await tester.pump();
      await tester.pump();

      expect(opener.opened, [destination]);
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
        _screenApp(controller: controller, opener: opener),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Laporan siap'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Laporan mingguan dapat dibuka.'), findsWidgets);
      expect(find.text('Lihat laporan'), findsOneWidget);
      expect(opener.opened, isEmpty);
      expect(transport.requests.map((request) => request.path).take(2), [
        '/api/v1/notifications?page_size=20&unread=false',
        '/api/v1/notifications/open',
      ]);

      await tester.tap(find.text('Lihat laporan'));
      await tester.pump();

      expect(opener.opened, ['https://erp.perusahaan.com/reports/weekly']);
    });

    testWidgets(
      'renders rich notification HTML and opens a trusted body link',
      (tester) async {
        final item = _itemJson(
          bodyHtml:
              '<h2>Ringkasan</h2><p><strong>Penjualan naik</strong> '
              '<a href="https://erp.perusahaan.com/reports/weekly">Buka laporan</a></p>',
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
          _screenApp(controller: controller, opener: opener),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Laporan siap'));
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Penjualan naik'),
          ),
          findsOneWidget,
        );
        final link = find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Buka laporan'),
        );
        expect(link, findsOneWidget);
        await tester.tap(link);
        await tester.pump();

        expect(opener.opened, ['https://erp.perusahaan.com/reports/weekly']);
      },
    );

    // The detail dialog follows the web app (notification-detail-dialog.tsx): any link the
    // server sanitizer kept opens, protocol-relative and unsafe hrefs do nothing.
    Future<void> openAnnouncement(
      WidgetTester tester,
      Map<String, Object?> item,
    ) async {
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
        _screenApp(controller: controller, opener: opener),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laporan siap'));
      await tester.pumpAndSettle();
    }

    Finder richText(String text) => find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText().contains(text),
    );

    testWidgets(
      'opens an external body link like the web, not a protocol-relative one',
      (tester) async {
        await openAnnouncement(
          tester,
          _itemJson(
            bodyHtml:
                '<p><a href="//attacker.example/steal">Tautan ganda</a></p>'
                '<p><a href="https://finnesia.com/promo" target="_blank">Promo</a></p>',
          ),
        );

        await tester.tapOnText(find.textRange.ofSubstring('Tautan ganda'));
        await tester.pump();
        expect(opener.opened, isEmpty);

        await tester.tapOnText(find.textRange.ofSubstring('Promo'));
        await tester.pump();
        expect(opener.opened, ['https://finnesia.com/promo']);
        // An external link leaves the dialog open, as a new tab does on the web.
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets(
      'an in-app body link opens the paired origin and closes the dialog',
      (tester) async {
        await openAnnouncement(
          tester,
          _itemJson(
            bodyHtml: '<p><a href="/reports/weekly">Rekap mingguan</a></p>',
          ),
        );

        await tester.tapOnText(find.textRange.ofSubstring('Rekap mingguan'));
        await tester.pumpAndSettle();

        expect(opener.opened, ['https://erp.perusahaan.com/reports/weekly']);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('shows every CTA the web shows, styled by its variant', (
      tester,
    ) async {
      await openAnnouncement(
        tester,
        _itemJson(
          buttons: [
            {
              'label': 'Promo',
              'link': 'https://finnesia.com/promo',
              'style': 'primary',
            },
            {
              'label': 'Email',
              'link': 'mailto:cs@finnesia.com',
              'style': 'outline',
            },
            {'label': 'Bantuan', 'link': 'tel:+62811', 'style': 'ghost'},
            {
              'label': 'Laporan',
              'link': '/reports/weekly',
              'style': 'secondary',
            },
            {
              'label': 'Bahaya',
              'link': 'javascript:alert(1)',
              'style': 'primary',
            },
            {'label': '   ', 'link': '/kosong', 'style': 'primary'},
          ],
        ),
      );

      expect(find.widgetWithText(FilledButton, 'Promo'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Bantuan'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Laporan'), findsOneWidget);
      expect(find.text('Bahaya'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Tutup'), findsOneWidget);

      await tester.tap(find.text('Email'));
      await tester.pump();
      expect(opener.opened, ['mailto:cs@finnesia.com']);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();
      expect(opener.opened.last, 'https://erp.perusahaan.com/reports/weekly');
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('keeps soft line breaks and the web heading scale', (
      tester,
    ) async {
      await openAnnouncement(
        tester,
        _itemJson(bodyHtml: '<h1>Judul</h1>\n<p>Baris satu\nBaris dua</p>'),
      );

      expect(richText('Baris satu\nBaris dua'), findsOneWidget);
      double? headingSize;
      tester.widget<RichText>(richText('Judul')).text.visitChildren((span) {
        if (span is TextSpan && (span.text ?? '').contains('Judul')) {
          headingSize = span.style?.fontSize;
          return false;
        }
        return true;
      });
      expect(headingSize, 20);
    });

    testWidgets('shows the content image and opens it full screen', (
      tester,
    ) async {
      await openAnnouncement(
        tester,
        _itemJson(
          image: 'https://cdn.finnesia.com/promo.png',
          imageRatio: '4:3',
        ),
      );

      final image = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url ==
                'https://cdn.finnesia.com/promo.png',
      );
      expect(image, findsOneWidget);

      await tester.tap(image);
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('loads a server-relative image from the paired server', (
      tester,
    ) async {
      // The API signs announcement images as `/static/...`; the web page loads them from its
      // own origin, the till from the server it is paired with.
      await openAnnouncement(
        tester,
        _itemJson(
          image: '/static/announcement/a.png?signature=s&expired=1',
          imageRatio: '3:4',
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is NetworkImage &&
              (widget.image as NetworkImage).url == 'https://erp.perusahaan.com/static/announcement/a.png?signature=s&expired=1',
        ),
        findsOneWidget,
      );
    });

    testWidgets('opens a push tap only after the server resolves it', (
      tester,
    ) async {
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
        _screenApp(controller: controller, opener: opener),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Laporan siap'));
      await tester.pump();
      await tester.pump();

      expect(opener.opened, isEmpty);
      expect(
        find.text('Tautan notifikasi tidak aman atau tidak tersedia.'),
        findsOneWidget,
      );
    });

    testWidgets('opens a trusted notification link in the system browser', (
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
          'link': 'https://erp.perusahaan.com/reports/weekly',
          'item': item,
        }),
      );
      transport.respond(_answer({'items': [], 'next_cursor': ''}));
      transport.respond(_answer({'total': 0}));

      await tester.pumpWidget(
        _screenApp(controller: controller, opener: opener),
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
