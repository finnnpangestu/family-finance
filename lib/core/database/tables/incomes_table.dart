abstract final class IncomesTable {
  static const String name = 'incomes';

  static const String id = 'id';
  static const String categoryName = 'category_name';
  static const String amount = 'amount';
  static const String date = 'date';
  static const String note = 'note';

  static const String createSql =
      '''
CREATE TABLE $name (
  $id INTEGER PRIMARY KEY AUTOINCREMENT,
  $categoryName TEXT NOT NULL,
  $amount REAL NOT NULL,
  $date TEXT NOT NULL,
  $note TEXT
)''';

  static const String createDateIndexSql =
      'CREATE INDEX idx_${name}_date ON $name ($date)';
}
