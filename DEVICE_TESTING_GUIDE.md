# Device Testing Guide - FinMate

## Testing on Real iOS Devices

Before submitting to the App Store, comprehensive testing on real iOS devices is essential.

## Prerequisites

### Requirements
- Mac with Xcode installed
- iOS device (iPhone/iPad) running iOS 13+
- Apple Developer Account
- USB cable to connect device
- Provisioning profiles and signing certificates set up

### Setup Steps

#### 1. Connect iOS Device
```bash
# Connect via USB
# Device will ask for trust - tap "Trust"

# List connected devices
flutter devices

# Should see output like:
# iPhone (mobile) • XXXXX • ios • iOS 17.0
```

#### 2. Enable Developer Mode (iOS 16+)
- Go to Settings → Privacy & Security → Developer Mode
- Toggle Developer Mode ON
- Confirm when prompted

#### 3. Trust Developer Certificate
- Settings → General → VPN and Device Management
- Trust your Apple Developer certificate

## Running Tests on Device

### Option 1: Run App on Device
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Example:
flutter run -d iPhone
```

### Option 2: Run Tests on Device
```bash
# Run all tests on device
flutter test -d <device_id>

# Example:
flutter test -d iPhone

# Run specific test
flutter test -d iPhone test/unit/entities/transaction_entity_test.dart
```

### Option 3: Build and Run
```bash
# Build for device
flutter build ios --release -d <device_id>

# Run the built app
flutter run -d <device_id>
```

## Manual Testing Checklist

### Authentication Flow
- [ ] Sign up with email
- [ ] Verify email confirmation
- [ ] Log in with credentials
- [ ] Test MFA (if enabled)
- [ ] Logout and log back in
- [ ] Password reset flow
- [ ] Biometric authentication

### Dashboard
- [ ] Net worth displays correctly
- [ ] Cash flow chart loads
- [ ] Transaction list loads
- [ ] Accounts display properly
- [ ] Refresh data works
- [ ] Responsive to screen rotation

### Transactions
- [ ] Add expense transaction
- [ ] Add income transaction
- [ ] Edit transaction
- [ ] Delete transaction
- [ ] Filter by category
- [ ] Filter by date
- [ ] Sort by amount
- [ ] Search transactions

### Accounts
- [ ] Create new account
- [ ] View account balance
- [ ] Update account
- [ ] Delete account
- [ ] View transaction history for account

### Budgets
- [ ] Create budget
- [ ] Set budget limit
- [ ] View budget progress
- [ ] Edit budget
- [ ] Delete budget

### Settings
- [ ] Change display settings
- [ ] Update profile
- [ ] Manage notifications
- [ ] Review privacy policy
- [ ] Review terms of service

### UI/UX
- [ ] All text readable
- [ ] Buttons responsive
- [ ] Forms validate
- [ ] Loading states appear
- [ ] Error messages clear
- [ ] Navigation works
- [ ] App handles rotation

### Performance
- [ ] App starts quickly
- [ ] No crashes
- [ ] Smooth animations
- [ ] Memory usage reasonable
- [ ] Battery drain acceptable
- [ ] Network requests fast

### Accessibility
- [ ] Text sizes readable
- [ ] Colors have contrast
- [ ] Touch targets adequate
- [ ] Gestures intuitive
- [ ] Screen reader compatible

## Testing Different Scenarios

### Network Conditions
```bash
# Throttle network in Xcode
# Xcode → Devices & Simulators → Conditions
# Set Network link conditioner

# Test with:
# - WiFi 6
# - LTE
# - Edge (3G)
# - No internet
```

### Low Memory
```bash
# Test app with limited memory
# Settings → Developer → Low Memory Warning Simulation
```

### Orientation Changes
- Test in Portrait
- Test in Landscape
- Test rotation animations

### Dark Mode
- Settings → Display & Brightness → Dark
- Test UI appearance
- Check contrast

### Different Screen Sizes
- iPhone 12 mini (5.4")
- iPhone 12 (6.1")
- iPhone 12 Pro (6.1")
- iPhone 12 Pro Max (6.7")
- iPad Pro (various sizes)

## Debugging on Device

### View Device Logs
```bash
# Real-time logs
flutter logs

