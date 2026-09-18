/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/tenant.dart';

/// What the signed-in cashier may do, as the till decides it.
///
/// The rule half of `usePermission` in
/// `finnesia-monorepo/packages/shared/src/hooks/use-permission.ts`. The hook also fetches the
/// list from the server (`team.permissions.my`); that is I/O and lives with the caller, and
/// the caller hands the result here. This is what remains once nothing is fetched: two
/// facts and a check, testable without a network.
///
/// Only [can] is ported. `canAny`, `canAll`, `isAdmin`, `activeRole` and `scope` are not read
/// by any POS screen.
final class Permissions {
  const Permissions._(this.isOwner, this._granted);

  /// [membership] is the cashier's membership in the paired company
  /// (`resolvePermissionViewer`); `null` when there is none.
  ///
  /// [granted] is what `team.permissions.my` answered, or `null` while it has not answered
  /// yet. The list is copied: a caller that later clears its own list must not change what
  /// this till allows.
  factory Permissions.of({
    required UserCompany? membership,
    Iterable<String>? granted,
  }) =>
      Permissions._(
        _isOwner(membership),
        Set<String>.unmodifiable(granted ?? const <String>[]),
      );

  /// The company's owner. An owner passes every check without asking the server.
  final bool isOwner;

  final Set<String> _granted;

  /// Whether [code] is allowed.
  ///
  /// An owner may do anything. So may anyone the server granted `'*'`, which is what it sends
  /// an owner or superadmin (`team_service.go`). Anything else needs the exact code.
  ///
  /// **Nothing is granted until the list has loaded**, so a permission question asked too
  /// early is answered no. That is the source's own behaviour (`permissions = data || []`)
  /// and the safe direction: a Pay button that appears late is better than one that appears
  /// and is withdrawn.
  bool can(String code) =>
      isOwner || _granted.contains('*') || _granted.contains(code);
}

/// `role === 'owner' || role_id === 'role_sys_owner'` in the hook. Strict equality, so
/// `'Owner'` is not an owner.
bool _isOwner(UserCompany? membership) {
  if (membership == null) return false;
  return membership.role == 'owner' || membership.roleId == 'role_sys_owner';
}
