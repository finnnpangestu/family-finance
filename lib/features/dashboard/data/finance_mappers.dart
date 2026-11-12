import '../../../core/database/tables/expenses_table.dart';
import '../../../core/database/tables/incomes_table.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/models/expense.dart';
import '../domain/models/income.dart';

typedef DbRow = Map<String, Object?>;

abstract final class FinanceMappers {
  static Income incomeFromRow(DbRow row) => Income(
    id: row[IncomesTable.id] as int?,
    categoryName: row[IncomesTable.categoryName] as String,
    amount: (row[IncomesTable.amount] as num).toDouble(),
    date: DateFormatter.fromStorage(row[IncomesTable.date] as String),
    note: row[IncomesTable.note] as String?,
  );

  static DbRow incomeToRow(Income income) => {
    if (income.id != null) IncomesTable.id: income.id,
    IncomesTable.categoryName: income.categoryName,
    IncomesTable.amount: income.amount,
    IncomesTable.date: DateFormatter.toStorage(income.date),
    IncomesTable.note: income.note,
  };

  static Expense expenseFromRow(DbRow row) => Expense(
    id: row[ExpensesTable.id] as int?,
    isLumpsum: (row[ExpensesTable.isLumpsum] as int) == 1,
    categoryName: row[ExpensesTable.categoryName] as String,
    itemName: row[ExpensesTable.itemName] as String?,
    amount: (row[ExpensesTable.amount] as num).toDouble(),
    date: DateFormatter.fromStorage(row[ExpensesTable.date] as String),
    note: row[ExpensesTable.note] as String?,
  );

  static DbRow expenseToRow(Expense expense) => {
    if (expense.id != null) ExpensesTable.id: expense.id,
    ExpensesTable.isLumpsum: expense.isLumpsum ? 1 : 0,
    ExpensesTable.categoryName: expense.categoryName,
    ExpensesTable.itemName: expense.itemName,
    ExpensesTable.amount: expense.amount,
    ExpensesTable.date: DateFormatter.toStorage(expense.date),
    ExpensesTable.note: expense.note,
  };
}
