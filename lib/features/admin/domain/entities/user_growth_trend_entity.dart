import 'package:equatable/equatable.dart';

/// User growth trend data point
class UserGrowthTrendEntity extends Equatable {
  final DateTime periodStart;
  final int newUsers;
  final int cumulativeUsers;

  const UserGrowthTrendEntity({
    required this.periodStart,
    required this.newUsers,
    required this.cumulativeUsers,
  });

  @override
  List<Object?> get props => [periodStart, newUsers, cumulativeUsers];
}
