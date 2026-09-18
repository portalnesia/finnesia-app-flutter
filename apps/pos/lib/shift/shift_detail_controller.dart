/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/permissions.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/endpoints/team.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:pos/state/loadable.dart';
import 'package:pos/state/paged_loadable.dart';

/// What the shift screen reads: the open drawer, and behind it the figures, the movements and the
/// individual sales.
///
/// The figures are not just totals. `expected_cash` is opening plus cash sales plus cash in, minus
/// cash out and drops, so every term is listed, and the sales and movements behind it are listed
/// too: a cashier who has to explain a variance can only do that by looking at what made it
/// (`shift-page.tsx`).
///
/// **Four reads, four states.** They fail differently and the screen shows them differently: a
/// summary that could not be read must not take the sales list down with it, and the other way
/// round. The shift is read first because everything else asks by its id; the other three then
/// start together.
///
/// The shift is read from the same endpoint the till reads (`pos.shifts.getActive`, filtered by the
/// paired outlet), not taken from the gate: the outlet has one open drawer at a time, and the till
/// and this screen must never disagree about which.
class ShiftDetailController extends ChangeNotifier {
  ShiftDetailController({
    required this._client,
    required this.outletId,
    required this.userId,
    required this.membership,
    POSShift? shift,
  }) : _picked = shift {
    this.shift = Loadable(() async {
      // A shift the history handed over is the one to show: nothing asks which drawer is open, and
      // this may be long closed.
      if (_picked != null) return _picked;
      // Asking without an outlet lets the server answer with another outlet's drawer, which is
      // worse than showing none (`MenuScreenController` skips its reads for the same reason).
      if (outletId.isEmpty) return null;
      return PosApi.shiftsGetActive(_client, query: {'outlet_id': outletId});
    });
    summary = Loadable(() => PosApi.shiftsGetSummary(_client, (id: _shiftId!)));
    movements = Loadable(
      () => PosApi.shiftsCashMovements(_client, (id: _shiftId!)),
    );
    // The transactions the closing figures are made of. A report the cashier cannot drill into is
    // a number they have to take on trust, and when it disagrees with the drawer the individual
    // sales are the only place the answer can be.
    sales = PagedLoadable(
      (cursor) => PosApi.salesList(
        _client,
        cursor: cursor,
        query: {'shift_id': _shiftId, 'page_size': _salesPageSize},
      ),
    );
  }

  static const _salesPageSize = 50;

  final ApiClient _client;

  /// The shift the history picked, or null when this reads the drawer that is open now.
  final POSShift? _picked;

  /// The outlet pairing locked.
  final String outletId;

  /// The cashier at the tablet. Null when the session names nobody.
  final String? userId;

  /// The cashier's membership in the paired company, which is where "owner" comes from.
  final UserCompany? membership;

  late final Loadable<POSShift?> shift;
  late final Loadable<ShiftSummaryResponse> summary;
  late final Loadable<List<POSCashMovement>> movements;
  late final PagedLoadable<POSSale> sales;

  /// The shift the three reads behind it ask about. Set once the shift is known, and only ever
  /// read by them, which only run after that.
  String? _shiftId;

  /// Whether the drawer, still open, belongs to someone else.
  ///
  /// Read the way the gate reads it: a session that names nobody cannot prove the drawer is the
  /// cashier's, and the safe direction is to say it is not (`resolveShiftGate`).
  ///
  /// Only for a shift that exists; without one there is nothing to hold.
  bool get isHeldByOther {
    final open = switch (shift.state) {
      Ready(:final data) => data,
      _ => null,
    };
    if (open == null) return false;
    // A closed drawer is nobody's to work: its figures are there to be read and printed, whoever
    // closed it. A status this build cannot read counts as open, the safe direction.
    if (open.status == ShiftStatus.closed) return false;
    final id = userId;
    return id == null || id.isEmpty || open.cashierId != id;
  }

  /// Whether the cashier may work another cashier's drawer (`pos.shift.override`).
  ///
  /// False until the permissions have been read, and when they could not be: the safe direction
  /// for a permission question (`Permissions.can`).
  bool get canOverride => Permissions.of(
    membership: membership,
    granted: _granted,
  ).can('pos.shift.override');

  List<String>? _granted;

  /// Reads the shift and, when it is the cashier's own, the figures behind it. Or reads them all
  /// again.
  ///
  /// Another cashier's drawer is read further only when this cashier may override it (an owner, or
  /// `pos.shift.override`): without that the screen shows no figures for it, and asking would fetch
  /// what nobody looks at.
  Future<void> load() async {
    await shift.load();
    final open = switch (shift.state) {
      Ready(:final data) => data,
      _ => null,
    };
    if (open == null) return;
    if (isHeldByOther) {
      await _readGranted();
      if (!canOverride) return;
    }

    _shiftId = open.id;
    // `Future.wait` and not a record's `.wait`: the record form reports a failure as a
    // `ParallelWaitError`, which is neither an `ApiError` nor a `TransportException` and would
    // read as a bug (`shift_controller.dart`).
    await Future.wait([summary.load(), movements.load(), sales.load()]);
  }

  /// Asks what the server allows this cashier, unless they own the company and need no asking.
  ///
  /// Only for a drawer that is someone else's: for one's own, nothing here depends on it.
  Future<void> _readGranted() async {
    _granted = null;
    if (Permissions.of(membership: membership).isOwner) return;
    try {
      _granted = await TeamApi.permissionsMy(_client);
    } on ApiError {
      // Left as "nothing granted": the cashier is shown that the drawer is someone else's, which
      // is true, rather than a failure screen for a permission they may not have needed.
    } on TransportException {
      // Same: no answer means no override, and the safe direction is to withhold it.
    }
  }

  @override
  void dispose() {
    shift.dispose();
    summary.dispose();
    movements.dispose();
    sales.dispose();
    super.dispose();
  }
}
