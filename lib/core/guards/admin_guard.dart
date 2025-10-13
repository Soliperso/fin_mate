import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/domain/entities/profile_entity.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';

/// Admin guard utility for checking admin privileges
class AdminGuard {
  /// Check if the current user has admin role
  /// Returns true if user is admin, false otherwise
  static bool isAdmin(WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (profile) => profile?.isAdmin ?? false,
      loading: () => false,
      error: (_, __) => false,
    );
  }

  /// Get the current user's profile if they are admin
  /// Returns ProfileEntity if admin, null otherwise
  static ProfileEntity? getAdminProfile(WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (profile) => (profile?.isAdmin ?? false) ? profile : null,
      loading: () => null,
      error: (_, __) => null,
    );
  }
}

/// Provider to check if current user is admin
final isAdminProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(profileProvider);

  return profileAsync.when(
    data: (profile) => profile?.isAdmin ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});
