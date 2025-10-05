import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

/// User model for data layer
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.avatarUrl,
    super.phone,
    super.dateOfBirth,
    super.currency,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create UserModel from Supabase User and profile data
  factory UserModel.fromSupabase(User authUser, Map<String, dynamic>? profile) {
    final now = DateTime.now();
    return UserModel(
      id: authUser.id,
      email: authUser.email ?? '',
      fullName: profile?['full_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      phone: profile?['phone'] as String?,
      dateOfBirth: profile?['date_of_birth'] != null
          ? DateTime.parse(profile!['date_of_birth'] as String)
          : null,
      currency: (profile?['currency'] as String?) ?? 'USD',
      createdAt: profile?['created_at'] != null
          ? DateTime.parse(profile!['created_at'] as String)
          : now,
      updatedAt: profile?['updated_at'] != null
          ? DateTime.parse(profile!['updated_at'] as String)
          : now,
    );
  }

  /// Create UserModel from JSON (from database)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      currency: (json['currency'] as String?) ?? 'USD',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      fullName: fullName,
      avatarUrl: avatarUrl,
      phone: phone,
      dateOfBirth: dateOfBirth,
      currency: currency,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
