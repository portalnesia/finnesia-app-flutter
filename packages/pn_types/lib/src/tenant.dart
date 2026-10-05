/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:freezed_annotation/freezed_annotation.dart';

import 'file_ref.dart';

part 'tenant.freezed.dart';
part 'tenant.g.dart';

/// One cashier's membership in one company, as the login response returns it.
///
/// Ported from `UserCompany` in `finnesia-monorepo/packages/types/src/tenant.ts`, which
/// also carries the membership's `company`, `role_model`, `branch`, `warehouse` and `outlet`
/// relations and its timestamps. `.claude/rules/project.md` §2.2 says to port **partially**:
/// only what the POS reads. That is the identifying ids and the role, which is what
/// `usePermission` and `resolvePermissionViewer` look at, plus [company] — the header's
/// avatar needs its name and logo together, and the till does not fetch per render.
/// `role_model`, `branch`, `warehouse` and `outlet` are still dropped when the login
/// response is parsed, so a session saved by this build does not carry them; a later change
/// that needs `role_model.allowed_scope` will have to add it here and let the next login
/// refill it.
@freezed
abstract class UserCompany with _$UserCompany {
  const factory UserCompany({
    required String id,
    @JsonKey(name: 'user_id') required String userId,

    /// The company this membership belongs to. The till compares it with the company
    /// pairing locked (`session.companyId`) to pick the membership that counts.
    @JsonKey(name: 'company_id') required String companyId,
    @JsonKey(name: 'role_id') String? roleId,
    @JsonKey(name: 'branch_id') String? branchId,
    @JsonKey(name: 'warehouse_id') String? warehouseId,
    @JsonKey(name: 'outlet_id') String? outletId,

    /// A plain string, not an enum: the source's union ends in `| string` because tenants
    /// can define their own roles, and an enum would throw on the first one.
    required String role,
    @JsonKey(name: 'is_active') required bool isActive,

    /// The company this membership belongs to, reduced to what the header shows.
    ///
    /// Not `required` because the source declares it `json:"company,omitempty"` and a login
    /// can legitimately return a membership without the company attached.
    CompanyRef? company,
  }) = _UserCompany;

  factory UserCompany.fromJson(Map<String, dynamic> json) =>
      _$UserCompanyFromJson(json);
}

/// The part of a company the till names on screen: its name, and its logo.
@freezed
abstract class CompanyRef with _$CompanyRef {
  const factory CompanyRef({@Default('') String name, FileRef? logo}) =
      _CompanyRef;

  factory CompanyRef.fromJson(Map<String, dynamic> json) =>
      _$CompanyRefFromJson(json);
}

/// The outlet a device was paired to, as the Menu names it.
///
/// Ported from `Outlet` in `finnesia-monorepo/packages/types/src/tenant.ts`, partially
/// (`project.md` §2.2). The session stores the outlet's id, not its name, and a cashier
/// checking where the tablet is pointed should not be shown a ULID (`menu-page.tsx`). The
/// rest of the record (branch, warehouses, per-outlet cash account, quota flags) is not read
/// by any till screen.
@freezed
abstract class Outlet with _$Outlet {
  const factory Outlet({required String id, required String name}) = _Outlet;

  factory Outlet.fromJson(Map<String, dynamic> json) => _$OutletFromJson(json);
}
