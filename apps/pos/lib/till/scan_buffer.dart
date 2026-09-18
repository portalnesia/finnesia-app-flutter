/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Tells a barcode scanner from a person, by how fast it types.
///
/// A scanner is a keyboard that types the whole code in a few milliseconds and finishes with
/// Enter. A scanner could be read through the search field, which has to be focused; on a tablet
/// the window itself can tell the two apart, so a cashier never has to touch a field before
/// scanning.
///
/// Time is an argument, not read here, so a test can say exactly how long each keystroke took.
///
/// The gap and the shortest code are guesses from common practice, **not measurements**: a
/// scanner configured with a slower cadence, or a code shorter than [minLength], is read as a
/// person and falls through to the search field, which still does the exact lookup on Enter.
/// Confirming both on the tablet's own scanner is `plan/ui/findings.md` V5.
class ScanBuffer {
  ScanBuffer({
    this.maxGap = const Duration(milliseconds: 50),
    this.minLength = 4,
  });

  /// The longest pause between two keystrokes that still belongs to one scan.
  final Duration maxGap;

  /// Fewer characters than this are never a code: a person typing quickly and pressing Enter.
  final int minLength;

  final _chars = StringBuffer();
  Duration? _last;

  /// One printable character arrived at [at].
  void character(String char, Duration at) {
    final last = _last;
    // A pause means a person. Whatever came before it is theirs, and the scan (if this is one)
    // starts here, so a slow keystroke before a burst does not join the code.
    if (last != null && at - last > maxGap) _chars.clear();
    _chars.write(char);
    _last = at;
  }

  /// Enter arrived at [at]. Returns the code when what was typed was a scan, else null. Either
  /// way the buffer is empty afterwards, so nothing can be read twice.
  String? enter(Duration at) {
    final last = _last;
    final code = _chars.toString();
    clear();
    if (last == null || at - last > maxGap) return null;
    return code.length < minLength ? null : code;
  }

  void clear() {
    _chars.clear();
    _last = null;
  }
}
