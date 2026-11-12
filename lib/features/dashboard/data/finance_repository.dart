import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/tables/expenses_table.dart';
import '../../../core/database/tables/incomes_table.dart';
import '../../../core/database/tables/savings_buckets_table.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/models/dashboard_summary.dart';
import '../domain/models/expense.dart';
import '../domain/models/income.dart';
import '../domain/models/month_range.dart';
import '../domain/models/monthly_cashflow.dart';
import 'finance_mappers.dart';

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(appDatabaseProvider)),
);

class FinanceRepository {
  const FinanceRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<int> addIncome(Income income) async {
    final Database db = await _db;
    return db.insert(IncomesTable.name, FinanceMappers.incomeToRow(income));
  }

  Future<int> addLumpsumExpense({
    required double amount,
    required DateTime date,
    String? note,
    int? memberId,
  }) async {
    final Database db = await _db;
    return db.insert(
      ExpensesTable.name,
      FinanceMappers.expenseToRow(
        Expense(
          isLumpsum: true,
          categoryName: Expense.lumpsumCategory,
          amount: amount,
          date: date,
          note: note,
          memberId: memberId,
        ),
      ),
    );
  }

  // All items are written atomically so a partial list is never saved.
  Future<void> addItemizedExpenses({
    required String categoryName,
    required List<ExpenseItemDraft> items,
    required DateTime date,
    String? note,
    int? memberId,
  }) async {
    if (items.isEmpty) throw ArgumentError.value(items, 'items', 'is empty');
    final Database db = await _db;
    await db.transaction((txn) async {
      final Batch batch = txn.batch();
      for (final ExpenseItemDraft item in items) {
        batch.insert(
          ExpensesTable.name,
          FinanceMappers.expenseToRow(
            Expense(
              isLumpsum: false,
              categoryName: categoryName,
              itemName: item.itemName,
              amount: item.amount,
              date: date,
              note: note,
              memberId: memberId,
            ),
          ),
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> deleteIncome(int id) async {
    final Database db = await _db;
    await db.delete(
      IncomesTable.name,
      where: '${IncomesTable.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final Database db = await _db;
    await db.delete(
      ExpensesTable.name,
      where: '${ExpensesTable.id} = ?',
      whereArgs: [id],
    );
  }

  Future<DashboardSummary> loadSummary(MonthRange month) async {
    final Database db = await _db;
    final List<Object> monthArgs = [
      DateFormatter.toStorage(month.start),
      DateFormatter.toStorage(month.end),
    ];

    final List<DbRow> streams = await db.rawQuery(
      'SELECT ${IncomesTable.categoryName} AS name, SUM(${IncomesTable.amount}) AS total '
      'FROM ${IncomesTable.name} '
      'WHERE ${IncomesTable.date} >= ? AND ${IncomesTable.date} < ? '
      'GROUP BY ${IncomesTable.categoryName} ORDER BY total DESC',
      monthArgs,
    );
    final double monthExpense = await _sum(
      db,
      'SELECT SUM(${ExpensesTable.amount}) FROM ${ExpensesTable.name} '
      'WHERE ${ExpensesTable.date} >= ? AND ${ExpensesTable.date} < ?',
      monthArgs,
    );
    final double lifetimeIncome = await _sum(
      db,
      'SELECT SUM(${IncomesTable.amount}) FROM ${IncomesTable.name}',
    );
    final double lifetimeExpense = await _sum(
      db,
      'SELECT SUM(${ExpensesTable.amount}) FROM ${ExpensesTable.name}',
    );
    final double totalAllocated = await _sum(
      db,
      'SELECT SUM(${SavingsBucketsTable.allocatedAmount}) FROM ${SavingsBucketsTable.name}',
    );

    final List<IncomeStreamTotal> incomeStreams = [
      for (final DbRow row in streams)
        IncomeStreamTotal(
          categoryName: row['name'] as String,
          amount: (row['total'] as num).toDouble(),
        ),
    ];

    return DashboardSummary(
      monthIncome: incomeStreams.fold(0, (sum, s) => sum + s.amount),
      monthExpense: monthExpense,
      incomeStreams: incomeStreams,
      lifetimeIncome: lifetimeIncome,
      lifetimeExpense: lifetimeExpense,
      totalAllocated: totalAllocated,
    );
  }

  // Oldest first, always [months] entries; months without data are zero.
  Future<List<MonthlyCashflow>> monthlyCashflow({
    int months = 6,
    DateTime? now,
  }) async {
    final Database db = await _db;
    final MonthRange current = MonthRange.of(now ?? DateTime.now());
    final List<MonthRange> ranges = [current];
    while (ranges.length < months) {
      ranges.insert(0, ranges.first.previous);
    }
    final List<Object> args = [
      DateFormatter.toStorage(ranges.first.start),
      DateFormatter.toStorage(current.end),
    ];

    Future<Map<String, double>> totalsByMonth(String table) async {
      // Dates are stored as yyyy-MM-dd, so the first 7 chars are the month.
      final List<DbRow> rows = await db.rawQuery(
        'SELECT substr(date, 1, 7) AS ym, SUM(amount) AS total FROM $table '
        'WHERE date >= ? AND date < ? GROUP BY ym',
        args,
      );
      return {
        for (final DbRow row in rows)
          row['ym'] as String: (row['total'] as num).toDouble(),
      };
    }

    final Map<String, double> income = await totalsByMonth(IncomesTable.name);
    final Map<String, double> expense = await totalsByMonth(ExpensesTable.name);

    return [
      for (final MonthRange range in ranges)
        MonthlyCashflow(
          month: range.start,
          income: income[_monthKey(range.start)] ?? 0,
          expense: expense[_monthKey(range.start)] ?? 0,
        ),
    ];
  }

  static String _monthKey(DateTime month) =>
      DateFormatter.toStorage(month).substring(0, 7);

  // Most used first so frequent choices appear at the start of the chip list.
  Future<List<String>> incomeCategories() =>
      _categories(IncomesTable.name, IncomesTable.categoryName);

  Future<List<String>> itemizedExpenseCategories() => _categories(
    ExpensesTable.name,
    ExpensesTable.categoryName,
    where: '${ExpensesTable.isLumpsum} = 0',
  );

  Future<List<String>> _categories(
    String table,
    String column, {
    String? where,
  }) async {
    final Database db = await _db;
    final List<DbRow> rows = await db.rawQuery(
      'SELECT $column AS name FROM $table '
      '${where == null ? '' : 'WHERE $where '}'
      'GROUP BY $column ORDER BY COUNT(*) DESC LIMIT 12',
    );
    return [for (final DbRow row in rows) row['name'] as String];
  }

  static Future<double> _sum(
    Database db,
    String sql, [
    List<Object>? args,
  ]) async {
    final List<DbRow> rows = await db.rawQuery(sql, args);
    return (rows.first.values.first as num?)?.toDouble() ?? 0;
  }
}
