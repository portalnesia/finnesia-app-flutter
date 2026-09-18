/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error.freezed.dart';
part 'api_error.g.dart';

/// The key for "this tablet is not registered".
const deviceUnregisteredKey = 'pos_device_unregistered';

/// The key for "this outlet has no room for another tablet".
const deviceLimitReachedKey = 'pos_device_limit_reached';

/// Whether a failed response says the server no longer knows this tablet: it was deleted from
/// the dashboard, or its device token does not resolve.
///
/// The caller's remedy is to pair again, so this is what cuts a deleted tablet off. Two
/// readings, in order:
///
/// 1. **`key`** — the contract (`plan/pos-device-registry/02-kebutuhan-error-key.md` §4.1).
/// 2. **`401` with code 137** — the fallback for a backend that does not send `key` yet. In the
///    POS chain that combination is emitted only by the device middleware, so it is correct;
///    but it rests on the routing table, not on a promise.
///
/// Takes the status and the parsed error rather than an [ApiError] because the transport has to
/// decide before the client has built one.
///
/// ponytail: drop the fallback once the backend sends `key` everywhere. Until then it is the only
/// thing that cuts a deleted tablet off against the deployed backend.
bool isDeviceUnregisteredError({
  required int status,
  required ApiErrorTypes? error,
}) {
  if (error?.key == deviceUnregisteredKey) return true;
  return error?.key == null && status == 401 && error?.code == 137;
}

/// Whether a failed response says the outlet has no room for another tablet.
///
/// **No fallback on purpose.** The backend answers `422` with code 720, and that same code covers
/// six unrelated Postgres conditions — including the unique-violation that a repeated fingerprint
/// produces. Guessing from status and code would tell a cashier the outlet is full when the real
/// problem is a duplicate device, and send them to the dashboard to delete a tablet for nothing.
/// Without `key`, this is simply not reported as a limit.
bool isDeviceLimitReachedError(ApiErrorTypes? error) =>
    error?.key == deviceLimitReachedKey;

/// The number of tablets an outlet allows, from the params the server sent with a
/// [deviceLimitReachedKey] error.
///
/// `null` when the server did not send it, so a caller falls back to its own wording rather than
/// printing a placeholder.
int? deviceLimitFrom(ApiErrorTypes? error) {
  final value = error?.params?['limit'];
  // JSON numbers arrive as `int` or `double` depending on whether they have a fraction, so
  // reading this as an `int` would throw on a value the server is entitled to send.
  return value is num ? value.toInt() : null;
}

/// The `error` object of a raw response body, or `null` when the body does not carry one.
///
/// [ApiClient] builds an [ApiError] for the authenticated path. The public calls — pairing,
/// device reset — read the body themselves, because they run before a session exists, and they
/// need the same parsing without an [ApiError] wrapped around it. One implementation so the two
/// cannot disagree about what a body means.
///
/// Deliberately tolerant: this runs in the code that handles failures, and a body that does not
/// fit must read as "no error object" rather than throw where the failure is being reported.
ApiErrorTypes? errorObjectOf(String? body) {
  if (body == null) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  final error = decoded['error'];
  if (error is! Map<String, dynamic>) return null;
  try {
    return ApiErrorTypes.fromJson(error);
  } on TypeError {
    return null;
  }
}

/// One entry of [ApiErrorTypes.details].
///
/// Ported from `ApiErrorDetail` in `finnesia-monorepo/packages/shared/src/api/types.ts`.
@freezed
abstract class ApiErrorDetail with _$ApiErrorDetail {
  const factory ApiErrorDetail({
    /// The form field the message belongs to. Unset when the error names a record.
    String? field,

    /// The document the detail points at, when the error names a blocking record rather
    /// than a form field. A `document_settled` rejection lists the payments and returns
    /// that already settled the document, so the message carries a document number the
    /// user can open. Plain validation errors leave it unset and stay plain text.
    String? id,
    required String message,
  }) = _ApiErrorDetail;

