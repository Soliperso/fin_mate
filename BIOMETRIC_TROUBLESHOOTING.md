# Biometric Login Troubleshooting Guide

If the biometric button is not working, follow these steps:

## ✅ Step 1: Check Platform Permissions

### iOS (Required for Face ID/Touch ID)
The `NSFaceIDUsageDescription` has been added to `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>FinMate needs Face ID permission to enable biometric login for secure and convenient access to your account.</string>
```

### Android (Required for Fingerprint)
The permissions have been added to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

## ✅ Step 2: Rebuild the App

After adding permissions, you MUST rebuild the app:

```bash
# Clean build
flutter clean
flutter pub get

# Rebuild for iOS
flutter build ios

# Rebuild for Android
flutter build apk

# Or just run
flutter run
```

## ✅ Step 3: Test the Flow

### First Time Setup:
1. **Login normally** with email and password
2. **CHECK "Remember me"** checkbox (IMPORTANT!)
3. Click "Log In"
4. Log out

### Using Biometric Login:
1. Go to login page
2. You should now see **"Use Biometric Login"** button
3. Click it
4. Authenticate with Face ID/Fingerprint
5. You're logged in!

## ❓ Why Isn't the Button Showing?

The button only appears when BOTH conditions are met:

1. ✅ **Device supports biometrics** (has Face ID, Touch ID, or Fingerprint sensor)
2. ✅ **User has saved credentials** (logged in with "Remember me" enabled)

### Debug Steps:

1. **Check if biometric is available on device:**
   - iOS: Settings → Face ID & Passcode (or Touch ID)
   - Android: Settings → Security → Fingerprint

2. **Check debug logs:**
   Run the app and look for these logs when clicking the button:
   ```
   🔐 Biometric login button pressed
   📱 Checking biometric availability...
   📱 Biometric available: true/false
   🔑 Getting saved credentials...
   🔑 Email found: true/false, Password found: true/false
   ```

3. **Clear and retry:**
   ```dart
   // If credentials are corrupted, clear them:
   final storage = SecureStorageService();
   await storage.clearAll();
   
   // Then login again with "Remember me" checked
   ```

## 🔍 Common Issues

### Issue 1: Button Not Visible
**Cause:** Credentials not saved
**Solution:** Login with "Remember me" checkbox enabled

### Issue 2: "Biometric authentication failed"
**Possible causes:**
- Biometric not set up on device
- User cancelled authentication
- Too many failed attempts (device locked)

**Solution:**
- Set up Face ID/Touch ID in device settings
- Try again
- Wait if device is locked

### Issue 3: "No saved credentials found"
**Cause:** User didn't enable "Remember me" or credentials were cleared
**Solution:** Login again with "Remember me" enabled

### Issue 4: iOS Face ID Permission Denied
**Cause:** User denied Face ID permission
**Solution:**
1. Go to iOS Settings → FinMate
2. Enable Face ID permission
3. Restart app

### Issue 5: Android Fingerprint Not Working
**Possible causes:**
- Fingerprint not enrolled in device
- Biometric API not supported (old Android version)

**Solution:**
- Enroll fingerprint in Settings → Security
- Ensure Android 6.0+ (API 23+)

## 🧪 Testing on Simulator/Emulator

### iOS Simulator:
1. Open Simulator
2. Features → Face ID → Enrolled
3. When prompted for Face ID, use: Features → Face ID → Matching Face

### Android Emulator:
1. Open Extended Controls (three dots)
2. Fingerprint
3. Touch the sensor when prompted

## 📱 Platform-Specific Notes

### iOS:
- Face ID requires iOS 11+
- Touch ID requires iOS 8+
- Requires actual device or simulator with biometric enrolled

### Android:
- Fingerprint requires Android 6.0+ (API 23)
- Some manufacturers have custom implementations
- Test on actual device for best results

## 🔧 Advanced Debugging

### Enable Detailed Logging:

The debug logs are already in place. Look for:
```
🔐 Biometric login button pressed
📱 Checking biometric availability...
🔑 Getting saved credentials...
👆 Starting biometric authentication...
✅ Biometric success, signing in...
```

### Check Biometric Availability Programmatically:

```dart
final biometricService = BiometricService();

// Check if device supports biometric
final isSupported = await biometricService.isDeviceSupported();
print('Device supports biometric: $isSupported');

// Check if biometric is enrolled
final canCheck = await biometricService.canCheckBiometrics();
print('Can check biometric: $canCheck');

// Get available types
final types = await biometricService.getAvailableBiometrics();
print('Available types: $types');
```

### Test Biometric Directly:

```dart
final result = await biometricService.authenticate(
  localizedReason: 'Test biometric',
);

if (result.success) {
  print('✅ Biometric works!');
} else {
  print('❌ Error: ${result.errorMessage}');
  print('Error type: ${result.errorType}');
}
```

## 📋 Verification Checklist

Before reporting issues, verify:

- [ ] Permissions added to Info.plist (iOS)
- [ ] Permissions added to AndroidManifest.xml (Android)
- [ ] App rebuilt after adding permissions
- [ ] Biometric enrolled on device
- [ ] "Remember me" enabled during login
- [ ] Credentials saved (check secure storage)
- [ ] Device supports biometric (not all simulators do)
- [ ] No biometric lockout (too many failed attempts)

## 🆘 Still Not Working?

1. Check Flutter console for error messages
2. Check the debug logs (🔐 🔑 👆 emojis)
3. Try on a different device
4. Clear app data and start fresh
5. Verify `local_auth` package is installed: `flutter pub get`

## 📚 Related Files

- Biometric Service: `lib/core/services/biometric_service.dart`
- Login Page: `lib/features/auth/presentation/pages/login_page.dart`
- Secure Storage: `lib/core/services/secure_storage_service.dart`
- iOS Permissions: `ios/Runner/Info.plist`
- Android Permissions: `android/app/src/main/AndroidManifest.xml`

---

**Note:** Biometric authentication requires a physical device or properly configured simulator/emulator. It will NOT work on all test environments.
