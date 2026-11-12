import 'package:equatable/equatable.dart';

class IncomeStreamTotal extends Equatable {
  const IncomeStreamTotal({required this.categoryName, required this.amount});

  final String categoryName;
  final double amount;

  @override
  List<Object?> get props => [categoryName, amount];
}

// Pure financial snapshot shown on the dashboard.
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.monthIncome,
    required this.monthExpense,
    required this.incomeStreams,
    required this.lifetimeIncome,
    required this.lifetimeExpense,
    required this.totalAllocated,
  });

  static const DashboardSummary empty = DashboardSummary(
    monthIncome: 0,
    monthExpense: 0,
    incomeStreams: [],
    lifetimeIncome: 0,
    lifetimeExpense: 0,
    totalAllocated: 0,
  );

  // Current month: Income A + Income B + ...
  final double monthIncome;
  final double monthExpense;
  final List<IncomeStreamTotal> incomeStreams;

  final double lifetimeIncome;
  final double lifetimeExpense;
  final double totalAllocated;

  // Money still free for daily spending after savings allocations.
  double get freeBalance => calculateFreeBalance(
    totalIncome: lifetimeIncome,
    totalExpense: lifetimeExpense,
    totalAllocated: totalAllocated,
  );

  static double calculateFreeBalance({
    required double totalIncome,
    required double totalExpense,
    required double totalAllocated,
  }) => totalIncome - totalExpense - totalAllocated;

  @override
  List<Object?> get props => [
    monthIncome,
    monthExpense,
    incomeStreams,
    lifetimeIncome,
    lifetimeExpense,
    totalAllocated,
  ];
}
