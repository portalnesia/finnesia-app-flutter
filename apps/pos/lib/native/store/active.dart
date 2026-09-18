/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/store_port.dart';
import 'package:pos/native/store/store_secure.dart';

/// Where the session, the device identity and the pending login live: the Keystore-backed
/// store, because the session holds a bearer token.
StorePort get store => _store;
StorePort _store = SecureStore();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setStore(StorePort impl) => _store = impl;
