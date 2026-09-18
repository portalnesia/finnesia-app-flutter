/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/api/environment.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/bootstrap.dart';

import '../support/boot_rig.dart';

void main() {
  group('AppScope', () {
    testWidgets('hands the services to the widgets below it', (tester) async {
      final services = await Rig().ready();
      AppServices? seen;

      await tester.pumpWidget(
        AppScope(
          services: services,
          child: Builder(
            builder: (context) {
              seen = AppScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(seen, same(services));
    });

    testWidgets('rebuilds what reads it when the services change', (
      tester,
    ) async {
      final services = await Rig().ready();
      var builds = 0;

      await tester.pumpWidget(
        AppScope(
          services: services,
          child: Builder(
            builder: (context) {
              AppScope.of(context);
              builds++;
              return const SizedBox();
            },
          ),
        ),
      );
      services.chooseEndpoint(EndpointEnvironment.production);
      await tester.pump();

      expect(builds, 2);
    });

    testWidgets('says what is missing when there is no scope above', (
      tester,
    ) async {
      Object? failure;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              AppScope.of(context);
            } on Object catch (e) {
              failure = e;
            }
            return const SizedBox();
          },
        ),
      );

      expect(failure, isA<StateError>());
      expect(failure.toString(), contains('AppScope'));
    });
  });
}
