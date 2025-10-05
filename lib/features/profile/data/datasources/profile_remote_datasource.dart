import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/profile_model.dart';

/// Remote datasource for profile data
class ProfileRemoteDataSource {
  final SupabaseClient _supabase;

  ProfileRemoteDataSource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  /// Get user profile
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Update user profile
  Future<ProfileModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? currency,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (dateOfBirth != null) {
        updates['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0];
      }
      if (currency != null) updates['currency'] = currency;

      await _supabase.from('user_profiles').update(updates).eq('id', userId);

      // Fetch updated profile
      final profile = await getProfile(userId);
      if (profile == null) {
        throw Exception('Profile not found after update');
      }

      return profile;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Upload avatar image
  Future<String> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      final fileExt = filePath.split('.').last.toLowerCase();
      final fileName = '$userId/avatar.$fileExt';

      // Upload to Supabase Storage
      await _supabase.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: null, // Auto-detect
            ),
          );

      // Get public URL
      final publicUrl =
          _supabase.storage.from('avatars').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  /// Update avatar URL in profile
  Future<ProfileModel> updateAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({'avatar_url': avatarUrl}).eq('id', userId);

      // Fetch updated profile
      final profile = await getProfile(userId);
      if (profile == null) {
        throw Exception('Profile not found after avatar update');
      }

      return profile;
    } catch (e) {
      throw Exception('Failed to update avatar URL: $e');
    }
  }

  /// Delete avatar
  Future<void> deleteAvatar(String userId) async {
    try {
      // Get current profile to find avatar URL
      final profile = await getProfile(userId);
      if (profile?.avatarUrl == null) return;

      // Extract filename from URL
      final fileName = '$userId/avatar';

      // Delete from storage (try common extensions)
      for (final ext in ['jpg', 'jpeg', 'png', 'webp']) {
        try {
          await _supabase.storage.from('avatars').remove(['$fileName.$ext']);
        } catch (_) {
          // Ignore if file doesn't exist
        }
      }

      // Remove avatar URL from profile
      await _supabase
          .from('user_profiles')
          .update({'avatar_url': null}).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete avatar: $e');
    }
  }
}
