/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/store_fake.dart';
import 'package:pos/printer/printer_service.dart';

void main() {
  group('printer format settings', () {
    test('uses legacy-safe defaults when no settings exist', () async {
      expect(
        await readPrinterFormatSettings(FakeStorePort()),
        defaultPrinterFormatSettings,
      );
    });

    test('saves and reads columns and the auto-cutter option', () async {
      final store = FakeStorePort();
      const settings = (columns: 48, autoCutter: true);

      await savePrinterFormatSettings(settings, store);

      expect(jsonDecode(store.values[printerFormatSettingsKey]!), {
        'columns': 48,
        'autoCutter': true,
      });
      expect(await readPrinterFormatSettings(store), settings);
    });

    test(
      'falls back safely for malformed or unsupported stored values',
      () async {
        for (final raw in ['not json', '[]']) {
          expect(
            await readPrinterFormatSettings(
              FakeStorePort({printerFormatSettingsKey: raw}),
            ),
            defaultPrinterFormatSettings,
            reason: raw,
          );
        }
        expect(
          await readPrinterFormatSettings(
            FakeStorePort({
              printerFormatSettingsKey: '{"columns": 49, "autoCutter": true}',
            }),
          ),
          (columns: 32, autoCutter: true),
        );
        expect(
          await readPrinterFormatSettings(
            FakeStorePort({
              printerFormatSettingsKey: '{"columns": 48, "autoCutter": "true"}',
            }),
          ),
          (columns: 48, autoCutter: false),
        );
      },
    );

    test(
      'rejects a width that is not one of the supported paper profiles',
      () async {
        await expectLater(
          savePrinterFormatSettings((
            columns: 49,
            autoCutter: false,
          ), FakeStorePort()),
          throwsArgumentError,
        );
      },
    );
  });
}
