# FinMate Setup Instructions

Complete guide to setting up and running the FinMate app with Supabase authentication.

## Prerequisites

- Flutter SDK 3.10.0 or higher
- A Supabase account (free tier works fine)
- iOS Simulator, Android Emulator, or a physical device

## Step 1: Install Dependencies

```bash
flutter pub get
```

## Step 2: Set Up Supabase

### 2.1 Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign in or create an account
3. Click "New Project"
4. Fill in the details:
   - **Name**: FinMate (or any name you prefer)
   - **Database Password**: Choose a strong password (save it securely!)
   - **Region**: Select the region closest to you
5. Click "Create new project" and wait for it to initialize (1-2 minutes)

### 2.2 Get Your API Credentials

1. Once your project is ready, go to **Settings** → **API**
2. You'll find two important values:
   - **Project URL**: `https://xxxxxxxxxxxxx.supabase.co`
   - **anon/public key**: A long string starting with `eyJ...`
3. Copy these values - you'll need them in the next step

### 2.3 Configure Environment Variables

1. Open the `.env` file in the project root
2. Replace the placeholder values with your actual Supabase credentials:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-actual-anon-key-here
```

⚠️ **IMPORTANT**: The `.env` file is already in `.gitignore` - never commit it to version control!

### 2.4 Set Up the Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy the entire contents of `supabase_schema.sql` from the project root
4. Paste it into the SQL editor
5. Click "Run" to execute the script

This will create:
- User profiles table
- Groups/wallets table
- Group members table
- Transactions table
- Transaction splits table
- Budgets table
- Accounts table
- Storage buckets for avatars and receipts
- All necessary Row Level Security (RLS) policies

### 2.5 Enable Email Authentication

1. Go to **Authentication** → **Providers**
2. Make sure **Email** is enabled
3. Configure these settings:
   - ✅ Enable email confirmations (recommended for production)
   - ✅ Enable secure email change
   - Set minimum password length to 6 characters

## Step 3: Run the App

```bash
# List available devices
flutter devices

# Run on a specific device
flutter run -d <device_id>

# Or just run (it will prompt you to select a device)
flutter run
```

## Step 4: Test the Authentication Flow

1. The app will launch with the splash screen
2. After the animation, you'll see the onboarding screen
3. Tap "Get Started" → "Sign Up"
4. Fill in your details:
   - Full Name
   - Email
   - Password (minimum 6 characters)
   - Accept terms
5. Tap "Sign Up"
6. Check your email for the confirmation link (check spam folder too!)
7. Click the confirmation link
8. Return to the app and log in with your credentials
9. You should be redirected to the dashboard

## Features Implemented

### Authentication
- ✅ Email/password sign up
- ✅ Email/password login
- ✅ Email confirmation
- ✅ Password reset
- ✅ Auto-login for authenticated users
- ✅ Protected routes (auth guards)
- ✅ Persistent sessions

### Database
- ✅ User profiles
- ✅ Groups/wallets for bill splitting
- ✅ Transactions and splits
- ✅ Budgets
- ✅ Accounts
- ✅ Row Level Security (RLS) policies
- ✅ Storage buckets

### UI
- ✅ Splash screen with animation
- ✅ Onboarding flow
- ✅ Login page with validation
- ✅ Signup page with validation
- ✅ Error handling and user feedback
- ✅ Loading states
- ✅ Bottom navigation
- ✅ Material 3 design

## Project Structure

```
lib/
├── core/
│   ├── config/
│   │   ├── env_config.dart           # Environment configuration
│   │   ├── supabase_client.dart      # Supabase client singleton
│   │   └── router.dart                # GoRouter with auth guards
│   ├── constants/                      # App colors, sizes, etc.
│   └── theme/                          # Material 3 themes
│
├── features/
│   └── auth/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── auth_remote_datasource.dart
│       │   ├── models/
│       │   │   └── user_model.dart
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── user_entity.dart
│       │   └── repositories/
│       │       └── auth_repository.dart
│       └── presentation/
│           ├── pages/
│           │   ├── splash_page.dart
│           │   ├── onboarding_page.dart
│           │   ├── login_page.dart
│           │   └── signup_page.dart
│           └── providers/
│               └── auth_providers.dart
│
└── main.dart                           # App entry point
```

## Troubleshooting

### "Invalid API key" error
- Double-check your `.env` file has the correct `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- Make sure you're using the **anon/public** key, not the service role key
- Restart the app after changing `.env`

### "Failed to load .env file"
- Ensure the `.env` file exists in the project root
- Run `flutter clean && flutter pub get`
- Restart your IDE

### Email confirmation not received
- Check your spam/junk folder
- For development, you can disable email confirmation in Supabase:
  - Go to Authentication → Settings
  - Uncheck "Enable email confirmations"

### "Invalid login credentials"
- Make sure you've confirmed your email
- Check that you're using the correct password
- Password is case-sensitive

### Database errors
- Make sure you've run the entire `supabase_schema.sql` script
- Check the Supabase dashboard → Database → Tables to verify tables were created
- Look at Supabase logs for specific error messages

### Row Level Security blocking queries
- RLS policies are configured to allow users to access only their own data
- Check the Supabase dashboard → Authentication → Users to verify your user exists
- Review the SQL policies in `supabase_schema.sql`

## Next Steps

Now that authentication is working, you can:

1. **Implement Dashboard Features**
   - Net worth calculation
   - Cash flow visualization
   - Upcoming bills timeline
   - Money health score

2. **Build Bill Splitting**
   - Create and manage groups
   - Add expenses and split them
   - Track balances
   - Settlement flows

3. **Add AI Insights**
   - Integrate OpenAI API
   - Weekly spending digest
   - Budget recommendations
   - Forecasting

4. **Enhance Security**
   - Add biometric authentication
   - Implement MFA (Multi-Factor Authentication)
   - Add session timeout
   - Implement audit logging

## Useful Commands

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Clean build
flutter clean && flutter pub get

# Check for outdated packages
flutter pub outdated

# Build for production
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
```

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter Guide](https://supabase.com/docs/reference/dart/introduction)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

## Support

If you encounter any issues:

1. Check the troubleshooting section above
2. Review the Supabase logs in the dashboard
3. Check the Flutter console for error messages
4. Verify all steps in this guide were followed correctly

---

**Happy coding! 🚀**
