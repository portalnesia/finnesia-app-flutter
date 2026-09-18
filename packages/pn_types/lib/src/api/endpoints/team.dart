/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import '../endpoint.dart';
import '../parsers.dart';

/// `finnesia-monorepo/packages/shared/src/api/all-endpoints/team.ts`: only the one endpoint
/// the POS uses.
///
/// No screen calls it directly. `usePermission`, in `@pn/shared`, calls it from inside the
/// hook — which is why a list of the POS's endpoints built by searching the app's own `src`
/// missed it (`api-client/README.md` §3, `ui/findings.md` F1).
abstract final class TeamApi {
  /// The permission codes the signed-in cashier holds in the paired company.
  ///
  /// An owner or superadmin gets `["*"]`, which means every permission. `Permissions` in
  /// `pn_pos` reads it.
  static final permissionsMy = ReadEndpoint<List<String>>(
    '/api/v1/team/my-permissions',
    parseStrings,
  );
}
