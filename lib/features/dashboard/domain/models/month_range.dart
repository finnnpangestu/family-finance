import 'package:equatable/equatable.dart';

// Half-open [start, end) calendar month used for SQL date filters.
class MonthRange extends Equatable {
  MonthRange.of(DateTime date)
    : start = DateTime(date.year, date.month),
      end = DateTime(date.year, date.month + 1);

  final DateTime start;
  final DateTime end;

  MonthRange get previous =>
      MonthRange.of(DateTime(start.year, start.month - 1));

  MonthRange get next => MonthRange.of(end);

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  @override
  List<Object?> get props => [start];
}
