/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

// The `parse` half of an endpoint: what to make of the `data` the client hands over.
//
// Each helper casts instead of validating, and a cast that fails is a TypeError.
// `ApiClient.request` translates TypeError, FormatException and ArgumentError into an
// ApiError, so a payload that no longer fits the model reaches the caller as an error it
// can show, not as a crash. Anything a `fromJson` throws for a wrong shape is one of those.

/// One model from a JSON object.
T Function(Object? data) parseObject<T>(
  T Function(Map<String, dynamic> json) from,
) =>
    (data) => from(data as Map<String, dynamic>);

/// A model per element of a JSON array, in order.
List<T> Function(Object? data) parseList<T>(
  T Function(Map<String, dynamic> json) from,
) =>
    (data) => [
      for (final e in data as List<Object?>) from(e as Map<String, dynamic>),
    ];

/// Like [parseObject], but `null` is an answer rather than a malformed response
/// (`pos.shifts.getActive` says null when no shift is open).
T? Function(Object? data) parseOrNull<T>(
  T Function(Map<String, dynamic> json) from,
) =>
    (data) => data == null ? null : from(data as Map<String, dynamic>);

/// A JSON array of strings, where `null` means none.
///
/// A Go nil slice marshals to `null`, not `[]`, so an endpoint whose handler can return one
/// (`GET /team/my-permissions`) would otherwise fail for the user who has no permissions.
/// Each element is cast as it is read: `List.cast` is lazy and would let a wrong type through
/// to fail at its first use, far from the response that carried it.
List<String> parseStrings(Object? data) => [
  for (final e in (data as List<Object?>?) ?? const <Object?>[]) e as String,
];

/// Product id to quantity on hand, from `GET /api/v1/pos/stock`.
Map<String, num> parseStock(Object? data) => {
  for (final MapEntry(:key, :value) in (data as Map<String, dynamic>).entries)
    key: value as num,
};

/// For an endpoint that answers with nothing worth reading (`r: null` in the source).
void parseNothing(Object? data) {}

/// The data, untouched — for an endpoint whose model is not ported yet.
///
/// Using it is a marker, not a design: the caller gets `Object?` and has to cast, which is
/// exactly what a model exists to prevent. Replace it with `parseObject`/`parseList` in the
/// same change that ports the model.
Object? parseRaw(Object? data) => data;
