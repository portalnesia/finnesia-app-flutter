/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/widgets.dart';
import 'package:pn_types/src/session.dart';
import 'package:pos/app/app_scope.dart';

enum GateDestination { pairing, login, till }

/// Where a device with [session] belongs.
///
/// No session is a device nobody has paired. A session with no token is a paired device with
/// nobody signed in (`SessionHolder.clearToken` leaves exactly that behind).
///
/// A revoked session is a device the server has deleted. It is checked first because it is the
/// only one of the three that the device cannot fix by itself: the pairing is over, and pairing
/// again is the only way forward. A device with no device token but not revoked is a different
/// thing — it was paired before the registry existed, or the backend does not send tokens yet —
/// and it still sells.
GateDestination gateDestination(PosSession? session) {
  if (session == null) return GateDestination.pairing;
  if (session.deviceRevoked) return GateDestination.pairing;
  if (session.sessionToken.isEmpty) return GateDestination.login;
  return GateDestination.till;
}

typedef GateScreens = ({
  WidgetBuilder pairing,
  WidgetBuilder login,
  WidgetBuilder till,
});

class Gate extends StatelessWidget {
  const Gate({super.key, required this.screens});

  final GateScreens screens;

  @override
  Widget build(BuildContext context) {
    // Read on every build: `AppScope` rebuilds this when the session changes, and the session
    // is the only thing that decides the screen.
    final session = AppScope.of(context).session.current;
    return switch (gateDestination(session)) {
      GateDestination.pairing => screens.pairing(context),
      GateDestination.login => screens.login(context),
      GateDestination.till => screens.till(context),
    };
  }
}
