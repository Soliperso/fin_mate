import 'package:equatable/equatable.dart';

/// User engagement metric
class EngagementMetricEntity extends Equatable {
  final String metricName;
  final double metricValue;
  final String metricDescription;

  const EngagementMetricEntity({
    required this.metricName,
    required this.metricValue,
    required this.metricDescription,
  });

  @override
  List<Object?> get props => [metricName, metricValue, metricDescription];
}
