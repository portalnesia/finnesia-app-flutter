/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import '../endpoint.dart';
import '../http_method.dart';
import '../parsers.dart';

/// The authenticated POS request the backend accepts to bind an FCM token to a session.
typedef PushTokenRegistrationRequest = ({
  String token,
  String platform,
  String app,
  String? deviceId,
  String locale,
});

/// The authenticated request that removes one FCM token from the current session.
typedef PushTokenUnregisterRequest = ({String token});

/// Push-token routes from the backend registry.
abstract final class PushTokenApi {
  static final register = WriteEndpoint<PushTokenRegistrationRequest, void>(
    HttpMethod.post,
    '/api/v1/push-tokens',
    parseNothing,
    (request) => {
      'token': request.token,
      'platform': request.platform,
      'app': request.app,
      if (request.deviceId != null) 'device_id': request.deviceId,
      'locale': request.locale,
    },
  );

  static final unregister = WriteEndpoint<PushTokenUnregisterRequest, void>(
    HttpMethod.post,
    '/api/v1/push-tokens/unregister',
    parseNothing,
    (request) => {'token': request.token},
  );
}
