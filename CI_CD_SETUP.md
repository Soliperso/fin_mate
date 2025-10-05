# CI/CD Setup Guide

This document provides instructions for setting up the CI/CD pipeline for FinMate.

## Overview

The CI/CD pipeline consists of:
- **Continuous Integration (CI)**: Automated testing, code analysis, and builds on every push/PR
- **Continuous Deployment (CD)**: Automated deployment to app stores and hosting platforms

## Workflows

### 1. CI Workflow (`.github/workflows/ci.yml`)
Runs on every push and pull request to `main` and `develop` branches.

**Jobs:**
- **Code Analysis**: Format verification and static analysis
- **Testing**: Unit and widget tests with coverage reporting
- **Build Android**: Creates release APK
- **Build iOS**: Creates iOS build (unsigned)

### 2. Android Deployment (`.github/workflows/deploy-android.yml`)
Deploys to Google Play Store.

**Triggers:**
- Version tags (e.g., `v1.0.0`)
- Manual workflow dispatch

**Deployment Tracks:**
- Internal (default)
- Alpha
- Beta
- Production

### 3. iOS Deployment (`.github/workflows/deploy-ios.yml`)
Deploys to TestFlight and App Store.

**Triggers:**
- Version tags (e.g., `v1.0.0`)
- Manual workflow dispatch

**Deployment Options:**
- TestFlight (default)
- App Store

### 4. Web Deployment (`.github/workflows/deploy-web.yml`)
Deploys to Firebase Hosting.

**Triggers:**
- Push to `main` branch
- Version tags
- Manual workflow dispatch

## Required GitHub Secrets

### General Secrets
- `CODECOV_TOKEN`: Token for Codecov coverage reporting (optional)

### Android Secrets
- `ANDROID_KEYSTORE_BASE64`: Base64-encoded upload keystore
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password
- `ANDROID_KEY_ALIAS`: Key alias
- `ANDROID_KEY_PASSWORD`: Key password
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: Google Play service account JSON

### iOS Secrets
- `IOS_CERTIFICATES_P12_BASE64`: Base64-encoded distribution certificate (.p12)
- `IOS_CERTIFICATES_P12_PASSWORD`: Certificate password
- `IOS_PROVISIONING_PROFILE_BASE64`: Base64-encoded provisioning profile
- `APP_STORE_CONNECT_API_KEY_ID`: App Store Connect API Key ID
- `APP_STORE_CONNECT_API_ISSUER_ID`: App Store Connect API Issuer ID
- `APP_STORE_CONNECT_API_KEY`: App Store Connect API Key (base64)

### Web/Firebase Secrets
- `FIREBASE_SERVICE_ACCOUNT`: Firebase service account JSON
- `FIREBASE_PROJECT_ID`: Firebase project ID

## Setup Instructions

### 1. Android Setup

#### Generate Upload Keystore
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

#### Encode Keystore to Base64
```bash
base64 -i upload-keystore.jks -o keystore.txt
```