# Filter specific messages
flutter logs | grep "FinMate"
```

### Attach Debugger
```bash
# Debug app
flutter run -d <device_id> -v

# Set breakpoints in VS Code
# Use Dart debugging
```

### Performance Profiling
```bash
# Profile app
flutter run -d <device_id> --profile

# View performance timeline in DevTools
# Run: flutter pub global activate devtools
# Then: devtools
```

### Memory Analysis
```bash
# Check memory usage
flutter pub global activate vm_service
flutter debug-adapter --machine
```

## Common Issues & Solutions

### Device Not Detected
```bash
# Restart Flutter
flutter clean
flutter pub get

# Reconnect device
# Unplug USB, plug back in

# Restart Xcode
killall Xcode
open /Applications/Xcode.app
```

### Provisioning Profile Issue
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# Go to Signing & Capabilities
# Select team and update provisioning profile
```

### App Crashes on Launch
```bash
# Check logs
flutter logs -d <device_id>

# Look for error messages
# Common: Missing permissions, database issues, network errors
```

### Build Fails
```bash
# Clean build
flutter clean
flutter pub get
flutter pub get --upgrade

# Build again
flutter build ios -d <device_id>
```

## App Store Preparation

### Final Device Testing Steps
1. **Functional Testing**
   - [ ] All features working
   - [ ] No crashes
   - [ ] Data persists

2. **Performance Testing**
   - [ ] Startup time < 3 seconds
   - [ ] Smooth 60fps animations
   - [ ] No memory leaks

3. **Security Testing**
   - [ ] No sensitive data in logs
   - [ ] Network communication encrypted
   - [ ] Secure storage working

4. **Compliance Testing**
   - [ ] Privacy policy accessible
   - [ ] Terms of service accessible
   - [ ] Proper permission requests
   - [ ] COPPA compliant (if needed)

## Real Device Test Report

Keep detailed notes:

```markdown
## Test Report - FinMate v1.0.0

**Device:** iPhone 12 Pro
**iOS Version:** 17.0
**Date:** 2024-10-21

### Features Tested
- [ ] Authentication
- [ ] Dashboard
- [ ] Transactions
- [ ] Accounts
- [ ] Budgets
- [ ] Settings

### Issues Found
1. **Issue:** Animation stuttering on list scroll
   **Severity:** Medium
   **Device:** iPhone 12 mini
   **Status:** Fixed

2. ...

### Performance Metrics
- Startup time: 1.2s ✅
- Memory usage: 120MB ✅
- Battery drain: 5% per hour ✅

### Conclusion
App ready for App Store submission ✅
```

## Testing Tools

### Xcode Tools
- Instruments (Performance analysis)
- Console (Logging)
- Devices and Simulators
- Network Link Conditioner

### Flutter Tools
- `flutter devices` - List devices
- `flutter run` - Run on device
- `flutter logs` - View device logs
- `flutter test` - Run tests on device
- DevTools - Web-based debugging

## Continuous Testing

### Pre-Release Checklist
- [ ] All automated tests pass
- [ ] Manual testing checklist complete
- [ ] Device testing on 3+ different iPhones
- [ ] Performance testing passed
- [ ] Security review completed
- [ ] Privacy policy updated
- [ ] Screenshots captured
- [ ] Release notes written

## Resources

- [Xcode Documentation](https://developer.apple.com/xcode/)
- [Flutter Device Testing](https://flutter.dev/docs/testing/testing-on-devices)
- [iOS App Testing Guide](https://developer.apple.com/app-store/app-testing-guide/)
- [Apple Beta Software](https://developer.apple.com/testflight/)

## Summary

Real device testing is crucial for:
- ✅ Identifying platform-specific issues
- ✅ Testing actual device performance
- ✅ Verifying user experience
- ✅ Ensuring App Store compliance
- ✅ Building confidence in release

Budget 4-6 hours for comprehensive device testing before App Store submission.
