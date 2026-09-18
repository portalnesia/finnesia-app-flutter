/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_pos/src/pos_pending_sale_sync.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/session/session_holder.dart';

/// Drains the offline queue in the background: a pass every [interval] once [start] is called,
/// and whatever else asks for one (`plan/offline-queue/README.md` §5.2, D-Q8).
///
/// Written new — there is no source to port. `use-pos-sync.ts` is a `useEffect` with a browser
/// timer and `window` event listeners; the part that is actually ported is `syncQueue` itself
/// (`pn_pos`, step Q3), and this is the worker that calls it from the app.
///
/// A [ChangeNotifier] for [pendingCount] and [failedCount]: they are the one source the status
/// strip, the Menu card and S17 (step Q8) all read, rather than each keeping a count of its own.
class QueueSync extends ChangeNotifier {
  QueueSync({
    required this._client,
    required this._queue,
    required SessionHolder session,
    required this._analytics,
    this.interval = const Duration(seconds: 60),
  }) : _session = session,
       _lastToken = session.current?.sessionToken ?? '' {
    _unsubscribeSession = _session.subscribe(_onSessionChanged);
  }

  final ApiClient _client;
  final PendingSaleStore _queue;
  final SessionHolder _session;
  final AnalyticsPort _analytics;

  /// How often [start] repeats a pass.
  final Duration interval;

  Timer? _timer;
  late final void Function() _unsubscribeSession;

  Future<void>? _inFlight;
  bool _disposed = false;

  int _pendingCount = 0;
  int _failedCount = 0;

  // The moment a session goes from no token to one is a sign-in finishing (D-Q8: "sesudah
  // login"). Any other change — a token lost, a different pairing — only changes what the next
  // pass sees, and is not itself a reason to run early.
  String _lastToken;

  /// Sales not yet known to be recorded, across every cashier on this tablet.
  int get pendingCount => _pendingCount;

  /// Sales the server refused, waiting for the cashier to retry or discard them.
  int get failedCount => _failedCount;

  void _onSessionChanged(PosSession? next) {
    final token = next?.sessionToken ?? '';
    if (token.isNotEmpty && token != _lastToken) sync();
    _lastToken = token;
  }

