import '../../domain/entities/subscription_cohort_entity.dart';

class SubscriptionCohortModel extends SubscriptionCohortEntity {
  const SubscriptionCohortModel({
    required super.cohortMonth,
    required super.cohortMonthDate,
    required super.totalSignups,
    required super.premiumCount,
    required super.conversionRate,
  });

  factory SubscriptionCohortModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionCohortModel(
      cohortMonth: json['cohort_month'] ?? '',
      cohortMonthDate: json['cohort_month_date'] != null
          ? DateTime.parse(json['cohort_month_date'])
          : DateTime.now(),
      totalSignups: (json['total_signups'] ?? 0) as int,
      premiumCount: (json['premium_count'] ?? 0) as int,
      conversionRate: (json['conversion_rate'] ?? 0).toDouble(),
    );
  }
}
