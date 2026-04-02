# Google Ads Integration - Setup Guide

## Overview

Google Mobile Ads have been successfully integrated into Finmate. Ads are automatically shown **only to freemium users** and hidden for premium subscribers.

## Current Status

⚠️ **CRITICAL: Test IDs in Use - MUST REPLACE BEFORE PRODUCTION**
- Currently using Google's test ad unit IDs
- Safe for testing and development only
- **App will violate AdMob policy if published with test IDs**
- **Your AdMob account may be suspended if test IDs are used in production**

## Ad Placements

Ads are strategically placed at the bottom of key pages:

1. **Dashboard Page** - Banner ad after Recent Transactions card
2. **Transactions Page** - Banner ad at the end of the transaction list
3. **Bill Splitting Page** - Banner ad at the end of the groups list

## Premium User Behavior

- Premium users (subscription_tier = 'premium') will **never see ads**
- Freemium users (subscription_tier = 'freemium') will see ads
- The check happens automatically via `shouldShowAdsProvider`

## Production Setup

### Before Publishing to App Store/Play Store

You **MUST** replace the test ad unit IDs with your real AdMob IDs:

#### Step 1: Create AdMob Account
1. Go to https://admob.google.com/
2. Sign in with your Google account
3. Create a new app for iOS and Android

#### Step 2: Get Your Ad Unit IDs
1. In AdMob console, create Banner ad units for:
   - iOS app
   - Android app
2. Copy the ad unit IDs (format: `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`)

#### Step 3: Update the Code

Open `/lib/core/services/ad_service.dart` and replace the test IDs:

**For Android:**
```dart
String get bannerAdUnitId {
  if (Platform.isAndroid) {
    // Replace this with your real Android ad unit ID
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  }
  // ... rest of code
}
```

**For iOS:**
```dart
String get bannerAdUnitId {
  if (Platform.isAndroid) {
    // ... Android code
  } else if (Platform.isIOS) {
    // Replace this with your real iOS ad unit ID
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  }
  // ... rest of code
}
```

#### Step 4: Update App Configuration

**iOS (ios/Runner/Info.plist):**
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~AAAAAAAAAA</string>
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
</array>
```

**Android (android/app/src/main/AndroidManifest.xml):**
```xml
<manifest>
  <application>
    <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~AAAAAAAAAA"/>
  </application>
</manifest>
```

## Testing Ads

### Test with Freemium User
1. Run the app
2. Login with a user account
3. Check that `subscription_tier` = 'freemium' in database
4. Navigate to Dashboard, Transactions, or Bill Splitting
5. You should see test banner ads at the bottom

### Test with Premium User
1. Update user's `subscription_tier` to 'premium' in database:
   ```sql
   UPDATE user_profiles
   SET subscription_tier = 'premium'
   WHERE id = 'user-id-here';
   ```
2. Restart the app
3. Navigate to the same pages
4. Ads should **not** appear

## Architecture

### Files Created/Modified

**New Files:**
- `/lib/core/services/ad_service.dart` - Manages ad lifecycle
- `/lib/core/providers/ad_provider.dart` - Premium status and ad display logic
- `/lib/shared/widgets/ads/ad_banner_widget.dart` - Reusable ad widget

**Modified Files:**
- `/lib/main.dart` - Initialize ads SDK on startup
- `/lib/features/dashboard/presentation/pages/dashboard_page.dart` - Add banner
- `/lib/features/transactions/presentation/pages/transactions_page.dart` - Add banner
- `/lib/features/bill_splitting/presentation/pages/bills_page.dart` - Add banner
- `/pubspec.yaml` - Add google_mobile_ads dependency

### How It Works

```
User opens page
    ↓
AdBannerWidget checks shouldShowAdsProvider
    ↓
shouldShowAdsProvider checks isPremiumProvider
    ↓
isPremiumProvider queries subscription_tier from database
    ↓
If freemium → Show ad
If premium → Hide ad (return empty widget)
```

## Troubleshooting

### Ads not showing in development
- Check that Mobile Ads SDK initialized successfully (check logs)
- Ensure you're using test ad unit IDs
- Verify internet connection
- Test ads may take a few seconds to load

### Ads showing for premium users
- Check user's `subscription_tier` in database
- Verify `isPremiumProvider` is working correctly
- Check for any provider caching issues

### App crashes on startup
- Ensure `google_mobile_ads` dependency installed: `flutter pub get`
- Check iOS/Android configuration files for AdMob app ID
- Review error logs for initialization issues

## Revenue Optimization Tips

1. **Ad Placement**: Current placements are non-intrusive. Monitor user feedback.
2. **Premium Conversion**: Use ads as incentive for users to upgrade to premium.
3. **Ad Types**: Currently using banners. Consider adding interstitials for specific actions.
4. **Frequency**: One banner per page is optimal for user experience.

## Support

- Google Mobile Ads Documentation: https://developers.google.com/admob/flutter
- AdMob Support: https://support.google.com/admob
- Flutter Plugin Issues: https://github.com/googleads/googleads-mobile-flutter

## Notes

- Test IDs are from Google's official documentation
- No changes required for current development/beta testing
- Production setup is **mandatory** before App Store/Play Store submission
- Ad revenue works alongside subscription revenue (dual monetization strategy)
