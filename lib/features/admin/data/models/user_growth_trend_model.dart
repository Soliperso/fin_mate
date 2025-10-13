import '../../domain/entities/user_growth_trend_entity.dart';

class UserGrowthTrendModel extends UserGrowthTrendEntity {
  const UserGrowthTrendModel({
    required super.periodStart,
    required super.newUsers,
    required super.cumulativeUsers,
  });

  factory UserGrowthTrendModel.fromJson(Map<String, dynamic> json) {
    return UserGrowthTrendModel(
      periodStart: DateTime.parse(json['period_start']),
      newUsers: json['new_users'] ?? 0,
      cumulativeUsers: json['cumulative_users'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period_start': periodStart.toIso8601String(),
      'new_users': newUsers,
      'cumulative_users': cumulativeUsers,
    };
  }
}
