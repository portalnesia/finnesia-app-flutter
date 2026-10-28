/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/notification.dart';
import 'package:pos/notifications/notification_inbox_controller.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/paged_loadable.dart';
import 'package:flutter_test/flutter_test.dart';

TransportResponse _jsonResponse(Object? data) => TransportResponse(
  status: 200,
  headers: const {'content-type': 'application/json'},
  body: jsonEncode({'data': data}),
);

Map<String, Object?> _itemJson({
  String id = 'recipient_1',
  String notificationId = 'notification_1',
  String? companyId = 'comp_1',
  String? link = '/reports/weekly',
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
  'buttons': <Object?>[],
  'read_at': null,
  'created_at': '2026-10-28T01:02:03Z',
};

NotificationItem _item({
  String id = 'recipient_1',
  String notificationId = 'notification_1',
  String? companyId = 'comp_1',
}) => NotificationItem.fromJson(
  _itemJson(id: id, notificationId: notificationId, companyId: companyId),
);

void main() {
  group('NotificationInboxController', () {
    late FakeApiTransport transport;
    late NotificationInboxController controller;

    setUp(() {
      transport = FakeApiTransport();
      controller = NotificationInboxController(
        client: ApiClient(transport: transport, language: () => 'id'),
      );
    });

    tearDown(() => controller.dispose());

    test(
      'loads typed items and unread count, then follows the server cursor',
      () async {
        transport.respond(
          _jsonResponse({
            'items': [_itemJson()],
            'next_cursor': 'cursor_2',
          }),
        );
        transport.respond(_jsonResponse({'total': 3}));

        await controller.loadInbox();
        await controller.loadUnreadCount();

        final inboxState = controller.inbox.state;
        final countState = controller.unreadCount.state;
        expect(inboxState, isA<Ready<PagedItems<NotificationItem>>>());
        expect(
          (inboxState as Ready<PagedItems<NotificationItem>>)
              .data
              .items
              .single
              .id,
          'recipient_1',
        );
        expect(countState, isA<Ready<int>>());
        expect((countState as Ready<int>).data, 3);

        transport.respond(
          _jsonResponse({
            'items': [_itemJson(id: 'recipient_2')],
            'next_cursor': '',
          }),
        );
        await controller.loadMore();

        expect(transport.requests[2].method, HttpMethod.get);
        expect(
          Uri.parse(transport.requests[2].path).queryParameters['cursor'],
          'cursor_2',
        );
        final paged =
            controller.inbox.state as Ready<PagedItems<NotificationItem>>;
        expect(paged.data.items.map((item) => item.id), [
          'recipient_1',
          'recipient_2',
        ]);
        expect(paged.data.hasMore, isFalse);
      },
    );

    test(
      'mark-read targets the recipient row and refreshes inbox and badge',
      () async {
        transport.respond(_jsonResponse({'updated': 1}));
        transport.respond(_jsonResponse({'items': [], 'next_cursor': ''}));
        transport.respond(_jsonResponse({'total': 0}));

        await controller.markRead(
          _item(id: 'recipient_9', notificationId: 'notification_42'),
        );

        final request = transport.requests.first;
        expect(request.method, HttpMethod.post);
        expect(request.path, '/api/v1/notifications/mark-read');
        expect(jsonDecode(request.body!), {
          'ids': ['recipient_9'],
          'all': false,
        });
        expect(
          transport.requests[1].path,
          startsWith('/api/v1/notifications?'),
        );
        expect(
          transport.requests[2].path,
          '/api/v1/notifications/unread-count',
        );
        expect((controller.unreadCount.state as Ready<int>).data, 0);
      },
    );

    test(
      'open targets notification id with company context and starts refresh',
      () async {
        transport.respond(
          _jsonResponse({
            'company_id': 'comp_1',
            'link': '/reports/weekly',
            'item': _itemJson(
              id: 'recipient_9',
              notificationId: 'notification_42',
            ),
          }),
        );
        transport.respond(_jsonResponse({'items': [], 'next_cursor': ''}));
        transport.respond(_jsonResponse({'total': 0}));

        final response = await controller.open(
          _item(id: 'recipient_9', notificationId: 'notification_42'),
        );
        await Future<void>.delayed(Duration.zero);

        expect(response.link, '/reports/weekly');
        final request = transport.requests.first;
        expect(request.method, HttpMethod.post);
        expect(request.path, '/api/v1/notifications/open');
        expect(jsonDecode(request.body!), {
          'notification_id': 'notification_42',
          'company_id': 'comp_1',
        });
        expect(
          transport.requests[1].path,
          startsWith('/api/v1/notifications?'),
        );
        expect(
          transport.requests[2].path,
          '/api/v1/notifications/unread-count',
        );
      },
    );

    test('global open sends a null company id', () async {
      transport.respond(
        _jsonResponse({
          'company_id': null,
          'link': '',
          'item': _itemJson(companyId: null),
        }),
      );
      transport.respond(_jsonResponse({'items': [], 'next_cursor': ''}));
      transport.respond(_jsonResponse({'total': 0}));

      await controller.open(_item(companyId: null));
      await Future<void>.delayed(Duration.zero);

      expect(jsonDecode(transport.requests.first.body!), {
        'notification_id': 'notification_1',
        'company_id': null,
      });
    });
  });
}
