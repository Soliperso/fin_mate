import 'dart:math';
import 'package:otp/otp.dart';

/// Service for handling Multi-Factor Authentication (MFA)
class MfaService {
  /// Generate a random TOTP secret
  String generateTotpSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'; // Base32 characters
    final random = Random.secure();
    final secret = List.generate(
      32,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    return secret;
  }

  /// Generate TOTP code from secret
  String generateTotpCode(String secret) {
    final code = OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
    return code;
  }

  /// Verify TOTP code
  bool verifyTotpCode({
    required String secret,
    required String code,
    int window = 1, // Allow 1 interval before/after
  }) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Check current time and window intervals
    for (int i = -window; i <= window; i++) {
      final timeOffset = currentTime + (i * 30 * 1000);
      final expectedCode = OTP.generateTOTPCodeString(
        secret,
        timeOffset,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      if (code == expectedCode) {
        return true;
      }
    }

    return false;
  }

  /// Generate TOTP URI for QR code
  /// Format: otpauth://totp/FinMate:user@email.com?secret=SECRET&issuer=FinMate
  String generateTotpUri({
    required String email,
    required String secret,
    String issuer = 'FinMate',
  }) {
    final encodedIssuer = Uri.encodeComponent(issuer);
    final encodedEmail = Uri.encodeComponent(email);
    return 'otpauth://totp/$encodedIssuer:$encodedEmail?secret=$secret&issuer=$encodedIssuer&algorithm=SHA1&digits=6&period=30';
  }

  /// Get remaining seconds until next TOTP code
  int getRemainingSeconds() {
    final now = DateTime.now();
    final seconds = now.second;
    return 30 - (seconds % 30);
  }

  /// Format OTP code with space for readability (e.g., "123 456")
  String formatOtpCode(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }

  /// Validate OTP code format
  bool isValidOtpFormat(String code) {
    // Remove spaces and check if it's 6 digits
    final cleanCode = code.replaceAll(' ', '');
    return cleanCode.length == 6 && int.tryParse(cleanCode) != null;
  }

  /// Clean OTP code (remove spaces)
  String cleanOtpCode(String code) {
    return code.replaceAll(' ', '').trim();
  }
}

/// MFA method types
enum MfaMethod {
  email,
  totp,
}

extension MfaMethodExtension on MfaMethod {
  String get displayName {
    switch (this) {
      case MfaMethod.email:
        return 'Email OTP';
      case MfaMethod.totp:
        return 'Authenticator App (TOTP)';
    }
  }

  String get description {
    switch (this) {
      case MfaMethod.email:
        return 'Receive a one-time code via email';
      case MfaMethod.totp:
        return 'Use an authenticator app like Google Authenticator or Authy';
    }
  }

  String get value {
    switch (this) {
      case MfaMethod.email:
        return 'email';
      case MfaMethod.totp:
        return 'totp';
    }
  }

  static MfaMethod? fromString(String? value) {
    switch (value) {
      case 'email':
        return MfaMethod.email;
      case 'totp':
        return MfaMethod.totp;
      default:
        return null;
    }
  }
}
