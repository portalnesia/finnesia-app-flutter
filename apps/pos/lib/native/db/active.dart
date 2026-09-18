/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pos/native/db/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// The app's one database handle, opened when something first asks for it.
///
/// Shared by every store rather than opened per store: they are tables of the **same** file
/// (`.claude/rules/project.md` §5.1), and two handles on one SQLite file is how a write gets
/// locked out by a read. Opening lazily matters too — a device that never parks a basket and
/// never queues a sale never opens a database at all.
Future<Database> openAppDbOnce() =>
    _database ??= openAppDatabase().onError((error, stack) {
      // A failure is not remembered: the next attempt tries again, instead of the stores staying
      // empty for the rest of the session because the first attempt hit a locked file.
      _database = null;
      Error.throwWithStackTrace(error!, stack);
    });

Future<Database>? _database;
