/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/session.dart';
import 'package:pn_types/src/tenant.dart';

/// Who the permission checks ask about: the paired company, and the cashier's membership in
/// it.
///
/// Ported from `PermissionViewer` in `@pn/shared/hooks/use-permission`, with one deliberate
/// difference: the company is its id, not `{ id }`. The object wrapper is the shape the React
/// hook wanted, and nothing here reads anything but the id.
typedef PermissionViewer = ({
  String? activeCompanyId,
  UserCompany? activeUserCompany,
});

/// Who the permission checks should ask about, derived from the session alone.
///
/// The active company is the one pairing locked, not the cashier's first membership: a
/// device bolted to one outlet must answer for that outlet's company even when the user
/// belongs to several. A membership from another company carries a role this till has no
/// business using, so it is not adopted. The till then falls back to the server's answer,
/// which is the safe direction for a permission question.
///
/// A membership is matched on its company only. Whether it is `is_active` is not looked at.
PermissionViewer resolvePermissionViewer(PosSession? session) {
  if (session == null) {
    return (activeCompanyId: null, activeUserCompany: null);
  }

  return (
    activeCompanyId: session.companyId,
    activeUserCompany: session.companies
        ?.where((company) => company.companyId == session.companyId)
        .firstOrNull,
  );
}
