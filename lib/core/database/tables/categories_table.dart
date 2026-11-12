// User-editable category lists for the form chips (income / expense).
abstract final class CategoriesTable {
  static const String name = 'categories';

  static const String id = 'id';
  static const String type = 'type';
  static const String categoryName = 'name';

  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  static const String createSql =
      '''
CREATE TABLE $name (
  $id INTEGER PRIMARY KEY AUTOINCREMENT,
  $type TEXT NOT NULL,
  $categoryName TEXT NOT NULL,
  UNIQUE($type, $categoryName)
)''';

  static const List<String> defaultIncome = ['Gaji Utama', 'Usaha Sampingan'];
  static const List<String> defaultExpense = [
    'Makan & Dapur',
    'Tagihan',
    'Transportasi',
    'Kesehatan',
    'Pendidikan',
    'Cicilan',
  ];
}
