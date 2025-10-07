import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive data like credentials
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys for stored values
  static const _keyRememberMe = 'remember_me';
  static const _keyEmail = 'saved_email';
  static const _keyPassword = 'saved_password';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyMfaEnabled = 'mfa_enabled';
  static const _keyMfaMethod = 'mfa_method';
  static const _keyTotpSecret = 'totp_secret';

  /// Save credentials securely
  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await Future.wait([
      _storage.write(key: _keyRememberMe, value: 'true'),
      _storage.write(key: _keyEmail, value: email),
      _storage.write(key: _keyPassword, value: password),
    ]);
  }

  /// Get saved email
  Future<String?> getSavedEmail() async {
    final rememberMe = await _storage.read(key: _keyRememberMe);
    if (rememberMe != 'true') return null;
    return await _storage.read(key: _keyEmail);
  }

  /// Get saved password
  Future<String?> getSavedPassword() async {
    final rememberMe = await _storage.read(key: _keyRememberMe);
    if (rememberMe != 'true') return null;
    return await _storage.read(key: _keyPassword);
  }

  /// Check if remember me is enabled
  Future<bool> isRememberMeEnabled() async {
    final rememberMe = await _storage.read(key: _keyRememberMe);
    return rememberMe == 'true';
  }

  /// Clear saved credentials
  Future<void> clearCredentials() async {
    await Future.wait([
      _storage.delete(key: _keyRememberMe),
      _storage.delete(key: _keyEmail),
      _storage.delete(key: _keyPassword),
    ]);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ============================================================================
  // Biometric Settings
  // ============================================================================

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  // ============================================================================
  // MFA Settings
  // ============================================================================

  /// Enable/disable MFA
  Future<void> setMfaEnabled(bool enabled) async {
    await _storage.write(key: _keyMfaEnabled, value: enabled.toString());
  }

  /// Check if MFA is enabled
  Future<bool> isMfaEnabled() async {
    final value = await _storage.read(key: _keyMfaEnabled);
    return value == 'true';
  }

  /// Set MFA method (email or totp)
  Future<void> setMfaMethod(String method) async {
    await _storage.write(key: _keyMfaMethod, value: method);
  }

  /// Get MFA method
  Future<String?> getMfaMethod() async {
    return await _storage.read(key: _keyMfaMethod);
  }

  /// Save TOTP secret
  Future<void> saveTotpSecret(String secret) async {
    await _storage.write(key: _keyTotpSecret, value: secret);
  }

  /// Get TOTP secret
  Future<String?> getTotpSecret() async {
    return await _storage.read(key: _keyTotpSecret);
  }

  /// Clear TOTP secret
  Future<void> clearTotpSecret() async {
    await _storage.delete(key: _keyTotpSecret);
  }

  /// Clear all MFA settings
  Future<void> clearMfaSettings() async {
    await Future.wait([
      _storage.delete(key: _keyMfaEnabled),
      _storage.delete(key: _keyMfaMethod),
      _storage.delete(key: _keyTotpSecret),
    ]);
  }
}
