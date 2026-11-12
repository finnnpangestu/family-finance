import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/tables/categories_table.dart';

enum CategoryType { income, expense }

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(appDatabaseProvider)),
);

// Chip lists for the forms; refreshed with every finance write.
final incomeCategoriesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) {
  ref.watch(financeRevisionProvider);
  return ref.watch(categoryRepositoryProvider).list(CategoryType.income);
});

final expenseCategoriesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) {
  ref.watch(financeRevisionProvider);
  return ref.watch(categoryRepositoryProvider).list(CategoryType.expense);
});

class CategoryRepository {
  const CategoryRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  static String _type(CategoryType type) => type == CategoryType.income
      ? CategoriesTable.typeIncome
      : CategoriesTable.typeExpense;

  // Insertion order: defaults first, then the user's own additions.
  Future<List<String>> list(CategoryType type) async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      CategoriesTable.name,
      columns: [CategoriesTable.categoryName],
      where: '${CategoriesTable.type} = ?',
      whereArgs: [_type(type)],
      orderBy: CategoriesTable.id,
    );
    return [
      for (final row in rows) row[CategoriesTable.categoryName] as String,
    ];
  }

  // Idempotent: typing an existing category again is a no-op.
  Future<void> add(CategoryType type, String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final Database db = await _appDatabase.database;
    await db.insert(CategoriesTable.name, {
      CategoriesTable.type: _type(type),
      CategoriesTable.categoryName: trimmed,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Past transactions keep their category text; only the chip disappears.
  Future<void> remove(CategoryType type, String name) async {
    final Database db = await _appDatabase.database;
    await db.delete(
      CategoriesTable.name,
      where:
          '${CategoriesTable.type} = ? AND ${CategoriesTable.categoryName} = ?',
      whereArgs: [_type(type), name],
    );
  }
}
