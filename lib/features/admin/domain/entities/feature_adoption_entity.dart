import 'package:equatable/equatable.dart';

/// Feature adoption statistics
class FeatureAdoptionEntity extends Equatable {
  final String featureName;
  final int usersUsingFeature;
  final int totalUsers;
  final double adoptionPercentage;
  final int totalItems;

  const FeatureAdoptionEntity({
    required this.featureName,
    required this.usersUsingFeature,
    required this.totalUsers,
    required this.adoptionPercentage,
    required this.totalItems,
  });

  @override
  List<Object?> get props => [
        featureName,
        usersUsingFeature,
        totalUsers,
        adoptionPercentage,
        totalItems,
      ];
}
