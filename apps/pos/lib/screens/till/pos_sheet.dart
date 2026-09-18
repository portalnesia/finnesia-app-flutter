/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_ui/src/theme/app_theme.dart';
import 'package:pn_ui/src/theme/tokens.dart';
import 'package:pos/l10n/app_localizations.dart';

/// A tall sheet from the bottom, [heightFactor] of the screen.
///
/// `useSafeArea` on a modal sheet guards the top and the sides, **not the bottom**: with
/// three-button navigation the system bar was drawn over whatever sat at the bottom of the sheet,
/// which is where the Done and Pay buttons are. The bottom inset is taken here, inside the sheet,
/// so its background still runs to the edge of the screen and only its content stays clear.
Future<T?> showPosSheet<T>(
  BuildContext context, {
  required double heightFactor,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => FractionallySizedBox(
    heightFactor: heightFactor,
    child: SafeArea(top: false, child: builder(context)),
  ),
);

/// The title bar of a sheet: a heading and a way to close it, one touch target high.
class PosSheetHeader extends StatelessWidget {
  const PosSheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pn = context.pn;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: pn.border)),
      ),
      child: SizedBox(
        height: PnTouch.primary,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              tooltip: l10n.commonClose,
              icon: const Icon(Icons.close),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
