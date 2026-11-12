import 'package:equatable/equatable.dart';

enum BudgetLevel { safe, warning, over }

// One category's monthly limit against what has been spent so far.
class BudgetStatus extends Equatable {
  const BudgetStatus({
    required this.categoryName,
    required this.limit,
    required this.spent,
  });

  // From this share on the budget counts as "almost used up".
  static const double warningRatio = 0.8;

  final String categoryName;
  final double limit;
  final double spent;

  double get ratio => limit <= 0 ? 0 : spent / limit;

  double get remaining => limit - spent;

  BudgetLevel get level => levelFor(ratio);

  static BudgetLevel levelFor(double ratio) => ratio >= 1
      ? BudgetLevel.over
      : ratio >= warningRatio
      ? BudgetLevel.warning
      : BudgetLevel.safe;

  @override
  List<Object?> get props => [categoryName, limit, spent];
}

// Raised when a new expense moves a category into a worse level.
class BudgetAlert extends Equatable {
  const BudgetAlert({required this.status});

  final BudgetStatus status;

  String get message => status.level == BudgetLevel.over
      ? 'Anggaran ${status.categoryName} terlampaui '
            '(${(status.ratio * 100).round()}%).'
      : 'Anggaran ${status.categoryName} hampir habis '
            '(${(status.ratio * 100).round()}%).';

  @override
  List<Object?> get props => [status];
}
