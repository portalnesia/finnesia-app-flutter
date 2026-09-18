/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pos/queue/queue_sync.dart';
import 'package:pos/state/loadable.dart';

/// S17: every sale this tablet has taken money for and not yet had confirmed
/// (`plan/offline-queue/README.md` §7).
///
/// Reads [PendingSaleStore] directly rather than [QueueSync]'s counts: a row here shows the
/// whole entry (when it was paid, how much, why it was refused), not a number.
///
/// Not built on [Loadable]: that type's `load()` treats anything but [ApiError]/
/// [TransportException] as a bug and rethrows it (`isServerOrNetworkFailure`), and a queue that
/// cannot be read is neither of those — it is exactly the state this screen exists to show
/// (`pos_pending_sale_store.dart`: unreadable is not the same as empty). [LoadState] itself is
/// reused, because the three states it names are still the right three.
class PendingSalesController extends ChangeNotifier with RequestGuard {
  PendingSalesController({
    required this._store,
    required this._sync,
    required this._analytics,
  });

  final PendingSaleStore _store;
  final QueueSync _sync;
  final AnalyticsPort _analytics;

  LoadState<List<PendingSale>> _state = const Loading();
  LoadState<List<PendingSale>> get state => _state;

  bool _isSending = false;

  /// Whether "Kirim sekarang" is out. The row actions (Ulangi, Buang) are not guarded by this —
  /// they are single writes, not a pass over the whole queue.
  bool get isSending => _isSending;

  void _set(LoadState<List<PendingSale>> next) {
    _state = next;
    notifyListeners();
  }

  /// Reads the queue, or reads it again.
  Future<void> load() async {
    switch (_state) {
      case Ready(:final data):
        _set(Ready(data, refreshing: true));
      case Failed():
        _set(const Loading());
      case Loading():
        break;
    }
    final request = startRequest();
    try {
      final entries = await _store.readAll();
      if (isCurrent(request)) _set(Ready(entries));
    } on PendingSaleStoreException catch (error) {
      if (isCurrent(request)) _set(Failed(error));
    }
  }

  /// Puts a failed entry back in the pending queue, and shows the result.
  Future<void> retry(String clientRef) async {
    await _store.retry(clientRef);
    await _analytics.logEvent('queue_sale_retried');
    await load();
  }

  /// Throws an entry away for good, and shows the result.
  Future<void> discard(String clientRef) async {
    await _store.remove(clientRef);
    await _analytics.logEvent('queue_sale_discarded');
    await load();
  }

  /// Tries to drain the whole queue now, then reads it again: the pass may have removed rows,
  /// marked some failed, or left the rest exactly as they were, and this is the one place all
  /// three show up.
  Future<void> sendNow() async {
    _isSending = true;
    notifyListeners();
    await _analytics.logEvent('queue_send_now_triggered');
    try {
      await _sync.sync();
    } finally {
      _isSending = false;
      await load();
    }
  }
}
