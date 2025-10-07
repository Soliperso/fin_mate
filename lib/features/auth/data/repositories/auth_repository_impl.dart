import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return user?.toEntity();
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return user.toEntity();
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final user = await _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      return user.toEntity();
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _remoteDataSource.resetPassword(email);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? currency,
  }) async {
    try {
      final currentUser = await _remoteDataSource.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final user = await _remoteDataSource.updateProfile(
        userId: currentUser.id,
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        currency: currency,
      );
      return user.toEntity();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    try {
      final currentUser = await _remoteDataSource.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      return await _remoteDataSource.uploadAvatar(currentUser.id, filePath);
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _remoteDataSource.isAuthenticated();
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges
        .map((user) => user?.toEntity());
  }

  @override
  Future<UserEntity> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    try {
      final user = await _remoteDataSource.verifyEmailOTP(
        email: email,
        token: token,
      );
      return user.toEntity();
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  @override
  Future<void> resendOTP(String email) async {
    try {
      await _remoteDataSource.resendOTP(email);
    } catch (e) {
      throw Exception('Failed to resend OTP: $e');
    }
  }

  @override
  Future<void> enableEmailMfa() async {
    try {
      await _remoteDataSource.enableEmailMfa();
    } catch (e) {
      throw Exception('Failed to enable email MFA: $e');
    }
  }

  @override
  Future<String> enableTotpMfa() async {
    try {
      return await _remoteDataSource.enableTotpMfa();
    } catch (e) {
      throw Exception('Failed to enable TOTP MFA: $e');
    }
  }

  @override
  Future<void> verifyAndActivateTotpMfa({
    required String secret,
    required String code,
  }) async {
    try {
      await _remoteDataSource.verifyAndActivateTotpMfa(
        secret: secret,
        code: code,
      );
    } catch (e) {
      throw Exception('Failed to verify and activate TOTP MFA: $e');
    }
  }

  @override
  Future<void> disableMfa() async {
    try {
      await _remoteDataSource.disableMfa();
    } catch (e) {
      throw Exception('Failed to disable MFA: $e');
    }
  }

  @override
  Future<void> sendMfaEmailOtp() async {
    try {
      await _remoteDataSource.sendMfaEmailOtp();
    } catch (e) {
      throw Exception('Failed to send MFA email OTP: $e');
    }
  }

  @override
  Future<bool> verifyMfaCode(String code) async {
    try {
      return await _remoteDataSource.verifyMfaCode(code);
    } catch (e) {
      throw Exception('Failed to verify MFA code: $e');
    }
  }

  @override
  Future<bool> isMfaEnabled() async {
    try {
      return await _remoteDataSource.isMfaEnabled();
    } catch (e) {
      throw Exception('Failed to check MFA status: $e');
    }
  }

  @override
  Future<String?> getMfaMethod() async {
    try {
      return await _remoteDataSource.getMfaMethod();
    } catch (e) {
      throw Exception('Failed to get MFA method: $e');
    }
  }
}
