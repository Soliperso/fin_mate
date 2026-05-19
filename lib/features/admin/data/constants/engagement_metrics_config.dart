import 'package:flutter/cupertino.dart';
import 'package:finmate/core/constants/app_colors.dart';

/// Configuration for engagement metrics displayed in analytics
class EngagementMetricsConfig {
  static final Map<String, EngagementMetricConfig> _metrics = {
    'daily_active_users_avg': EngagementMetricConfig(
      key: 'daily_active_users_avg',
      displayName: 'Daily Active Users (Avg)',
      description: 'Average number of unique users per day',
      icon: CupertinoIcons.person_2,
      color: AppColors.brandTeal,
    ),
    'transactions_per_user': EngagementMetricConfig(
      key: 'transactions_per_user',
      displayName: 'Transactions Per Active User',
      description: 'Average transactions per active user',
      icon: CupertinoIcons.arrow_right_arrow_left,
      color: AppColors.brandTeal,
    ),
    'average_transaction_value': EngagementMetricConfig(
      key: 'average_transaction_value',
      displayName: 'Average Transaction Value',
      description: 'Average amount per transaction',
      icon: CupertinoIcons.money_dollar_circle,
      color: AppColors.systemBlue,
    ),
    'user_retention_rate': EngagementMetricConfig(
      key: 'user_retention_rate',
      displayName: 'User Retention Rate',
      description: 'Percentage of users from first half still active in second half',
      icon: CupertinoIcons.arrow_up_right_circle,
      color: AppColors.systemGreen,
    ),
    'bill_settlement_rate': EngagementMetricConfig(
      key: 'bill_settlement_rate',
      displayName: 'Bill Settlement Rate',
      description: 'Percentage of expense splits that have been settled',
      icon: CupertinoIcons.checkmark_circle,
      color: AppColors.systemGreen,
    ),
  };

  static Map<String, EngagementMetricConfig> get metrics => _metrics;

  /// Get metric config by display name (for backward compatibility with existing SQL)
  static EngagementMetricConfig? getByDisplayName(String displayName) {
    return _metrics.values.firstWhere(
      (metric) => metric.displayName == displayName,
      orElse: () => EngagementMetricConfig.fallback(),
    );
  }

  /// Get all metric display names
  static List<String> getAllDisplayNames() {
    return _metrics.values.map((m) => m.displayName).toList();
  }
}

/// Configuration for a single engagement metric
class EngagementMetricConfig {
  final String key;
  final String displayName;
  final String description;
  final IconData icon;
  final Color color;

  EngagementMetricConfig({
    required this.key,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory EngagementMetricConfig.fallback() {
    return EngagementMetricConfig(
      key: 'unknown',
      displayName: 'Unknown Metric',
      description: 'Unknown metric',
      icon: CupertinoIcons.chart_bar,
      color: AppColors.systemBlue,
    );
  }
}
