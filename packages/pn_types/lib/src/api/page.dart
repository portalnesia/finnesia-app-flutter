/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// One page of a list, and where the next one starts.
///
/// Named for what it is because `Page` is already a Flutter class, and this package's
/// consumers import both.
class CursorPage<T> {
  const CursorPage({required this.items, this.nextCursor});

  final List<T> items;

  /// The cursor to send back for the next page, or `null` when this is the last one.
  final String? nextCursor;
}
