import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// Service for detecting compromised devices (rooted/jailbroken)
class DeviceSecurityService {
  /// Check if device is jailbroken (iOS) or rooted (Android)
  Future<bool> isDeviceCompromised() async {
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      // If detection fails, assume device is safe
      return false;
    }
  }

  /// Check if app is running in developer mode
  Future<bool> isDeveloperMode() async {
    try {
      return await FlutterJailbreakDetection.developerMode;
    } catch (e) {
      return false;
    }
  }

  /// Get comprehensive security status
  Future<DeviceSecurityStatus> getSecurityStatus() async {
    final isJailbroken = await isDeviceCompromised();
    final isDevMode = await isDeveloperMode();

    return DeviceSecurityStatus(
      isJailbroken: isJailbroken,
      isDeveloperMode: isDevMode,
      isSafe: !isJailbroken && !isDevMode,
    );
  }
}

/// Device security status model
class DeviceSecurityStatus {
  final bool isJailbroken;
  final bool isDeveloperMode;
  final bool isSafe;

  DeviceSecurityStatus({
    required this.isJailbroken,
    required this.isDeveloperMode,
    required this.isSafe,
  });
}
