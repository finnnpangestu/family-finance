import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../domain/backup_models.dart';

final backupLocalDataSourceProvider = Provider<BackupLocalDataSource>(
  (ref) => BackupLocalDataSource(ref.watch(appDatabaseProvider)),
);

// Serializes the whole database to JSON and restores it atomically.
class BackupLocalDataSource {
  const BackupLocalDataSource(this._appDatabase);

  static const String appId = 'ff.family_finance';

  // Whitelisted columns per table; anything else in a file is ignored.
  static const Map<String, List<String>> columns = AppDatabase.profileColumns;

  final AppDatabase _appDatabase;

  Future<List<int>> exportBytes({DateTime? now}) async {
    final Database db = await _appDatabase.database;
    final Map<String, Object?> tables = {};
    for (final String table in AppDatabase.tableNames) {
      tables[table] = await db.query(table, columns: columns[table]);
    }
    return utf8.encode(
      jsonEncode({
        'app': appId,
        'schemaVersion': AppDatabase.schemaVersion,
        'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
        'tables': tables,
      }),
    );
  }

  // Validates everything before touching the DB; the transaction rolls back
  // on any insert failure so local data is never half-replaced.
  Future<void> restoreBytes(List<int> bytes) async {
    final Map<String, List<Map<String, Object?>>> tables = parse(bytes);
    final Database db = await _appDatabase.database;
    await db.transaction((txn) async {
      final Batch batch = txn.batch();
      for (final String table in AppDatabase.tableNames.reversed) {
        batch.delete(table);
      }
      for (final String table in AppDatabase.tableNames) {
        for (final Map<String, Object?> row in tables[table]!) {
          batch.insert(table, row);
        }
      }
      await batch.commit(noResult: true);
      // Backups older than v3 carry no categories: rebuild the chip list.
      await AppDatabase.seedDefaultCategories(txn);
      await AppDatabase.syncCategoriesFromTransactions(txn);
    });
  }

  static Map<String, List<Map<String, Object?>>> parse(List<int> bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException catch (e) {
      throw BackupException(BackupFailureKind.invalidFile, e.message);
    }
    if (decoded is! Map<String, Object?> || decoded['app'] != appId) {
      throw const BackupException(
        BackupFailureKind.invalidFile,
        'not an FF backup',
      );
    }
    final Object? version = decoded['schemaVersion'];
    if (version is! int || version > AppDatabase.schemaVersion) {
      throw BackupException(BackupFailureKind.invalidFile, 'schema $version');
    }
    final Object? rawTables = decoded['tables'];
    if (rawTables is! Map<String, Object?>) {
      throw const BackupException(
        BackupFailureKind.invalidFile,
        'missing tables',
      );
    }

    return {
      for (final String table in AppDatabase.tableNames)
        table: _parseRows(table, rawTables[table]),
    };
  }

  static List<Map<String, Object?>> _parseRows(String table, Object? raw) {
    if (raw == null) return const [];
    if (raw is! List<Object?>) {
      throw BackupException(
        BackupFailureKind.invalidFile,
        '$table is not a list',
      );
    }
    final List<String> allowed = columns[table]!;
    return [
      for (final Object? row in raw)
        if (row is Map<String, Object?>)
          {
            for (final String c in allowed)
              if (row.containsKey(c)) c: row[c],
          }
        else
          throw BackupException(BackupFailureKind.invalidFile, '$table row'),
    ];
  }
}
