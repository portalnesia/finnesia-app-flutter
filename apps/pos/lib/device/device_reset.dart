/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_hold_store.dart';
import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pn_types/src/api/http_method.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/native/analytics_port.dart';
import 'package:pn_types/src/native/public_http_port.dart';
import 'package:pos/session/session_holder.dart';

/// Where the device tells the server to drop it. Public on purpose: the only credential is the
/// device token, so a tablet with nobody signed in can still release itself
/// (`plan/pos-device-registry/01-kontrak-aplikasi-android.md` §3.4).
const deviceResetPath = '/api/v1/pos/devices/me';

/// Everything a device reset touches, injected so it can be tested without a platform plugin or
/// a network (`.claude/rules/testing.md` §4).
///
/// [holdStore] is here because what is parked on the tablet goes with the pairing: see
/// [resetDevice].
typedef DeviceResetDeps = ({
  PublicHttpPort http,
  SessionHolder session,
  HoldOrderStore holdStore,
  PendingSaleStore pendingSaleStore,
  AnalyticsPort analytics,
});

/// What a reset did about the server.
enum DeviceResetOutcome {
  /// The server dropped the row, or had already dropped it. Nothing left to do.
  done,

  /// The tablet could not reach the server, or the server refused for a reason that is not
  /// "already gone". The pairing is released locally either way, but the row may still exist,
  /// and the cashier is told so rather than left believing the dashboard is clean.
  serverFailed,

  /// The offline queue is not known to be empty — a sale is still on it, whichever outlet or
  /// cashier it belongs to, or it could not be read at all. Nothing was touched: not the
  /// session, not the held baskets (`plan/offline-queue/README.md` §6, `project.md` §5).
  queueNotEmpty,
}

/// Releases this tablet: tells the server to delete the device row, then unpairs locally.
///
/// The order is the whole point. `X-Device-Token` is what authenticates the call, so the token
/// has to still be in the session when the request goes out — clearing first would leave the row
/// behind with nothing able to identify it, which is the opposite of what the cashier asked for.
///
/// The session is cleared in **every** outcome, including a failure. A cashier who asked to
/// release the tablet must not be left holding a device they can no longer use: the pairing is
/// theirs to end, and a tablet stuck on the login screen can only be recovered by the admin who
/// could already delete the row. What the outcome decides is whether they are told the server
/// may still list it.
///
/// Every basket parked on the tablet goes with the pairing, whichever outlet it belongs to
/// (owner's decision, 2026-09-21). They are not money received, but they hold a tenant's customers
/// and orders: a tablet released from its outlet, or paired to another tenant, must not carry them
/// on its disk. Baskets from an earlier pairing are hidden by the outlet lock, and would have stayed
/// for ever.
///
/// A [StoreException] from the clear is not swallowed. A pairing that could not be removed would
/// come back at the next launch, and the tablet would look paired to an outlet whose server row
/// is gone.
Future<DeviceResetOutcome> resetDevice(DeviceResetDeps deps) async {
  // Before anything else is touched, including the held baskets below: money already taken on
  // this tablet, for any outlet and any cashier, must not be reset out from under the cashier
  // who has not sent or discarded it yet.
  if (!await _queueIsEmpty(deps.pendingSaleStore)) {
    await deps.analytics.logEvent(
      'device_reset_blocked',
      parameters: {'reason': 'queue_not_empty'},
    );
    return DeviceResetOutcome.queueNotEmpty;
  }

  final session = deps.session.current;
  // Nothing paired, nothing to release — and nothing to tell the server about.
  if (session == null || session.baseUrl.isEmpty) {
    await _unpair(deps);
    await deps.analytics.logEvent('device_reset');
    return DeviceResetOutcome.done;
  }

  final token = session.deviceToken ?? '';
  // A device paired before the registry has no token, so it was never in the registry: there is
  // no row for this call to delete, and sending the request without the header would only get a
  // 401 back. Clearing locally is the whole of the work.
  if (token.isEmpty) {
    await _unpair(deps);
    await deps.analytics.logEvent('device_reset');
    return DeviceResetOutcome.done;
  }

  final outcome = await _tellServer(deps.http, session.baseUrl, token);

  await _unpair(deps);
  // Logged for both outcomes: the tablet is reset locally either way. `serverFailed` only means
  // the row may still exist on the dashboard, not that nothing happened here.
  await deps.analytics.logEvent('device_reset');
  return outcome;
}

/// Asks the server to drop this device, and says what came back.
///
/// Split out so the request's own `try` cannot be confused with the local clear that follows it:
/// the clear runs in every outcome, and mixing the two in one block is how a failure to reach the
/// server would leave the pairing in place.
Future<DeviceResetOutcome> _tellServer(
  PublicHttpPort http,
  String baseUrl,
  String token,
) async {
  try {
    final response = await http.send(
      baseUrl,
      TransportRequest(
        method: HttpMethod.delete,
        path: deviceResetPath,
        // The device token is the only credential this endpoint wants: it is not a session
        // call, so the bearer is deliberately not sent. No `Content-Type` either — there is no
        // body, and a header promising one is a lie the server may act on.
        headers: {'Accept': 'application/json', 'X-Device-Token': token},
      ),
    );
    // 401 is the endpoint's single meaning for "this device is not registered", which from the
    // cashier's side is the request already being true — the contract calls it idempotent. Not
    // routed through `isDeviceUnregisteredError`: that detector exists for the shared POS chain,
    // where a 401 has several meanings and the status alone cannot be trusted.
    return response.ok || response.status == 401
        ? DeviceResetOutcome.done
        : DeviceResetOutcome.serverFailed;
  } on TransportException {
    return DeviceResetOutcome.serverFailed;
  }
}

/// Whether the offline queue has nothing left on it — any outlet, any cashier, any status.
///
/// An unreadable queue is never treated as empty (`pos_pending_sale_store.dart`): a reset must
/// not proceed over a queue it cannot prove is clear.
Future<bool> _queueIsEmpty(PendingSaleStore store) async {
  try {
    return await store.count(status: null) == 0;
  } on PendingSaleStoreException {
    return false;
  }
}

/// Ends the pairing, and empties what belonged to it. The baskets go only after the pairing did: a
/// clear that throws leaves the tablet paired, and a paired tablet keeps its baskets.
///
/// The hold store's own contract swallows a failed write, so a basket that could not be deleted is
/// not reported; nothing here can tell.
Future<void> _unpair(DeviceResetDeps deps) async {
  await deps.session.clear();
  await deps.holdStore.writeAll(const []);
}
