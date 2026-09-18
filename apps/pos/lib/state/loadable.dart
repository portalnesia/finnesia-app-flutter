/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/transport.dart';

/// What a screen that reads the server is showing: nothing yet, the data, or why there is none.
///
/// Sealed, so a `switch` over it must name all three and a screen cannot forget the failure.
sealed class LoadState<T> {
  const LoadState();
}

final class Loading<T> extends LoadState<T> {
  const Loading();
}

final class Ready<T> extends LoadState<T> {
  const Ready(this.data, {this.refreshing = false});

  final T data;

  /// A newer answer is on its way; [data] is the last one, and it is still worth showing.
  final bool refreshing;
}

final class Failed<T> extends LoadState<T> {
  const Failed(this.error);

  final Object error;
}

/// Which answer is still wanted, for a notifier whose requests can overlap.
///
/// A request that was overtaken by a newer one, or that finishes after its screen is gone, must
/// not touch the state: the first is an old answer shown as the new one, the second is
/// `notifyListeners` after `dispose`.
mixin RequestGuard on ChangeNotifier {
  int _generation = 0;
  bool _disposed = false;

  /// Starts a request, and makes every earlier one stale.
  int startRequest() => ++_generation;

  bool isCurrent(int request) => !_disposed && request == _generation;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Whether [error] is something the failed state is for: the server's answer, or no answer.
/// Anything else is a bug, and stays loud.
bool isServerOrNetworkFailure(Object error) =>
    error is ApiError || error is TransportException;

/// The sentence for a failed read: the server's own when it refused, [fallback] when nobody
/// answered.
///
/// A refusal is the server's to explain — "stok tidak cukup", a subscription that has ended — and
/// no wording this app invents can be as specific. The fallback is for the case that has no
/// speaker: a connection that dropped, where "check the connection" is the only advice that fits.
///
/// One function rather than one per screen: the rule is about the error, not the screen, and two
/// copies of it had already started to drift (the Menu read the server's sentence, the shift gate
/// showed its own wording for every failure, including a 402 that retrying cannot fix).
String failedReadText(Object error, String fallback) {
  if (error is ApiError && error.message.isNotEmpty) return error.message;
  return fallback;
}

/// One read from the server, and the state of it.
///
/// Deliberately small, and not a cache: nothing is kept between screens and nothing is fetched
/// unless a screen asks (`plan/ui/README.md` §5.1).
class Loadable<T> extends ChangeNotifier with RequestGuard {
  Loadable(this._fetch);

  final Future<T> Function() _fetch;
  LoadState<T> _state = const Loading();

  LoadState<T> get state => _state;

  void _set(LoadState<T> next) {
    _state = next;
    notifyListeners();
  }

  /// Fetches, or fetches again.
  Future<void> load() async {
    switch (_state) {
      case Ready(:final data):
        // The grid does not blink empty on every tap of a category.
        _set(Ready(data, refreshing: true));
      case Failed():
        _set(const Loading());
      case Loading():
        break;
    }
    final request = startRequest();
    try {
      final data = await _fetch();
      if (isCurrent(request)) _set(Ready(data));
    } on Object catch (error) {
      if (isCurrent(request)) _set(Failed(error));
      // A bug stays loud, whether or not anyone is still waiting for it.
      if (!isServerOrNetworkFailure(error)) rethrow;
    }
  }
}
