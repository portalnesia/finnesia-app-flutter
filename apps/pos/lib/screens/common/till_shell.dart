/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/material.dart';
import 'package:pn_ui/src/widgets/till_bar.dart';
import 'package:pos/app/app_scope.dart';
import 'package:pos/l10n/app_localizations.dart';
import 'package:pos/screens/menu/menu_screen.dart';
import 'package:pos/screens/shift/shift_screen.dart';

/// Everything behind the till, with the Menu one tap away, and the shift detail beside it once
/// there is a shift to show one of.
///
/// The bar is above [child] rather than inside it, so it stands over **whatever the shift gate
/// decides to show** — the till, or one of the shift panels. A cashier who cannot sell yet still
/// has to be able to change the language or sign out (`till-bar.tsx`), and a tablet whose cashier
/// left without signing out would otherwise have no way back to the login screen.
///
/// The shift gate's `Scaffold` is inside [child], so the bar is wrapped around the gate rather
/// than placed in it. That is the one arrangement that does not require every panel of the gate
/// to know about the bar. The gate still has to say whether a shift exists, though — reported
/// through `AppServices.activeShift` rather than threaded through as a widget parameter, which
/// is the one thing this arrangement otherwise cannot get from a screen it wraps rather than
/// contains.
class TillShell extends StatelessWidget {
  const TillShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final services = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ListenableBuilder(
              listenable: services.activeShift,
              builder: (context, _) {
                final shift = services.activeShift.value;
                return TillBar(
                  label: l10n.menuOpen,
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const MenuScreen()),
                  ),
                  // Reported by the gate: reflects "a shift exists", the same rule the Menu
                  // uses, not "this cashier may sell in it" — a shift held by another cashier
                  // still has a detail worth showing. Nothing while it is null, whether that
                  // is because none is open or because the gate has not answered yet: a
                  // button that opens a screen with nothing to read is worse than one shown a
                  // beat late.
                  trailingLabel: shift == null ? null : l10n.menuShiftDetail,
                  trailingIcon: shift == null
                      ? null
                      : Icons.receipt_long_outlined,
                  onTrailing: shift == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ShiftScreen(),
                          ),
                        ),
                );
              },
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
