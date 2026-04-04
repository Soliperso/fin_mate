import 'package:equatable/equatable.dart';

/// One day's subscription event counts for timeline charts
class SubscriptionTimelineEntity extends Equatable {
  final DateTime periodDate;
  final int newSubs;
  final int cancellations;
  final int renewals;
  final int trials;

  const SubscriptionTimelineEntity({
    required this.periodDate,
    required this.newSubs,
    required this.cancellations,
    required this.renewals,
    required this.trials,
  });

  @override
  List<Object?> get props =>
      [periodDate, newSubs, cancellations, renewals, trials];
}
