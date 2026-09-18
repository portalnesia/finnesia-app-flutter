/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Ported from `HttpMethod` in `finnesia-monorepo/packages/shared/src/api/types.ts`:
/// `'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'`.
///
/// An enum, so an endpoint registered with a method that does not exist is a compile
/// error rather than a request the server never routes.
enum HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE');

  const HttpMethod(this.wire);

  /// The exact verb for the request line.
  final String wire;
}
