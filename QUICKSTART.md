# FinMate - Quick Start Guide

Get up and running with FinMate in 5 minutes!

---

## Prerequisites

- Flutter SDK ^3.10.0 installed
- iOS Simulator / Android Emulator / Chrome browser
- Code editor (VS Code, Android Studio, or IntelliJ)

---

## Step 1: Verify Installation ✅

The project is already initialized! Dependencies are installed and the code is ready.

```bash
# Verify everything is working
flutter doctor

# Check that dependencies are installed
flutter pub get
```

---

## Step 2: Run the App 🚀

```bash
# Run on your preferred platform
flutter run

# Or specify a device
flutter run -d chrome        # Web
flutter run -d iPhone         # iOS Simulator
flutter run -d emulator       # Android Emulator
```

**Expected Result**: You should see the splash screen, followed by the auth flow.

---

## Step 3: Explore the Structure 📁

The app uses **feature-first architecture**:

```
lib/
├── features/
│   ├── auth/           → Login, signup, onboarding
│   ├── dashboard/      → Main dashboard with overview
│   ├── bill_splitting/ → Groups and expense tracking
│   ├── budgets/        → Budget management
│   ├── ai_insights/    → AI-powered insights
│   └── profile/        → User profile settings
├── core/
│   ├── config/         → Router & environment config
│   ├── theme/          → Material 3 theme
│   └── constants/      → Colors, sizes, etc.
└── shared/
    └── widgets/        → Reusable components
```

---

## Step 4: Set Up Supabase (For Full Functionality) 🔐

### Create Supabase Project

1. Go to https://supabase.com
2. Click "New Project"
3. Fill in:
   - Name: `finmate`
   - Database Password: (save this!)
   - Region: (choose closest)

### Get Credentials

1. In Supabase dashboard, go to **Settings → API**
2. Copy:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

### Configure Environment

```bash
# Copy the template
cp .env.example .env

# Edit .env and add your Supabase credentials
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=your-anon-key
```

### Run with Environment Variables

```bash
flutter run \
  --dart-define=ENVIRONMENT=development \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## Step 5: Enable Authentication 🔑

In Supabase dashboard:

1. Go to **Authentication → Providers**
2. Enable:
   - ✅ Email (for MVP)
   - ✅ Phone (for SMS OTP - optional)
   - ✅ Google (optional, for Phase 2)
3. Configure email templates (optional)

---

## Step 6: Create Database Schema 🗄️

Run this SQL in Supabase SQL Editor:

```sql
-- Users profile table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Trigger to create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

## Step 7: Test Authentication Flow 🧪

1. Run the app
2. Click "Sign Up" on the login screen
3. Enter email & password
4. Check your email for confirmation link
5. Confirm and log in

---

## Development Workflow 🛠️

### Making Changes

1. **Hot Reload**: Press `r` in terminal (fast)
2. **Hot Restart**: Press `R` in terminal (resets state)
3. **Full Restart**: Stop and rerun `flutter run`

### Code Style

```bash
# Format code
dart format .

# Analyze for issues
flutter analyze

# Fix common issues
dart fix --apply
```

### Adding Dependencies

```bash
# Add a new package
flutter pub add package_name

# Add a dev dependency
flutter pub add --dev package_name

# Update all packages
flutter pub upgrade
```

---

## Common Issues & Solutions 🔧

### Issue: "Supabase URL not configured"

**Solution**: Make sure you're passing environment variables:

```bash
flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
```

### Issue: "No device found"

**Solution**: Start a simulator/emulator first:

```bash
# iOS
open -a Simulator

# Android (if you have emulator set up)
flutter emulators
flutter emulators --launch <emulator_id>
```

### Issue: Build errors after adding packages

**Solution**: Clean and rebuild:

```bash
flutter clean
flutter pub get
flutter run
```

### Issue: "Gradle build failed" (Android)

**Solution**:
1. Open `android/` in Android Studio
2. Let it sync Gradle
3. Try running again

---

## What's Already Built 🎉

✅ **Routing**: Full navigation with bottom tabs
✅ **Theme**: Material 3 with custom fintech colors
✅ **Architecture**: Feature-first with clean layers
✅ **Placeholders**: All main feature screens
✅ **Widgets**: Custom buttons, loading states, empty states
✅ **Security**: Gitignore configured for secrets

---

## What to Build Next 🚧

**Phase 1 - MVP (0-3 months)**:

1. **Auth Flow** (Week 1-2)
   - Login/signup with Supabase
   - Onboarding screens
   - Biometric authentication
   - MFA setup

2. **Dashboard** (Week 3-4)
   - Net worth calculation
   - Cash flow chart
   - Upcoming bills
   - Money health score

3. **Bill Splitting** (Week 5-7)
   - Group creation
   - Expense tracking
   - Balance calculation
   - Manual settlement

4. **AI Insights** (Week 8-10)
   - Weekly digest
   - Basic forecasting
   - Recommendations

5. **Polish** (Week 11-12)
   - Testing
   - Bug fixes
   - Performance optimization

---

## Resources 📚

- **Flutter Docs**: https://docs.flutter.dev
- **Supabase Docs**: https://supabase.com/docs
- **Riverpod Docs**: https://riverpod.dev
- **GoRouter Docs**: https://pub.dev/packages/go_router
- **Material 3**: https://m3.material.io

---

## Getting Help 🆘

1. Check the PRD: `PRD.md`
2. Review setup summary: `SETUP_SUMMARY.md`
3. Check Flutter docs
4. Ask in Flutter Discord/Slack

---

## Tips for Success 💡

1. **Start small**: Get one feature working end-to-end first
2. **Test early**: Write tests as you build features
3. **Use hot reload**: Speeds up development massively
4. **Follow the architecture**: Keep data/domain/presentation separate
5. **Security first**: Never commit secrets, always validate input

---

**Ready to build?** Start with authentication!

```bash
# Navigate to auth feature
cd lib/features/auth

# Files to implement:
# - data/datasources/auth_remote_datasource.dart
# - data/repositories/auth_repository_impl.dart
# - domain/entities/user.dart
# - domain/repositories/auth_repository.dart
# - domain/usecases/login_usecase.dart
# - presentation/providers/auth_provider.dart
```

Good luck! 🚀
