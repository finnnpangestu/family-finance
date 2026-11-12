import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/database_providers.dart';
import '../database/tables/app_settings_table.dart';

// Always the device database, so settings survive switching accounts.
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SettingsStore(ref.watch(deviceDatabaseProvider)),
);

// Small key/value store on top of the app_settings table.
class SettingsStore {
  const SettingsStore(this._appDatabase);

  static const String currencyCode = 'currency_code';
  // Email of the Google account whose data profile is active.
  static const String activeAccount = 'active_account';
  // Its Google display name, cached for the dashboard greeting offline.
  static const String activeAccountName = 'active_account_name';
  // Reminders: "true"/"false" flags and the daily time as "HH:mm".
  static const String dailyReminderEnabled = 'daily_reminder_enabled';
  static const String dailyReminderTime = 'daily_reminder_time';
  static const String budgetAlertEnabled = 'budget_alert_enabled';

  final AppDatabase _appDatabase;

  Future<String?> read(String key) async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      AppSettingsTable.name,
      columns: [AppSettingsTable.value],
      where: '${AppSettingsTable.key} = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first[AppSettingsTable.value] as String?;
  }

  Future<void> write(String key, String value) async {
    final Database db = await _appDatabase.database;
    await db.insert(AppSettingsTable.name, {
      AppSettingsTable.key: key,
      AppSettingsTable.value: value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remove(String key) async {
    final Database db = await _appDatabase.database;
    await db.delete(
      AppSettingsTable.name,
      where: '${AppSettingsTable.key} = ?',
      whereArgs: [key],
    );
  }
}
