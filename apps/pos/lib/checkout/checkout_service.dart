/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:async';

import 'package:pn_pos/src/pos_pending_sale.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_pos/src/ulid.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/pos.dart';

/// What happened to a checkout.
///
/// Sealed on purpose: every screen that handles a checkout has to decide what to show for each
/// of the three, and adding a variant stops them compiling until they do. That is safer than a
/// branch written now that no code path can reach (`plan/ui/README.md` §4.3).
sealed class CheckoutOutcome {
  const CheckoutOutcome();
}

/// The server recorded the sale.
final class CheckoutSynced extends CheckoutOutcome {
  const CheckoutSynced(this.sale);

  final POSSale sale;
}

/// The server understood the request and refused it, so **no sale was recorded**.
///
/// [message] is the sentence the server wrote, in the cashier's language: what to fix is
/// often something only it knows (an unmapped tender account, a deactivated product).
final class CheckoutRejected extends CheckoutOutcome {
  const CheckoutRejected(this.message, this.status);

  final String message;
  final int status;
}

/// Nobody knows whether the sale was recorded — and **it is written down**, so it will be sent
/// again until the server says what became of it.
///
/// This is the outcome of every send that did not get a definite answer: no response, a 5xx, a
/// 2xx this app could not read, or an answer that took longer than [CheckoutService.answerWithin].
/// Retrying is safe, and only because the retry carries the same `client_ref`: the server looks a
/// sale up by it before creating one.
///
/// Replaces `CheckoutUnconfirmed` from step A4, which said the same thing without a record behind
/// it. With the queue in place that variant is unreachable: every unknown send leaves a row.
final class CheckoutQueued extends CheckoutOutcome {
  const CheckoutQueued(this.entry);

  /// The row written for this sale, for the temporary receipt the cashier can print
  /// (`plan/offline-queue/README.md` §7).
  ///
  /// A sale the same basket was already queued for keeps the **stored** row's timestamps: the
  /// store is idempotent on `client_ref`, so the first write is the one on disk. The figures the
  /// receipt prints are the same either way — they come from the basket, not from the clock.
  final PendingSale entry;
}

/// Sends a checkout to the server, and owns the `client_ref` that makes a retry safe.
///
/// The server finds a sale by `(company, client_ref)` and returns the one it has **without
/// comparing what was in it** (`pos_service.go:1103-1109`). So a ref may be reused for exactly
/// the same basket and never for another:
///
/// | Before | After |
/// | ------ | ----- |
/// | unconfirmed attempt, then the **same** basket | same ref (a retry) |
/// | unconfirmed attempt, then an **edited** basket | new ref |
/// | a sale was recorded, then any basket, even an identical one | new ref |
/// | a refusal, then any basket | new ref |
///
/// The second row is what stops an edited basket from silently returning the old sale. The
/// third is what stops the next customer's two coffees from being swallowed as a duplicate of
/// the last customer's.
///
/// ## The sale is written down before it is sent
///
/// `.claude/rules/security.md` §5: "a queued sale is stored **before** it is sent, not after".
/// The web app does the opposite — it keeps a sale only once a send has failed — and an app that
/// dies mid-request therefore loses a sale the server may already have recorded.
///
/// A write that fails **throws** out of [submit], and that is deliberate: the caller keeps the
/// cart in front of the cashier and says the sale was not processed. Clearing the cart for a sale
/// that is in no queue and on no server is the one outcome this port exists to prevent.
class CheckoutService {
  CheckoutService({
    required this._client,
    required this._queue,
    required this._analytics,
    this._newRef = ulid,
    this._answerWithin = const Duration(seconds: 15),
  });

  final ApiClient _client;
  final PendingSaleStore _queue;
  final AnalyticsPort _analytics;

  final String Function() _newRef;

  /// How long to wait for an answer before treating the send as one that may have been recorded.
  ///
  /// Fifteen seconds rather than the transport's own thirty (`public_http_dio.dart:38-40`),
  /// because the customer is standing at the counter while this runs. A request still in flight
  /// is not cancelled — the answer is simply ignored, and the sale is sent again under the same
  /// `client_ref`, which the server answers with the sale it already has.
  ///
  /// This is a **behaviour** limit, not a transport setting: it is enforced here, on the await,
  /// so it holds for whatever the transport underneath does.
  final Duration _answerWithin;

  // The last basket that was sent without knowing what came of it, and the ref it went under.
  ({POSCheckoutDTO basket, String ref})? _unconfirmed;

