/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import '../endpoint.dart';
import '../http_method.dart';
import '../parsers.dart';
import '../../notification.dart';

/// Notification inbox routes. List uses an object page because the server returns
/// both `items` and `next_cursor` in the same `data` object.
abstract final class NotificationApi {
  static final list = ReadEndpoint<NotificationListResponse>(
    '/api/v1/notifications',
    parseObject(NotificationListResponse.fromJson),
  );

  static final unreadCount = ReadEndpoint<NotificationUnreadCountResponse>(
    '/api/v1/notifications/unread-count',
    parseObject(NotificationUnreadCountResponse.fromJson),
  );

  static final markRead =
      WriteEndpoint<NotificationMarkReadRequest, NotificationMarkReadResponse>(
        HttpMethod.post,
        '/api/v1/notifications/mark-read',
        parseObject(NotificationMarkReadResponse.fromJson),
        (request) => request.toJson(),
      );

  static final open =
      WriteEndpoint<NotificationOpenRequest, NotificationOpenResponse>(
        HttpMethod.post,
        '/api/v1/notifications/open',
        parseObject(NotificationOpenResponse.fromJson),
        (request) => request.toJson(),
      );
}
