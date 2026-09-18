/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:pos/till/scan_buffer.dart';

// Written new: a scanner could be read through the search field's `Enter`, which needs the field
// focused. A scanner is a keyboard that types fast and finishes with Enter, so on a tablet the
// window can tell it from a person without a field: by how fast it types. The 50 ms gap is a
// guess from common practice, not a measurement (`plan/ui/findings.md` V5).

/// Types [text] one character at a time, [gap] apart, starting at [from]. Returns the time
/// after the last character.
Duration typeAll(ScanBuffer buffer, String text, Duration from, Duration gap) {
  var at = from;
  for (final char in text.split('')) {
    buffer.character(char, at);
    at += gap;
  }
  return at;
}

const fast = Duration(milliseconds: 8);
const slow = Duration(milliseconds: 250);

void main() {
  group('what a scanner does', () {
    test('types fast and finishes with Enter, and that is a code', () {
      final buffer = ScanBuffer();

      final end = typeAll(buffer, '8991234567890', Duration.zero, fast);

      expect(buffer.enter(end), '8991234567890');
    });

    test('two scans in a row are two codes', () {
      final buffer = ScanBuffer();

      var at = typeAll(buffer, '111111', Duration.zero, fast);
      expect(buffer.enter(at), '111111');
      at = typeAll(buffer, '222222', at + fast, fast);
      expect(buffer.enter(at), '222222');
    });

    test('a code that is not finished by Enter is not one', () {
      final buffer = ScanBuffer();

      final end = typeAll(buffer, '8991234567890', Duration.zero, fast);

      // The person came back and pressed Enter a second later: that is a person.
      expect(buffer.enter(end + const Duration(seconds: 1)), isNull);
    });
  });

  group('what a person does', () {
    test('typing at a human pace is never a code', () {
      final buffer = ScanBuffer();

      final end = typeAll(buffer, '8991234567890', Duration.zero, slow);

      expect(buffer.enter(end), isNull);
    });

    test('a slow hand before a fast burst does not join the code', () {
      final buffer = ScanBuffer();
      buffer.character('a', Duration.zero);

      final end = typeAll(buffer, '123456', slow, fast);

      expect(buffer.enter(end), '123456');
    });

    test('Enter with nothing typed is nothing', () {
      expect(ScanBuffer().enter(Duration.zero), isNull);
    });

    test('a few quick keystrokes are not a code', () {
      final buffer = ScanBuffer();

      final end = typeAll(buffer, '12', Duration.zero, fast);

      // Too short to be a barcode: someone typing quickly and pressing Enter.
      expect(buffer.enter(end), isNull);
    });
  });

  group('starting over', () {
    test('Enter empties the buffer, so it cannot be read twice', () {
      final buffer = ScanBuffer();
      final end = typeAll(buffer, '123456', Duration.zero, fast);
      buffer.enter(end);

      expect(buffer.enter(end + fast), isNull);
    });

    test('can be emptied on purpose', () {
      final buffer = ScanBuffer();
      final end = typeAll(buffer, '123456', Duration.zero, fast);

      buffer.clear();

      expect(buffer.enter(end), isNull);
    });
  });
}
