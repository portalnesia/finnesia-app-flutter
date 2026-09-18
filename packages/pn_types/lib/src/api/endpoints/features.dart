/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import '../endpoint.dart';
import '../parsers.dart';

/// `finnesia-monorepo/packages/shared/src/api/all-endpoints/features.ts`
abstract final class FeaturesApi {
  // untyped: CompanyFeature is not ported yet
  static final company = ReadEndpoint<Object?>(
    '/api/v1/company-features',
    parseRaw,
  );
}
