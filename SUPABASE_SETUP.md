# Supabase Setup Guide

This guide will help you set up Supabase for the FinMate app.

## Prerequisites

- A Supabase account (sign up at https://supabase.com)
- Flutter development environment set up

## Step 1: Create a Supabase Project

1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Fill in the project details:
   - **Name**: FinMate (or your preferred name)
   - **Database Password**: Use a strong password (save this securely!)
   - **Region**: Choose the region closest to your users
4. Click "Create new project" (this may take a few minutes)

## Step 2: Get Your API Credentials

1. Once your project is created, go to **Settings** → **API**
2. You'll find two important values:
   - **Project URL**: Something like `https://xxxxxxxxxxxxx.supabase.co`
   - **anon/public key**: A long string starting with `eyJ...`

## Step 3: Configure Your Local Environment

1. Open the `.env` file in the root of your project
2. Replace the placeholder values with your actual credentials:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-actual-anon-key-here
```

⚠️ **IMPORTANT**: Never commit the `.env` file to version control! It's already in `.gitignore`.

## Step 4: Set Up Database Tables (MVP Phase)

Run these SQL commands in the Supabase SQL Editor (**Database** → **SQL Editor**):

### 1. Enable Row Level Security (RLS)
```sql
-- Enable RLS on all tables by default
ALTER DEFAULT PRIVILEGES REVOKE ALL ON TABLES FROM PUBLIC;
```

### 2. Create Users Profile Table
```sql
CREATE TABLE public.user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid() = id);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON public.user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);
```

### 3. Create Groups/Wallets Table
```sql
CREATE TABLE public.groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view groups they're members of
CREATE POLICY "Users can view groups they belong to"
  ON public.groups FOR SELECT
  USING (
    id IN (
      SELECT group_id FROM public.group_members
      WHERE user_id = auth.uid()
    )
  );
```

### 4. Create Group Members Table
```sql
CREATE TABLE public.group_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view members of their groups"
  ON public.group_members FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM public.group_members
      WHERE user_id = auth.uid()
    )
  );
```

### 5. Create Transactions Table
```sql
CREATE TABLE public.transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  paid_by UUID REFERENCES auth.users(id) NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  description TEXT NOT NULL,
  category TEXT,
  transaction_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view group transactions"
  ON public.transactions FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM public.group_members
      WHERE user_id = auth.uid()
    )
  );
```

### 6. Create Transaction Splits Table
```sql
CREATE TABLE public.transaction_splits (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id UUID REFERENCES public.transactions(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  is_settled BOOLEAN DEFAULT FALSE,
  settled_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE public.transaction_splits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view splits in their groups"
  ON public.transaction_splits FOR SELECT
  USING (
    transaction_id IN (
      SELECT id FROM public.transactions
      WHERE group_id IN (
        SELECT group_id FROM public.group_members
        WHERE user_id = auth.uid()
      )
    )
  );
```

## Step 5: Enable Authentication Methods

1. Go to **Authentication** → **Providers** in your Supabase dashboard
2. Enable the following providers:
   - **Email**: Enable (for email/password auth)
   - **Phone**: Enable (for SMS OTP - requires Twilio integration)
   - **Google**: Enable for social login (optional, requires OAuth setup)

### Email Settings:
- Enable "Confirm email"
- Enable "Secure email change"
- Set "Minimum password length" to 8

### Configure Email Templates (Optional):
- Go to **Authentication** → **Email Templates**
- Customize the confirmation, password reset, and magic link emails

## Step 6: Configure Storage (for profile images)

1. Go to **Storage** in your Supabase dashboard
2. Create a new bucket called `avatars`
3. Set the bucket to **Public**
4. Set up RLS policies for the bucket:

```sql
-- Policy: Users can upload their own avatar
CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy: Anyone can view avatars
CREATE POLICY "Public avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Policy: Users can update their own avatar
CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

## Step 7: Test the Connection

Run your Flutter app:

```bash
flutter run
```

The app should start without errors. Check the console for Supabase initialization logs.

## Step 8: Set Up Real-time Subscriptions (Optional)

If you want real-time updates for transactions and balances:

1. Go to **Database** → **Replication**
2. Enable replication for the tables you want to subscribe to:
   - `transactions`
   - `transaction_splits`
   - `groups`
   - `group_members`

## Security Best Practices

✅ **DO:**
- Keep your `.env` file secure and never commit it
- Use Row Level Security (RLS) policies for all tables
- Validate data on both client and server side
- Use the `anon` key for client-side apps
- Store sensitive operations in Supabase Edge Functions

❌ **DON'T:**
- Don't use the `service_role` key in client-side code
- Don't store sensitive data unencrypted
- Don't skip email verification in production
- Don't expose your database password

## Troubleshooting

### Issue: "Invalid API key" error
- Double-check your `.env` file has the correct `SUPABASE_ANON_KEY`
- Make sure you're using the **anon/public** key, not the service role key

### Issue: "Failed to load .env file"
- Ensure `.env` file is in the project root
- Make sure it's added to `pubspec.yaml` under assets
- Run `flutter clean && flutter pub get`

### Issue: Row Level Security blocking queries
- Check your RLS policies in the SQL Editor
- Use the Supabase dashboard to test queries as different users

## Next Steps

1. Set up authentication flows in your Flutter app
2. Create UI for user registration and login
3. Implement group creation and management
4. Build the bill splitting features

## Useful Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart/introduction)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase Auth Guide](https://supabase.com/docs/guides/auth)
