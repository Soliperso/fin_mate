import '../entities/profile_entity.dart';

/// Abstract profile repository interface
abstract class ProfileRepository {
  /// Get current user profile
  Future<ProfileEntity?> getProfile(String userId);

  /// Update user profile
  Future<ProfileEntity> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? currency,
  });

  /// Upload avatar image
  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
  });

  /// Update avatar URL
  Future<ProfileEntity> updateAvatar({
    required String userId,
    required String avatarUrl,
  });

  /// Delete avatar
  Future<void> deleteAvatar(String userId);
}
