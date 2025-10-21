import 'package:equatable/equatable.dart';

enum AnomalyType {
  unusualAmount, // Transaction much higher than average
  unusualMerchant, // First time buying from this merchant
  unusualTime, // Purchase at unusual time of day
  unusualFrequency, // Too many transactions in short period
  suspiciousPattern, // Matches fraud-like pattern
  unknown;

  String get displayName {
    switch (this) {
      case AnomalyType.unusualAmount:
        return 'Unusual Amount';
      case AnomalyType.unusualMerchant:
        return 'New Merchant';
      case AnomalyType.unusualTime:
        return 'Unusual Time';
      case AnomalyType.unusualFrequency:
        return 'High Frequency';
      case AnomalyType.suspiciousPattern:
        return 'Suspicious Pattern';
      case AnomalyType.unknown:
        return 'Unknown Anomaly';
    }
  }
}

enum AnomalySeverity {
  low, // Interesting but not concerning
  medium, // Worth reviewing
  high, // Should investigate
  critical; // Likely fraud or error

  String get displayName {
    switch (this) {
      case AnomalySeverity.low:
        return 'Low';
      case AnomalySeverity.medium:
        return 'Medium';
      case AnomalySeverity.high:
        return 'High';
      case AnomalySeverity.critical:
        return 'Critical';
    }
  }
}

/// Represents an unusual spending transaction or pattern
class SpendingAnomaly extends Equatable {
  final String id;
  final String transactionId;
  final AnomalyType type;
  final AnomalySeverity severity;
  final String title;
  final String description;
  final double transactionAmount;
  final double? categoryAverage;
  final double? deviationPercentage; // How much higher/lower than expected
  final String category;
  final String merchant;
  final DateTime transactionDate;
  final Map<String, dynamic>? contextData; // Additional context
  final bool isReviewed;

  const SpendingAnomaly({
    required this.id,
    required this.transactionId,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.transactionAmount,
    this.categoryAverage,
    this.deviationPercentage,
    required this.category,
    required this.merchant,
    required this.transactionDate,
    this.contextData,
    this.isReviewed = false,
  });

  @override
  List<Object?> get props => [
        id,
        transactionId,
        type,
        severity,
        title,
        description,
        transactionAmount,
        categoryAverage,
        deviationPercentage,
        category,
        merchant,
        transactionDate,
        contextData,
        isReviewed,
      ];

  SpendingAnomaly copyWith({
    String? id,
    String? transactionId,
    AnomalyType? type,
    AnomalySeverity? severity,
    String? title,
    String? description,
    double? transactionAmount,
    double? categoryAverage,
    double? deviationPercentage,
    String? category,
    String? merchant,
    DateTime? transactionDate,
    Map<String, dynamic>? contextData,
    bool? isReviewed,
  }) {
    return SpendingAnomaly(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      transactionAmount: transactionAmount ?? this.transactionAmount,
      categoryAverage: categoryAverage ?? this.categoryAverage,
      deviationPercentage: deviationPercentage ?? this.deviationPercentage,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      transactionDate: transactionDate ?? this.transactionDate,
      contextData: contextData ?? this.contextData,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'description': description,
      'transaction_amount': transactionAmount,
      'category_average': categoryAverage,
      'deviation_percentage': deviationPercentage,
      'category': category,
      'merchant': merchant,
      'transaction_date': transactionDate.toIso8601String(),
      'context_data': contextData,
      'is_reviewed': isReviewed,
    };
  }

  factory SpendingAnomaly.fromJson(Map<String, dynamic> json) {
    return SpendingAnomaly(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      type: AnomalyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnomalyType.unknown,
      ),
      severity: AnomalySeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AnomalySeverity.low,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      transactionAmount: (json['transaction_amount'] as num).toDouble(),
      categoryAverage: json['category_average'] != null ? (json['category_average'] as num).toDouble() : null,
      deviationPercentage: json['deviation_percentage'] != null ? (json['deviation_percentage'] as num).toDouble() : null,
      category: json['category'] as String,
      merchant: json['merchant'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      contextData: json['context_data'] as Map<String, dynamic>?,
      isReviewed: json['is_reviewed'] as bool? ?? false,
    );
  }
}
