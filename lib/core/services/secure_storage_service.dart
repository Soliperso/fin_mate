import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive data like credentials
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys for stored values
  static const _keyEmail = 'saved_email';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyRefreshToken = 'biometric_refresh_token';
  static const _keyMfaEnabled = 'mfa_enabled';
  static const _keyMfaMethod = 'mfa_method';
  static const _keyTotpSecret = 'totp_secret';
  static const _keyHasSeenOnboarding = 'has_seen_onboarding';

  Future<void> saveHasSeenOnboarding() async {
    await _storage.write(key: _keyHasSeenOnboarding, value: 'true');
  }

  Future<bool> getHasSeenOnboarding() async {
    return await _storage.read(key: _keyHasSeenOnboarding) == 'true';
  }

  /// Save email for auto-fill
  Future<void> saveEmail(String email) async {
    await _storage.write(key: _keyEmail, value: email);
  }

  /// Get saved email
  Future<String?> getSavedEmail() async {
    return await _storage.read(key: _keyEmail);
  }

  /// Clear saved email
  Future<void> clearEmail() async {
    await _storage.delete(key: _keyEmail);
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

  /// Save refresh token for biometric re-authentication
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// Get saved refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Clear saved refresh token
  Future<void> clearRefreshToken() async {
    await _storage.delete(key: _keyRefreshToken);
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

  // ============================================================================
  // Smart Alert Dismissals
  // ============================================================================

  Future<Set<String>> getDismissedAlertIds(String userId) async {
    final raw = await _storage.read(key: 'dismissed_alerts_$userId');
    if (raw == null || raw.isEmpty) return {};
    return Set<String>.from(jsonDecode(raw) as List);
  }

  Future<void> saveDismissedAlertIds(String userId, Set<String> ids) async {
    await _storage.write(
      key: 'dismissed_alerts_$userId',
      value: jsonEncode(ids.toList()),
    );
  }
}
