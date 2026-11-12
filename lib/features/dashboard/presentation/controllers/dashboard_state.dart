import 'package:equatable/equatable.dart';

import '../../domain/models/dashboard_summary.dart';
import '../../domain/models/monthly_cashflow.dart';

class DashboardState extends Equatable {
  const DashboardState({
    required this.summary,
    required this.isLoading,
    this.cashflow = const [],
    this.errorMessage,
  });

  static const DashboardState initial = DashboardState(
    summary: DashboardSummary.empty,
    isLoading: true,
  );

  final DashboardSummary summary;
  final bool isLoading;

  // Last 6 months, oldest first, for the cashflow chart.
  final List<MonthlyCashflow> cashflow;
  final String? errorMessage;

  // Shorthands so widgets can `select` a single number.
  double get totalIncome => summary.monthIncome;
  double get totalExpense => summary.monthExpense;
  double get freeBalance => summary.freeBalance;
  double get totalAllocated => summary.totalAllocated;

  DashboardState copyWith({
    DashboardSummary? summary,
    bool? isLoading,
    List<MonthlyCashflow>? cashflow,
    String? Function()? errorMessage,
  }) {
    return DashboardState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      cashflow: cashflow ?? this.cashflow,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [summary, isLoading, cashflow, errorMessage];
}
