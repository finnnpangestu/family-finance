import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  const Expense({
    this.id,
    required this.isLumpsum,
    required this.categoryName,
    this.itemName,
    required this.amount,
    required this.date,
    this.note,
    this.memberId,
  });

  // Category used by the quick (lump-sum) recording mode.
  static const String lumpsumCategory = 'Pengeluaran Harian';

  final int? id;
  final bool isLumpsum;
  final String categoryName;

  // Only set for itemized entries, e.g. "Listrik".
  final String? itemName;
  final double amount;
  final DateTime date;
  final String? note;

  // Family member this belongs to; null = unassigned.
  final int? memberId;

  @override
  List<Object?> get props => [
    id,
    isLumpsum,
    categoryName,
    itemName,
    amount,
    date,
    note,
    memberId,
  ];
}

// One row of the itemized form before it is stamped with category & date.
class ExpenseItemDraft extends Equatable {
  const ExpenseItemDraft({required this.itemName, required this.amount});

  final String itemName;
  final double amount;

  @override
  List<Object?> get props => [itemName, amount];
}
