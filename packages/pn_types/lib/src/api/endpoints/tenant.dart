/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import '../../tenant.dart';
import '../endpoint.dart';
import '../parsers.dart';

/// `finnesia-monorepo/packages/shared/src/api/all-endpoints/tenant.ts`
abstract final class TenantApi {
  static final outletsGet = ReadEndpointP<ById, Outlet>(
    (p) => '/api/v1/outlets/${Uri.encodeComponent(p.id)}',
    parseObject(Outlet.fromJson),
  );
}
