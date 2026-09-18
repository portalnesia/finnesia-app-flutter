/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/auth.dart';
import 'package:pn_types/src/api/endpoints/pos.dart';
import 'package:pn_types/src/api/endpoints/tenant.dart';
import 'package:pn_types/src/pos_shift.dart';
import 'package:pn_types/src/session.dart';
import 'package:pn_types/src/tenant.dart';
import 'package:pos/state/loadable.dart';

/// What the Menu reads from the server: the outlet this tablet is pointed at, and the drawer
/// that is open.
///
/// Named `MenuScreenController` and not `MenuController` because Flutter has one of those
/// already (`raw_menu_anchor.dart`, for anchoring a menu to a widget). Hiding the framework's
/// would work and would leave every later reader of this file to work out which one is in scope.
///
/// Ported from `menu-page.tsx`, where the two live in separate `useQuery`s. They stay separate
/// here for the reason the source keeps them apart: the outlet name is a courtesy so a cashier
/// checking where the tablet points is not shown a ULID, and the shift is what they came for.
/// One failing must not blank the other.
///
/// **Nothing here signs anyone out.** That is `SessionHolder.clearToken()`, and the screen calls
/// it directly: a controller that owned it would have to be reachable from a screen that is
/// about to be destroyed by it.
class MenuScreenController extends ChangeNotifier {
  MenuScreenController({required this._client, required this.outletId});

  final ApiClient _client;

  /// The outlet pairing locked. Empty when the session carries none, which asks for nothing.
  final String outletId;

  /// The outlet's name, for the one row that would otherwise print a ULID.
  ///
  /// Null when [outletId] is empty: a paired device always has one, but a session written by an
  /// older build may not, and `/outlets/` is not a request — it is a round trip that answers 404.
  late final outlet = Loadable<Outlet?>(() async {
    if (!_hasOutlet) return null;
    return TenantApi.outletsGet(_client, (id: outletId));
  });

  /// The drawer that is open, or null when none is. Null is an answer, not a failure.
  late final shift = Loadable<POSShift?>(() async {
    if (!_hasOutlet) return null;
    return PosApi.shiftsGetActive(_client, query: {'outlet_id': outletId});
  });

  /// Whether there is an outlet to ask about.
  ///
  /// Both reads are skipped without one, as the source does (`enabled: !!outletId`). Asking for
  /// the active shift without saying which outlet would let the server answer with another
  /// outlet's drawer, which is worse than showing nothing.
  bool get _hasOutlet => outletId.isNotEmpty;

  /// Reads both rows, or reads them again.
  ///
  /// `Future.wait` and not a record's `.wait`: the record form reports a failure as a
  /// `ParallelWaitError`, which is neither an `ApiError` nor a `TransportException` and would
  /// read as a bug rather than as a failed read (`shift_controller.dart`).
  Future<void> load() => Future.wait([outlet.load(), shift.load()]);

  /// Who is signed in, as the screen should show them.
  ///
  /// The session is the fast path and the answer in every ordinary case. It is not enough on a
  /// tablet that signed in through the browser: `/api/auth/mobile/poll` is registered without
  /// `RequireAuth` (it is rate-limited as a credential surface instead), so the handler has no
  /// `ctx.User` and `GetProfile` answers `&model.User{ID: userID}` — an id with an empty name and
  /// an empty email. Stored as-is, the account card has nothing to print and falls back to
  /// "Tidak diketahui" for a cashier who is signed in.
  ///
  /// Asking the server is what the source does, and for the same reason: rather than telling the
  /// cashier to sign out and back in to repair a stored record, the profile is fetched when the
  /// local copy cannot answer. One request, once, and only when it is needed.
  SessionUser? get profile => _profile ?? _sessionUser;

  SessionUser? _sessionUser;
  SessionUser? _profile;

  /// Completes [user] from the server if it cannot answer "which account is this?" itself.
  ///
  /// Never throws: a profile that could not be read leaves the cashier with what the session has,
  /// which is what they would have had without this. A screen that dies because a courtesy row
  /// could not be filled is worse than the row saying "Tidak diketahui".
  Future<void> loadProfile(SessionUser? user) async {
    _sessionUser = user;
    // Nobody signed in, or the stored profile already names them. Either name or email answers
    // the card's only question.
    if (user == null) return;
    final hasIdentity = _text(user.name) != null || _text(user.email) != null;
    if (hasIdentity) return;

    try {
      final data = await AuthApi.me(_client);
      if (data is! Map<String, dynamic>) return;
      final fetched = _readUser(data['user']);
      if (fetched == null) return;
      _profile = fetched;
      notifyListeners();
    } on Object {
      // Left as it is. The card says "Tidak diketahui", which is the truth about what the app
      // knows, and everything else on the screen still works.
    }
  }

  @override
  void dispose() {
    outlet.dispose();
    shift.dispose();
    super.dispose();
  }
}

/// A trimmed, non-empty string, or nothing at all.
///
/// Same rule as the login's own reader (`native_login.dart`): `users.name` is NOT NULL but not
/// non-empty, so an OIDC-provisioned profile can arrive as `""`. Read as present, it would print
/// a blank where the email should have been.
String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// The profile as `/api/auth/me` sends it, or null when the payload is not one.
SessionUser? _readUser(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final id = value['id'];
  if (id is! String || id.isEmpty) return null;
  return SessionUser(
    id: id,
    name: _text(value['name']),
    email: _text(value['email']),
  );
}
