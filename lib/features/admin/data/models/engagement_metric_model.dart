import '../../domain/entities/engagement_metric_entity.dart';

class EngagementMetricModel extends EngagementMetricEntity {
  const EngagementMetricModel({
    required super.metricName,
    required super.metricValue,
    required super.metricDescription,
  });

  factory EngagementMetricModel.fromJson(Map<String, dynamic> json) {
    return EngagementMetricModel(
      metricName: json['metric_name'] ?? '',
      metricValue: (json['metric_value'] ?? 0).toDouble(),
      metricDescription: json['metric_description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metric_name': metricName,
      'metric_value': metricValue,
      'metric_description': metricDescription,
    };
  }
}
