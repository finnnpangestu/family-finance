import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

// Unified read model for incomes and expenses in the history list.
class TransactionEntry extends Equatable {
  const TransactionEntry({
    required this.id,
    required this.type,
    required this.categoryName,
    this.itemName,
    required this.amount,
    required this.date,
    this.note,
    this.isLumpsum = false,
  });

  final int id;
  final TransactionType type;
  final String categoryName;
  final String? itemName;
  final double amount;
  final DateTime date;
  final String? note;
  final bool isLumpsum;

  bool get isIncome => type == TransactionType.income;

  // Ids are only unique per table.
  String get key => '${type.name}-$id';

  String get title => itemName ?? categoryName;

  @override
  List<Object?> get props => [
    id,
    type,
    categoryName,
    itemName,
    amount,
    date,
    note,
    isLumpsum,
  ];
}

class CategorySpending extends Equatable {
  const CategorySpending({required this.categoryName, required this.amount});

  final String categoryName;
  final double amount;

  @override
  List<Object?> get props => [categoryName, amount];
}
