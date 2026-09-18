/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/palette.dart';
import 'package:pn_ui/src/widgets/ledger_row.dart';

import '../support/harness.dart';

// The one motif of the app: a label on the left, an amount in tabular figures on the right, a
// hairline under. It is the cart, the payment, the shift summary, the close and the cash
// movements (`plan/ui/README.md` §3.3), so it is built once and tested here.

Widget rows(List<Widget> children) =>
    Column(mainAxisSize: MainAxisSize.min, children: children);

void main() {
  group('a ledger row', () {
    testWidgets('shows its label and its amount', (tester) async {
      await tester.pumpWidget(
        harness(const LedgerRow(label: 'Subtotal', value: 'Rp 50.000')),
      );

      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Rp 50.000'), findsOneWidget);
    });

    testWidgets('puts the label at the left and the amount at the right', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const LedgerRow(label: 'Subtotal', value: 'Rp 50.000')),
      );

      final row = tester.getRect(find.byType(LedgerRow));
      final label = tester.getRect(find.text('Subtotal'));
      final value = tester.getRect(find.text('Rp 50.000'));
      expect(label.left, lessThan(row.left + 24));
      expect(value.right, greaterThan(row.right - 24));
      expect(label.right, lessThan(value.left));
    });

    testWidgets('lines the amounts of stacked rows up at one right edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          rows(const [
            LedgerRow(label: 'Subtotal', value: 'Rp 50.000'),
            LedgerRow(label: 'Diskon', value: '- Rp 2.500'),
            LedgerRow(label: 'Total', value: 'Rp 1.047.500'),
          ]),
        ),
      );

      final edges = [
        for (final v in ['Rp 50.000', '- Rp 2.500', 'Rp 1.047.500'])
          tester.getRect(find.text(v)).right,
      ];
      expect(edges[1], closeTo(edges[0], 0.5));
      expect(edges[2], closeTo(edges[0], 0.5));
    });

    testWidgets('draws a hairline under itself, in the border colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const LedgerRow(label: 'Subtotal', value: 'Rp 50.000')),
      );

      final decorations = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(LedgerRow),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>();
      final bottoms = decorations.map((d) => d.border).whereType<Border>();
      expect(
          bottoms.any((b) => b.bottom.color == PnPalette.light.border), isTrue);
    });

    testWidgets('can carry a second line under the label, in the muted ink', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const LedgerRow(
            label: 'Kopi susu',
            detail: '2 × Rp 15.000',
            value: 'Rp 30.000',
          ),
        ),
      );

      final label = tester.getRect(find.text('Kopi susu'));
      final detail = tester.getRect(find.text('2 × Rp 15.000'));
      expect(detail.top, greaterThanOrEqualTo(label.bottom));
      final style = tester.widget<Text>(find.text('2 × Rp 15.000')).style!;
      expect(style.color, PnPalette.light.inkMuted);
    });

    testWidgets('is read as one thing: label, then amount', (tester) async {
      await tester.pumpWidget(
        harness(const LedgerRow(label: 'Subtotal', value: 'Rp 50.000')),
      );

      expect(
        find.bySemanticsLabel(RegExp(r'Subtotal\s+Rp 50\.000')),
        findsOneWidget,
      );
    });

    testWidgets('makes the emphasised row bigger and bolder', (tester) async {
      await tester.pumpWidget(
        harness(
          rows(const [
            LedgerRow(label: 'Subtotal', value: 'Rp 50.000'),
            LedgerRow(label: 'Total', value: 'Rp 50.000', emphasized: true),
          ]),
        ),
      );

      final plain = tester.widget<Text>(find.text('Subtotal')).style!;
      final total = tester.widget<Text>(find.text('Total')).style!;
      expect(total.fontSize!, greaterThan(plain.fontSize!));
      expect(total.fontWeight!.value, greaterThan(plain.fontWeight!.value));
    });

    for (final width in checkedWidths) {
      for (final scale in checkedTextScales) {
        for (final brightness in Brightness.values) {
          testWidgets(
            'keeps a long label from pushing the amount out at ${width.toInt()} dp, text ${scale}x, ${brightness.name}',
            (tester) async {
              await tester.useSize(width);
              await tester.pumpWidget(
                harness(
                  rows(const [
                    LedgerRow(
                      label:
                          'Nasi goreng spesial dengan telur mata sapi dan kerupuk udang besar',
                      detail: '12 × Rp 1.250.000',
                      value: 'Rp 15.000.000',
                    ),
                  ]),
                  brightness: brightness,
                  textScale: scale,
                ),
              );

              expect(tester.takeException(), isNull);
              expect(find.text('Rp 15.000.000'), findsOneWidget);
            },
          );
        }
      }
    }
  });
}
