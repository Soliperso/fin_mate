import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/services/mfa_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../models/user_model.dart';

/// Remote datasource for authentication
class AuthRemoteDataSource {
  final SupabaseClient _supabase;
  final MfaService _mfaService;
  final SecureStorageService _storage;

  AuthRemoteDataSource({
    SupabaseClient? supabaseClient,
    MfaService? mfaService,
    SecureStorageService? storage,
  })  : _supabase = supabaseClient ?? supabase,
        _mfaService = mfaService ?? MfaService(),
        _storage = storage ?? SecureStorageService();

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

  // ============================================================================
  // MFA Methods
  // ============================================================================

  /// Enable MFA with email OTP
  Future<void> enableEmailMfa() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Update user profile to indicate MFA is enabled with email method
    await _supabase.from('user_profiles').update({
      'mfa_enabled': true,
      'mfa_method': 'email',
    }).eq('id', user.id);

    // Save to local storage
    await _storage.setMfaEnabled(true);
    await _storage.setMfaMethod('email');
  }

  /// Enable MFA with TOTP (returns secret for QR code generation)
  Future<String> enableTotpMfa() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Generate TOTP secret
    final secret = _mfaService.generateTotpSecret();

    // Save secret temporarily (will be confirmed after verification)
    await _storage.saveTotpSecret(secret);

    return secret;
  }

  /// Verify and activate TOTP MFA
  Future<void> verifyAndActivateTotpMfa({
    required String secret,
    required String code,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Verify the TOTP code
    final isValid = _mfaService.verifyTotpCode(
      secret: secret,
      code: code,
    );

    if (!isValid) {
      throw Exception('Invalid TOTP code');
    }

    // Update user profile to indicate MFA is enabled with TOTP
    await _supabase.from('user_profiles').update({
      'mfa_enabled': true,
      'mfa_method': 'totp',
      'totp_secret': secret,
    }).eq('id', user.id);

    // Save to local storage
    await _storage.setMfaEnabled(true);
    await _storage.setMfaMethod('totp');
    await _storage.saveTotpSecret(secret);
  }

  /// Disable MFA
  Future<void> disableMfa() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Update user profile
    await _supabase.from('user_profiles').update({
      'mfa_enabled': false,
      'mfa_method': null,
      'totp_secret': null,
    }).eq('id', user.id);

    // Clear local storage
    await _storage.clearMfaSettings();
  }

  /// Send email OTP for MFA verification
  Future<void> sendMfaEmailOtp() async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated user');
    }

    // Use Supabase's OTP functionality
    await _supabase.auth.signInWithOtp(email: user.email!);
  }

  /// Verify MFA code (works for both email and TOTP)
  Future<bool> verifyMfaCode(String code) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Get MFA method from local storage first, then fallback to database
    String? mfaMethod = await _storage.getMfaMethod();

    if (mfaMethod == null) {
      // Fetch from database
      final profile = await _supabase
          .from('user_profiles')
          .select('mfa_method')
          .eq('id', user.id)
          .maybeSingle();

      mfaMethod = profile?['mfa_method'];
    }

    if (mfaMethod == 'totp') {
      // Verify TOTP code
      final secret = await _storage.getTotpSecret();
      if (secret == null) {
        // Fetch from database
        final profile = await _supabase
            .from('user_profiles')
            .select('totp_secret')
            .eq('id', user.id)
            .maybeSingle();

        final dbSecret = profile?['totp_secret'];
        if (dbSecret == null) {
          throw Exception('TOTP secret not found');
        }

        return _mfaService.verifyTotpCode(
          secret: dbSecret,
          code: code,
        );
      }

      return _mfaService.verifyTotpCode(
        secret: secret,
        code: code,
      );
    } else if (mfaMethod == 'email') {
      // Verify email OTP using Supabase
      try {
        final response = await _supabase.auth.verifyOTP(
          type: OtpType.email,
          email: user.email!,
          token: code,
        );
        return response.user != null;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  /// Check if user has MFA enabled
  Future<bool> isMfaEnabled() async {
    // Check local storage first
    final localMfaEnabled = await _storage.isMfaEnabled();
    if (localMfaEnabled) return true;

    // Fallback to database
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final profile = await _supabase
        .from('user_profiles')
        .select('mfa_enabled')
        .eq('id', user.id)
        .maybeSingle();

    return profile?['mfa_enabled'] == true;
  }

  /// Get current MFA method
  Future<String?> getMfaMethod() async {
    // Check local storage first
    final localMethod = await _storage.getMfaMethod();
    if (localMethod != null) return localMethod;

    // Fallback to database
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final profile = await _supabase
        .from('user_profiles')
        .select('mfa_method')
        .eq('id', user.id)
        .maybeSingle();

    return profile?['mfa_method'];
  }
}
