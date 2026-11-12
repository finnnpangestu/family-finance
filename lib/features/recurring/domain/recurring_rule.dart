import 'package:equatable/equatable.dart';

enum RecurringType { income, expense }

// A transaction that repeats on the same day every month.
class RecurringRule extends Equatable {
  const RecurringRule({
    this.id,
    required this.type,
    required this.categoryName,
    this.itemName,
    required this.amount,
    required this.dayOfMonth,
    required this.nextDue,
    this.note,
    this.memberId,
    this.active = true,
  });

  final int? id;
  final RecurringType type;
  final String categoryName;

  // Set for itemized expenses ("Listrik"); null for income / quick expense.
  final String? itemName;
  final double amount;

  // 1-31; short months fall back to their last day.
  final int dayOfMonth;
  final DateTime nextDue;
  final String? note;
  final int? memberId;
  final bool active;

  String get title => itemName ?? categoryName;

  // Next occurrence after [from], keeping the preferred day of month.
  static DateTime nextDueAfter(DateTime from, int dayOfMonth) {
    final int lastDay = DateTime(from.year, from.month + 2, 0).day;
    return DateTime(from.year, from.month + 1, dayOfMonth.clamp(1, lastDay));
  }

  RecurringRule copyWith({DateTime? nextDue, bool? active}) => RecurringRule(
    id: id,
    type: type,
    categoryName: categoryName,
    itemName: itemName,
    amount: amount,
    dayOfMonth: dayOfMonth,
    nextDue: nextDue ?? this.nextDue,
    note: note,
    memberId: memberId,
    active: active ?? this.active,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    categoryName,
    itemName,
    amount,
    dayOfMonth,
    nextDue,
    note,
    memberId,
    active,
  ];
}