#### Configure Google Play Service Account
1. Go to Google Play Console > Setup > API access
2. Create a service account
3. Download the JSON key file
4. Add as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` secret

#### Update Android Build Configuration
Edit `android/app/build.gradle`:
```gradle
android {
    ...
    signingConfigs {
        release {
            def keystorePropertiesFile = rootProject.file("key.properties")
            def keystoreProperties = new Properties()
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 2. iOS Setup

#### Generate Distribution Certificate
1. Open Xcode > Preferences > Accounts
2. Select your Apple ID > Manage Certificates
3. Create "iOS Distribution" certificate
4. Export certificate as .p12 file with password

#### Encode Certificate to Base64
```bash
base64 -i Certificates.p12 -o certificate.txt
```

#### Create Provisioning Profile
1. Go to Apple Developer Portal > Certificates, IDs & Profiles
2. Create App Store provisioning profile
3. Download the profile

#### Encode Provisioning Profile to Base64
```bash
base64 -i profile.mobileprovision -o profile.txt
```

#### Create App Store Connect API Key
1. Go to App Store Connect > Users and Access > Keys
2. Create new API key with "Developer" role
3. Download the .p8 key file
4. Note the Key ID and Issuer ID

#### Encode API Key to Base64
```bash
base64 -i AuthKey_XXXXXXXXXX.p8 -o apikey.txt
```

#### Update ExportOptions.plist
Edit `ios/ExportOptions.plist`:
- Replace `YOUR_TEAM_ID` with your Apple Developer Team ID
- Replace `YOUR_PROVISIONING_PROFILE_NAME` with your provisioning profile name

### 3. Firebase/Web Setup

#### Initialize Firebase Project
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
```

#### Create Firebase Service Account
1. Go to Firebase Console > Project Settings > Service Accounts
2. Generate new private key
3. Download JSON file
4. Add entire JSON content as `FIREBASE_SERVICE_ACCOUNT` secret

#### Update Firebase Configuration
Edit `.firebaserc`:
- Replace `YOUR_FIREBASE_PROJECT_ID` with your Firebase project ID

### 4. Adding Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Click "New repository secret"
4. Add each secret from the lists above

### 5. Release Workflow

#### Create a Release
```bash
# Tag the version
git tag v1.0.0
git push origin v1.0.0
```

This will trigger all deployment workflows.

#### Manual Deployment
1. Go to Actions tab in GitHub
2. Select the workflow (e.g., "Deploy Android")
3. Click "Run workflow"
4. Select deployment options
5. Click "Run workflow"

## Environment-Specific Configuration

### Development
- Automatic deployment disabled
- Only CI tests run on feature branches

### Staging
- Deploys to internal/TestFlight on `develop` branch merges

### Production
- Deploys on version tags
- Requires manual approval for App Store/Play Store production

## Updating Release Notes

Edit `distribution/whatsnew/whatsnew-en-US` before each release:
```
• New feature description
• Bug fixes
• Performance improvements
```

For other languages, create files like:
- `whatsnew-es-ES` (Spanish)
- `whatsnew-fr-FR` (French)
- `whatsnew-de-DE` (German)

## Troubleshooting

### Build Failures
- Check Flutter version compatibility
- Ensure all dependencies are up to date
- Verify secrets are correctly set

### Android Signing Issues
- Verify keystore password is correct
- Check key alias matches
- Ensure `key.properties` is properly generated

### iOS Code Signing Issues
- Verify certificate hasn't expired
- Check provisioning profile is valid
- Ensure bundle identifier matches

### Web Deployment Issues
- Verify Firebase project ID is correct
- Check service account has necessary permissions
- Ensure hosting is enabled in Firebase

## Security Best Practices

- **Never commit secrets**: Use GitHub Secrets for all sensitive data
- **Rotate credentials**: Regularly update keystore passwords and API keys
- **Limit access**: Use service accounts with minimal required permissions
- **Review logs**: Check workflow logs but ensure no secrets are printed
- **Enable branch protection**: Require PR reviews before merging to `main`

## Monitoring and Notifications

### Setup Status Checks
1. Go to Settings > Branches
2. Add branch protection rule for `main`
3. Require status checks to pass:
   - Code Analysis
   - Run Tests
   - Build Android
   - Build iOS

### Slack/Discord Notifications (Optional)
Add notification step to workflows:
```yaml
- name: Notify Slack
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "Build failed: ${{ github.workflow }}"
      }
```

## Cost Optimization

- Artifacts are retained for 30 days (configurable)
- Builds are cached to reduce build time
- Parallel jobs run where possible
- Only critical tests run on PR, full suite on merge

## Next Steps

1. Set up all required secrets
2. Test CI workflow with a sample PR
3. Create a test release tag to verify deployments
4. Configure branch protection rules
5. Set up monitoring and alerts
