import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/tables/expenses_table.dart';
import '../../../core/database/tables/incomes_table.dart';
import '../../../core/utils/date_formatter.dart';
import '../../dashboard/domain/models/month_range.dart';
import '../domain/history_filter.dart';
import '../domain/transaction_entry.dart';

typedef _Row = Map<String, Object?>;

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.watch(appDatabaseProvider)),
);

class HistoryRepository {
  const HistoryRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  // Both tables projected onto one shape for UNION ALL.
  static const String _unionSql =
      '''
        SELECT ${IncomesTable.id} AS id, 'income' AS type, ${IncomesTable.categoryName} AS category,
              NULL AS item, ${IncomesTable.amount} AS amount, ${IncomesTable.date} AS date,
              ${IncomesTable.note} AS note, 0 AS lumpsum
        FROM ${IncomesTable.name}
        WHERE ${IncomesTable.date} >= ? AND ${IncomesTable.date} < ?
        UNION ALL
        SELECT ${ExpensesTable.id}, 'expense', ${ExpensesTable.categoryName},
              ${ExpensesTable.itemName}, ${ExpensesTable.amount}, ${ExpensesTable.date},
              ${ExpensesTable.note}, ${ExpensesTable.isLumpsum}
        FROM ${ExpensesTable.name}
        WHERE ${ExpensesTable.date} >= ? AND ${ExpensesTable.date} < ?
      ''';

  Future<Database> get _db => _appDatabase.database;

  Future<List<TransactionEntry>> load(HistoryFilter filter) async {
    final Database db = await _db;
    final String? category = filter.category;
    final List<_Row> rows = await db.rawQuery(
      'SELECT * FROM ($_unionSql) '
      '${category == null ? '' : 'WHERE category = ? '}'
      'ORDER BY date DESC, type ASC, id DESC',
      [..._monthArgs(filter.month), ?category],
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<List<String>> categories(MonthRange month) async {
    final Database db = await _db;
    final List<_Row> rows = await db.rawQuery(
      'SELECT category FROM ($_unionSql) GROUP BY category ORDER BY category',
      _monthArgs(month),
    );
    return [for (final _Row row in rows) row['category'] as String];
  }

  Future<List<CategorySpending>> spendingByCategory(MonthRange month) async {
    final Database db = await _db;
    final List<_Row> rows = await db.rawQuery(
      'SELECT ${ExpensesTable.categoryName} AS category, SUM(${ExpensesTable.amount}) AS total '
      'FROM ${ExpensesTable.name} '
      'WHERE ${ExpensesTable.date} >= ? AND ${ExpensesTable.date} < ? '
      'GROUP BY ${ExpensesTable.categoryName} ORDER BY total DESC',
      _monthArgs(month).sublist(0, 2),
    );
    return [
      for (final _Row row in rows)
        CategorySpending(
          categoryName: row['category'] as String,
          amount: (row['total'] as num).toDouble(),
        ),
    ];
  }

  static List<Object> _monthArgs(MonthRange month) {
    final String start = DateFormatter.toStorage(month.start);
    final String end = DateFormatter.toStorage(month.end);
    return [start, end, start, end];
  }

  static TransactionEntry _fromRow(_Row row) => TransactionEntry(
    id: row['id'] as int,
    type: row['type'] == 'income'
        ? TransactionType.income
        : TransactionType.expense,
    categoryName: row['category'] as String,
    itemName: row['item'] as String?,
    amount: (row['amount'] as num).toDouble(),
    date: DateFormatter.fromStorage(row['date'] as String),
    note: row['note'] as String?,
    isLumpsum: (row['lumpsum'] as int) == 1,
  );
}
