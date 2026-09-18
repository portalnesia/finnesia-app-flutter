/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/preferences/app_preferences.dart';

/// The language, as two named choices rather than a globe icon.
///
/// Lived in the pairing screen until the Menu existed, with a comment saying so: a tablet set up
/// in the wrong language had no way to change it before signing in. The Menu is that way now, so
/// this is one widget in one place instead of two that drift apart
/// (`.claude/rules/patterns.md` §2.1).
///
/// Both names are written in their own language — "Indonesia", "English" — never translated. A
/// cashier looking for their own language has to be able to recognise it on a screen they cannot
/// read.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final services = AppScope.of(context);
    final language = services.language;
    return ListenableBuilder(
      listenable: language,
      builder: (context, _) => SegmentedButton<AppLanguage>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: AppLanguage.id,
            label: Text(l10n.commonLanguageId),
          ),
          ButtonSegment(
            value: AppLanguage.en,
            label: Text(l10n.commonLanguageEn),
          ),
        ],
        selected: {language.value},
        onSelectionChanged: (picked) async {
          final choice = picked.single;
          // Before the write: a no-op tap (already this language) is not a change worth logging.
          final changed = choice != language.value;
          await language.select(choice);
          if (changed) await services.analytics.logEvent('language_changed');
        },
      ),
    );
  }
}

/// The theme: follow the tablet, or overrule it.
///
/// Three choices, not a switch. A two-way switch cannot say "follow the system", and the default
/// is exactly that (`README` §2.1), so a switch would have to show a lie the moment the screen
/// opens.
class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final services = AppScope.of(context);
    final theme = services.theme;
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) => SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: ThemeMode.system,
            label: Text(l10n.commonThemeSystem),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            label: Text(l10n.commonThemeLight),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: Text(l10n.commonThemeDark),
          ),
        ],
        selected: {theme.value},
        onSelectionChanged: (picked) async {
          final choice = picked.single;
          final changed = choice != theme.value;
          await theme.select(choice);
          if (changed) await services.analytics.logEvent('theme_changed');
        },
      ),
    );
  }
}
