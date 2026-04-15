import 'package:equatable/equatable.dart';

/// Profile entity representing user profile data
class ProfileEntity extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final DateTime? dateOfBirth;
  final String currency;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.dateOfBirth,
    this.currency = 'USD',
    this.role = 'user',
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        avatarUrl,
        phone,
        dateOfBirth,
        currency,
        role,
        createdAt,
        updatedAt,
      ];

  ProfileEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phone,
    DateTime? dateOfBirth,
    String? currency,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      currency: currency ?? this.currency,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name (full name or email)
  String get displayName => fullName ?? email.split('@').first;

  /// Get initials for avatar
  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  /// Check if user has admin role
  bool get isAdmin => role == 'admin';
}
