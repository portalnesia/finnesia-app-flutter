/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_types/src/native/public_http_fake.dart';
import 'package:pos/app/pos_app.dart';
import 'package:pos/branding/company_avatar.dart';
import 'package:pos/http/inspector/request_inspector.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/menu/inspector_screen.dart';

import '../../support/boot_rig.dart';

// The debug screen (README §14). What is on it was redacted when it was recorded
// (`inspector_interceptor_test.dart`); what is tested here is what it shows of that, and that
// the cashier can see it, expand a row, and clear it.

final l10n = lookupL10n(const Locale('id'));

final signedIn = paired.copyWith(
  user: const SessionUser(id: 'u1', name: 'Budi'),
);

InspectedRequest entry(
  String url, {
  String method = 'GET',
  int? statusCode = 200,
  String? error,
  Map<String, String> requestHeaders = const {},
  Object? responseBody,
  int minute = 0,
}) => InspectedRequest(
  method: method,
  url: url,
  requestHeaders: requestHeaders,
  requestBody: null,
  at: DateTime.utc(2026, 9, 21, 9, minute),
  statusCode: statusCode,
  responseBody: responseBody,
  duration: const Duration(milliseconds: 120),
  error: error,
);

Future<void> pumpInspector(
  WidgetTester tester,
  RequestInspector inspector, {
  Size size = const Size(1280, 800),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final rig = Rig(storedSession(signedIn));
  await rig.theme.select(theme);
  await tester.pumpWidget(
    PosApp(
      boot: () => rig.bootWith(http: FakePublicHttp()),
      language: rig.language,
      theme: rig.theme,
      screens: (
        pairing: (_) => const Text('pairing'),
        login: (_) => const Text('login'),
        till: (_) => InspectorScreen(inspector: inspector),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the request inspector screen', () {
    testWidgets('says so when nothing has been recorded', (tester) async {
      await pumpInspector(tester, RequestInspector());

      expect(find.text(l10n.inspectorEmpty), findsOneWidget);
    });

    testWidgets('lists what was recorded, the latest first', (tester) async {
      final inspector = RequestInspector()
        ..record(entry('https://t.example/api/v1/older', minute: 1))
        ..record(entry('https://t.example/api/v1/newer', minute: 2));

      await pumpInspector(tester, inspector);

      final older = tester.getTopLeft(find.textContaining('/api/v1/older')).dy;
      final newer = tester.getTopLeft(find.textContaining('/api/v1/newer')).dy;
      expect(newer, lessThan(older));
    });

    testWidgets('names the method and the status of each request', (
      tester,
    ) async {
      final inspector = RequestInspector()
        ..record(
          entry(
            'https://t.example/api/v1/sales',
            method: 'POST',
            statusCode: 422,
          ),
        );

      await pumpInspector(tester, inspector);

      expect(find.textContaining('POST'), findsOneWidget);
      expect(find.textContaining('422'), findsOneWidget);
    });

    testWidgets('a request that got no answer shows why, not a status', (
      tester,
    ) async {
      final inspector = RequestInspector()
        ..record(
          entry(
            'https://t.example/api/v1/sales',
            statusCode: null,
            error: 'connectionTimeout',
          ),
        );

      await pumpInspector(tester, inspector);

      expect(find.textContaining('connectionTimeout'), findsOneWidget);
    });

    testWidgets('expanding a request shows its headers as they were recorded', (
      tester,
    ) async {
      final inspector = RequestInspector()
        ..record(
          entry(
            'https://t.example/api/v1/sales',
            requestHeaders: {'Authorization': 'Bearer ***'},
            responseBody: {'data': 'ok'},
          ),
        );
      await pumpInspector(tester, inspector);
      expect(find.textContaining('Bearer ***'), findsNothing);

      await tester.tap(find.textContaining('/api/v1/sales'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bearer ***'), findsOneWidget);
      expect(find.textContaining('"data": "ok"'), findsOneWidget);
    });

    testWidgets('clearing empties the list and the inspector', (tester) async {
      final inspector = RequestInspector()
        ..record(entry('https://t.example/api/v1/sales'));
      await pumpInspector(tester, inspector);

      await tester.tap(find.byTooltip(l10n.inspectorClear));
      await tester.pumpAndSettle();

      expect(find.text(l10n.inspectorEmpty), findsOneWidget);
      expect(inspector.entries, isEmpty);
    });

    // The avatar went into the header's trailing slot, which already had two buttons in it.
    // Wrapping rather than replacing is the whole point: a cashier who loses Refresh because a
    // logo was added has to debug the app, not the screen.
    testWidgets('keeps both actions beside the company avatar', (tester) async {
      await pumpInspector(tester, RequestInspector());

      expect(find.byType(CompanyAvatar), findsOneWidget);
      expect(find.byTooltip(l10n.inspectorRefresh), findsOneWidget);
      expect(find.byTooltip(l10n.inspectorClear), findsOneWidget);
    });

    testWidgets('refreshing shows what came in after it was opened', (
      tester,
    ) async {
      final inspector = RequestInspector();
      await pumpInspector(tester, inspector);

      inspector.record(entry('https://t.example/api/v1/later'));
      await tester.tap(find.byTooltip(l10n.inspectorRefresh));
      await tester.pumpAndSettle();

      expect(find.textContaining('/api/v1/later'), findsOneWidget);
    });

    testWidgets(
      'fits a phone-width screen with long addresses, text at 1.3x, dark',
      (tester) async {
        final inspector = RequestInspector()
          ..record(
            entry(
              'https://tenant-with-a-long-name.example.com/api/v1/pos/shifts/01J8ZZZZZZZZZZZZZZZZZZZZZZ/cash-movements?limit=50&cursor=abcdefghijklmnopqrstuvwxyz',
              statusCode: 500,
            ),
          );

        await pumpInspector(
          tester,
          inspector,
          size: const Size(360, 640),
          textScale: 1.3,
          theme: ThemeMode.dark,
        );

        expect(tester.takeException(), isNull);
      },
    );
  });
}
