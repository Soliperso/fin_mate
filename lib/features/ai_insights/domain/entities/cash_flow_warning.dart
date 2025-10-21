import 'package:equatable/equatable.dart';

/// Represents a predicted cash flow issue
class CashFlowWarning extends Equatable {
  final String id;
  final double currentBalance;
  final double projectedBalance;
  final double dailyBurnRate; // Average spending per day
  final int daysUntilLowBalance; // How many days until balance gets critical
  final double safeThreshold; // Minimum balance user should maintain
  final DateTime projectedDate; // When balance will drop below threshold
  final String recommendation; // Action to take
  final List<String> suggestions; // Additional steps

  const CashFlowWarning({
    required this.id,
    required this.currentBalance,
    required this.projectedBalance,
    required this.dailyBurnRate,
    required this.daysUntilLowBalance,
    required this.safeThreshold,
    required this.projectedDate,
    required this.recommendation,
    required this.suggestions,
  });

  bool get isCritical => daysUntilLowBalance <= 3;
  bool get isWarning => daysUntilLowBalance <= 7;
  double get bufferDays => (currentBalance - safeThreshold) / dailyBurnRate;

  @override
  List<Object?> get props => [
        id,
        currentBalance,
        projectedBalance,
        dailyBurnRate,
        daysUntilLowBalance,
        safeThreshold,
        projectedDate,
        recommendation,
        suggestions,
      ];

  CashFlowWarning copyWith({
    String? id,
    double? currentBalance,
    double? projectedBalance,
    double? dailyBurnRate,
    int? daysUntilLowBalance,
    double? safeThreshold,
    DateTime? projectedDate,
    String? recommendation,
    List<String>? suggestions,
  }) {
    return CashFlowWarning(
      id: id ?? this.id,
      currentBalance: currentBalance ?? this.currentBalance,
      projectedBalance: projectedBalance ?? this.projectedBalance,
      dailyBurnRate: dailyBurnRate ?? this.dailyBurnRate,
      daysUntilLowBalance: daysUntilLowBalance ?? this.daysUntilLowBalance,
      safeThreshold: safeThreshold ?? this.safeThreshold,
      projectedDate: projectedDate ?? this.projectedDate,
      recommendation: recommendation ?? this.recommendation,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'current_balance': currentBalance,
      'projected_balance': projectedBalance,
      'daily_burn_rate': dailyBurnRate,
      'days_until_low_balance': daysUntilLowBalance,
      'safe_threshold': safeThreshold,
      'projected_date': projectedDate.toIso8601String(),
      'recommendation': recommendation,
      'suggestions': suggestions,
    };
  }

  factory CashFlowWarning.fromJson(Map<String, dynamic> json) {
    return CashFlowWarning(
      id: json['id'] as String,
      currentBalance: (json['current_balance'] as num).toDouble(),
      projectedBalance: (json['projected_balance'] as num).toDouble(),
      dailyBurnRate: (json['daily_burn_rate'] as num).toDouble(),
      daysUntilLowBalance: json['days_until_low_balance'] as int,
      safeThreshold: (json['safe_threshold'] as num).toDouble(),
      projectedDate: DateTime.parse(json['projected_date'] as String),
      recommendation: json['recommendation'] as String,
      suggestions: List<String>.from(json['suggestions'] as List),
    );
  }
}
