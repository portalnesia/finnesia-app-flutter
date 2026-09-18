/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_pending_sale_store.dart';
import 'package:pos/native/db/active.dart';
import 'package:pos/native/queue/pending_sale_sqlite.dart';

/// The queue for [companyId], over the app's one database.
///
/// A factory rather than a getter, because the store is bound to a tenant and the tenant is only
/// known once the device is paired (`plan/offline-queue/README.md` §4.1). A store bound to the
/// wrong company would read its own queue as **empty** — indistinguishable from "everything has
/// been sent", which is the failure the binding exists to prevent.
PendingSaleStore pendingSaleStoreFor(String companyId) =>
    SqlitePendingSaleStore(openAppDbOnce, companyId: companyId);
