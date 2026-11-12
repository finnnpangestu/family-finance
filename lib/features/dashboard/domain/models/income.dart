import 'package:equatable/equatable.dart';

class Income extends Equatable {
  const Income({
    this.id,
    required this.categoryName,
    required this.amount,
    required this.date,
    this.note,
    this.memberId,
  });

  final int? id;

  // Income stream, e.g. "Gaji Utama" or "Usaha Sampingan".
  final String categoryName;
  final double amount;
  final DateTime date;
  final String? note;

  // Family member this belongs to; null = unassigned.
  final int? memberId;

  @override
  List<Object?> get props => [id, categoryName, amount, date, note, memberId];
}
