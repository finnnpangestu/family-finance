// Key/value preferences (currency, backup session flag). Not part of backups.
abstract final class AppSettingsTable {
  static const String name = 'app_settings';

  static const String key = 'key';
  static const String value = 'value';

  static const String createSql =
      '''
CREATE TABLE $name (
  $key TEXT PRIMARY KEY,
  $value TEXT NOT NULL
)''';
}
