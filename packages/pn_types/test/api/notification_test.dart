/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/notification.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/api/transport_fake.dart';
import 'package:pn_types/src/notification.dart';
import 'package:test/test.dart';

TransportResponse _jsonResponse(Object? data) => TransportResponse(
  status: 200,
  headers: const {'content-type': 'application/json'},
  body: jsonEncode({'data': data}),
);

({ApiClient client, FakeApiTransport transport}) _client(String language) {
  final transport = FakeApiTransport();
  return (
    client: ApiClient(transport: transport, language: () => language),
    transport: transport,
  );
}

Map<String, Object?> _itemJson({
  String id = 'recipient_1',
  String notificationId = 'notification_1',
  String? link = '/reports/weekly',
  Object? buttons = const <Object?>[],
  Object? readAt,
}) => {
  'id': id,
  'notification_id': notificationId,
  'type': 'announcement',
  'category': 'system',
  'title': 'Laporan siap',
  'body': 'Laporan mingguan dapat dibuka.',
  'link': link,
  'ref': null,
  'company_id': 'comp_1',
  'actor': null,
  'icon': null,
  'image': null,
  'image_ratio': null,
  'buttons': buttons,
  'read_at': readAt,
  'created_at': '2026-10-28T01:02:03Z',
};

void main() {
  group('notification models', () {
    test('keeps recipient id separate from notification id and parses CTA', () {
      final item = NotificationItem.fromJson(
        _itemJson(
          id: 'recipient_9',
          notificationId: 'notification_42',
          buttons: [
            {
              'label': 'Lihat laporan',
              'link': '/reports/weekly',
              'style': 'primary',
            },
          ],
          readAt: '2026-10-28T02:00:00Z',
        ),
      );

      expect(item.id, 'recipient_9');
      expect(item.notificationId, 'notification_42');
      expect(item.createdAt, DateTime.utc(2026, 10, 28, 1, 2, 3));
      expect(item.readAt, DateTime.utc(2026, 10, 28, 2));
      expect(item.buttons.single.label, 'Lihat laporan');
      expect(item.buttons.single.link, '/reports/weekly');
    });

    test('accepts a nil buttons slice and an empty cursor', () {
      final response = NotificationListResponse.fromJson({
        'items': [_itemJson(link: null, buttons: null)],
        'next_cursor': '',
      });

      expect(response.items.single.link, isNull);
      expect(response.items.single.buttons, isEmpty);
      expect(response.nextCursor, isEmpty);
    });
  });

  group('notification API', () {
    test(
      'lists an object-shaped cursor page with the server query names',
      () async {
        final t = _client('id');
        t.transport.respond(
          _jsonResponse({
            'items': [_itemJson()],
            'next_cursor': 'cursor_2',
          }),
        );

        final response = await NotificationApi.list.call(
          t.client,
          query: {'cursor': 'cursor_1', 'page_size': 20, 'unread': false},
        );

        expect(response.items.single.id, 'recipient_1');
        expect(response.nextCursor, 'cursor_2');
        final request = t.transport.requests.single;
        expect(request.method, HttpMethod.get);
        expect(Uri.parse(request.path).path, '/api/v1/notifications');
        expect(Uri.parse(request.path).queryParameters, {
          'cursor': 'cursor_1',
          'page_size': '20',
          'unread': 'false',
        });
      },
    );

    test('reads unread count from its response object', () async {
      final t = _client('en');
      t.transport.respond(_jsonResponse({'total': 7}));

      final response = await NotificationApi.unreadCount.call(t.client);

      expect(response.total, 7);
      expect(
        t.transport.requests.single.path,
        '/api/v1/notifications/unread-count',
      );
    });

    test(
      'marks the recipient row read, not the notification template id',
      () async {
        final t = _client('id');
        t.transport.respond(_jsonResponse({'updated': 1}));

        final response = await NotificationApi.markRead.call(
          t.client,
          const NotificationMarkReadRequest(ids: ['recipient_9']),
        );

        expect(response.updated, 1);
        final request = t.transport.requests.single;
        expect(request.method, HttpMethod.post);
        expect(request.path, '/api/v1/notifications/mark-read');
        expect(jsonDecode(request.body!), {
          'ids': ['recipient_9'],
          'all': false,
        });
      },
    );

    test('opens by notification id and supplies the company context', () async {
      final t = _client('id');
      t.transport.respond(
        _jsonResponse({
          'company_id': 'comp_1',
          'link': '/reports/weekly',
          'item': _itemJson(
            id: 'recipient_9',
            notificationId: 'notification_42',
          ),
        }),
      );

      final response = await NotificationApi.open.call(
        t.client,
        const NotificationOpenRequest(
          notificationId: 'notification_42',
          companyId: 'comp_1',
        ),
      );

      expect(response.item?.id, 'recipient_9');
      expect(response.item?.notificationId, 'notification_42');
      expect(response.link, '/reports/weekly');
      final request = t.transport.requests.single;
      expect(request.method, HttpMethod.post);
      expect(request.path, '/api/v1/notifications/open');
      expect(jsonDecode(request.body!), {
        'notification_id': 'notification_42',
        'company_id': 'comp_1',
      });
    });

    test('sends null company id for a global notification', () async {
      final t = _client('id');
      t.transport.respond(
        _jsonResponse({'company_id': null, 'link': '', 'item': _itemJson()}),
      );

      await NotificationApi.open.call(
        t.client,
        const NotificationOpenRequest(notificationId: 'notification_1'),
      );

      expect(jsonDecode(t.transport.requests.single.body!), {
        'notification_id': 'notification_1',
        'company_id': null,
      });
    });

    test('turns a malformed response into an API error', () async {
      final t = _client('id');
      t.transport.respond(_jsonResponse({'items': 'wrong', 'next_cursor': ''}));

      await expectLater(
        NotificationApi.list.call(t.client),
        throwsA(isA<ApiError>()),
      );
    });
  });
}
