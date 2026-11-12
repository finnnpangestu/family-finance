import 'package:equatable/equatable.dart';

import '../../dashboard/domain/models/month_range.dart';

class HistoryFilter extends Equatable {
  const HistoryFilter({required this.month, this.category});

  final MonthRange month;

  // null shows every category.
  final String? category;

  HistoryFilter copyWith({MonthRange? month, String? Function()? category}) =>
      HistoryFilter(
        month: month ?? this.month,
        category: category != null ? category() : this.category,
      );

  @override
  List<Object?> get props => [month, category];
}
