import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/supabase_client.dart';

/// Compares two semantic version strings (e.g. "1.2.3").
/// Returns negative if a < b, 0 if equal, positive if a > b.
int _compareVersions(String a, String b) {
  final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  for (int i = 0; i < 3; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va.compareTo(vb);
  }
  return 0;
}

/// Whether the installed app version is below the admin-set minimum.
/// Returns false on any error (fail open — never block users due to a network issue).
final forceUpdateRequiredProvider = FutureProvider<bool>((ref) async {
  try {
    // Only applies to iOS and Android; skip on other platforms (web, desktop).
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    final platform = Platform.isIOS ? 'ios' : 'android';

    final row = await supabase
        .from('app_versions')
        .select('min_version, force_update')
        .eq('platform', platform)
        .maybeSingle();

    if (row == null) return false;
    if (!(row['force_update'] as bool? ?? false)) return false;

    final info = await PackageInfo.fromPlatform();
    final minVersion = row['min_version'] as String? ?? '0.0.0';
    return _compareVersions(info.version, minVersion) < 0;
  } catch (_) {
    return false;
  }
});
