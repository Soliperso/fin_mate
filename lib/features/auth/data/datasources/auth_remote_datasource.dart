import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/user_model.dart';

/// Remote datasource for authentication
class AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    // Fetch user profile from database
    final response = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    return UserModel.fromSupabase(authUser, response);
  }

  /// Sign in with email and password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Sign in failed: No user returned');
    }

    // Fetch user profile
    final profile = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', response.user!.id)
        .maybeSingle();

    return UserModel.fromSupabase(response.user!, profile);
  }

  /// Sign up with email and password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );

    if (response.user == null) {
      throw Exception('Sign up failed: No user returned');
    }

    // Sign out after signup so user must verify email and login
    await _supabase.auth.signOut();

    // Return user (will not be used since we sign out)
    return UserModel.fromSupabase(response.user!, null);
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? currency,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (dateOfBirth != null) {
      updates['date_of_birth'] = dateOfBirth.toIso8601String();
    }
    if (currency != null) updates['currency'] = currency;

    await _supabase.from('user_profiles').update(updates).eq('id', userId);

    // Fetch updated profile
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) {
      throw Exception('No authenticated user');
    }

    final profile = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromSupabase(authUser, profile);
  }

  /// Upload avatar
  Future<String> uploadAvatar(String userId, String filePath) async {
    final file = File(filePath);
    final fileExt = filePath.split('.').last;
    final fileName = '$userId/avatar.$fileExt';

    await _supabase.storage.from('avatars').upload(
          fileName,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

    // Update profile with avatar URL
    await _supabase
        .from('user_profiles')
        .update({'avatar_url': publicUrl}).eq('id', userId);

    return publicUrl;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Listen to auth state changes
  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;

      final profile = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return UserModel.fromSupabase(user, profile);
    });
  }

  /// Verify email with OTP
  Future<UserModel> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: token,
    );

    if (response.user == null) {
      throw Exception('OTP verification failed: No user returned');
    }

    // Fetch user profile
    final profile = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', response.user!.id)
        .maybeSingle();

    return UserModel.fromSupabase(response.user!, profile);
  }

  /// Resend OTP to email
  Future<void> resendOTP(String email) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }
}
