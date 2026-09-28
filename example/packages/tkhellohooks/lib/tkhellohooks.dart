/// tkhellohooks: tkhello plus the sqlite version through sqflite_common_ffi,
/// whose sqlite3 dependency has a build hook.
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// tkhellohooks package version (keep in sync with pubspec.yaml).
const tkhellohooksVersion = '1.0.0';

/// The sqlite version, from an in-memory database.
Future<String> getSqliteVersion() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  try {
    final rows = await db.rawQuery('select sqlite_version()');
    return rows.first.values.first.toString();
  } finally {
    await db.close();
  }
}
