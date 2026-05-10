import 'package:equatable/equatable.dart';

/// One row in the signup-month cohort table
class SubscriptionCohortEntity extends Equatable {
  final String cohortMonth; // e.g. 'Jan 2025'
  final DateTime cohortMonthDate; // for sorting / charting
  final int totalSignups;
  final int premiumCount;
  final double conversionRate; // percent

  const SubscriptionCohortEntity({
    required this.cohortMonth,
    required this.cohortMonthDate,
    required this.totalSignups,
    required this.premiumCount,
    required this.conversionRate,
  });

  @override
  List<Object?> get props => [
        cohortMonth,
        cohortMonthDate,
        totalSignups,
        premiumCount,
        conversionRate,
      ];
}
