// Monthly spending limit per expense category.
abstract final class BudgetsTable {
  static const String name = 'budgets';

  static const String id = 'id';
  static const String categoryName = 'category_name';
  static const String monthlyLimit = 'monthly_limit';

  static const String createSql =
      '''
CREATE TABLE $name (
  $id INTEGER PRIMARY KEY AUTOINCREMENT,
  $categoryName TEXT NOT NULL UNIQUE,
  $monthlyLimit REAL NOT NULL
)''';
}
