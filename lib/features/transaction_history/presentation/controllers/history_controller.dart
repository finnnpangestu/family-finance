import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../dashboard/domain/models/month_range.dart';
import '../../../dashboard/presentation/controllers/transaction_actions.dart';
import '../../data/history_repository.dart';
import '../../domain/history_filter.dart';
import '../../domain/transaction_entry.dart';

class HistoryState extends Equatable {
  const HistoryState({
    required this.filter,
    this.entries = const [],
    this.categories = const [],
    this.spending = const [],
    this.isLoading = true,
    this.errorMessage,
    this.selectedKey,
  });

  final HistoryFilter filter;
  final List<TransactionEntry> entries;
  final List<String> categories;
  final List<CategorySpending> spending;
  final bool isLoading;
  final String? errorMessage;

  // Entry shown in the tablet detail pane.
  final String? selectedKey;

  TransactionEntry? get selected {
    for (final TransactionEntry e in entries) {
      if (e.key == selectedKey) return e;
    }
    return null;
  }

  double get totalIncome =>
      entries.where((e) => e.isIncome).fold(0, (sum, e) => sum + e.amount);

  double get totalExpense =>
      entries.where((e) => !e.isIncome).fold(0, (sum, e) => sum + e.amount);

  HistoryState copyWith({
    HistoryFilter? filter,
    List<TransactionEntry>? entries,
    List<String>? categories,
    List<CategorySpending>? spending,
    bool? isLoading,
    String? Function()? errorMessage,
    String? Function()? selectedKey,
  }) {
    return HistoryState(
      filter: filter ?? this.filter,
      entries: entries ?? this.entries,
      categories: categories ?? this.categories,
      spending: spending ?? this.spending,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      selectedKey: selectedKey != null ? selectedKey() : this.selectedKey,
    );
  }

  @override
  List<Object?> get props => [
    filter,
    entries,
    categories,
    spending,
    isLoading,
    errorMessage,
    selectedKey,
  ];
}

final historyControllerProvider =
    NotifierProvider.autoDispose<HistoryController, HistoryState>(
      HistoryController.new,
    );

class HistoryController extends AutoDisposeNotifier<HistoryState> {
  int _loadToken = 0;

  @override
  HistoryState build() {
    ref.listen<int>(financeRevisionProvider, (_, _) => refresh());
    // Invalidates in-flight loads so they never write to a disposed notifier.
    ref.onDispose(() => _loadToken++);
    Future.microtask(refresh);
    return HistoryState(
      filter: HistoryFilter(month: MonthRange.of(DateTime.now())),
    );
  }

  void previousMonth() => _applyFilter(
    state.filter.copyWith(
      month: state.filter.month.previous,
      category: () => null,
    ),
  );

  void nextMonth() => _applyFilter(
    state.filter.copyWith(month: state.filter.month.next, category: () => null),
  );

  void setCategory(String? category) =>
      _applyFilter(state.filter.copyWith(category: () => category));

  void select(TransactionEntry entry) =>
      state = state.copyWith(selectedKey: () => entry.key);

  Future<void> delete(TransactionEntry entry) {
    final TransactionActions actions = ref.read(transactionActionsProvider);
    return entry.isIncome
        ? actions.deleteIncome(entry.id)
        : actions.deleteExpense(entry.id);
  }

  void _applyFilter(HistoryFilter filter) {
    state = state.copyWith(filter: filter, selectedKey: () => null);
    refresh();
  }

  Future<void> refresh() async {
    final int token = ++_loadToken;
    final HistoryFilter filter = state.filter;
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final HistoryRepository repository = ref.read(historyRepositoryProvider);
      final List<TransactionEntry> entries = await repository.load(filter);
      final List<String> categories = await repository.categories(filter.month);
      final List<CategorySpending> spending = await repository
          .spendingByCategory(filter.month);
      if (token != _loadToken) return;

      // Keep the selection if it still exists, else pick the newest entry.
      final String? currentKey = state.selectedKey;
      final bool stillExists = entries.any((e) => e.key == currentKey);
      state = state.copyWith(
        entries: entries,
        categories: categories,
        spending: spending,
        isLoading: false,
        selectedKey: () => stillExists
            ? currentKey
            : (entries.isEmpty ? null : entries.first.key),
      );
    } catch (error, stack) {
      debugPrint('History load failed: $error\n$stack');
      if (token != _loadToken) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Gagal memuat riwayat transaksi.',
      );
    }
  }
}
