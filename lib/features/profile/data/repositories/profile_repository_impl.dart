import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// Implementation of ProfileRepository
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<ProfileEntity?> getProfile(String userId) async {
    try {
      final profile = await _remoteDataSource.getProfile(userId);
      return profile?.toEntity();
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  @override
  Future<ProfileEntity> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? currency,
  }) async {
    try {
      final profile = await _remoteDataSource.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        currency: currency,
      );
      return profile.toEntity();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    try {
      return await _remoteDataSource.uploadAvatar(
        userId: userId,
        filePath: filePath,
      );
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  @override
  Future<ProfileEntity> updateAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    try {
      final profile = await _remoteDataSource.updateAvatar(
        userId: userId,
        avatarUrl: avatarUrl,
      );
      return profile.toEntity();
    } catch (e) {
      throw Exception('Failed to update avatar: $e');
    }
  }

  @override
  Future<void> deleteAvatar(String userId) async {
    try {
      await _remoteDataSource.deleteAvatar(userId);
    } catch (e) {
      throw Exception('Failed to delete avatar: $e');
    }
  }
}
