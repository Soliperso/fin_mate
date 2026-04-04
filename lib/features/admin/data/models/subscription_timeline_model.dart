import '../../domain/entities/subscription_timeline_entity.dart';

class SubscriptionTimelineModel extends SubscriptionTimelineEntity {
  const SubscriptionTimelineModel({
    required super.periodDate,
    required super.newSubs,
    required super.cancellations,
    required super.renewals,
    required super.trials,
  });

  factory SubscriptionTimelineModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionTimelineModel(
      periodDate: json['period_date'] != null
          ? DateTime.parse(json['period_date'])
          : DateTime.now(),
      newSubs: (json['new_subs'] ?? 0) as int,
      cancellations: (json['cancellations'] ?? 0) as int,
      renewals: (json['renewals'] ?? 0) as int,
      trials: (json['trials'] ?? 0) as int,
    );
  }
}