  Future<CheckoutOutcome>? _inFlight;

  /// [draft] is the basket without a `client_ref`: this service chooses it.
  ///
  /// [entry] builds the row to write for that basket. It is a parameter of **this** call and not
  /// of the constructor because the row needs what only the moment of the sale knows: the lines
  /// as they were rung up, and the tenders as the cashier typed them. It receives the
  /// `client_ref` this service chose, which is the one thing it cannot work out itself.
  ///
  /// While one checkout is in flight, another call gets **the same future** and sends nothing,
  /// whatever basket it carries: a double tap on Pay must not charge twice, and the pay screen
  /// does not let the basket change while it is open.
  ///
  /// That single-flight is also what keeps the server's own idempotency sufficient. It looks a
  /// sale up by `client_ref` and then creates it, with the lookup **outside** the write's
  /// transaction (`pos_service.go:1103-1109`), so two requests for one ref at the same instant
  /// can both find nothing and both create. Serialising the sends is what makes that unreachable
  /// from this device.
  ///
  /// Anything that is neither a server answer nor a network failure is not turned into an
  /// outcome; it reaches the caller.
  Future<CheckoutOutcome> submit(
    POSCheckoutDTO draft, {
    required PendingSale Function(String clientRef) entry,
  }) {
    final running = _inFlight;
    if (running != null) return running;
    return _inFlight = _send(draft, entry).whenComplete(() => _inFlight = null);
  }

  Future<CheckoutOutcome> _send(
    POSCheckoutDTO draft,
    PendingSale Function(String clientRef) buildEntry,
  ) async {
    final basket = draft.copyWith(clientRef: null);
    final previous = _unconfirmed;
    final ref = previous != null && previous.basket == basket
        ? previous.ref
        : _newRef();

    final queued = buildEntry(ref);
    // Written down first, and a failure here reaches the caller with nothing sent: the cashier
    // keeps the cart, and no request goes out for a sale that is nowhere.
    await _queue.enqueue(queued);

    // Recorded before the call: an exception nobody handles must not lose the ref of a
    // request that may have gone out.
    _unconfirmed = (basket: basket, ref: ref);

    try {
      final sale = await PosApi.salesCheckout(
        _client,
        basket.copyWith(clientRef: ref),
      ).timeout(_answerWithin);
      await _clear(ref);
      _unconfirmed = null;
      await _analytics.logEvent('sale_completed');
      return CheckoutSynced(sale);
    } on ApiError catch (e) {
      // Only a 4xx is a refusal. A 5xx may have committed before it failed, and a 2xx that
      // could not be read (`ApiClient` reports it as an ApiError with the 2xx status) means
      // the sale exists.
      if (e.status >= 400 && e.status < 500) {
        await _clear(ref);
        _unconfirmed = null;
        // The status code only — never `e.message`, which is the server's sentence to the
        // cashier and may quote back whatever they typed (`plan/firebase/README.md` §2).
        await _analytics.logEvent(
          'sale_rejected',
          parameters: {'status': e.status},
        );
        return CheckoutRejected(e.message, e.status);
      }
      await _analytics.logEvent('sale_queued_offline');
      return CheckoutQueued(queued);
    } on TransportException {
      await _analytics.logEvent('sale_queued_offline');
      return CheckoutQueued(queued);
    } on TimeoutException {
      // The request is still out there. It is not cancelled: its answer is ignored, and the
      // sale goes again under the same ref, which is answered with whatever the first one did.
      await _analytics.logEvent('sale_queued_offline');
      return CheckoutQueued(queued);
    }
  }

  /// Takes the row out of the queue once the sale's fate is known.
  ///
  /// A failure to clear it is **not** allowed to change the answer, and that is a deliberate
  /// swallow with a reason rather than a blanket one:
  ///
  /// - The fate of the sale is already decided. Reporting "unknown" for a sale the server
  ///   recorded is what sends the cashier to ring it up a second time by hand, which is a
  ///   genuine double charge — the app's own retry is safe, a manual re-ring is not.
  /// - The row left behind resolves itself. The drain loop sends it under the same `client_ref`,
  ///   and the server answers with the same sale, which the loop then removes; a refusal is
  ///   parked as `failed` for the cashier to discard.
  ///
  /// So the leftover costs a row in the panel, and never money.
  Future<void> _clear(String ref) async {
    try {
      await _queue.remove(ref);
    } on PendingSaleStoreException {
      // See above: the row is left for the drain loop, and the outcome stands.
    }
  }
}
