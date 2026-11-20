/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/transport.dart';

/// What came of adding a customer or a product from the till.
///
/// Sealed, so the screen must name all four. [QuickCreateInvalid] is separate from
/// [QuickCreateRejected] because nothing was sent: the cashier is told what to fix without a round
/// trip that the server would refuse anyway.
sealed class QuickCreateOutcome<T> {
  const QuickCreateOutcome();
}

/// It exists now.
final class QuickCreateOk<T> extends QuickCreateOutcome<T> {
  const QuickCreateOk(this.created);

  final T created;
}

/// Nothing was sent: the name was empty once trimmed.
final class QuickCreateInvalid<T> extends QuickCreateOutcome<T> {
  const QuickCreateInvalid();
}

/// The server refused it, and [message] is its own sentence about why.
final class QuickCreateRejected<T> extends QuickCreateOutcome<T> {
  const QuickCreateRejected(this.message);

  final String message;
}

/// No answer at all. A different situation from a refusal, and the screen words it differently.
final class QuickCreateUnavailable<T> extends QuickCreateOutcome<T> {
  const QuickCreateUnavailable();
}

/// Sends one create at a time, and reads its failure the way the till words it.
///
/// While one is in flight another call gets **the same future** and sends nothing, as
/// `CheckoutService.submit` does: the form is disabled while saving, so a second call could only
/// come from a caller that skipped that, and creating a second customer or product is not
/// something to do on its behalf.
final class QuickCreateRunner<T> {
  Future<QuickCreateOutcome<T>>? _inFlight;

  Future<QuickCreateOutcome<T>> run(Future<T> Function() send) {
    final running = _inFlight;
    if (running != null) return running;
    return _inFlight = _send(send).whenComplete(() => _inFlight = null);
  }

  Future<QuickCreateOutcome<T>> _send(Future<T> Function() send) async {
    try {
      return QuickCreateOk(await send());
    } on ApiError catch (failure) {
      // Only a 4xx is a refusal. A 5xx may have committed, and a 2xx that could not be read means
      // it exists: neither is a sentence to show as the server's.
      if (failure.status >= 400 && failure.status < 500) {
        return QuickCreateRejected(failure.message);
      }
      return const QuickCreateUnavailable();
    } on TransportException {
      return const QuickCreateUnavailable();
    }
  }
}

/// `x || undefined` for an optional field the cashier left alone: empty means absent, and the
/// server validates these `omitempty`.
String? orAbsent(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
