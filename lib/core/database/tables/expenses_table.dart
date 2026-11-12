abstract final class ExpensesTable {
  static const String name = 'expenses';

  static const String id = 'id';
  static const String isLumpsum = 'is_lumpsum';
  static const String categoryName = 'category_name';
  static const String itemName = 'item_name';
  static const String amount = 'amount';
  static const String date = 'date';
  static const String note = 'note';
  // v3: optional family member (null = unassigned).
  static const String memberId = 'member_id';

  static const String createSql =
      '''
CREATE TABLE $name (
  $id INTEGER PRIMARY KEY AUTOINCREMENT,
  $isLumpsum INTEGER NOT NULL,
  $categoryName TEXT NOT NULL,
  $itemName TEXT,
  $amount REAL NOT NULL,
  $date TEXT NOT NULL,
  $note TEXT
)''';

  static const String createDateIndexSql =
      'CREATE INDEX idx_${name}_date ON $name ($date)';
}
