import 'package:equatable/equatable.dart';

// Income vs expense totals for one calendar month.
class MonthlyCashflow extends Equatable {
  const MonthlyCashflow({
    required this.month,
    required this.income,
    required this.expense,
  });

  // First day of the month.
  final DateTime month;
  final double income;
  final double expense;

  double get net => income - expense;

  bool get isEmpty => income == 0 && expense == 0;

  @override
  List<Object?> get props => [month, income, expense];
}
