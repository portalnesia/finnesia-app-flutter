/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/page.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pos/state/paged_loadable.dart';

/// Which shifts the history lists: all of them, or only the ones still open or already closed.
enum ShiftHistoryFilter {
  all,
  open,
  closed;

  /// The value the server filters by, or null for no filter.
  String? get wire => switch (this) {
    all => null,
    open => ShiftStatus.open.wire,
    closed => ShiftStatus.closed.wire,
  };
}

/// The shifts of the paired outlet, newest first, a page at a time (`pos-shifts-page.tsx`).
///
/// Every filter is the server's: narrowing the page already downloaded would hide the rows that
/// match on any page but the first. The outlet is the one pairing locked, so it is not a filter
/// the cashier picks: the web lists every outlet, which is not this tablet's business.
class ShiftHistoryController extends ChangeNotifier {
  ShiftHistoryController({required this.client, required this.outletId}) {
    shifts = PagedLoadable(_readPage);
  }

  static const _pageSize = 25;

  final ApiClient client;

  /// The outlet pairing locked.
  final String outletId;

  late final PagedLoadable<POSShift> shifts;

  ShiftHistoryFilter _filter = ShiftHistoryFilter.all;
  ShiftHistoryFilter get filter => _filter;

  Future<CursorPage<POSShift>> _readPage(String? cursor) async {
    // Asking without an outlet lets the server answer with other outlets' shifts, which is worse
    // than showing none (`ShiftDetailController` skips its reads for the same reason).
    if (outletId.isEmpty) return const CursorPage(items: []);
    return PosApi.shiftsList(
      client,
      cursor: cursor,
      query: {
        'outlet_id': outletId,
        'status': _filter.wire,
        'page_size': _pageSize,
      },
    );
  }

  /// Reads the first page, or reads it again.
  Future<void> load() => shifts.load();

  /// Narrows the list, and starts again from its top: a cursor points into the result the old
  /// filter made.
  Future<void> setFilter(ShiftHistoryFilter next) async {
    if (next == _filter) return;
    _filter = next;
    notifyListeners();
    await shifts.load();
  }

  @override
  void dispose() {
    shifts.dispose();
    super.dispose();
  }
}
