# FinMate Build Instructions

## Security Note
**IMPORTANT:** Environment variables are now injected at build time using `--dart-define` flags. The `.env` file is NO LONGER bundled in the app to prevent credential exposure.

## Prerequisites
1. `.env` file in project root (see `.env.example`)
2. Flutter 3.37+ installed
3. Xcode 16+ (for iOS builds)

## Quick Build Commands

### iOS Development Build
```bash
./build_ios.sh
```

This script:
- Loads environment variables from `.env`
- Injects them via `--dart-define` flags
- Builds release IPA
- Output: `build/ios/ipa/finmate.ipa`

### Manual iOS Build
If you prefer to build manually:
```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx \
  --dart-define=STRIPE_MONTHLY_PRICE_ID=price_xxx \
  --dart-define=STRIPE_ANNUAL_PRICE_ID=price_xxx \
  --dart-define=SENTRY_DSN=https://xxx \
  --dart-define=ENVIRONMENT=production
```

### iOS Debug (for testing)
```bash
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

## TestFlight Upload

### Option 1: Via Xcode (Recommended for first build)
1. Build IPA: `./build_ios.sh`
2. Open Xcode Organizer: `open build/ios/archive/Runner.xcarchive`
3. Select archive → Distribute App
4. Choose: App Store Connect → Upload
5. Wait 5-30 minutes for processing

### Option 2: Via Command Line
```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/finmate.ipa \
  --apiKey YOUR_API_KEY_ID \
  --apiIssuer YOUR_ISSUER_ID
```

## Environment Variables Reference

### Required (Production)
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous key (public, safe for client)
- `STRIPE_PUBLISHABLE_KEY` - Stripe publishable key (use `pk_live_` for production)
- `STRIPE_MONTHLY_PRICE_ID` - Stripe monthly subscription price ID
- `STRIPE_ANNUAL_PRICE_ID` - Stripe annual subscription price ID
- `SENTRY_DSN` - Sentry error tracking DSN
- `ENVIRONMENT` - `production`, `staging`, or `development`

### Optional
- `ENABLE_BIOMETRIC_AUTH` - true/false (default: true)
- `ENABLE_AI_INSIGHTS` - true/false (default: true)
- `ENABLE_BANK_SYNC` - true/false (default: false)

## Security Checklist

Before deploying to TestFlight:
- [ ] `.env` file is NOT in `pubspec.yaml` assets
- [ ] No `STRIPE_SECRET_KEY` in client code (server-side only)
- [ ] Using `--dart-define` for all environment variables
- [ ] Test IPA doesn't contain `.env` file:
  ```bash
  unzip -l build/ios/ipa/finmate.ipa | grep ".env"
  # Should return nothing
  ```

## Troubleshooting

### "Missing environment variables" error
- Ensure `.env` file exists
- Check all required variables are set
- Use `./build_ios.sh` which validates automatically

### "Provisioning profile not found"
- Download distribution profile from Apple Developer Portal
- Install to: `~/Library/MobileDevice/Provisioning Profiles/`
- Or use Xcode automatic signing

### App crashes on launch
- Check Sentry for crash reports
- Verify all `--dart-define` values are correct
- Ensure Supabase URL and ANON_KEY are valid

## Production Deployment Checklist

Before switching from TestFlight to App Store:
- [ ] Replace `pk_test_` with `pk_live_` Stripe keys
- [ ] Update `STRIPE_MONTHLY_PRICE_ID` and `STRIPE_ANNUAL_PRICE_ID` to live price IDs
- [ ] Set `ENVIRONMENT=production`
- [ ] Deploy Supabase Edge Functions with production Stripe secret key
- [ ] Enable Sentry rate limiting
- [ ] Test payment flow end-to-end
