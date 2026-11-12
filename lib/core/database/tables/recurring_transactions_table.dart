// Monthly rules; next_due (yyyy-MM-dd) makes generation idempotent.
abstract final class RecurringTransactionsTable {
  static const String name = 'recurring_transactions';

  static const String id = 'id';
  static const String type = 'type';
  static const String categoryName = 'category_name';
  static const String itemName = 'item_name';
  static const String amount = 'amount';
  static const String dayOfMonth = 'day_of_month';
  static const String nextDue = 'next_due';
  static const String note = 'note';
  static const String memberId = 'member_id';
  static const String active = 'active';

  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  static const String createSql =
      '''
CREATE TABLE $name (
  $id INTEGER PRIMARY KEY AUTOINCREMENT,
  $type TEXT NOT NULL,
  $categoryName TEXT NOT NULL,
  $itemName TEXT,
  $amount REAL NOT NULL,
  $dayOfMonth INTEGER NOT NULL,
  $nextDue TEXT NOT NULL,
  $note TEXT,
  $memberId INTEGER,
  $active INTEGER NOT NULL DEFAULT 1
)''';
}
