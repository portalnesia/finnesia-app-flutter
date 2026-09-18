/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/pos_shift.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/shift/submit_problem.dart';

/// The state behind closing a drawer: what was counted, the note, and the act of closing.
class CloseShiftController extends ChangeNotifier {
  CloseShiftController({
    required this._client,
    required this.summary,
    required this.isOverride,
    required this._analytics,
  });

  final ApiClient _client;
  final AnalyticsPort _analytics;

  /// What the drawer is counted against.
  final ShiftSummaryResponse summary;

  /// The drawer is another cashier's, closed through `pos.shift.override`.
  final bool isOverride;

  num countedCash = 0;
  String notes = '';

  void setCountedCash(num value) {
    countedCash = value;
    notifyListeners();
  }

  void setNotes(String value) {
    notes = value;
    notifyListeners();
  }

  /// The rule (`shiftCloseState`), applied to what is entered now.
  ShiftCloseState get close => shiftCloseState(
    expectedCash: summary.expectedCash,
    countedCash: countedCash,
    notes: notes,
    isOverride: isOverride,
  );

  bool isClosed = false;
  SubmitProblem? problem;

  bool isClosing = false;

  /// Closes the drawer with what is entered now.
  ///
  /// Throws a [StateError] when the rule does not allow it. The screen keeps the button disabled
  /// until it does, so arriving here means something skipped that, and a drawer closed on a count
  /// nobody explained is not something to send anyway.
  Future<void> submit() async {
    if (!close.canClose) {
      throw StateError(
        'The count is not ready to be closed: ${close.variance}',
      );
    }
    // Asked again while one is on its way, it does nothing: a double tap must not close twice.
    if (isClosing) return;
    final note = notes.trim();
    isClosing = true;
    problem = null;
    notifyListeners();
    try {
      await PosApi.shiftsClose(
        _client,
        (id: summary.shiftId),
        CloseShiftDTO(
          countedCash: countedCash,
          notes: note.isEmpty ? null : note,
        ),
      );
      isClosed = true;
      await _analytics.logEvent('shift_closed');
    } on ApiError catch (failure) {
      problem = SubmitProblem.answered(failure);
    } on TransportException {
      problem = const SubmitProblem.noAnswer();
    } finally {
      isClosing = false;
    }
    notifyListeners();
  }
}
