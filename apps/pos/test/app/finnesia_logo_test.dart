/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/app/finnesia_logo.dart';

// One logo for both themes (owner decision K8): it was drawn to read on light and on dark, so
// there is no white variant and nothing here changes with the brightness.

Widget under(Brightness brightness, Widget child) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('is a PNG the app really ships', (tester) async {
    // Reads the bundle, so it fails if the asset is not declared in the pubspec or the file is
    // not where the widget says it is.
    final data = await tester.runAsync(
      () => rootBundle.load(finnesiaLogoAsset),
    );

    final bytes = data!.buffer.asUint8List();
    expect(bytes.sublist(1, 4), 'PNG'.codeUnits);
  });

  testWidgets('is named for a screen reader', (tester) async {
    await tester.pumpWidget(
      under(
        Brightness.light,
        const FinnesiaLogo(width: 240, semanticLabel: 'Finnesia POS'),
      ),
    );

    expect(find.bySemanticsLabel('Finnesia POS'), findsOneWidget);
  });

  testWidgets('is the same image in the light and in the dark theme', (
    tester,
  ) async {
    ImageProvider providerOf() =>
        tester.widget<Image>(find.byType(Image)).image;
    const logo = FinnesiaLogo(width: 240, semanticLabel: 'Finnesia POS');

    await tester.pumpWidget(under(Brightness.light, logo));
    final light = providerOf();
    await tester.pumpWidget(under(Brightness.dark, logo));
    final dark = providerOf();

    expect(dark, light);
  });

  testWidgets('keeps the proportions of the artwork at the width it is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      under(
        Brightness.light,
        const FinnesiaLogo(width: 240, semanticLabel: 'Finnesia POS'),
      ),
    );

    // 970 x 250: the file is wider than tall, and the widget must not stretch it into a box.
    final size = tester.getSize(find.byType(Image));
    expect(size.width, 240);
    expect(size.height, closeTo(240 * 250 / 970, 0.5));
  });
}
