/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/notification.dart';
import 'package:pn_types/src/api/page.dart';
import 'package:pn_types/src/notification.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/paged_loadable.dart';

/// Inbox data and mutations for the menu badge and notification list.
///
/// Opening is deliberately server-first: [open] does not return a destination until the API has
/// authorized and resolved it. Only then may the screen validate the URL and navigate. The
/// server's open endpoint marks the recipient read; the separate [markRead] action is for rows a
/// cashier wants to clear without opening.
class NotificationInboxController {
  NotificationInboxController({required this.client}) {
    inbox = PagedLoadable<NotificationItem>(_readPage);
    unreadCount = Loadable<int>(_readUnreadCount);
  }

  static const pageSize = 20;

  final ApiClient client;
  late final PagedLoadable<NotificationItem> inbox;
  late final Loadable<int> unreadCount;

  Future<CursorPage<NotificationItem>> _readPage(String? cursor) async {
    final response = await NotificationApi.list.call(
      client,
      query: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'page_size': pageSize,
        'unread': false,
      },
    );
    return CursorPage(
      items: response.items,
      nextCursor: response.nextCursor.isEmpty ? null : response.nextCursor,
    );
  }

  Future<int> _readUnreadCount() async =>
      (await NotificationApi.unreadCount.call(client)).total;

  Future<void> loadInbox() => inbox.load();

  Future<void> loadMore() => inbox.loadMore();

  Future<void> loadUnreadCount() => unreadCount.load();

  /// Marks this recipient row read and refreshes the list and menu count.
  Future<void> markRead(NotificationItem item) async {
    await NotificationApi.markRead.call(
      client,
      NotificationMarkReadRequest(ids: [item.id]),
    );
    await _refresh();
  }

  /// Requests the server-resolved open destination before the caller navigates.
  ///
  /// The API's open route also marks the row read. Its refreshed unread count and inbox are
  /// requested in the background so they do not delay the navigation that follows the response.
  Future<NotificationOpenResponse> open(NotificationItem item) async {
    return openById(item.notificationId, companyId: item.companyId);
  }

  /// Opens a notification delivered by FCM without trusting its `link` field.
  Future<NotificationOpenResponse> openById(
    String notificationId, {
    String? companyId,
  }) async {
    final response = await NotificationApi.open.call(
      client,
      NotificationOpenRequest(
        notificationId: notificationId,
        companyId: companyId,
      ),
    );
    unawaited(_refresh());
    return response;
  }

  Future<void> _refresh() => Future.wait([loadInbox(), loadUnreadCount()]);

  void dispose() {
    inbox.dispose();
    unreadCount.dispose();
  }
}
