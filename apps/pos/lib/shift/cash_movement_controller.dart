/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/master.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/master_data.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/pos.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/shift/submit_problem.dart';
import 'package:pos/state/loadable.dart';

/// The state behind recording money that enters or leaves the drawer without a sale.
class CashMovementController extends ChangeNotifier {
  CashMovementController({
    required this._client,
    required this.shiftId,
    required this._analytics,
    this.debounce = const Duration(milliseconds: 300),
  }) {
    // Whether it may be submitted, and whether an account is required, read the settings; what is
    // listed is the accounts. A screen listening to this controller has to hear when they arrive.
    settings.addListener(notifyListeners);
    accounts.addListener(notifyListeners);
  }

  final ApiClient _client;
  final AnalyticsPort _analytics;

  /// The drawer the movement is recorded against.
  final String shiftId;

  /// How long the search text has to sit still before the server is asked.
  final Duration debounce;

  late final settings = Loadable<POSPreferences>(
    () => PosApi.settingsGet(_client),
  );
  late final accounts = Loadable<List<ChartOfAccount>>(
    () => MasterApi.coaList(
      _client,
      query: {if (_search.isNotEmpty) 'q': _search, 'page_size': 50},
    ),
  );

  String _search = '';
  Timer? _debounceTimer;

  /// Asks the server for accounts matching [text] once the typing stops. A request per letter is
  /// what N+1 looks like from the UI (`optimization.md` §6.1).
  void setAccountSearch(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      final wanted = text.trim();
      // A trailing space changes the field and nothing else, so it is not a new request.
      if (wanted == _search) return;
      _search = wanted;
      accounts.load();
    });
  }

  CashMovementType type = CashMovementType.cashOut;
  int amount = 0;
  String reason = '';

  /// The account on the other side of the journal, when one was picked.
  ChartOfAccount? account;

  void setType(CashMovementType value) {
    type = value;
    notifyListeners();
  }

  void setAmount(int value) {
    amount = value;
    notifyListeners();
  }

  void setReason(String value) {
    reason = value;
    notifyListeners();
  }

  void pickAccount(ChartOfAccount? picked) {
    account = picked;
    notifyListeners();
  }

  /// Whether the drawer account has to be picked: once the company has one configured there is no
  /// safe default for the other side of the journal, and falling back to the drawer account
  /// itself would post a "balanced" entry that debits and credits the same account.
  bool get requireAccount => switch (settings.state) {
    Ready(:final data) => data.cashAccountId != null,
    _ => false,
  };

  /// Whether the settings that decide [requireAccount] have been read. Part of the gate on
  /// purpose: while they are in flight the account looks optional, and submitting then would be
  /// refused by the server after everything was typed.
  bool get isSettingsReady => settings.state is Ready<POSPreferences>;

  bool get canSubmit =>
      amount > 0 &&
      reason.trim().isNotEmpty &&
      (!requireAccount || account != null) &&
      isSettingsReady;

  bool isRecorded = false;
  bool isSubmitting = false;
  SubmitProblem? problem;

  /// Records the movement with what is entered now.
  ///
  /// Throws a [StateError] when the rules do not allow it: the screen keeps the button disabled
  /// until they do, so arriving here means something skipped that.
  ///
  /// There is no `client_ref` on this endpoint, so a write whose answer was lost cannot be repeated
  /// safely, and [problem] says it may have been recorded rather than that it was not.
  Future<void> submit() async {
    if (!canSubmit) {
      throw StateError('The cash movement is not ready to be recorded.');
    }
    // Asked again while one is on its way, it does nothing: a double tap must not record twice.
    if (isSubmitting) return;
    isSubmitting = true;
    problem = null;
    notifyListeners();
    try {
      await PosApi.shiftsRecordCashMovement(
        _client,
        (id: shiftId),
        CashMovementDTO(
          type: type,
          amount: amount,
          reason: reason.trim(),
          accountId: account?.id,
        ),
      );
      isRecorded = true;
      await _analytics.logEvent(
        'cash_movement_recorded',
        parameters: {'type': type.name},
      );
    } on ApiError catch (failure) {
      problem = SubmitProblem.answered(failure);
    } on TransportException {
      problem = const SubmitProblem.noAnswer();
    } finally {
      isSubmitting = false;
    }
    notifyListeners();
  }

  /// Reads what the form needs before it can be submitted.
  Future<void> open() => Future.wait([settings.load(), accounts.load()]);

  @override
  void dispose() {
    _debounceTimer?.cancel();
    settings.removeListener(notifyListeners);
    accounts.removeListener(notifyListeners);
    settings.dispose();
    accounts.dispose();
    super.dispose();
  }
}
