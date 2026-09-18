/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

// Whitespace and `-` are the separators a pasted code tends to carry.
final _separators = RegExp(r'[\s-]');

/// Reduces what the cashier typed or pasted to the canonical form the backend expects.
///
/// Upper-cases because codes are displayed in capitals while the tablet keyboard may not
/// be (`strings.ToUpper` on the backend folds case on lookup). Strips separators, which is
/// what a code pasted out of a chat message tends to carry.
///
/// Characters it does not recognize are deliberately KEPT, never dropped: silently removing
/// one would leave the cashier with a shorter code and no idea why, and validation is what
/// decides whether the result is a code.
String normalizePairingCode(String raw) =>
    raw.toUpperCase().replaceAll(_separators, '');

const pairingCodeLength = 6;

// Six characters, 0-9 and A-Z. Nothing else is forbidden.
//
// The backend draws codes from a narrower set (A-Z and 2-9 without I, L, O, 0, 1 —
// `posDevicePairingAlphabet`), so a code with one of those five can never succeed. The
// client does not enforce that on purpose: it costs the cashier only a vaguer error, and a
// client that never rejects a real code cannot be broken if the backend widens its alphabet.
final _shape = RegExp('^[0-9A-Z]{$pairingCodeLength}\$');

/// Whether [code] has the shape of a pairing code: six characters, each 0-9 or A-Z.
///
/// Expects a normalized code: a lower-case letter or a space is invalid here, so normalize
/// first. Length is counted in UTF-16 code units, as `String.length` does in the source
/// too; an astral character is two units, neither of which is a letter or digit.
bool isValidPairingCode(String code) => _shape.hasMatch(code);

/// The pairing-code field's next value after a keystroke or a paste.
///
/// Normalizes first, then refuses a change that would leave more than six characters.
/// Refusing rather than truncating is deliberate: cutting a pasted string down to six would
/// silently turn it into a different, plausible-looking code — the same failure
/// [normalizePairingCode] exists to avoid. A refused change keeps [previous], so the extra
/// keystroke simply does nothing.
///
/// This lives here rather than in the input's `maxLength` because `maxLength` counts the raw
/// string: a code pasted as "AB3 K7M" is seven raw characters and would be truncated into a
/// different, shorter code before normalization could strip the space.
///
/// A shrinking edit is always allowed, even while the value is still over six characters.
/// Only the scanner can put such a value in the field (a QR that is not a pairing code), and
/// refusing its backspaces too would leave the field stuck with no way back to a usable code.
String applyPairingCodeInput(String raw, String previous) {
  final normalized = normalizePairingCode(raw);
  if (normalized.length > pairingCodeLength &&
      normalized.length >= previous.length) {
    return previous;
  }
  return normalized;
}
