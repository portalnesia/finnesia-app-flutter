/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import '../endpoint.dart';
import '../parsers.dart';

/// `finnesia-monorepo/packages/shared/src/api/all-endpoints/auth.ts`
abstract final class AuthApi {
  // untyped: AuthMeResponse is not ported yet
  static final me = ReadEndpoint<Object?>('/api/auth/me', parseRaw);
}
