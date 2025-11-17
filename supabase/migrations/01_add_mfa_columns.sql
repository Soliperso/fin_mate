-- Migration: Add MFA columns to user_profiles table
-- Created: 2025-10-05
-- Description: Adds multi-factor authentication support columns

-- Add MFA columns to user_profiles table
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS mfa_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS mfa_method TEXT CHECK (mfa_method IN ('email', 'totp') OR mfa_method IS NULL),
ADD COLUMN IF NOT EXISTS totp_secret TEXT;

-- Add index for faster MFA lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_mfa_enabled ON user_profiles(mfa_enabled) WHERE mfa_enabled = true;

-- Add comment to columns for documentation
COMMENT ON COLUMN user_profiles.mfa_enabled IS 'Whether multi-factor authentication is enabled for this user';
COMMENT ON COLUMN user_profiles.mfa_method IS 'The MFA method being used: email or totp';
COMMENT ON COLUMN user_profiles.totp_secret IS 'Encrypted TOTP secret for authenticator apps (store encrypted in production)';

-- Ensure RLS is enabled on user_profiles if not already
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Update RLS policy to allow users to update their own MFA settings
-- Drop existing policy if it exists and recreate
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

CREATE POLICY "Users can update own profile"
ON user_profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Add select policy if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_profiles'
    AND policyname = 'Users can view own profile'
  ) THEN
    CREATE POLICY "Users can view own profile"
    ON user_profiles
    FOR SELECT
    USING (auth.uid() = id);
  END IF;
END $$;

-- Add insert policy for new users (created via trigger on auth.users)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_profiles'
    AND policyname = 'Users can insert own profile'
  ) THEN
    CREATE POLICY "Users can insert own profile"
    ON user_profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);
  END IF;
END $$;
