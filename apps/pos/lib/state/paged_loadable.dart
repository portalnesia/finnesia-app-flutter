/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/api/page.dart';
import 'package:pos/state/loadable.dart';

/// The rows loaded so far, and whether the list can still grow.
final class PagedItems<T> {
  const PagedItems({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
    this.moreError,
  });

  final List<T> items;
  final bool hasMore;

  /// The next page is on its way, and the list should show it at its end.
  final bool loadingMore;

  /// Why the last request for a next page failed. The rows stay, and asking again retries.
  final Object? moreError;
}

/// A list read page by page with a cursor, for the catalog and the sales of a shift.
///
/// Shares the states of [Loadable], so a screen switches over the same three cases. One request
/// per page, however often the list asks.
class PagedLoadable<T> extends ChangeNotifier with RequestGuard {
  PagedLoadable(this._fetch);

  final Future<CursorPage<T>> Function(String? cursor) _fetch;
  LoadState<PagedItems<T>> _state = const Loading();
  String? _cursor;

  LoadState<PagedItems<T>> get state => _state;

  void _set(LoadState<PagedItems<T>> next) {
    _state = next;
    notifyListeners();
  }

  /// Fetches the first page, or fetches it again from the start.
  ///
  /// The rows already shown stay on screen until the new first page arrives, and a next page
  /// that was still on its way is dropped: it belongs to the list that is being replaced.
  Future<void> load() async {
    final request = startRequest();
    switch (_state) {
      case Ready(:final data):
        _set(
          Ready(
            PagedItems(items: data.items, hasMore: data.hasMore),
            refreshing: true,
          ),
        );
      case Failed():
        _set(const Loading());
      case Loading():
        break;
    }
    try {
      final page = await _fetch(null);
      if (!isCurrent(request)) return;
      _cursor = page.nextCursor;
      _set(Ready(PagedItems(items: page.items, hasMore: _cursor != null)));
    } on Object catch (error) {
      if (isCurrent(request)) _set(Failed(error));
      if (!isServerOrNetworkFailure(error)) rethrow;
    }
  }

  /// Fetches the page after the last one shown, once.
  ///
  /// Asked again while a request is out, or after the last page, it does nothing: a scroll view
  /// asks on every frame near its end.
  Future<void> loadMore() async {
    final current = _state;
    // While the first page is being loaded again the rows on screen are the old list's.
    if (current is! Ready<PagedItems<T>> || current.refreshing) return;
    final shown = current.data;
    if (!shown.hasMore || shown.loadingMore) return;

    final request = startRequest();
    final asked = _cursor;
    _set(
      Ready(PagedItems(items: shown.items, hasMore: true, loadingMore: true)),
    );
    try {
      final page = await _fetch(asked);
      if (!isCurrent(request)) return;
      // A cursor that has not moved would be asked for again for ever.
      _cursor = page.nextCursor == asked ? null : page.nextCursor;
      _set(
        Ready(
          PagedItems(
            items: [...shown.items, ...page.items],
            hasMore: _cursor != null,
          ),
        ),
      );
    } on Object catch (error) {
      if (isCurrent(request)) {
        _set(
          Ready(
            PagedItems(items: shown.items, hasMore: true, moreError: error),
          ),
        );
      }
      if (!isServerOrNetworkFailure(error)) rethrow;
    }
  }
}
