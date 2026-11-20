/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:flutter/foundation.dart';
import 'package:pn_pos/src/permissions.dart';
import 'package:pn_pos/src/pos_quick_create.dart';
import 'package:pn_types/src/api/api_error.dart';
import 'package:pn_types/src/api/client.dart';
import 'package:pn_types/src/api/endpoints/team.dart';
import 'package:pn_types/src/api/transport.dart';
import 'package:pn_types/src/tenant.dart';

/// Whether the till offers "New product" and "Add customer" to the cashier signed in.
///
/// The rule is `canQuickAddProduct` / `canQuickAddCustomer` in `pn_pos`; this is the read that
/// feeds it. Asked once, when the till opens: the answer belongs to the session, and the buttons
/// are drawn from it for the whole shift.
///
/// **Nothing is offered until the answer is in, and nothing when it could not be read.** A button
/// that appears late is better than one the server refuses with a 403 (R-26), which is the
/// direction `Permissions.can` already takes.
class QuickCreateAccess extends ChangeNotifier {
  QuickCreateAccess({required this.client, required this.membership});

  final ApiClient client;

  /// The cashier's membership in the paired company (`resolvePermissionViewer`).
  final UserCompany? membership;

  List<String>? _granted;
  bool _disposed = false;

  Permissions get _permissions =>
      Permissions.of(membership: membership, granted: _granted);

  bool get canAddProduct => canQuickAddProduct(_permissions);

  bool get canAddCustomer => canQuickAddCustomer(_permissions);

  /// Reads what the server allows this cashier, unless they own the company and need no asking.
  Future<void> load() async {
    if (_permissions.isOwner) return;
    try {
      _granted = await TeamApi.permissionsMy(client);
    } on ApiError {
      // Left as "nothing granted": the till still sells, and the buttons stay away.
      return;
    } on TransportException {
      // Same: no answer means no shortcut, and the safe direction is to withhold it.
      return;
    }
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
