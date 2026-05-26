import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_client.dart';

/// Client-side feature flags fetched once per session.
/// Returns a map of flag key → effective enabled state.
///
/// Rollout is applied deterministically: a user always lands in the same bucket
/// so they never see a flag flicker between states. Bucket = userId.hashCode % 100.
/// Fails open (returns true) if flags are unavailable.
final appFeatureFlagsProvider = FutureProvider<Map<String, bool>>((ref) async {
  try {
    final result = await supabase.rpc('get_feature_flags');
    if (result == null) return {};
    final userId = supabase.auth.currentUser?.id ?? '';
    final bucket = userId.hashCode.abs() % 100;
    return Map.fromEntries(
      (result as List).map((f) {
        final enabled = f['enabled'] as bool;
        final pct = (f['rollout_percentage'] as int?) ?? 100;
        final inRollout = bucket < pct;
        return MapEntry(f['key'] as String, enabled && inRollout);
      }),
    );
  } catch (_) {
    return {};
  }
});

/// Returns whether a feature is enabled. Defaults to true while loading or on error.
bool featureEnabled(Map<String, bool>? flags, String key) =>
    flags?[key] ?? true;
