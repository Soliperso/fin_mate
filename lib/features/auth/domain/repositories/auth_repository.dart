import '../entities/user_entity.dart';

/// Abstract auth repository interface
abstract class AuthRepository {
  /// Get current authenticated user
  Future<UserEntity?> getCurrentUser();

  /// Sign in with email and password
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  });

  /// Sign out
  Future<void> signOut();

  /// Reset password
  Future<void> resetPassword(String email);

  /// Update user profile
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? currency,
  });

  /// Upload avatar
  Future<String> uploadAvatar(String filePath);

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Listen to auth state changes
  Stream<UserEntity?> get authStateChanges;

  /// Verify email with OTP
  Future<UserEntity> verifyEmailOTP({
    required String email,
    required String token,
  });

  /// Resend OTP to email
  Future<void> resendOTP(String email);
}
