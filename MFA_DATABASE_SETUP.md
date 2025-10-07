# MFA Database Setup Guide

This guide will help you add the required database columns for Multi-Factor Authentication (MFA) in FinMate.

## Quick Start (Easiest Method)

### Option 1: Using Supabase Dashboard (Recommended)

1. **Go to your Supabase Dashboard**
   - Visit: https://app.supabase.com
   - Select your FinMate project

2. **Open SQL Editor**
   - Click **"SQL Editor"** in the left sidebar
   - Click **"New Query"** button

3. **Copy and Paste this SQL**

```sql
-- Add MFA columns to user_profiles table
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS mfa_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS mfa_method TEXT CHECK (mfa_method IN ('email', 'totp') OR mfa_method IS NULL),
ADD COLUMN IF NOT EXISTS totp_secret TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_mfa_enabled
ON user_profiles(mfa_enabled)
WHERE mfa_enabled = true;
```

4. **Click "Run"** (or press Cmd/Ctrl + Enter)

5. **Verify Success**
   - You should see: "Success. No rows returned"
   - The columns are now added!

---

## Option 2: Using Supabase CLI

If you have the Supabase CLI installed:

```bash
# Navigate to project directory
cd /Users/ahmedchebli/Desktop/fin_mate

# Link to your Supabase project (if not already linked)
supabase link --project-ref YOUR_PROJECT_REF

# Push the migration
supabase db push

# The migration file is at: supabase/migrations/add_mfa_columns.sql
```

---

## Option 3: Manual SQL Execution

If you prefer to run the SQL manually from the migration file:

```bash
# View the migration file
cat supabase/migrations/add_mfa_columns.sql

# Copy the SQL content and paste it into Supabase SQL Editor
```

---

## Verification

After running the migration, verify it worked:

### 1. Check Columns Exist

Run this query in Supabase SQL Editor:

```sql
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'user_profiles'
AND column_name IN ('mfa_enabled', 'mfa_method', 'totp_secret');
```

**Expected Result:**
```
column_name  | data_type | column_default
-------------+-----------+---------------
mfa_enabled  | boolean   | false
mfa_method   | text      | NULL
totp_secret  | text      | NULL
```

### 2. Test from Flutter App

1. Run your Flutter app: `flutter run`
2. Log in to your account
3. Navigate to: **Profile → Security**
4. Try enabling MFA
5. Check the database:

```sql
SELECT id, email, mfa_enabled, mfa_method
FROM user_profiles
WHERE mfa_enabled = true;
```

---

## Troubleshooting

### ❌ Error: "relation user_profiles does not exist"

**Solution:** You need to create the user_profiles table first.

Run this SQL in Supabase SQL Editor:

```sql
-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  date_of_birth TIMESTAMPTZ,
  currency TEXT DEFAULT 'USD',
  mfa_enabled BOOLEAN DEFAULT false,
  mfa_method TEXT CHECK (mfa_method IN ('email', 'totp') OR mfa_method IS NULL),
  totp_secret TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON user_profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
ON user_profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();
```

### ❌ Error: "permission denied"

**Solution:** Check Row Level Security policies.

```sql
-- View current policies
SELECT * FROM pg_policies WHERE tablename = 'user_profiles';

-- Recreate update policy if needed
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
CREATE POLICY "Users can update own profile"
ON user_profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
```

### ❌ Error: "column already exists"

**Solution:** This is actually fine! It means the columns were already added. You can ignore this error.

### ❌ MFA settings not saving in app

**Checklist:**
1. ✅ Verify user is logged in
2. ✅ Check Supabase logs in dashboard
3. ✅ Verify RLS policies exist
4. ✅ Check Flutter console for errors
5. ✅ Ensure `.env` file has correct Supabase credentials

---

## What These Columns Do

| Column | Type | Purpose |
|--------|------|---------|
| `mfa_enabled` | boolean | Whether MFA is turned on for this user |
| `mfa_method` | text | Which MFA method: 'email' or 'totp' |
| `totp_secret` | text | Secret key for authenticator apps (Google Authenticator, Authy, etc.) |

---

## Security Notes

### 🔒 Production Considerations

For production, consider encrypting the `totp_secret` column:

```sql
-- Example: Use Supabase Vault for encryption (requires Vault setup)
-- Or implement app-level encryption before storing
```

### 📊 Optional: Add Audit Logging

Track when users enable/disable MFA:

```sql
CREATE TABLE mfa_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  mfa_method TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Next Steps

After database setup is complete:

1. ✅ Run your Flutter app: `flutter run`
2. ✅ Create a test account or log in
3. ✅ Go to **Profile → Security**
4. ✅ Test **Biometric Login** (if device supports it)
5. ✅ Test **MFA Setup** with TOTP (scan QR code with Google Authenticator)
6. ✅ Test **MFA Setup** with Email OTP
7. ✅ Verify login works with MFA enabled

---

## Resources

- [Supabase Dashboard](https://app.supabase.com)
- [Supabase SQL Editor Docs](https://supabase.com/docs/guides/database/overview)
- [FinMate Migration File](supabase/migrations/add_mfa_columns.sql)

---

## Support

If you encounter issues:

1. Check Supabase Dashboard → Logs
2. Check Flutter console output
3. Verify `.env` file credentials
4. Review existing schema files in project root

Need help? The migration file includes detailed SQL with comments.
