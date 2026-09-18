/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/native/preferences_port.dart';

/// One setting that is a choice from a fixed set, kept across restarts.
///
/// The language and the theme are the same shape (a name from an enum under a key), so they are
/// one class and not two that drift apart (`.claude/rules/patterns.md` §2.1).
class EnumPreference<T extends Enum> extends ChangeNotifier {
  EnumPreference({
    required this._port,
    required this._key,
    required this._values,
    required T fallback,
  }) : _value = fallback;

  final PreferencesPort _port;
  final String _key;
  final List<T> _values;
  T _value;
  bool _chosen = false;
  bool _disposed = false;

  T get value => _value;

  /// Reads the stored choice.
  Future<void> load() async {
    final String? stored;
    try {
      stored = await _port.read(_key);
    } on PreferencesException {
      // Language and theme are not worth stopping the till for: the fallback is a working
      // screen, and the choice is offered again in the menu.
      return;
    }
    // The read started before the cashier chose, so what it found is older than the choice.
    if (_chosen || _disposed) return;
    // Nothing stored, or a name that is no longer a choice: the fallback stays.
    final match = _values.where((v) => v.name == stored).firstOrNull;
    if (match == null) return;
    _value = match;
    notifyListeners();
  }

  /// Applies [choice] at once and stores it.
  Future<void> select(T choice) async {
    // Before the equality check: tapping what is already shown is still a choice, and a load
    // in flight must not take it back.
    _chosen = true;
    if (choice == _value) return;
    _value = choice;
    notifyListeners();
    try {
      await _port.write(_key, choice.name);
    } on PreferencesException {
      // The choice holds for this run, and the cashier sees it applied. Undoing it because the
      // disk was full would be worse than forgetting it on the next start.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
