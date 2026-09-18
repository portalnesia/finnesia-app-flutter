/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Corner radii, in logical pixels. Two, so the corners say what is a control and what is a
/// surface (`antislop` R-11): neither is a pill.
///
/// Proposed by the agent, not decided by the owner (`DESIGN.md`, "Belum diputuskan"). The web
/// app's `--radius` is `0.5rem` (8), which is [control]; [surface] is 4 more so a card is
/// visibly softer than the button on it.
abstract final class PnRadius {
  /// Buttons, inputs, chips, keypad keys.
  static const control = 8.0;

  /// Cards, dialogs, sheets.
  static const surface = 12.0;
}

/// Minimum touch sizes, in logical pixels. A mis-tap on Pay is money.
abstract final class PnTouch {
  /// Every tappable thing.
  static const min = 48.0;

  /// The action a screen exists for: Pay, Close shift, Confirm.
  static const primary = 56.0;
}
