import '../../domain/entities/feature_adoption_entity.dart';

class FeatureAdoptionModel extends FeatureAdoptionEntity {
  const FeatureAdoptionModel({
    required super.featureName,
    required super.usersUsingFeature,
    required super.totalUsers,
    required super.adoptionPercentage,
    required super.totalItems,
  });

  factory FeatureAdoptionModel.fromJson(Map<String, dynamic> json) {
    return FeatureAdoptionModel(
      featureName: json['feature_name'] ?? '',
      usersUsingFeature: json['users_using_feature'] ?? 0,
      totalUsers: json['total_users'] ?? 0,
      adoptionPercentage: (json['adoption_percentage'] ?? 0).toDouble(),
      totalItems: json['total_items'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feature_name': featureName,
      'users_using_feature': usersUsingFeature,
      'total_users': totalUsers,
      'adoption_percentage': adoptionPercentage,
      'total_items': totalItems,
    };
  }
}
