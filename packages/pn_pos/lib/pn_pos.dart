/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

/// Pure POS logic: cart maths, tender, shift rules, ESC/POS bytes.
///
/// The Dart counterpart of `finnesia-monorepo/packages/shared/src/pos/`. Nothing
/// has been ported into it yet.
///
/// This package must never import `flutter`. That constraint is what lets the
/// money logic be tested with `dart test` rather than `flutter test`
/// (`.claude/rules/architecture.md` §3), and it is checked in CI with:
///
/// ```
/// grep -rn "^import 'package:flutter" packages/pn_pos/lib/
/// ```
library;
