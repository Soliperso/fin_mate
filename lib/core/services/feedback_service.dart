import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/supabase_client.dart';

class FeedbackService {
  static Future<void> submit({
    required String category,
    required String message,
  }) async {
    final info = await PackageInfo.fromPlatform();
    final platform = Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'other';
    await supabase.from('user_feedback').insert({
      'user_id': supabase.auth.currentUser?.id,
      'category': category,
      'message': message,
      'app_version': info.version,
      'platform': platform,
    });
  }
}
