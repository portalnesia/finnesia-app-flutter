/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/palette.dart';
import 'package:pn_ui/src/widgets/status_strip.dart';

import '../support/harness.dart';

// The bar at the top of the till: who is signed in, which outlet, which shift. It is one line of
// plain text with hairlines between, at a fixed height, so it never grows into the catalog.

StatusStripItem plain(String label) => (label: label, onTap: null);

final items = [
  plain('Budi'),
  plain('Outlet Mataram'),
  plain('Shift POS-0007'),
];

void main() {
  group('the status strip', () {
    testWidgets('shows every item, in order', (tester) async {
      await tester.pumpWidget(harness(StatusStrip(items: items)));

      final lefts = [
        for (final item in items) tester.getRect(find.text(item.label)).left,
      ];
      expect(lefts, [...lefts]..sort());
      expect(lefts.toSet(), hasLength(items.length));
    });

    testWidgets('puts a hairline between items, and none at the ends', (
      tester,
    ) async {
      await tester.pumpWidget(harness(StatusStrip(items: items)));

      expect(find.byType(VerticalDivider), findsNWidgets(items.length - 1));
    });

    testWidgets('keeps one height, whatever it holds', (tester) async {
      await tester.pumpWidget(harness(StatusStrip(items: items)));
      final few = tester.getSize(find.byType(StatusStrip)).height;
      await tester.pumpWidget(harness(StatusStrip(items: [plain('Budi')])));
      final one = tester.getSize(find.byType(StatusStrip)).height;

      expect(few, 40);
      expect(one, 40);
    });

    testWidgets('sits on the muted surface', (tester) async {
      await tester.pumpWidget(harness(StatusStrip(items: items)));

      final box = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(StatusStrip),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(box.color, PnPalette.light.surfaceMuted);
    });

    testWidgets('takes no room at all when there is nothing to say', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const StatusStrip(items: [])));

      expect(tester.getSize(find.byType(StatusStrip)).height, 0);
    });

    for (final width in checkedWidths) {
      for (final scale in checkedTextScales) {
        for (final brightness in Brightness.values) {
          testWidgets(
            'scrolls sideways rather than overflow at ${width.toInt()} dp, text ${scale}x, ${brightness.name}',
            (tester) async {
              await tester.useSize(width);
              await tester.pumpWidget(
                harness(
                  StatusStrip(
                    items: [
                      plain('Budi Santoso'),
                      plain('Outlet Mataram Selatan'),
                      plain('Shift POS-0007'),
                      plain('Dibuka 08.15'),
                      plain('Printer tersambung'),
                    ],
                  ),
                  brightness: brightness,
                  textScale: scale,
                ),
              );

              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });

  group('a tappable item', () {
    testWidgets('runs onTap when it is tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        harness(
          StatusStrip(
            items: [(label: 'N belum terkirim', onTap: () => taps++)],
          ),
        ),
      );

      await tester.tap(find.text('N belum terkirim'));

      expect(taps, 1);
    });

    testWidgets('an item with no onTap does not react to a tap', (
      tester,
    ) async {
      await tester.pumpWidget(harness(StatusStrip(items: [plain('Budi')])));

      // Must not throw: `InkWell(onTap: null)` is how "not tappable" is drawn, not the absence
      // of the wrapper — a bare `Text` and a disabled `InkWell` must both survive a tap attempt.
      await tester.tap(find.text('Budi'), warnIfMissed: false);

      expect(tester.takeException(), isNull);
    });
  });
}
