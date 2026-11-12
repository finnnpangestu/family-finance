import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/tables/budgets_table.dart';
import '../../../core/database/tables/expenses_table.dart';
import '../../../core/utils/date_formatter.dart';
import '../../dashboard/domain/models/month_range.dart';
import '../domain/budget_status.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(ref.watch(appDatabaseProvider)),
);

// This month's budgets, closest to the limit first; refreshed on writes.
final budgetStatusProvider = FutureProvider.autoDispose<List<BudgetStatus>>((
  ref,
) {
  ref.watch(financeRevisionProvider);
  return ref
      .watch(budgetRepositoryProvider)
      .statusFor(MonthRange.of(DateTime.now()));
});

class BudgetRepository {
  const BudgetRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<void> upsert(String categoryName, double monthlyLimit) async {
    final Database db = await _appDatabase.database;
    await db.insert(BudgetsTable.name, {
      BudgetsTable.categoryName: categoryName.trim(),
      BudgetsTable.monthlyLimit: monthlyLimit,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remove(String categoryName) async {
    final Database db = await _appDatabase.database;
    await db.delete(
      BudgetsTable.name,
      where: '${BudgetsTable.categoryName} = ?',
      whereArgs: [categoryName],
    );
  }

  // Every budget with the month's spending in its category.
  Future<List<BudgetStatus>> statusFor(MonthRange month) async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT b.${BudgetsTable.categoryName} AS name, '
      'b.${BudgetsTable.monthlyLimit} AS limit_amount, '
      'IFNULL(SUM(e.${ExpensesTable.amount}), 0) AS spent '
      'FROM ${BudgetsTable.name} b '
      'LEFT JOIN ${ExpensesTable.name} e '
      'ON e.${ExpensesTable.categoryName} = b.${BudgetsTable.categoryName} '
      'AND e.${ExpensesTable.date} >= ? AND e.${ExpensesTable.date} < ? '
      'GROUP BY b.${BudgetsTable.id}',
      [
        DateFormatter.toStorage(month.start),
        DateFormatter.toStorage(month.end),
      ],
    );
    final List<BudgetStatus> statuses = [
      for (final row in rows)
        BudgetStatus(
          categoryName: row['name'] as String,
          limit: (row['limit_amount'] as num).toDouble(),
          spent: (row['spent'] as num).toDouble(),
        ),
    ];
    statuses.sort((a, b) => b.ratio.compareTo(a.ratio));
    return statuses;
  }

  // Compares statuses from before and after a write; only categories that
  // moved into a worse level produce an alert.
  static List<BudgetAlert> alertsBetween(
    List<BudgetStatus> before,
    List<BudgetStatus> after,
  ) {
    final Map<String, BudgetLevel> previous = {
      for (final s in before) s.categoryName: s.level,
    };
    return [
      for (final s in after)
        if (s.level.index >
            (previous[s.categoryName] ?? BudgetLevel.safe).index)
          BudgetAlert(status: s),
    ];
  }
}
