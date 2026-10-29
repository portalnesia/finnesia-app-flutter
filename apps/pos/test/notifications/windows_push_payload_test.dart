/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/notifications/windows_push_payload.dart';

void main() {
  group('Windows WNS launch arguments', () {
    test('keeps only the IDs needed to load the inbox item', () {
      final message = parseWindowsPushLaunchArguments(
        '{"notification_id":"  n_42  ","company_id":" c_1 ",'
        '"type":"sale.created","link":"https://evil.example"}',
      );

      expect(message, isNotNull);
      expect(message!.data, {'notification_id': 'n_42', 'company_id': 'c_1'});
    });

    test('ignores an absent or blank notification id', () {
      expect(parseWindowsPushLaunchArguments('{"company_id":"c_1"}'), isNull);
      expect(
        parseWindowsPushLaunchArguments('{"notification_id":"  "}'),
        isNull,
      );
      expect(parseWindowsPushLaunchArguments('{"notification_id":42}'), isNull);
    });

    test('does not fail on malformed or non-object activation data', () {
      expect(parseWindowsPushLaunchArguments(null), isNull);
      expect(parseWindowsPushLaunchArguments(''), isNull);
      expect(parseWindowsPushLaunchArguments('not-json'), isNull);
      expect(parseWindowsPushLaunchArguments('[]'), isNull);
      expect(parseWindowsPushLaunchArguments('"notification"'), isNull);
    });

    test('ignores a non-string company id', () {
      final message = parseWindowsPushLaunchArguments(
        '{"notification_id":"n_42","company_id":7}',
      );

      expect(message?.data, {'notification_id': 'n_42'});
    });
  });
}
