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
}