  /// Starts the periodic pass, every [interval]. Called once, by `PosApp` after boot — not from
  /// this constructor, so building a [QueueSync] (which every boot does, `bootstrap.dart`) never
  /// leaves a live `Timer` behind on its own. A widget test that boots the app without ever
  /// asking for a periodic pass would otherwise fail flutter_test's "no pending timers" check
  /// for a feature it is not testing at all.
  ///
  /// Safe to call more than once: only the first call starts a timer.
  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(interval, (_) => sync());
    // A tablet that was signed in and had sales queued before it was ever turned off must not
    // wait out a whole [interval] after boot before the first attempt.
    sync();
  }

  /// Tries to drain the queue once. Two callers at once — the timer and a cashier tapping Kirim
  /// sekarang — share the one pass under way rather than starting a second.
  Future<void> sync() {
    final running = _inFlight;
    if (running != null) return running;
    return _inFlight = _run().whenComplete(() => _inFlight = null);
  }

  Future<void> _run() async {
    final current = _session.current;
    // Not paired: no outlet to count against, and nobody could have queued anything under this
    // tenant.
    if (current == null) return;

    final cashierId = current.user?.id;
    // "Tanpa token sesi (tidak ada yang masuk): tidak melakukan apa-apa dan tidak menghitung
    // sebagai gagal" (README §5.2) — a sale sent under nobody's name would be recorded against
    // whoever the server thinks is authenticated, which is the exact mistake D-Q1 exists to
    // avoid, so a device with no cashier at the till sends nothing at all.
    if (current.sessionToken.isNotEmpty &&
        cashierId != null &&
        await _hasPending(current.outletId)) {
      // The active-shift lookup is one request every pass; skipping it when there is nothing
      // queued is what keeps a signed-in, empty tablet from polling the server once a minute
      // for no reason.
      final openShiftId = await _openShiftId(current.outletId);
      await syncQueue(
        _queue,
        send: _send,
        openShiftId: openShiftId,
        cashierId: cashierId,
      );
    }

    await _refreshCounts(current.outletId);
  }

  /// Reads [pendingCount] and [failedCount] straight from the store, without trying to send
  /// anything. Safe to call as often as a screen likes — a sale that was just written to the
  /// queue (or just retried, or just discarded) does not change these numbers on its own, since
  /// nothing about a store write tells this object to look again.
  Future<void> refreshCounts() async {
    final current = _session.current;
    if (current == null) return;
    await _refreshCounts(current.outletId);
  }

  /// Whether there is anything at this outlet worth asking the server about.
  ///
  /// A read failure is **not** caught here: an unreadable queue is not the same as an empty one
  /// (`pos_pending_sale_store.dart`), and treating it as empty would skip a pass that had sales
  /// to send. It reaches the caller of [sync] instead, and the next pass tries again.
  Future<bool> _hasPending(String outletId) async =>
      await _queue.count(outletId: outletId) > 0;

  /// The shift open at this outlet right now, or `null` when there is none, or when the platform
  /// could not say.
  ///
  /// A failed lookup is treated the same as "no shift is open": [toCheckoutPayload] then drops
  /// every entry's `shift_id`, which is always safe — the server attaches a sale with no
  /// `shift_id` to whichever shift is open (`findings.md` F3), the same shift this lookup would
  /// have named if it had answered. Guessing wrong in the other direction is not safe: a stale
  /// `shift_id` sent as if it were still open is refused outright (`pos_shift_closed`).
  Future<String?> _openShiftId(String outletId) async {
    try {
      final shift = await PosApi.shiftsGetActive(
        _client,
        query: {'outlet_id': outletId},
      );
      return shift?.id;
    } on ApiError {
      return null;
    } on TransportException {
      return null;
    }
  }

  Future<SendOutcome> _send(POSCheckoutDTO payload) async {
    try {
      await PosApi.salesCheckout(_client, payload);
      await _analytics.logEvent('queue_sale_synced');
      return const SendSucceeded();
    } on ApiError catch (e) {
      // A 401 that reaches here already survived `PosTransport`'s own refresh-and-retry
      // (`pos_transport.dart`): the session could not be renewed, not the sale that is wrong.
      // Marking it `failed` would blame a sale the cashier cannot fix by retrying it — the fix is
      // signing in again, and the queue waits on disk until that happens (README R6).
      if (e.status == 401) return const SendUnreachable();
      // 402 is not one thing. The backend answers it for three different reasons — the
      // subscription has ended (`subscription_expired`), the user quota is full
      // (`user_over_quota`), or the outlet quota is full (`outlet_over_quota`)
      // (`finnesia-monorepo` `middleware/tenant.go` and `service/outlet_resolver.go`) — and a
      // 403 `outlet_inactive` is a fourth with the same meaning. In every case the sale is not
      // wrong and the refusal is not permanent: it clears when the owner renews, moves outlet,
      // or reactivates the outlet, with no change to the sale. Parking any of them as `failed`
      // would strand money the cashier has already taken, for a reason the cashier cannot act
      // on, so it stays pending and the pass stops — exactly like the 401 above.
      //
      // The **sentence is the server's**, passed through unchanged; `key` only decides whether
      // this is a block, never which text appears. The backend already translates each key
      // (`errors.yaml`), so a local table here would drift from it and lose the specific reason
      // the cashier needs.
      if (e.status == 402) return SendBlocked(e.message);
      if (e.status == 403 && e.errorData?.key == 'outlet_inactive') {
        return SendBlocked(e.message);
      }
      if (e.status >= 400 && e.status < 500) {
        return SendRefused(e.status, e.message);
      }
      return const SendUnreachable();
    } on TransportException {
      return const SendUnreachable();
    }
  }

  Future<void> _refreshCounts(String outletId) async {
    try {
      final pending = await _queue.count(outletId: outletId);
      final failed = await _queue.count(
        outletId: outletId,
        status: PendingSaleStatus.failed,
      );
      // The pass may have outlived this object: a screen tear-down disposes it, and a disposed
      // `ChangeNotifier` throws if told anything changed.
      if (_disposed) return;
      if (pending == _pendingCount && failed == _failedCount) return;
      _pendingCount = pending;
      _failedCount = failed;
      notifyListeners();
    } on PendingSaleStoreException {
      // Display-only: the rows are still on disk whatever this read did, and the next pass reads
      // them again. Nothing here is allowed to turn a stale count into a wrong one.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _unsubscribeSession();
    super.dispose();
  }
}
