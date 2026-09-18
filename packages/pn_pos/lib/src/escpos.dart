/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Hand-rolled ESC/POS command builder.
///
/// Ported from `finnesia-monorepo/apps/web/src/lib/escpos.ts`.
///
/// No dependency exists for this in the repo, and the commands a plain-text receipt needs
/// (init, align, bold, font size, feed, cut) are a few dozen bytes each — well under the
/// point where pulling in a library would pay for itself. Raster/image printing (a logo) is
/// a different, much larger protocol; revisit with a library if that is ever needed.
///
/// Every command here is pure: given the same input it returns the same bytes, so this file
/// needs no device, no Bluetooth, and no mock to unit test.
///
/// ## `Uint8List`, not `List<int>`
///
/// The source returns `number[]` and wraps it in a `Uint8Array` only at the very end. Here
/// every builder returns bytes directly, per `.claude/rules/native-ports.md` §2.1 — the
/// transport carries bytes, and `List<int>` would discard the 0–255 guarantee and push
/// conversions to the transport boundary. The byte sequences are identical, including the
/// modulo-256 wrapping on out-of-range values.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'js_compat.dart';

const int _esc = 0x1b;
const int _gs = 0x1d;

/// Horizontal alignment for [cmdAlign].
enum EscPosAlign {
  left(0),
  center(1),
  right(2);

  const EscPosAlign(this.code);
  final int code;
}

/// Resets the printer.
Uint8List cmdInit() => Uint8List.fromList([_esc, 0x40]);

Uint8List cmdAlign(EscPosAlign align) =>
    Uint8List.fromList([_esc, 0x61, align.code]);

Uint8List cmdBold(bool on) => Uint8List.fromList([_esc, 0x45, on ? 1 : 0]);

/// Character size. `width`/`height` are the printer's multiplier, 1–8; 1 is normal.
///
/// ## Why the clamp does not call `round()`
///
/// The source clamps with `Math.min(8, Math.max(1, Math.round(n)))`. In JavaScript
/// `Math.round(NaN)` is `NaN`, which propagates through `max` and `min` and finally through
/// `(NaN - 1) << 4`, yielding 0 — so a NaN size quietly prints at normal size.
///
/// **Dart's `num.round()` throws `UnsupportedError` on NaN and on infinity** (verified by
/// running it). Porting the expression literally would crash the till mid-sale on a value
/// that the web app tolerates, so the NaN case is handled explicitly to reproduce
/// JavaScript's answer.
///
/// [jsRound] is used rather than `round()` for the same reason it is needed in
/// `pos_shift.dart`: JavaScript rounds half toward positive infinity, Dart rounds half away
/// from zero, and the two disagree on every negative half.
Uint8List cmdFontSize([num width = 1, num height = 1]) {
  final w = _clampSize(width);
  final h = _clampSize(height);
  return Uint8List.fromList([_gs, 0x21, ((w - 1) << 4) | (h - 1)]);
}

/// Clamps a size multiplier into 1–8, answering `NaN` the way JavaScript does.
///
/// `NaN` falls out as **1**, which is what the source produces: `Math.min(8, Math.max(1,
/// NaN))` is `NaN`, and `(NaN - 1) << 4` is `0` — the same byte as a multiplier of 1.
int _clampSize(num value) {
  if (value.isNaN) return 1;
  if (value == double.infinity) return 8;
  if (value == double.negativeInfinity) return 1;
  return jsRound(value).clamp(1, 8);
}

/// Advances the paper by `lines` lines.
///
/// No clamp, matching the source. Out-of-range values wrap modulo 256 when they reach the
/// byte — `cmdFeed(300)` emits byte 44 — and that wrapping is preserved rather than
/// "corrected" into a clamp, which would diverge from the web app.
Uint8List cmdFeed([int lines = 1]) => Uint8List.fromList([_esc, 0x64, lines]);

/// Partial cut (`m=1`): a full cut (`m=0`) on a printer with no partial-cut blade jams
/// instead of cutting, which is the more common failure of the two to get wrong.
Uint8List cmdCut() => Uint8List.fromList([_gs, 0x56, 1]);

/// Encodes [text] as UTF-8 with a trailing newline.
Uint8List cmdText(String text) => Uint8List.fromList(utf8.encode('$text\n'));

Uint8List cmdDivider([int width = 32]) => cmdText('-' * width);

/// Left-aligned label, right-aligned value, padded to one line — the plain-text equivalent
/// of the `flex justify-between` rows the CSS receipt renders.
///
/// Truncates the left side rather than overflowing when both sides together do not fit,
/// since a truncated label still leaves the amount (the part that matters most) readable.
///
/// Note this measures in **characters, not bytes**, exactly as the source does with
/// `String.length`. A multi-byte character therefore counts as one column here but prints
/// as several, so a line containing non-ASCII can exceed the paper width. Preserved rather
/// than fixed: changing it would change every receipt the web app already prints, and the
/// fix belongs in the source first (`.claude/rules/cross-repo.md` §4).
Uint8List cmdLineColumns(String left, String right, [int width = 32]) {
  final space = width - left.length - right.length;
  if (space >= 1) return cmdText(left + ' ' * space + right);
  final keep = width - right.length - 1;
  final truncated = keep <= 0 ? '' : left.substring(0, keep);
  return cmdText('$truncated $right');
}

/// Flattens a list of commands into one byte array, ready for the transport.
Uint8List buildCommands(List<List<int>> ops) =>
    Uint8List.fromList([for (final op in ops) ...op]);
