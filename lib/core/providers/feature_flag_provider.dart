import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_client.dart';

/// Client-side feature flags fetched once per session.
/// Returns a map of flag key → enabled. Fails open (defaults to true).
final appFeatureFlagsProvider = FutureProvider<Map<String, bool>>((ref) async {
  try {
    final result = await supabase.rpc('get_feature_flags');
    if (result == null) return {};
    return Map.fromEntries(
      (result as List)
          .map((f) => MapEntry(f['key'] as String, f['enabled'] as bool)),
    );
  } catch (_) {
    return {};
  }
});

/// Returns whether a feature is enabled. Defaults to true while loading or on error.
bool featureEnabled(Map<String, bool>? flags, String key) =>
    flags?[key] ?? true;
