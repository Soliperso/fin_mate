import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

/// Service for handling biometric authentication
class BiometricService {
  final LocalAuthentication _localAuth;

  BiometricService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Check if biometrics are enrolled (fingerprint/face/etc)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isSupported = await isDeviceSupported();
      final canCheck = await canCheckBiometrics();
      return isSupported && canCheck;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate using biometrics
  /// Returns true if authentication successful, false otherwise
  Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Please authenticate to access FinMate',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notAvailable,
          errorMessage: 'Biometric authentication is not available on this device',
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        return BiometricAuthResult(success: true);
      } else {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.userCancelled,
          errorMessage: 'Authentication was cancelled',
        );
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        errorType: BiometricErrorType.unknown,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get user-friendly biometric type name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Biometric';
      case BiometricType.weak:
        return 'Biometric';
    }
  }

  /// Get primary biometric type for display
  Future<String?> getPrimaryBiometricType() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) return null;

      // Prioritize Face ID, then fingerprint
      if (biometrics.contains(BiometricType.face)) {
        return getBiometricTypeName(BiometricType.face);
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return getBiometricTypeName(BiometricType.fingerprint);
      } else if (biometrics.contains(BiometricType.iris)) {
        return getBiometricTypeName(BiometricType.iris);
      } else {
        return getBiometricTypeName(biometrics.first);
      }
    } catch (e) {
      return null;
    }
  }

  BiometricAuthResult _handlePlatformException(PlatformException e) {
    BiometricErrorType errorType;
    String errorMessage;

    switch (e.code) {
      case auth_error.notAvailable:
        errorType = BiometricErrorType.notAvailable;
        errorMessage = 'Biometric authentication is not available';
        break;
      case auth_error.notEnrolled:
        errorType = BiometricErrorType.notEnrolled;
        errorMessage = 'No biometrics enrolled. Please set up biometrics in device settings';
        break;
      case auth_error.lockedOut:
        errorType = BiometricErrorType.lockedOut;
        errorMessage = 'Too many attempts. Biometric authentication is temporarily locked';
        break;
      case auth_error.permanentlyLockedOut:
        errorType = BiometricErrorType.permanentlyLockedOut;
        errorMessage = 'Biometric authentication is permanently locked. Please use password';
        break;
      case auth_error.passcodeNotSet:
        errorType = BiometricErrorType.passcodeNotSet;
        errorMessage = 'Device passcode is not set. Please set a passcode first';
        break;
      default:
        errorType = BiometricErrorType.unknown;
        errorMessage = e.message ?? 'Biometric authentication failed';
    }

    return BiometricAuthResult(
      success: false,
      errorType: errorType,
      errorMessage: errorMessage,
    );
  }

  /// Stop authentication (if in progress)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      // Ignore errors when stopping
    }
  }
}

/// Result of biometric authentication attempt
class BiometricAuthResult {
  final bool success;
  final BiometricErrorType? errorType;
  final String? errorMessage;

  BiometricAuthResult({
    required this.success,
    this.errorType,
    this.errorMessage,
  });
}

/// Types of biometric authentication errors
enum BiometricErrorType {
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  passcodeNotSet,
  userCancelled,
  unknown,
}
