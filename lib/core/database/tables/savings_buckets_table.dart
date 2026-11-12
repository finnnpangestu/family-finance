abstract final class SavingsBucketsTable {
  static const String name = 'savings_buckets';

  static const String id = 'id';
  static const String bucketName = 'bucket_name';
  static const String allocatedAmount = 'allocated_amount';
  static const String targetAmount = 'target_amount';

  static const String createSql =
      '''
CREATE TABLE $name (
  $id INTEGER PRIMARY KEY AUTOINCREMENT,
  $bucketName TEXT NOT NULL,
  $allocatedAmount REAL NOT NULL DEFAULT 0.0,
  $targetAmount REAL DEFAULT 0.0
)''';
}
