/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_ui/src/layout/window_class.dart';

import '../support/harness.dart';

void main() {
  group('the window class of a width', () {
    test('is compact below 840', () {
      expect(windowClassOf(0), WindowClass.compact);
      expect(windowClassOf(360), WindowClass.compact);
      expect(windowClassOf(839.9), WindowClass.compact);
    });

    test('is regular from 840 up to, and not including, 1200', () {
      expect(windowClassOf(840), WindowClass.regular);
      expect(windowClassOf(1024), WindowClass.regular);
      expect(windowClassOf(1199.9), WindowClass.regular);
    });

    test('is wide from 1200', () {
      expect(windowClassOf(1200), WindowClass.wide);
      expect(windowClassOf(1920), WindowClass.wide);
    });
  });

  group('the window class of a screen', () {
    Future<WindowClass> seen(WidgetTester tester, double w, double h) async {
      await tester.useSize(w, h);
      late WindowClass found;
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (context) {
              found = context.windowClass;
              return const SizedBox();
            },
          ),
        ),
      );
      return found;
    }

    testWidgets('follows the width, so a tablet in portrait is compact', (
      tester,
    ) async {
      expect(await seen(tester, 800, 1280), WindowClass.compact);
    });

    testWidgets('does not follow the orientation: portrait can be regular', (
      tester,
    ) async {
      // A wide portrait window, as in split-screen or a fixed-size window, is not a phone.
      expect(await seen(tester, 900, 1300), WindowClass.regular);
    });

    testWidgets('is wide for a 10-inch tablet in landscape', (tester) async {
      expect(await seen(tester, 1280, 800), WindowClass.wide);
    });
  });
}
