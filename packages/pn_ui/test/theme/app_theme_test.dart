/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/contrast.dart';
import 'package:pn_ui/src/theme/palette.dart';
import 'package:pn_ui/src/theme/tokens.dart';

// What these test is what a cashier meets, not that a constant equals itself: a button big
// enough to hit, the edge of an input that can be seen, figures that line up.

final themes = {
  Brightness.light: pnTheme(Brightness.light),
  Brightness.dark: pnTheme(Brightness.dark),
};

PnPalette paletteOf(Brightness b) =>
    b == Brightness.light ? PnPalette.light : PnPalette.dark;

void main() {
  for (final b in Brightness.values) {
    group('the ${b.name} theme', () {
      final theme = themes[b]!;
      final palette = paletteOf(b);

      test('has the brightness it was asked for', () {
        expect(theme.brightness, b);
        expect(theme.colorScheme.brightness, b);
      });

      test('carries the palette, for the tokens Material has no slot for', () {
        expect(theme.extension<PnColors>()!.palette, same(palette));
      });

      test('makes the amber the primary colour, with dark text on it', () {
        expect(theme.colorScheme.primary, palette.accent);
        expect(theme.colorScheme.onPrimary, palette.onAccent);
      });

      // Material asks for a second colour, and this is the brand's: the web app's purple, for a
      // state that is real but not yet in effect. Left unset it fell back to the neutral, so a
      // `SegmentedButton`'s selected segment was drawn in ink and the Shorebird update banner
      // put ink words on an ink bar.
      test('carries the second colour, in its own slot', () {
        final scheme = theme.colorScheme;

        expect(scheme.secondary, palette.secondary);
        expect(scheme.onSecondary, palette.onSecondary);
        expect(scheme.secondaryContainer, palette.secondaryContainer);
        expect(scheme.onSecondaryContainer, palette.onSecondaryContainer);
      });

      test('carries the amber as words, and as a panel', () {
        final scheme = theme.colorScheme;

        // `colorScheme.primary` stays the amber: it is what every Material **fill** takes, and a
        // button that takes money is amber. The words are `brandInk` instead, which
        // `textButtonTheme` sets (the full amber as text on the light page is 2.04:1).
        expect(scheme.primary, palette.accent);
        expect(scheme.primaryContainer, palette.primaryContainer);
        expect(scheme.onPrimaryContainer, palette.onPrimaryContainer);
      });

      // The three slots above are what a `SegmentedButton` and the update banners really read.
      // A test that only compares constants would pass on a scheme nobody paints with, so this
      // drives the widgets themselves.
      testWidgets('paints a selected segment in the second colour, not in ink',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Open')),
                    ButtonSegment(value: 1, label: Text('Closed')),
                  ],
                  selected: const {1},
                  onSelectionChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        final selected = tester.widget<Material>(
          find
              .ancestor(
                of: find.text('Closed'),
                matching: find.byType(Material),
              )
              .first,
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Closed'),
        );

        expect(selected.color, palette.secondaryContainer);
        expect(paragraph.text.style?.color, palette.onSecondaryContainer);
      });

      test(
          'draws the edge of an input in the outline colour, and focus in the focus colour',
          () {
        final decoration = theme.inputDecorationTheme;

        expect(
            (decoration.enabledBorder as OutlineInputBorder).borderSide.color,
            palette.outline);
        expect(
            (decoration.focusedBorder as OutlineInputBorder).borderSide.color,
            palette.focus);
      });

      test(
          'greys out a main button that cannot be pressed, and keeps its words legible',
          () {
        final style = theme.filledButtonTheme.style!;

        expect(style.backgroundColor!.resolve({WidgetState.disabled}),
            palette.surfaceMuted);
        expect(style.foregroundColor!.resolve({WidgetState.disabled}),
            palette.inkMuted);
        expect(style.backgroundColor!.resolve({}), palette.accent);
        expect(style.foregroundColor!.resolve({}), palette.onAccent);
      });

      test('draws a text button in a colour that can be read where it stands',
          () {
        // `TextButton` takes its words from `colorScheme.primary`, which is the amber. The amber
        // is a **surface** colour: as words on the light page it is 2.04:1. The web app keeps a
        // second, darker amber for text (`--brand-ink`), and this is that token.
        final style = theme.textButtonTheme.style!;
        final words = style.foregroundColor!.resolve({})!;

        expect(words, palette.brandInk);
        expect(contrastRatio(words, palette.background),
            greaterThanOrEqualTo(4.5));
        expect(
            contrastRatio(words, palette.surface), greaterThanOrEqualTo(4.5));
      });

      test(
          'greys out a text button that cannot be pressed, and keeps its words legible',
          () {
        final style = theme.textButtonTheme.style!;

        expect(style.foregroundColor!.resolve({WidgetState.disabled}),
            palette.inkMuted);
      });

      test('shows keyboard focus on a button in the focus colour', () {
        final side = theme.filledButtonTheme.style!.side!
            .resolve({WidgetState.focused})!;

        expect(side.color, palette.focus);
        expect(side.width, greaterThanOrEqualTo(2));
        // Outside the edge: on the amber fill an inside ring would sit on amber, and the
        // ring is only worth drawing where it lands on the page behind the button.
        expect(side.strokeAlign, BorderSide.strokeAlignOutside);
      });

      test(
          'sets every figure in tabular width, so a total does not jitter as it changes',
          () {
        final styles = [
          theme.textTheme.displayLarge,
          theme.textTheme.headlineMedium,
          theme.textTheme.titleMedium,
          theme.textTheme.bodyLarge,
          theme.textTheme.bodyMedium,
          theme.textTheme.labelLarge,
        ];

        for (final style in styles) {
          expect(style!.fontFeatures,
              contains(const FontFeature.tabularFigures()));
        }
      });

      test(
          'gives a card and a dialog one radius and a button a smaller one, and neither is a pill',
          () {
        final card = (theme.cardTheme.shape as RoundedRectangleBorder)
            .borderRadius as BorderRadius;
        final dialog = (theme.dialogTheme.shape as RoundedRectangleBorder)
            .borderRadius as BorderRadius;
        final button = (theme.filledButtonTheme.style!.shape!.resolve({})
                as RoundedRectangleBorder)
            .borderRadius as BorderRadius;

        expect(card.topLeft.x, PnRadius.surface);
        expect(dialog.topLeft.x, PnRadius.surface);
        expect(button.topLeft.x, PnRadius.control);
        expect(PnRadius.control, lessThan(PnRadius.surface));
        // A pill is a radius of half the height or more; the biggest control is 56 tall.
        expect(PnRadius.surface, lessThan(PnTouch.primary / 2));
      });
    });
  }

  group('the amber', () {
    // The web app splits the amber (owner decision 2026-09-29, replacing K5): the fill is 50% on
    // the light page and 52% on the dark one, and the words are darker still where they have to
    // be (`--brand-ink`). One amber, three jobs.
    test('is a fill in one value per theme, and words in another', () {
      expect(
        themes[Brightness.light]!.colorScheme.primary,
        PnPalette.light.accent,
      );
      expect(
        themes[Brightness.dark]!.colorScheme.primary,
        PnPalette.dark.accent,
      );
      expect(PnPalette.light.brandInk, isNot(PnPalette.light.accent));
      expect(PnPalette.dark.brandInk, PnPalette.dark.accent);
    });
  });

  group('context.pn', () {
    testWidgets('reads the palette of the theme in scope', (tester) async {
      late PnPalette seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: themes[Brightness.dark],
          home: Builder(builder: (context) {
            seen = context.pn;
            return const SizedBox();
          }),
        ),
      );

      expect(seen, same(PnPalette.dark));
    });

    testWidgets('says what is wrong when the app theme was not applied',
        (tester) async {
      Object? failure;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            try {
              context.pn;
            } on Object catch (e) {
              failure = e;
            }
            return const SizedBox();
          }),
        ),
      );

      expect(failure, isA<StateError>());
      expect(failure.toString(), contains('pnTheme'));
    });
  });

  group('a button in the theme', () {
    Future<Size> sizeOf(
        WidgetTester tester, Widget button, Brightness b) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: themes[b],
          home: Scaffold(body: Center(child: button)),
        ),
      );
      return tester.getSize(find.byType(button.runtimeType));
    }

    testWidgets('is at least 56 tall when it is the main action',
        (tester) async {
      final size = await sizeOf(
          tester,
          FilledButton(onPressed: () {}, child: const Text('A')),
          Brightness.light);

      expect(size.height, greaterThanOrEqualTo(PnTouch.primary));
    });

    testWidgets('is at least 48 tall for every other button', (tester) async {
      for (final button in <Widget>[
        OutlinedButton(onPressed: () {}, child: const Text('A')),
        TextButton(onPressed: () {}, child: const Text('A')),
      ]) {
        final size = await sizeOf(tester, button, Brightness.dark);

        expect(size.height, greaterThanOrEqualTo(PnTouch.min),
            reason: button.runtimeType.toString());
      }
    });

    testWidgets(
        'keeps its tap target padded out to the minimum even when it is small',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: themes[Brightness.light],
          home: Scaffold(
              body: Center(
                  child: IconButton(
                      onPressed: () {}, icon: const Icon(Icons.close)))),
        ),
      );

      expect(tester.getSize(find.byType(IconButton)).shortestSide,
          greaterThanOrEqualTo(PnTouch.min));
    });

    // An `AlertDialog` is as wide as its text on one line, up to the screen. A sentence of
    // explanation under "Sign out" made it span most of a 1280 dp tablet.
    //
    // Measured on the dialog's own `Material`, not on `find.byType(AlertDialog)`: that widget's
    // render box is the padding around the dialog, which is always the whole screen.
    Future<double> dialogWidth(WidgetTester tester, ThemeData theme) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Keluar?'),
                  content: Text('Anda harus masuk lagi. ' * 20),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final box = find
          .descendant(
              of: find.byType(AlertDialog), matching: find.byType(Material))
          .first;
      return tester.getSize(box).width;
    }

    // In the dark theme the default barrier (black at 54%) over a near-black page left the page
    // barely darker than it was, so a dialog did not stand out from what it covered.
    for (final b in Brightness.values) {
      testWidgets(
          'dims the ${b.name} page behind a dialog enough to set the dialog apart',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: themes[b],
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(title: Text('Keluar?')),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final barrier =
            tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color!;
        final dimmedPage = Color.alphaBlend(barrier, paletteOf(b).background);

        expect(contrastRatio(dimmedPage, paletteOf(b).surface),
            greaterThanOrEqualTo(1.25));
      });
    }

    testWidgets(
        'keeps a confirm dialog narrow on a tablet, however long its text',
        (tester) async {
      expect(await dialogWidth(tester, themes[Brightness.light]!),
          lessThanOrEqualTo(560));
    });

    testWidgets(
        'is measured in a way that can tell a wide dialog from a narrow one',
        (tester) async {
      // Without this, "narrow" above would also be what a broken measurement reports. A plain
      // theme has no width limit, so the same dialog must come out wide.
      expect(await dialogWidth(tester, ThemeData()), greaterThan(560));
    });
  });
}
