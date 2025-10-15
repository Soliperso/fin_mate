import 'package:equatable/equatable.dart';

enum EmergencyFundLevel {
  critical, // < 1 month
  low, // 1-2 months
  moderate, // 2-4 months
  good, // 4-6 months
  excellent, // > 6 months
}

class EmergencyFundStatus extends Equatable {
  final double currentAmount;
  final double minimumRecommended; // 3 months
  final double targetRecommended; // 6 months
  final double averageMonthlyExpenses;
  final double readinessScore; // 0-100
  final double monthsCovered;
  final EmergencyFundLevel level;
  final List<String> recommendations;

  const EmergencyFundStatus({
    required this.currentAmount,
    required this.minimumRecommended,
    required this.targetRecommended,
    required this.averageMonthlyExpenses,
    required this.readinessScore,
    required this.monthsCovered,
    required this.level,
    required this.recommendations,
  });

  bool get isHealthy => level == EmergencyFundLevel.good || level == EmergencyFundLevel.excellent;
  bool get needsAttention => level == EmergencyFundLevel.critical || level == EmergencyFundLevel.low;

  double get remainingToMinimum => (minimumRecommended - currentAmount).clamp(0, double.infinity);
  double get remainingToTarget => (targetRecommended - currentAmount).clamp(0, double.infinity);

  String get statusMessage {
    switch (level) {
      case EmergencyFundLevel.critical:
        return 'Your emergency fund needs immediate attention';
      case EmergencyFundLevel.low:
        return 'Building your emergency fund is recommended';
      case EmergencyFundLevel.moderate:
        return 'Your emergency fund is growing';
      case EmergencyFundLevel.good:
        return 'Your emergency fund is in good shape';
      case EmergencyFundLevel.excellent:
        return 'Excellent! Your emergency fund is strong';
    }
  }

  @override
  List<Object?> get props => [
        currentAmount,
        minimumRecommended,
        targetRecommended,
        averageMonthlyExpenses,
        readinessScore,
        monthsCovered,
        level,
        recommendations,
      ];
}
