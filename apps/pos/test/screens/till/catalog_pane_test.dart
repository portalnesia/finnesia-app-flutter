/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/file_ref.dart';
import 'package:pn_types/src/product.dart';
import 'package:pos/screens/till/catalog_pane.dart';

import '../../support/app_harness.dart';

// The catalogue tile. A cashier picks goods hundreds of times a shift, so what the tile does
// with a photo that is not there, with a photo that is wide, and with a long name at a large
// text size is what these tests are about: a tile that overflows puts a yellow stripe across
// the grid the cashier is reaching into.

const attached = FileRef(
  id: 'f1',
  name: 'teh.png',
  status: 'attached',
  url: 'https://cdn.example.com/teh.png',
);

/// The tile's own box: 156.8 wide at a five-column 816px catalogue, 240 tall.
const tile = Size(156.8, 240);

Product product({
  String name = 'Teh Botol Sosro 450ml',
  FileRef? image,
  num sellPrice = 15000,
}) => Product(
  id: 'p1',
  name: name,
  unitId: 'u1',
  sellPrice: sellPrice,
  image: image,
);

Future<void> pumpCard(
  WidgetTester tester,
  Product p, {
  double textScale = 1,
  Size size = tile,
}) async {
  await tester.pumpWidget(
    harness(
      Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: ProductCard(
            product: p,
            stockKnown: false,
            stock: null,
            onPick: (_) {},
          ),
        ),
      ),
      textScale: textScale,
    ),
  );
  await tester.pump();
}

Finder get photo => find.byWidgetPredicate(
  (widget) => widget is AspectRatio && widget.aspectRatio == 1,
  description: 'the square product photo',
);

void main() {
  group('ProductCard photo', () {
    testWidgets('is a square filling the tile width', (tester) async {
      await pumpCard(tester, product(image: attached));

      expect(photo, findsOneWidget);
      expect(tester.getSize(photo), const Size(136.8, 136.8));
    });

    // `cover`, not `contain`: a product photo of any ratio fills the box and loses its edges,
    // rather than shrinking the goods to a stamp in the middle of an empty tile.
    testWidgets('covers the square rather than fitting inside it', (
      tester,
    ) async {
      await pumpCard(tester, product(image: attached));

      expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
    });

    testWidgets('renders the file that is attached', (tester) async {
      await pumpCard(tester, product(image: attached));

      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<NetworkImage>().having(
          (image) => image.url,
          'url',
          'https://cdn.example.com/teh.png',
        ),
      );
    });

    // No photo at all: the icon, not an empty hole where the product should be.
    testWidgets('falls back to an icon when the product has no image', (
      tester,
    ) async {
      await pumpCard(tester, product());

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(photo, findsOneWidget);
    });

    // A file the API still holds in `detached` is not a photo yet, and fetching it would only
    // produce an error to catch.
    testWidgets('falls back to an icon when the image is not attached', (
      tester,
    ) async {
      await pumpCard(
        tester,
        product(
          image: const FileRef(
            id: 'f1',
            name: 'teh.png',
            status: 'detached',
            url: 'https://cdn.example.com/teh.png',
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('falls back to an icon when the image fails to load', (
      tester,
    ) async {
      await pumpCard(tester, product(image: attached));

      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
  });

  group('ProductCard fits its tile', () {
    // A name and a price that cannot both fit at 1.3 is the case the tile has to survive: a
    // cashier on a tablet with large system text is not an edge case.
    testWidgets('no overflow at text scale 1.3 with a long name', (
      tester,
    ) async {
      await pumpCard(
        tester,
        product(
          name: 'Teh Botol Sosro 450ml Kemasan C prevailing Isi 6 Botol',
          image: attached,
        ),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at text scale 1.3 without a photo', (
      tester,
    ) async {
      await pumpCard(
        tester,
        product(name: 'Teh Botol Sosro 450ml Kemasan prevailing Isi 6 Botol'),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });

    // A price long enough that it cannot fit at 1.0 either: it shrinks rather than overflows.
    testWidgets('no overflow with a very large price', (tester) async {
      await pumpCard(
        tester,
        product(name: 'Paket组件', image: attached, sellPrice: 123456789),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
