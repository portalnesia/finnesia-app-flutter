/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pn_types/src/native/preferences_fake.dart';
import 'package:pos/preferences/app_preferences.dart';

void main() {
  group('language preference', () {
    test('is Indonesian until the cashier picks another', () {
      final language = languagePreference(FakePreferences());

      expect(language.value, AppLanguage.id);
    });

    test('takes English from what was stored', () async {
      final language = languagePreference(FakePreferences({'language': 'en'}));

      await language.load();

      expect(language.value, AppLanguage.en);
    });

    test('is stored under its own key, apart from the theme', () async {
      final port = FakePreferences();
      final language = languagePreference(port);

      await language.select(AppLanguage.en);

      expect(port.values, {'language': 'en'});
    });

    test('names the locale the interface is built in', () {
      expect(AppLanguage.id.locale, const Locale('id'));
      expect(AppLanguage.en.locale, const Locale('en'));
    });
  });

  group('theme preference', () {
    test('follows the system until the cashier picks one', () {
      final theme = themePreference(FakePreferences());

      expect(theme.value, ThemeMode.system);
    });

    test('takes dark from what was stored', () async {
      final theme = themePreference(FakePreferences({'theme': 'dark'}));

      await theme.load();

      expect(theme.value, ThemeMode.dark);
    });

    test('is stored under its own key, apart from the language', () async {
      final port = FakePreferences();
      final theme = themePreference(port);

      await theme.select(ThemeMode.light);

      expect(port.values, {'theme': 'light'});
    });
  });
}
