/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/pos.dart';

import 'pos_pending_sale.dart';
import 'pos_pending_sale_store.dart';

/// What a single send attempt came to.
///
/// A sealed type rather than a thrown exception, and that is a deliberate difference from the
/// source: `syncQueue` in
/// `finnesia-monorepo/apps/web/src/hooks/use-pos-sync.ts` catches whatever the fetch threw and
/// reads a `status` property off it. Dart has no such shape — an `ApiError` and a
/// `TransportException` are unrelated types — so the caller in `apps/pos` does the one thing it
/// knows how to do (ask the API) and answers with **what happened**, which is the only thing this
/// loop needs. It also makes the loop testable without a transport at all.
///
/// `.claude/rules/patterns.md` §2a.3: a union, not two nullable fields, so the caller cannot
/// forget one and there is no `!` on the money path.
sealed class SendOutcome {
  const SendOutcome();
}

/// The server recorded the sale.
final class SendSucceeded extends SendOutcome {
  const SendSucceeded();
}

/// The server understood the request and refused it.
///
/// [status] is what makes it final: a 4xx means replaying it verbatim can only fail again.
/// [message] is the server's own sentence, in the cashier's language, and it is what the panel
/// shows — what to fix is often something only the server knows (an unmapped tender account, a
/// deactivated product).
final class SendRefused extends SendOutcome {
  const SendRefused(this.status, this.message);

  final int status;
  final String message;
}

/// The server understood the request and blocked it on the state of the tenant or the outlet,
/// rather than on anything wrong with the sale.
///
/// A 402, or a 403 `outlet_inactive`. The distinction from [SendRefused] is the whole point:
/// parking one of these as `failed` would mark money the cashier has already taken as broken
/// for a reason the cashier cannot act on, and the block is **not permanent** — it clears when
/// the subscription is renewed or the outlet is reactivated, with no change to the sale.
///
/// So the entry stays `pending`, exactly like [SendUnreachable], and the pass stops: a block on
/// the tenant applies to every sale behind this one. [message] is the server's own sentence,
/// passed through unchanged, and it is what the panel shows while the sale waits.
///
/// The loop does **not** know what a 402 is: that classification belongs to the caller in
/// `apps/pos` (`queue_sync.dart`), which is the only place that sees an HTTP status at all.
final class SendBlocked extends SendOutcome {
  const SendBlocked(this.message);

  final String message;
}

/// Nobody knows whether the sale was recorded: no answer, a 5xx, or a 2xx this app could not
/// read.
///
/// Retrying is safe, and only because the retry carries the same `client_ref`: the server looks a
/// sale up by it before creating one.
final class SendUnreachable extends SendOutcome {
  const SendUnreachable();
}

/// The seam the drain loop calls to post one sale. Replaced in tests.
typedef SendPendingSale = Future<SendOutcome> Function(POSCheckoutDTO payload);

/// Sends the queued sales of one cashier, in the order they were rung up.
///
/// Ported from `syncQueue` in `finnesia-monorepo/apps/web/src/hooks/use-pos-sync.ts`, with the
/// order and decision rules kept exactly and the storage reshaped
/// (`plan/offline-queue/README.md` §5.1).
///
/// ## What happens to each sale
///
/// | Answer | What it does | Why |
/// | ------ | ------------ | --- |
/// | [SendSucceeded] | removes it, carries on | the `client_ref` is consumed, which is what stops a reconnect posting the same sale twice |
/// | [SendRefused] 4xx | marks it failed with the server's sentence, **carries on** | a refusal is final for that sale only; the next one can still succeed |
/// | [SendBlocked] | counts an attempt with the server's sentence, **stops the pass** | the tenant or outlet is blocked, not the sale; the sale is not wrong and the block lifts on its own, so parking it would strand money the cashier took |
/// | [SendRefused] 5xx / [SendUnreachable] | counts an attempt, **stops the pass** | the device is offline or the server is unwell, so everything behind it would fail the same way — and stopping keeps the rest in order |
///
/// ## Ownership
///
/// [cashierId] is **who typed the sale**, not who is sending it. The server attributes a sale to
/// whoever is authenticated at send time and does not accept a cashier id at all
/// (`findings.md` F4), so a sale rung up by one cashier and sent by another is recorded against
/// the sender — the wrong person, on a document that ends up in the books. D-Q1 therefore sends
/// only the sales the given cashier typed; the rest are skipped **without counting an attempt**,
/// because a sale that was not sent was not refused.
///
/// Passing no cashier sends everything, which is what a test wants and what a device with nobody
/// signed in can do.
///
/// ## Why I/O inside a loop is allowed here
///
/// `optimization.md` §1 forbids it; §1.1 allows it under a written exception, and this is that
/// exception (`README.md` §5.3):
///
/// - **Why:** the server has no batch checkout, and order matters — a sale has to land in the
///   shift that is open when it arrives.
/// - **Ceiling:** a pass costs **one** request that fails, because it stops at the first one, and
///   **one** read of the queue. Neither grows with the number of sales.
/// - **When to remove it:** if the server ever offers a batch checkout.
///
/// ## What it does not swallow
///
/// A storage failure **throws** rather than being logged and ignored — the opposite of the web
/// app, and the point of the whole port. That includes the worst case: a sale the server accepted
/// but the tablet could not remove. It is safe (the same `client_ref` answers with the same sale)
/// but it is **not** a clean pass, and telling the caller it was one is how a queue quietly stops
/// draining.
Future<void> syncQueue(
  PendingSaleStore store, {
  required SendPendingSale send,
  String? openShiftId,
  String? cashierId,
}) async {
  // One read for the whole pass, whatever the queue holds. A read per sale would be O(n) storage
  // work for a loop that is already O(n) requests.
  final pending = [
    for (final entry in await store.readAll())
      if (entry.status == PendingSaleStatus.pending)
        if (cashierId == null || entry.cashierId == cashierId) entry,
  ];

  for (final entry in pending) {
    final outcome = await send(
      toCheckoutPayload(entry, openShiftId: openShiftId),
    );
    switch (outcome) {
      case SendSucceeded():
        // Removing it is what stops a reconnect from posting the same sale a second time.
        await store.remove(entry.clientRef);
      case SendRefused(:final status, :final message):
        if (!isFinalError(status)) {
          // A 5xx may have committed before it failed, so the sale stays pending and the pass
          // stops: the sales behind it would fail the same way.
          await store.recordAttempt(entry.clientRef);
          return;
        }
        // Parked, not dropped: the cashier decides whether to retry it or to discard it
        // knowing the drawer will be short. The pass carries on — a refusal is final for that
        // sale only.
        await store.markFailed(entry.clientRef, message);
      case SendBlocked(:final message):
        // Not a refusal: the tenant or outlet is blocked, so this sale and every one behind it
        // would fail the same way. It stays `pending` with the server's sentence kept as the
        // reason, and the pass stops — the block lifts on its own and the next pass drains the
        // queue without the cashier doing anything.
        await store.recordAttempt(entry.clientRef, reason: message);
        return;
      case SendUnreachable():
        await store.recordAttempt(entry.clientRef);
        return;
    }
  }
}
