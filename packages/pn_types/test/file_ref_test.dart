/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/file_ref.dart';
import 'package:test/test.dart';

// Inputs are wire JSON run through `jsonDecode`, as the API delivers them.
FileRef parse(String json) =>
    FileRef.fromJson(jsonDecode(json) as Map<String, dynamic>);

void main() {
  group('FileRef.fromJson', () {
    test('reads the fields the POS renders from', () {
      final f = parse(
        '{"id":"file_1","name":"logo.png","status":"attached",'
        '"url":"https://cdn.example/logo.png","size_bytes":1234,'
        '"content_type":"image/png","created_at":"2026-01-01T00:00:00Z"}',
      );

      expect(f.id, 'file_1');
      expect(f.name, 'logo.png');
      expect(f.status, 'attached');
      expect(f.url, 'https://cdn.example/logo.png');
    });

    test('leaves the file name null when the API omits it', () {
      expect(
        parse('{"id":"f","status":"attached","url":"https://u"}').name,
        isNull,
      );
    });

    test('defaults id, status and url when the API omits them', () {
      final f = parse('{}');

      expect(f.id, isEmpty);
      expect(f.status, isEmpty);
      expect(f.url, isEmpty);
    });

    // The whole reason for the per-field casts: `pairing.dart` catches a `TypeError` from
    // `PosBranding.fromJson` and calls the whole activation unavailable, so one field of the
    // wrong type must not cost a cashier their pairing.
    test('does not throw on a url that is not a string', () {
      expect(parse('{"url":7}').url, isEmpty);
    });

    test('does not throw on a null status', () {
      expect(parse('{"status":null,"url":"https://u"}').status, isEmpty);
    });

    test('does not throw on an id that is not a string', () {
      expect(parse('{"id":{"nested":true}}').id, isEmpty);
    });

    test('reads a name of the wrong type as null rather than throwing', () {
      expect(parse('{"name":7}').name, isNull);
    });

    test('a wrongly typed url is not renderable, not a crash', () {
      expect(parse('{"status":"attached","url":7}').renderableUrl, isNull);
    });
  });

  group('FileRef.renderableUrl', () {
    test('is the url when the file is attached and the url is filled', () {
      expect(
        parse(
          '{"status":"attached","url":"https://cdn.example/a.png"}',
        ).renderableUrl,
        'https://cdn.example/a.png',
      );
    });

    test('is null for a status that is not attached', () {
      for (final s in ['pending', 'detached', 'deleting', '', 'archived']) {
        expect(
          parse(
            '{"status":"$s","url":"https://cdn.example/a.png"}',
          ).renderableUrl,
          isNull,
          reason: 'status "$s" must not render',
        );
      }
    });

    test('is null when the status is attached but the url is empty', () {
      expect(parse('{"status":"attached","url":""}').renderableUrl, isNull);
      expect(parse('{"status":"attached"}').renderableUrl, isNull);
    });

    // Built directly, not through JSON: the decision lives in the getter, not in the parser.
    test('is null when there is no status at all', () {
      expect(
        const FileRef(url: 'https://cdn.example/a.png').renderableUrl,
        isNull,
      );
    });
  });
}
