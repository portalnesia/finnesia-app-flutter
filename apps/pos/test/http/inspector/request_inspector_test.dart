/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pos/http/inspector/request_inspector.dart';

InspectedRequest entry(int n) => InspectedRequest(
  method: 'GET',
  url: 'https://apps.finnesia.com/api/v1/x/$n',
  requestHeaders: const {},
  requestBody: null,
  at: DateTime(2026, 9, 19),
);

void main() {
  group('RequestInspector', () {
    test('keeps what it recorded, oldest first', () {
      final inspector = RequestInspector()
        ..record(entry(1))
        ..record(entry(2));

      expect(inspector.entries.map((e) => e.url), [
        'https://apps.finnesia.com/api/v1/x/1',
        'https://apps.finnesia.com/api/v1/x/2',
      ]);
    });

    test('keeps the last 50 by default', () {
      final inspector = RequestInspector();
      for (var i = 1; i <= 60; i++) {
        inspector.record(entry(i));
      }

      expect(inspector.entries, hasLength(50));
      expect(inspector.entries.first.url, endsWith('/11'));
      expect(inspector.entries.last.url, endsWith('/60'));
    });

    // The tablet runs for days: a buffer that grows without a limit uses up the memory before
    // anyone opens the screen.
    test('stops at maxEntries and drops the oldest', () {
      final inspector = RequestInspector(maxEntries: 3);
      for (var i = 1; i <= 5; i++) {
        inspector.record(entry(i));
      }

      expect(inspector.entries.map((e) => e.url.split('/').last), [
        '3',
        '4',
        '5',
      ]);
    });

    test('refuses a buffer that cannot hold anything', () {
      expect(() => RequestInspector(maxEntries: 0), throwsArgumentError);
      expect(() => RequestInspector(maxEntries: -1), throwsArgumentError);
    });

    test('clear empties it', () {
      final inspector = RequestInspector()
        ..record(entry(1))
        ..clear();

      expect(inspector.entries, isEmpty);
    });

    test('can be used again after it was cleared', () {
      final inspector = RequestInspector(maxEntries: 2)
        ..record(entry(1))
        ..clear()
        ..record(entry(2));

      expect(inspector.entries, hasLength(1));
    });

    test('hands out a list that cannot be changed', () {
      final inspector = RequestInspector()..record(entry(1));

      expect(() => inspector.entries.add(entry(2)), throwsUnsupportedError);
      expect(() => inspector.entries.clear(), throwsUnsupportedError);
    });

    test(
      'hands out a snapshot: a later record does not change an earlier read',
      () {
        final inspector = RequestInspector()..record(entry(1));
        final before = inspector.entries;

        inspector.record(entry(2));

        expect(before, hasLength(1));
      },
    );
  });
}
