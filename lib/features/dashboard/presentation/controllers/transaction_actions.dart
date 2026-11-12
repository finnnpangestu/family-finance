import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/notifications/reminder_service.dart';
import '../../../../core/settings/settings_store.dart';
import '../../../budget/data/budget_repository.dart';
import '../../../budget/domain/budget_status.dart';
import '../../../categories/data/category_repository.dart';
import '../../../recurring/data/recurring_repository.dart';
import '../../../recurring/domain/recurring_rule.dart';
import '../../data/finance_repository.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/income.dart';
import '../../domain/models/month_range.dart';

final transactionActionsProvider = Provider<TransactionActions>(
  (ref) => TransactionActions(ref),
);

// Write use-cases; every success notifies listeners via the revision counter.
class TransactionActions {
  const TransactionActions(this._ref);

  final Ref _ref;

  FinanceRepository get _repository => _ref.read(financeRepositoryProvider);
  RecurringRepository get _recurring => _ref.read(recurringRepositoryProvider);
  CategoryRepository get _categories => _ref.read(categoryRepositoryProvider);
  BudgetRepository get _budgets => _ref.read(budgetRepositoryProvider);

  // With [repeatMonthly] the same income is also created every month on
  // the same day, starting next month.
  Future<void> addIncome(Income income, {bool repeatMonthly = false}) =>
      _write(() async {
        await _repository.addIncome(income);
        await _categories.add(CategoryType.income, income.categoryName);
        if (repeatMonthly) {
          await _recurring.create(
            _rule(
              RecurringType.income,
              income.categoryName,
              null,
              income.amount,
              income.date,
              income.note,
              income.memberId,
            ),
          );
        }
      });

  // Returns budget alerts the expense triggered (empty when none).
  Future<List<BudgetAlert>> addLumpsumExpense({
    required double amount,
    required DateTime date,
    String? note,
    int? memberId,
    bool repeatMonthly = false,
  }) => _writeExpense(date, () async {
    await _repository.addLumpsumExpense(
      amount: amount,
      date: date,
      note: note,
      memberId: memberId,
    );
    if (repeatMonthly) {
      await _recurring.create(
        _rule(
          RecurringType.expense,
          Expense.lumpsumCategory,
          null,
          amount,
          date,
          note,
          memberId,
        ),
      );
    }
  });

  // Each item becomes its own monthly rule when [repeatMonthly] is set.
  Future<List<BudgetAlert>> addItemizedExpenses({
    required String categoryName,
    required List<ExpenseItemDraft> items,
    required DateTime date,
    String? note,
    int? memberId,
    bool repeatMonthly = false,
  }) => _writeExpense(date, () async {
    await _repository.addItemizedExpenses(
      categoryName: categoryName,
      items: items,
      date: date,
      note: note,
      memberId: memberId,
    );
    await _categories.add(CategoryType.expense, categoryName);
    if (repeatMonthly) {
      for (final ExpenseItemDraft item in items) {
        await _recurring.create(
          _rule(
            RecurringType.expense,
            categoryName,
            item.itemName,
            item.amount,
            date,
            note,
            memberId,
          ),
        );
      }
    }
  });

  Future<void> deleteIncome(int id) =>
      _write(() => _repository.deleteIncome(id));

  Future<void> deleteExpense(int id) =>
      _write(() => _repository.deleteExpense(id));

  static RecurringRule _rule(
    RecurringType type,
    String category,
    String? itemName,
    double amount,
    DateTime firstDate,
    String? note,
    int? memberId,
  ) => RecurringRule(
    type: type,
    categoryName: category,
    itemName: itemName,
    amount: amount,
    dayOfMonth: firstDate.day,
    // The first occurrence is the transaction just saved.
    nextDue: RecurringRule.nextDueAfter(firstDate, firstDate.day),
    note: note,
    memberId: memberId,
  );

  Future<void> _write(Future<void> Function() operation) async {
    await operation();
    _ref.read(financeRevisionProvider.notifier).bump();
  }

  // Budgets are compared before/after so only a newly crossed threshold
  // alerts. Alert failures never undo or fail the saved expense.
  Future<List<BudgetAlert>> _writeExpense(
    DateTime date,
    Future<void> Function() operation,
  ) async {
    final MonthRange month = MonthRange.of(date);
    final List<BudgetStatus> before = await _budgets.statusFor(month);
    await _write(operation);
    try {
      final List<BudgetAlert> alerts = BudgetRepository.alertsBetween(
        before,
        await _budgets.statusFor(month),
      );
      if (alerts.isNotEmpty) await _notify(alerts);
      return alerts;
    } catch (error) {
      debugPrint('Budget check skipped: $error');
      return const [];
    }
  }

  Future<void> _notify(List<BudgetAlert> alerts) async {
    final SettingsStore settings = _ref.read(settingsStoreProvider);
    if (await settings.read(SettingsStore.budgetAlertEnabled) != 'true') {
      return;
    }
    final ReminderService service = _ref.read(reminderServiceProvider);
    for (final BudgetAlert alert in alerts) {
      await service.showBudgetAlert(
        categoryName: alert.status.categoryName,
        message: alert.message,
      );
    }
  }
}
