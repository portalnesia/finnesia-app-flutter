/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/shift_gate.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/state/loadable.dart';

/// What the gate decides from: the drawer that is open (if any), and the company's POS
/// preferences.
///
/// The preferences are read here because the gate already asks for them, and one request that
/// answers several questions is cheaper than several that answer one each. The till's detail
/// sheet reads `show_table_number` and `default_customer_id` off the same answer rather than
/// asking for the settings again.
typedef ShiftContext = ({POSShift? shift, POSPreferences preferences});

/// Why opening a shift did not work, as far as the screen can tell the cashier.
///
/// [message] is the server's own sentence when it refused, shown as it came (a refusal is the
/// server's to explain). It is null when there was no answer at all, which the screen words
/// itself: "check the connection" is advice only that case can use.
final class OpenShiftProblem {
  const OpenShiftProblem(this.message);

  final String? message;
}

/// The state behind the shift gate: what the till reads before it may sell, which open shift the
/// cashier has consciously chosen to continue, and the act of opening one.
///
/// Where `pos-page.tsx` holds two queries and a `useSyncExternalStore` and `shift-gate.tsx` holds
/// the open form, this is one object, so the gate (which asks) and the till (which may render)
/// cannot disagree about whether the decision was made.
///
/// **The decision to continue lives here and nowhere else.** Not in storage: persisting it would
/// silently resume yesterday's shift on the next sign-in, which is the mistake the "already
/// open" screen exists to prevent (`plan/ui/findings.md` F6). The controller belongs to the
/// screen, so a sign-out that removes the screen removes the decision with it.
class ShiftController extends ChangeNotifier {
  ShiftController({
    required this._client,
    required this.outletId,
    required this.userId,
    required this._analytics,
  }) {
    _context = Loadable(_read);
    _context.addListener(_forward);
  }

  final ApiClient _client;
  final AnalyticsPort _analytics;

  /// The outlet pairing locked.
  final String outletId;

  /// The cashier at the till, from the session. Null when the session names nobody.
  final String? userId;

  late final Loadable<ShiftContext> _context;
  bool _disposed = false;

  String? _resumedShiftId;
  bool _isOpening = false;
  OpenShiftProblem? _openProblem;

  LoadState<ShiftContext> get state => _context.state;

  /// The open drawer, once it has been read. Null before that, and when none is open.
  POSShift? get activeShift => switch (state) {
    Ready(:final data) => data.shift,
    _ => null,
  };

  /// The company's POS preferences, once they have been read. Null before that.
  ///
  /// Read from the same answer the gate is decided on, so the till's detail sheet does not have
  /// to ask for the settings a second time.
  POSPreferences? get preferences => switch (state) {
    Ready(:final data) => data.preferences,
    _ => null,
  };

  bool get isOpening => _isOpening;
  OpenShiftProblem? get openProblem => _openProblem;

  /// Which screen the cashier gets.
  ///
  /// [ShiftGateState.loading] also stands for a read that failed: the failure is [state]'s to
  /// report, and it must not be taken for "no shift is open", which would offer to open one the
  /// server may already have.
  ShiftGateState get gate {
    final context = switch (state) {
      Ready(:final data) => data,
      _ => null,
    };
    return resolveShiftGate(
      isLoading: context == null,
      activeShift: context?.shift,
      // Not yet read means "unknown"; `isLoading` has already answered before this is looked at.
      requireShift: context?.preferences.requireShift ?? true,
      outletId: outletId,
      currentUserId: userId,
      resumedShiftId: _resumedShiftId,
    );
  }

  /// Reads the shift and the settings, or reads them again.
  Future<void> load() => _context.load();

  /// The cashier chose to continue the shift that is open.
  void resume() {
    final shift = activeShift;
    if (shift == null) return;
    _resumedShiftId = shift.id;
    _forward();
  }

  /// Opens a shift with [openingCash] counted in the drawer.
  ///
  /// Asked again while one is being opened, it does nothing: a double tap must not open two.
  Future<void> open(num openingCash) async {
    if (_isOpening) return;
    _isOpening = true;
    _openProblem = null;
    notifyListeners();

    try {
      final shift = await PosApi.shiftsOpen(
        _client,
        OpenShiftDTO(outletId: outletId, openingCash: openingCash),
      );
      // Opening is the "continue" decision, already made. Without recording it the gate would
      // answer the cashier's own form with the "already open" screen, as if it were someone
      // else's drawer.
      // The screen may be gone by now (a sign-out replaces it): nothing is left to tell.
      if (_disposed) return;
      _resumedShiftId = shift.id;
      await _analytics.logEvent('shift_opened');
      // Read again while still opening, so the form stays on screen until the answer is there
      // rather than flashing back to "open a shift" for a shift that now exists.
      await _context.load();
    } on ApiError catch (failure) {
      _openProblem = OpenShiftProblem(failure.message);
      // Only a 4xx is a refusal. A 5xx may have committed before it failed, and a 2xx that
      // could not be read means the shift exists: either way "no shift is open" is no longer
      // known, so the screen asks the server instead of guessing.
      final refused = failure.status >= 400 && failure.status < 500;
      if (!refused && !_disposed) await _context.load();
    } on TransportException {
      _openProblem = const OpenShiftProblem(null);
    } finally {
      _isOpening = false;
      _forward();
    }
  }

  Future<ShiftContext> _read() async {
    // Two different resources, one request each. Together, so the gate is never decided on one
    // half: `require_shift` defaults to true while unread, and deciding early would flash "open
    // a shift" at a company that has shifts switched off (`pos-page.tsx`).
    //
    // `Future.wait` and not a record's `.wait`: the record form reports a failure as a
    // `ParallelWaitError`, which is neither an `ApiError` nor a `TransportException` and would
    // read as a bug.
    final answers = await Future.wait<Object?>([
      PosApi.shiftsGetActive(_client, query: {'outlet_id': outletId}),
      PosApi.settingsGet(_client),
    ]);
    return (
      shift: answers[0] as POSShift?,
      preferences: answers[1] as POSPreferences,
    );
  }

  // What [gate] answered the last time it was reported, so a rebuild that leaves the cashier
  // in the same blocked screen (an unrelated `_isOpening` toggle, a second identical read)
  // does not log the event again. `null` before anything has been reported.
  ShiftGateState? _lastReportedGate;

  void _forward() {
    if (_disposed) return;
    _reportGateIfBlocked();
    notifyListeners();
  }

  void _reportGateIfBlocked() {
    final current = gate;
    if (current == _lastReportedGate) return;
    _lastReportedGate = current;
    final reason = switch (current) {
      ShiftGateState.alreadyOpen => 'already_open',
      ShiftGateState.heldByOther => 'held_by_other',
      _ => null,
    };
    if (reason == null) return;
    // Not awaited: `_forward` is a synchronous callback (`notifyListeners`, `_context`'s own
    // listener), and the port's contract is that logging never throws.
    unawaited(
      _analytics.logEvent('shift_open_blocked', parameters: {'reason': reason}),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _context.removeListener(_forward);
    _context.dispose();
    super.dispose();
  }
}
