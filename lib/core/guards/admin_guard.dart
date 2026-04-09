import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_client.dart';
import '../../features/profile/domain/entities/profile_entity.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';

/// Server-side admin verification — calls verify_admin_access() RPC.
/// Returns false on any error to fail-safe.
final serverAdminVerifiedProvider = FutureProvider<bool>((ref) async {
  try {
    final result = await supabase.rpc('verify_admin_access');
    return result as bool? ?? false;
  } catch (_) {
    return false;
  }
});

/// Admin guard utility for checking admin privileges.
/// Uses both local profile cache AND server-side RPC for defence-in-depth.
class AdminGuard {
  /// Check if the current user has admin role (local profile cache).
  static bool isAdmin(WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return profileAsync.when(
      data: (profile) => profile?.isAdmin ?? false,
      loading: () => false,
      error: (error, stack) => false,
    );
  }

  /// Get the current user's profile if they are admin.
  static ProfileEntity? getAdminProfile(WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return profileAsync.when(
      data: (profile) => (profile?.isAdmin ?? false) ? profile : null,
      loading: () => null,
      error: (error, stack) => null,
    );
  }
}

/// Provider to check if current user is admin (local profile cache).
/// Use [serverAdminVerifiedProvider] for sensitive operations.
final isAdminProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(profileProvider);
  return profileAsync.when(
    data: (profile) => profile?.isAdmin ?? false,
    loading: () => false,
    error: (error, stack) => false,
  );
});
