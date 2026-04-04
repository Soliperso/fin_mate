import '../../domain/entities/churn_metric_entity.dart';

class ChurnMetricModel extends ChurnMetricEntity {
  const ChurnMetricModel({
    required super.metricKey,
    required super.metricLabel,
    required super.metricValue,
    required super.metricChange,
    required super.metricUnit,
  });

  factory ChurnMetricModel.fromJson(Map<String, dynamic> json) {
    return ChurnMetricModel(
      metricKey: json['metric_key'] ?? '',
      metricLabel: json['metric_label'] ?? '',
      metricValue: (json['metric_value'] ?? 0).toDouble(),
      metricChange: (json['metric_change'] ?? 0).toDouble(),
      metricUnit: json['metric_unit'] ?? 'count',
    );
  }
}
