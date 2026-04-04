import 'package:equatable/equatable.dart';

/// A single churn / subscription KPI metric
class ChurnMetricEntity extends Equatable {
  final String metricKey;
  final String metricLabel;
  final double metricValue;
  final double metricChange; // absolute change vs previous period
  final String metricUnit;   // 'count', 'percent', 'currency'

  const ChurnMetricEntity({
    required this.metricKey,
    required this.metricLabel,
    required this.metricValue,
    required this.metricChange,
    required this.metricUnit,
  });

  bool get isPercent => metricUnit == 'percent';

  /// True when a lower value is better (churn rate, cancellations)
  bool get lowerIsBetter =>
      metricKey == 'churn_rate' ||
      metricKey == 'revenue_churn_rate' ||
      metricKey == 'cancellations';

  @override
  List<Object?> get props =>
      [metricKey, metricLabel, metricValue, metricChange, metricUnit];
}
