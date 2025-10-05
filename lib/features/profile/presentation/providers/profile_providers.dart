import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

// ============================================================================
// Data Source Provider
// ============================================================================

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource();
});

// ============================================================================
// Repository Provider
// ============================================================================

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.read(profileRemoteDataSourceProvider),
  );
});

// ============================================================================
// Profile Provider
// ============================================================================

final profileProvider = FutureProvider<ProfileEntity?>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final repository = ref.watch(profileRepositoryProvider);

  if (authState.user == null) return null;

  return repository.getProfile(authState.user!.id);
});

// ============================================================================
// Profile State Notifier
// ============================================================================

class ProfileState {
  final ProfileEntity? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool isUploadingAvatar;

  ProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.isUploadingAvatar = false,
  });

  ProfileState copyWith({
    ProfileEntity? profile,
    bool? isLoading,
    String? errorMessage,
    bool? isUploadingAvatar,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final String userId;

  ProfileNotifier(this._repository, this.userId) : super(ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.getProfile(userId);
      state = ProfileState(profile: profile, isLoading: false);
    } catch (e) {
      state = ProfileState(
        isLoading: false,
        errorMessage: 'Failed to load profile: ${e.toString()}',
      );
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? currency,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        currency: currency,
      );
      state = ProfileState(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update profile: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> uploadAndUpdateAvatar(String filePath) async {
    state = state.copyWith(isUploadingAvatar: true, errorMessage: null);
    try {
      // Upload avatar
      final avatarUrl = await _repository.uploadAvatar(
        userId: userId,
        filePath: filePath,
      );

      // Update profile with new avatar URL
      final profile = await _repository.updateAvatar(
        userId: userId,
        avatarUrl: avatarUrl,
      );

      state = ProfileState(profile: profile, isUploadingAvatar: false);
    } catch (e) {
      state = state.copyWith(
        isUploadingAvatar: false,
        errorMessage: 'Failed to upload avatar: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> deleteAvatar() async {
    state = state.copyWith(isUploadingAvatar: true, errorMessage: null);
    try {
      await _repository.deleteAvatar(userId);
      await loadProfile(); // Reload profile
    } catch (e) {
      state = state.copyWith(
        isUploadingAvatar: false,
        errorMessage: 'Failed to delete avatar: ${e.toString()}',
      );
      rethrow;
    }
  }
}

final profileNotifierProvider =
    StateNotifierProvider.family<ProfileNotifier, ProfileState, String>(
  (ref, userId) {
    return ProfileNotifier(ref.watch(profileRepositoryProvider), userId);
  },
);

// ============================================================================
// Current User Profile Provider
// ============================================================================

final currentUserProfileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState.user == null) {
    throw Exception('User not authenticated');
  }
  return ProfileNotifier(
    ref.watch(profileRepositoryProvider),
    authState.user!.id,
  );
});
