import 'package:equatable/equatable.dart';

import '../../dashboard/domain/models/month_range.dart';

class HistoryFilter extends Equatable {
  const HistoryFilter({required this.month, this.category, this.memberId});

  final MonthRange month;

  // null shows every category.
  final String? category;

  // null shows every family member.
  final int? memberId;

  HistoryFilter copyWith({
    MonthRange? month,
    String? Function()? category,
    int? Function()? memberId,
  }) => HistoryFilter(
    month: month ?? this.month,
    category: category != null ? category() : this.category,
    memberId: memberId != null ? memberId() : this.memberId,
  );

  @override
  List<Object?> get props => [month, category, memberId];
}
