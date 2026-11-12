import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../data/finance_repository.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/income.dart';

final transactionActionsProvider = Provider<TransactionActions>(
  (ref) => TransactionActions(ref),
);

// Write use-cases; every success notifies listeners via the revision counter.
class TransactionActions {
  const TransactionActions(this._ref);

  final Ref _ref;

  FinanceRepository get _repository => _ref.read(financeRepositoryProvider);

  Future<void> addIncome(Income income) =>
      _write(() => _repository.addIncome(income));

  Future<void> addLumpsumExpense({
    required double amount,
    required DateTime date,
    String? note,
  }) => _write(
    () => _repository.addLumpsumExpense(amount: amount, date: date, note: note),
  );

  Future<void> addItemizedExpenses({
    required String categoryName,
    required List<ExpenseItemDraft> items,
    required DateTime date,
    String? note,
  }) => _write(
    () => _repository.addItemizedExpenses(
      categoryName: categoryName,
      items: items,
      date: date,
      note: note,
    ),
  );

  Future<void> deleteIncome(int id) =>
      _write(() => _repository.deleteIncome(id));

  Future<void> deleteExpense(int id) =>
      _write(() => _repository.deleteExpense(id));

  Future<void> _write(Future<Object?> Function() operation) async {
    await operation();
    _ref.read(financeRevisionProvider.notifier).bump();
  }
}

const List<String> _defaultIncomeCategories = ['Gaji Utama', 'Usaha Sampingan'];
const List<String> _defaultExpenseCategories = [
  'Tagihan',
  'Belanja Dapur',
  'Transportasi',
  'Kesehatan',
  'Pendidikan',
];

final incomeCategoriesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  ref.watch(financeRevisionProvider);
  final List<String> used = await ref
      .read(financeRepositoryProvider)
      .incomeCategories();
  return mergeCategories(used, _defaultIncomeCategories);
});

final expenseCategoriesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  ref.watch(financeRevisionProvider);
  final List<String> used = await ref
      .read(financeRepositoryProvider)
      .itemizedExpenseCategories();
  return mergeCategories(used, _defaultExpenseCategories);
});

// Used categories first, then defaults that are not used yet.
List<String> mergeCategories(List<String> used, List<String> defaults) =>
    {...used, ...defaults}.toList(growable: false);
