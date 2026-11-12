import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/tables/expenses_table.dart';
import '../../../core/database/tables/incomes_table.dart';
import '../../../core/database/tables/recurring_transactions_table.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/recurring_rule.dart';

typedef _Row = Map<String, Object?>;

final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepository(ref.watch(appDatabaseProvider)),
);

final recurringRulesProvider = FutureProvider.autoDispose<List<RecurringRule>>((
  ref,
) {
  ref.watch(financeRevisionProvider);
  return ref.watch(recurringRepositoryProvider).list();
});

class RecurringRepository {
  const RecurringRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<int> create(RecurringRule rule) async {
    final Database db = await _appDatabase.database;
    return db.insert(RecurringTransactionsTable.name, _toRow(rule));
  }

  // Active rules first, then by the day they fall on.
  Future<List<RecurringRule>> list() async {
    final Database db = await _appDatabase.database;
    final List<_Row> rows = await db.query(
      RecurringTransactionsTable.name,
      orderBy:
          '${RecurringTransactionsTable.active} DESC, '
          '${RecurringTransactionsTable.dayOfMonth} ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<void> setActive(int id, {required bool active}) async {
    final Database db = await _appDatabase.database;
    await db.update(
      RecurringTransactionsTable.name,
      {RecurringTransactionsTable.active: active ? 1 : 0},
      where: '${RecurringTransactionsTable.id} = ?',
      whereArgs: [id],
    );
  }

  // Already generated transactions stay in the history.
  Future<void> remove(int id) async {
    final Database db = await _appDatabase.database;
    await db.delete(
      RecurringTransactionsTable.name,
      where: '${RecurringTransactionsTable.id} = ?',
      whereArgs: [id],
    );
  }

  // Creates every occurrence due up to [today], including missed months,
  // and advances next_due in the same transaction so reruns never double.
  // Returns how many transactions were created.
  Future<int> generateDue(DateTime today) async {
    final Database db = await _appDatabase.database;
    final String todayKey = DateFormatter.toStorage(today);
    return db.transaction((txn) async {
      final List<_Row> rows = await txn.query(
        RecurringTransactionsTable.name,
        where:
            '${RecurringTransactionsTable.active} = 1 AND '
            '${RecurringTransactionsTable.nextDue} <= ?',
        whereArgs: [todayKey],
      );
      int created = 0;
      for (final RecurringRule rule in rows.map(_fromRow)) {
        DateTime due = rule.nextDue;
        while (!due.isAfter(today)) {
          await _insertOccurrence(txn, rule, due);
          created++;
          due = RecurringRule.nextDueAfter(due, rule.dayOfMonth);
        }
        await txn.update(
          RecurringTransactionsTable.name,
          {RecurringTransactionsTable.nextDue: DateFormatter.toStorage(due)},
          where: '${RecurringTransactionsTable.id} = ?',
          whereArgs: [rule.id],
        );
      }
      return created;
    });
  }

  static Future<void> _insertOccurrence(
    Transaction txn,
    RecurringRule rule,
    DateTime date,
  ) async {
    final String dateKey = DateFormatter.toStorage(date);
    if (rule.type == RecurringType.income) {
      await txn.insert(IncomesTable.name, {
        IncomesTable.categoryName: rule.categoryName,
        IncomesTable.amount: rule.amount,
        IncomesTable.date: dateKey,
        IncomesTable.note: rule.note,
        IncomesTable.memberId: rule.memberId,
      });
    } else {
      await txn.insert(ExpensesTable.name, {
        // Rules without an item name come from the quick (lump-sum) form.
        ExpensesTable.isLumpsum: rule.itemName == null ? 1 : 0,
        ExpensesTable.categoryName: rule.categoryName,
        ExpensesTable.itemName: rule.itemName,
        ExpensesTable.amount: rule.amount,
        ExpensesTable.date: dateKey,
        ExpensesTable.note: rule.note,
        ExpensesTable.memberId: rule.memberId,
      });
    }
  }

  static _Row _toRow(RecurringRule rule) => {
    if (rule.id != null) RecurringTransactionsTable.id: rule.id,
    RecurringTransactionsTable.type: rule.type == RecurringType.income
        ? RecurringTransactionsTable.typeIncome
        : RecurringTransactionsTable.typeExpense,
    RecurringTransactionsTable.categoryName: rule.categoryName,
    RecurringTransactionsTable.itemName: rule.itemName,
    RecurringTransactionsTable.amount: rule.amount,
    RecurringTransactionsTable.dayOfMonth: rule.dayOfMonth,
    RecurringTransactionsTable.nextDue: DateFormatter.toStorage(rule.nextDue),
    RecurringTransactionsTable.note: rule.note,
    RecurringTransactionsTable.memberId: rule.memberId,
    RecurringTransactionsTable.active: rule.active ? 1 : 0,
  };

  static RecurringRule _fromRow(_Row row) => RecurringRule(
    id: row[RecurringTransactionsTable.id] as int?,
    type:
        row[RecurringTransactionsTable.type] ==
            RecurringTransactionsTable.typeIncome
        ? RecurringType.income
        : RecurringType.expense,
    categoryName: row[RecurringTransactionsTable.categoryName] as String,
    itemName: row[RecurringTransactionsTable.itemName] as String?,
    amount: (row[RecurringTransactionsTable.amount] as num).toDouble(),
    dayOfMonth: row[RecurringTransactionsTable.dayOfMonth] as int,
    nextDue: DateFormatter.fromStorage(
      row[RecurringTransactionsTable.nextDue] as String,
    ),
    note: row[RecurringTransactionsTable.note] as String?,
    memberId: row[RecurringTransactionsTable.memberId] as int?,
    active: (row[RecurringTransactionsTable.active] as int) == 1,
  );
}
