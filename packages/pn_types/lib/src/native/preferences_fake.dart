/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';
import 'dart:collection';

import 'preferences_port.dart';

/// A [PreferencesPort] for tests: keeps values in memory, records every write, and can be told
/// to fail or to hold a read back.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). Fails on request (§4: a fake with no failure path
/// never exercises what the caller does about one).
class FakePreferences implements PreferencesPort {
  FakePreferences([Map<String, String> initial = const {}])
    : values = {...initial};

  /// What is stored right now.
  final Map<String, String> values;

  /// Every write received, in order — including the ones that failed.
  final writes = <({String key, String value})>[];

  final _readFailures = Queue<PreferencesException>();
  final _writeFailures = Queue<PreferencesException>();
  Completer<void>? _readGate;

  /// Makes the next [read] throw [failure].
  void failNextRead(PreferencesException failure) => _readFailures.add(failure);

  /// Makes the next [write] throw [failure].
  void failNextWrite(PreferencesException failure) =>
      _writeFailures.add(failure);

  /// Holds every read until [releaseReads], to test what happens while one is in flight.
  void holdReads() => _readGate = Completer<void>();

  void releaseReads() {
    _readGate?.complete();
    _readGate = null;
  }

  @override
  Future<String?> read(String key) async {
    // Taken now, not after the gate: a real read that started before a write returns what
    // was there when it started, which is what a held read has to model.
    final value = values[key];
    final gate = _readGate;
    if (gate != null) await gate.future;
    if (_readFailures.isNotEmpty) throw _readFailures.removeFirst();
    return value;
  }

  @override
  Future<void> write(String key, String value) async {
    writes.add((key: key, value: value));
    if (_writeFailures.isNotEmpty) throw _writeFailures.removeFirst();
    values[key] = value;
  }
}
