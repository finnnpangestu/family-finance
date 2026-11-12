import 'package:ff/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Fresh in-memory database per test, running on the desktop FFI driver.
AppDatabase createTestDatabase() {
  sqfliteFfiInit();
  return AppDatabase(
    factory: databaseFactoryFfiNoIsolate,
    path: inMemoryDatabasePath,
  );
}
