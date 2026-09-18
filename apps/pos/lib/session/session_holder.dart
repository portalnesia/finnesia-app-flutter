/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:pn_types/src/native/store_port.dart';
import 'package:pn_types/src/session.dart';

/// Where the session lives in the local store.
const sessionKey = 'session';

/// Whether [session] ends within [window] of [now], an end that has already passed included.
///
/// A session that says nothing about its end, or something that is not a date, does not: there
/// is nothing to compare, and guessing would refresh on every request.
bool endsWithin(PosSession session, Duration window, DateTime now) {
  final end = DateTime.tryParse(session.expiresAt ?? '');
  return end != null && end.difference(now) < window;
}

class SessionHolder {
  SessionHolder(this._store);

  final StorePort _store;
  PosSession? _current;
  final _listeners = <void Function(PosSession?)>{};

  /// Notifies when the session changes, so the UI can mirror it.
  ///
  /// The holder is read synchronously by the transport and cannot be a widget, so whatever
  /// mirrors it into UI state has no way to notice a write that did not come from itself.
  /// Pairing is exactly that: it saves the session from the pairing screen, and without this
  /// the UI keeps serving "not paired" and sends a freshly paired device straight back to
  /// the pairing screen.
  ///
  /// Subscribing does not replay the current value — read [current] for that. Returns the
  /// function that unsubscribes.
  void Function() subscribe(void Function(PosSession?) listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  // Iterates a copy: JavaScript's Set tolerates a delete during iteration, Dart's throws,
  // and a listener that unsubscribes when its notification arrives is ordinary.
  void _notify() {
    for (final l in List.of(_listeners)) {
      l(_current);
    }
  }

  // The order is the source's: the cache first (the transport reads it on the very next
  // request), then the listeners, then the store. `finally` because a listener that throws is
  // a bug in the UI, and it must not cost the cashier the pairing — the session is persisted
  // either way, and the error still reaches the caller.
  Future<void> _commit(
    PosSession? next,
    Future<void> Function() persist,
  ) async {
    _current = next;
    try {
      _notify();
    } finally {
      await persist();
    }
  }

  PosSession? get current => _current;

  /// Reads the persisted session into the cache. Awaited once at bootstrap.
  ///
  /// What is stored but no longer a session — not JSON, or JSON of the wrong shape — reads as
  /// no session, and does not throw: `main` awaits this before anything renders, and an app
  /// that dies here shows nothing at all, which is worse than an unpaired device that at
  /// least says so. (In the source that contract lived in the browser store.)
  ///
  /// A failing *storage* is different, and is not swallowed: [StoreException] passes through
  /// and the session in memory is left alone. Reading a transient failure as "not paired"
  /// could send a cashier to re-pair a device that is in fact paired.
  Future<PosSession?> hydrate() async {
    final raw = await _store.read(sessionKey);
    _current = raw == null ? null : _decode(raw);
    _notify();
    return _current;
  }

  PosSession? _decode(String raw) {
    try {
      return PosSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> save(PosSession next) async {
    await _commit(
      next,
      () => _store.write(sessionKey, jsonEncode(next.toJson())),
    );
  }

  Future<void> clear() async {
    await _commit(null, () => _store.remove(sessionKey));
  }

  /// Signs the cashier out without unpairing the device.
  ///
  /// Pairing belongs to the tablet, not to the person standing in front of it: a shift
  /// change must not send a device that is already registered to an outlet back to the
  /// pairing screen. Only the credential goes — including the refresh token, which would
  /// otherwise let a signed-out device renew itself silently — while `baseUrl` and the outlet
  /// it resolved to stay put. The memberships go with the credential: they describe who this
  /// cashier is inside the company, and a device with no cashier must not keep answering
  /// permission questions with the previous one's role.
  ///
  /// The device token stays: it identifies the tablet, not the cashier, and the server writes
  /// presence from it on every request. Dropping it here would blank the device in the
  /// dashboard until the next cashier signed in.
  Future<void> clearToken() async {
    final current = _current;
    if (current == null) return;
    await save(
      current.copyWith(
        sessionToken: '',
        sessionRefreshToken: null,
        expiresAt: null,
        user: null,
        companies: null,
      ),
    );
  }

  /// Records that the server no longer knows this tablet, so the gate sends it back to pairing.
  ///
  /// Called when the server answers `pos_device_unregistered` — the device was deleted from the
  /// dashboard, or its token no longer resolves. The pairing is over: the device token is gone
  /// for good (the server stores only a hash) and the branding belonged to the tenant the device
  /// was paired to. Both are cleared.
  ///
  /// **The cashier's login stays.** The contract is explicit that this is not a sign-out: the
  /// cashier is still signed in, and once the tablet is paired again they carry on without
  /// logging in. A shift that was open on the server is not closed by deleting a device, and the
  /// same cashier can close it from the web app.
  ///
  /// A [StoreException] is not swallowed. A revocation that could not be persisted would be
  /// forgotten at the next launch, and the tablet would carry on transacting against a registry
  /// entry that no longer exists — the exact failure this exists to prevent.
  Future<void> unregisterDevice() async {
    final current = _current;
    if (current == null) return;
    await save(
      current.copyWith(deviceRevoked: true, deviceToken: null, branding: null),
    );
  }
}
