/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_hold_store.dart';
import 'package:pos/native/db/active.dart';
import 'package:pos/native/hold/hold_sqlite.dart';

/// Where parked baskets live: the app's SQLite database.
HoldOrderStore get holdStore => _holdStore;
HoldOrderStore _holdStore = SqliteHoldOrderStore(openAppDbOnce);

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setHoldStore(HoldOrderStore impl) => _holdStore = impl;
