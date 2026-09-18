/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pos/native/hold/hold_sqlite.dart';
import 'package:pos/native/queue/pending_sale_sqlite.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The one SQLite database of the app.
///
/// SQLite and not `shared_preferences`, for the reason `project.md` §5 gives: what lives here is a
/// sale in progress, and preferences can be cleared by the system. Each store that keeps its data
/// here creates its own table in [_create] and does not open a database of its own.
///
/// **There is no migration yet, and that is deliberate.** Nothing has been released, so no tablet
/// in the field holds a file older than the current schema; a development tablet that does is
/// wiped (Android: clear app data; Windows: delete `finnesia_pos.db`), and a missing table fails
/// loudly rather than quietly. **From the first release onward that stops being true**: every
/// schema change then needs an `onUpgrade` and a test that opens a file of the previous version
/// with data in it, because the queue holds money that was already taken.
///
/// **Where the file goes is one rule for every platform: the application support directory.** That
/// is where the other plugins already keep their files on Windows
/// (`%APPDATA%\<company>\<product>\`, taken from `Runner.rc`), so this file lives beside the
/// session and the preferences and follows them if the app is renamed. On Android that directory
/// is inside the app's private storage, like `shared_prefs/` where the session and the preferences
/// are kept; `allowBackup` is off, so none of it leaves the device.
///
/// The factory is `sqflite`'s on Android, and `sqflite_common_ffi`'s on Windows, because `sqflite`
/// itself has no Windows implementation. Windows is not a supported target yet
/// (`.claude/rules/windows.md`); this only makes the store work there.
///
/// [factory], [windows] and [supportDirectory] are for tests: they pass SQLite through FFI, say
/// which platform to behave as, and give a directory of their own. [path] is for tests that want
/// SQLite in memory.
Future<Database> openAppDatabase({
  DatabaseFactory? factory,
  String? path,
  bool? windows,
  Future<Directory> Function()? supportDirectory,
}) async {
  var opener = factory;
  if (opener == null) {
    if (windows ?? Platform.isWindows) {
      sqfliteFfiInit();
      opener = databaseFactoryFfi;
    } else {
      // Named, not the global `databaseFactory`: that one is only set when the plugin has
      // registered, and throws a StateError before it has.
      opener = databaseFactorySqflitePlugin;
    }
  }
  return opener.openDatabase(
    path ?? await _fileInSupportDirectory(supportDirectory),
    options: OpenDatabaseOptions(
      version: _version,
      onCreate: (db, version) => _create(db),
    ),
  );
}

Future<String> _fileInSupportDirectory(
  Future<Directory> Function()? supportDirectory,
) async {
  final directory =
      await (supportDirectory ?? getApplicationSupportDirectory)();
  // The plugin creates it, and a test's directory may not exist yet: opening a file in a folder
  // that is not there fails in a way that reads like a corrupt database.
  await directory.create(recursive: true);
  return '${directory.path}/finnesia_pos.db';
}

/// Bumped with every migration. Version 1 is the held orders and the pending-sale queue.
const _version = 1;

Future<void> _create(Database db) async {
  await SqliteHoldOrderStore.createTable(db);
  await SqlitePendingSaleStore.createTable(db);
}
