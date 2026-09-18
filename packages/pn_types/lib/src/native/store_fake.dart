/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:collection';

import 'store_port.dart';

enum StoreOp { read, write, remove }

/// One operation the fake received. The key only: values can be a bearer token.
typedef StoreCall = ({StoreOp op, String key});

/// A [StorePort] for tests: an in-memory map that records what touched it and can be told
/// to fail.
///
/// Lives in `lib/`, not `test/`, so `apps/pos` tests can use it too
/// (`.claude/rules/native-ports.md` §2.3). Fails on request, and a failed operation changes
/// nothing (§4: a fake with no failure path never exercises what the caller does about one).
class FakeStorePort implements StorePort {
  /// [initial] is copied, so later edits to the map a test passed in do not leak into the
  /// store. Seeding is not an operation: it is not recorded.
  FakeStorePort([Map<String, String> initial = const {}])
    : _values = Map.of(initial);

  final Map<String, String> _values;

  /// A read-only copy of what is stored now. Looking is not an operation.
  Map<String, String> get values => Map.unmodifiable(_values);

  /// Every operation received, in order.
  final operations = <StoreCall>[];

  final _failures = Queue<StoreException>();

  /// Makes the next operation throw [failure].
  void failNext(StoreException failure) => _failures.add(failure);

  void _throwIfFailing() {
    if (_failures.isNotEmpty) throw _failures.removeFirst();
  }

  @override
  Future<String?> read(String key) async {
    operations.add((op: StoreOp.read, key: key));
    _throwIfFailing();
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    operations.add((op: StoreOp.write, key: key));
    _throwIfFailing(); // before the change: a failed write leaves what was there
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    operations.add((op: StoreOp.remove, key: key));
    _throwIfFailing();
    _values.remove(key);
  }
}
