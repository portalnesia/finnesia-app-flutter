/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/palette.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pn_ui/src/widgets/segmented_code_field.dart';

import '../support/harness.dart';

// A code drawn as separate cells, over ONE real text field. The cells are the look; the field
// is what a keyboard, a paste, an IME and a screen reader all talk to, so there is a single
// place where the text lives.

// What a screen would pass: capitals, no dashes or spaces, never over six.
String tidy(String raw, String previous) {
  final next = raw.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  return next.length > 6 ? previous : next;
}

class Host extends StatefulWidget {
  const Host(
      {super.key,
      this.initial = '',
      this.hasError = false,
      this.enabled = true});

  final String initial;
  final bool hasError;
  final bool enabled;

  @override
  State<Host> createState() => HostState();
}

class HostState extends State<Host> {
  late String value = widget.initial;

  /// A change that does not come from the field, as a screen would make.
  void change(String next) => setState(() => value = next);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SegmentedCodeField(
          length: 6,
          value: value,
          filter: tidy,
          onChanged: (v) => setState(() => value = v),
          label: 'Kode pairing',
          hasError: widget.hasError,
          enabled: widget.enabled,
        ),
      );
}

Finder get cells => find.byKey(const ValueKey('code-cell'));

BoxDecoration decorationOf(WidgetTester tester, int index) => tester
    .widget<DecoratedBox>(
      find.descendant(of: cells.at(index), matching: find.byType(DecoratedBox)),
    )
    .decoration as BoxDecoration;

void main() {
  group('the code field', () {
    testWidgets('draws one cell per character of the length', (tester) async {
      await tester.pumpWidget(harness(const Host()));

      expect(cells, findsNWidgets(6));
    });

    testWidgets('shows the characters in their cells, in order',
        (tester) async {
      await tester.pumpWidget(harness(const Host(initial: 'AB3')));

      final lefts = [
        for (final c in ['A', 'B', '3'])
          tester.getRect(find.widgetWithText(Container, c).first).left,
      ];
      expect(lefts, [...lefts]..sort());
      for (final c in ['A', 'B', '3']) {
        expect(
            find.descendant(of: cells, matching: find.text(c)), findsOneWidget);
      }
    });

    testWidgets('is one real text field, named for a screen reader', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const Host()));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.bySemanticsLabel('Kode pairing'), findsOneWidget);
    });

    testWidgets('gives the field what was typed, tidied, and shows it', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const Host()));

      await tester.enterText(find.byType(TextField), 'ab3-k7m');
      await tester.pump();

      expect(tester.state<HostState>(find.byType(Host)).value, 'AB3K7M');
      expect(
          find.descendant(of: cells, matching: find.text('K')), findsOneWidget);
    });

    testWidgets('refuses a character over the length, and keeps what was there',
        (
      tester,
    ) async {
      await tester.pumpWidget(harness(const Host(initial: 'AB3K7M')));

      await tester.enterText(find.byType(TextField), 'AB3K7MX');
      await tester.pump();

      expect(tester.state<HostState>(find.byType(Host)).value, 'AB3K7M');
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'AB3K7M');
    });

    testWidgets('follows the value when it is changed from outside', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const Host(initial: 'AB3')));

      tester.state<HostState>(find.byType(Host)).change('ZZZZZZ');
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'ZZZZZZ');
    });

    testWidgets('marks the cell that takes the next character while focused', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const Host(initial: 'AB')));
      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(decorationOf(tester, 2).border!.top.width, 2);
      expect(decorationOf(tester, 2).border!.top.color, PnPalette.light.focus);
      expect(decorationOf(tester, 0).border!.top.width, 1);
    });

    testWidgets('marks no cell while it does not have focus', (tester) async {
      await tester.pumpWidget(harness(const Host(initial: 'AB')));

      for (var i = 0; i < 6; i++) {
        expect(decorationOf(tester, i).border!.top.width, 1, reason: 'cell $i');
      }
    });

    testWidgets('draws the cells in the error colour when there is an error', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const Host(hasError: true)));

      expect(
          decorationOf(tester, 0).border!.top.color, PnPalette.light.errorText);
    });

    testWidgets('takes a tap on a cell as a tap on the field', (tester) async {
      await tester.pumpWidget(harness(const Host()));

      await tester.tap(cells.at(3), warnIfMissed: false);
      await tester.pump();

      expect(
        FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<TextField>() ??
            FocusManager.instance.primaryFocus?.context?.widget,
        isNotNull,
      );
      expect(
          tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
          isTrue);
    });

    testWidgets('reports the Done key of the keyboard', (tester) async {
      var submitted = 0;
      await tester.pumpWidget(
        harness(
          SegmentedCodeField(
            length: 6,
            value: 'AB3K7M',
            filter: tidy,
            onChanged: (_) {},
            onSubmitted: () => submitted++,
            label: 'Kode pairing',
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(submitted, 1);
    });

    testWidgets('does not take input while disabled', (tester) async {
      await tester.pumpWidget(harness(const Host(enabled: false)));

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('has cells big enough to hit, with room between them', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const Host()));

      final first = tester.getRect(cells.at(0));
      final second = tester.getRect(cells.at(1));
      expect(first.height, greaterThanOrEqualTo(PnTouch.primary));
      expect(second.left - first.right, greaterThanOrEqualTo(8));
    });

    for (final width in checkedWidths) {
      for (final scale in checkedTextScales) {
        for (final brightness in Brightness.values) {
          testWidgets(
            'fits ${width.toInt()} dp at text ${scale}x in the ${brightness.name} theme',
            (tester) async {
              await tester.useSize(width);
              await tester.pumpWidget(
                harness(const Host(initial: 'AB3K7M'),
                    brightness: brightness, textScale: scale),
              );

              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });
}
