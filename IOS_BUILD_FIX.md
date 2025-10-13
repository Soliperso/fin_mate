# iOS Build Fix - Deployment Target

## Issue
The app failed to build for iOS simulator with the error:
```
The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 12.0,
but the range of supported deployment target versions is 12.0 to 18.5.99.
```

## Root Cause
The `flutter_secure_storage` dependency requires iOS 13.0+, but the Podfile didn't specify a minimum deployment target, causing some pods to default to older versions.

## Fix Applied

### 1. Updated Podfile
**File**: `ios/Podfile`

**Changes**:
1. Uncommented the platform line:
   ```ruby
   platform :ios, '13.0'
   ```

2. Added deployment target enforcement in post_install:
   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_ios_build_settings(target)
       target.build_configurations.each do |config|
         config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
       end
     end
   end
   ```

### 2. Reinstalled Pods
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
```

## Result
✅ Pods installed successfully
✅ All dependencies now use iOS 13.0 as minimum deployment target
✅ Build should now succeed

## Next Steps
Try running the app again:
```bash
flutter run
```

## Notes
- iOS 13.0 is a reasonable minimum target (released Sept 2019)
- All current dependencies support iOS 13.0+
- This aligns with Flutter's recommended minimum iOS version
- Most devices can update to iOS 13+ (iPhone 6S and later)