  factory ApiErrorDetail.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorDetailFromJson(json);
}

/// The `error` object of a failed response.
///
/// Ported from `ApiErrorTypes` in the same file. Every field is optional because the
/// backend fills only what applies — an empty object is a valid error body.
@freezed
abstract class ApiErrorTypes with _$ApiErrorTypes {
  const factory ApiErrorTypes({
    String? name,
    int? code,
    String? message,
    String? description,
    List<ApiErrorDetail>? details,

    /// The i18n key the server used to build [description], e.g. `pos_device_unregistered`.
    ///
    /// The one machine-readable part of an error. [code] cannot stand in for it: 422/720 is
    /// shared by the device limit and six unrelated Postgres conditions.
    ///
    /// Absent against a backend that predates it — see `plan/pos-device-registry/`
    /// `02-kebutuhan-error-key.md`.
    String? key,

    /// The values interpolated into [description], e.g. `{'limit': 10}`.
    Map<String, dynamic>? params,
  }) = _ApiErrorTypes;

  factory ApiErrorTypes.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorTypesFromJson(json);
}

/// A request that reached the server (or failed trying) and did not succeed.
///
/// Ported from `ApiError` in `finnesia-monorepo/packages/shared/src/api/error.ts`. Dart
/// has no `instanceof`-style static `is`; a plain `err is ApiError` does that job.
class ApiError implements Exception {
  ApiError(
    this.message, {
    this.status = 500,
    this.data,
    this.errorData,
    this.retryAfter,
  });

  final String message;
  final int status;

  /// The raw response body, when there was one.
  final Object? data;

  /// The body's `error` object, parsed.
  final ApiErrorTypes? errorData;

  /// Seconds to wait before retrying, from `Retry-After` on a 429.
  final int? retryAfter;

  /// True when the server rejected the request for exceeding a rate limit.
  static bool isRateLimit(Object? err) => err is ApiError && err.status == 429;

  /// True when the server no longer knows this tablet: it was deleted from the dashboard, or
  /// its device token does not resolve.
  ///
  /// See [isDeviceUnregisteredError] for the two readings, in order.
  static bool isDeviceUnregistered(Object? err) =>
      err is ApiError &&
      isDeviceUnregisteredError(status: err.status, error: err.errorData);

  /// True when the outlet already holds the maximum number of tablets, so this activation
  /// would exceed it.
  ///
  /// See [isDeviceLimitReachedError] for why there is no fallback.
  static bool isDeviceLimitReached(Object? err) =>
      err is ApiError && isDeviceLimitReachedError(err.errorData);

  // Status and message only. [data] is the raw response body and can hold customer
  // names and amounts; this string ends up in logs and crash reports.
  @override
  String toString() => 'ApiError($status): $message';
}

// JavaScript's `parseInt` skips leading whitespace and reads a numeric prefix, so
// `' 30'` and `'30abc'` are both 30 in the web app. `int.tryParse` is strict and would
// reject them, which would make the cashier's "wait N seconds" differ between clients.
final _intPrefix = RegExp(r'^\s*([+-]?\d+)');

/// Reads `Retry-After` (delta-seconds, RFC 6585) from a throttled response.
///
/// Ported from `parseRetryAfter` in `finnesia-monorepo/packages/shared/src/api/internal/
/// api.base.ts`. Only a 429 carries a meaningful value here; the same header on a 503
/// is ignored, as in the source. An HTTP-date is not parsed, also as in the source.
///
/// Returns `null` for a value too large for an `int` where JavaScript would return a
/// float that no retry timer could use.
int? parseRetryAfter({required int status, String? header}) {
  if (status != 429 || header == null) return null;
  final digits = _intPrefix.firstMatch(header)?.group(1);
  final seconds = digits == null ? null : int.tryParse(digits);
  return seconds != null && seconds >= 0 ? seconds : null;
}
