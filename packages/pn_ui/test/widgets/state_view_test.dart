/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/state_view.dart';

import '../support/harness.dart';

// The three things a screen that reads data can be showing besides the data: it is still
// loading, there is nothing to show, or it could not be read. Every screen that reads the server
// draws them with this, and draws them before it draws the case where all went well (R-27).

void main() {
  group('loading', () {
    testWidgets('shows a progress indicator and says what is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
          harness(const StateView.loading(label: 'Memuat produk…')));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memuat produk…'), findsOneWidget);
    });
  });

  group('empty or failed', () {
    testWidgets('says what happened, and what to do about it', (tester) async {
      await tester.pumpWidget(
        harness(
          const StateView(
            title: 'Tidak ada produk',
            description: 'Coba kata kunci lain atau pilih kategori lain',
          ),
        ),
      );

      expect(find.text('Tidak ada produk'), findsOneWidget);
      expect(
        find.text('Coba kata kunci lain atau pilih kategori lain'),
        findsOneWidget,
      );
    });

    testWidgets('has no button unless there is something to do',
        (tester) async {
      await tester.pumpWidget(
        harness(const StateView(title: 'Keranjang kosong')),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('offers the action, and runs it when tapped', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        harness(
          StateView(
            title: 'Gagal memuat katalog',
            actionLabel: 'Coba lagi',
            onAction: () => retried++,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Coba lagi'));

      expect(retried, 1);
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(PnTouch.primary),
      );
    });

    testWidgets('is announced with its title as a heading', (tester) async {
      await tester.pumpWidget(
        harness(const StateView(title: 'Tidak ada produk')),
      );

      expect(
        tester.getSemantics(find.text('Tidak ada produk')),
        matchesSemantics(label: 'Tidak ada produk', isHeader: true),
      );
    });
  });

  group('all three', () {
    for (final width in checkedWidths) {
      for (final scale in checkedTextScales) {
        for (final brightness in Brightness.values) {
          testWidgets(
            'fit ${width.toInt()} dp wide and 320 tall at text ${scale}x, ${brightness.name}',
            (tester) async {
              await tester.useSize(width, 320);

              for (final view in <Widget>[
                const StateView.loading(label: 'Memuat produk…'),
                const StateView(
                  title: 'Tidak ada produk',
                  description:
                      'Coba kata kunci lain atau pilih kategori lain, atau periksa sambungan tablet ini.',
                ),
                StateView(
                  title: 'Gagal memuat katalog',
                  description: 'Periksa koneksi lalu coba lagi.',
                  actionLabel: 'Coba lagi',
                  onAction: () {},
                ),
              ]) {
                await tester.pumpWidget(
                  harness(view, brightness: brightness, textScale: scale),
                );

                expect(tester.takeException(), isNull);
              }
            },
          );
        }
      }
    }
  });
}
