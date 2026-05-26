import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_client.dart';

/// Active announcement banners fetched on dashboard load.
/// Returns an empty list on error (fail open — never block the dashboard).
final activeAnnouncementsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final result = await supabase.rpc('get_active_announcements');
    if (result == null) return [];
    return List<Map<String, dynamic>>.from(result as List);
  } catch (_) {
    return [];
  }
});
