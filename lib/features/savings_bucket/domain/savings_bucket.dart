import 'package:equatable/equatable.dart';

class SavingsBucket extends Equatable {
  const SavingsBucket({
    this.id,
    required this.bucketName,
    this.allocatedAmount = 0,
    this.targetAmount = 0,
  });

  final int? id;
  final String bucketName;
  final double allocatedAmount;

  // 0 means the bucket has no target.
  final double targetAmount;

  bool get hasTarget => targetAmount > 0;

  // 0.0 - 1.0, clamped for progress bars.
  double get progress =>
      hasTarget ? (allocatedAmount / targetAmount).clamp(0.0, 1.0) : 0;

  bool get isTargetReached => hasTarget && allocatedAmount >= targetAmount;

  @override
  List<Object?> get props => [id, bucketName, allocatedAmount, targetAmount];
}

// Thrown when an allocation or withdrawal would break balance rules.
class SavingsRuleException implements Exception {
  const SavingsRuleException(this.message);

  final String message;

  @override
  String toString() => 'SavingsRuleException: $message';
}
