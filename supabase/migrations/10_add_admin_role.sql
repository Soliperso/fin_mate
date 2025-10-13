-- ============================================================================
-- ADD ADMIN ROLE TO USER PROFILES
-- ============================================================================
-- This migration adds a role column to user_profiles table
-- The role can ONLY be set via direct database access (not through app UI)
-- ============================================================================

-- Add role column with enum constraint
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS role TEXT
CHECK (role IN ('user', 'admin'))
DEFAULT 'user'
NOT NULL;

-- Create index for efficient role-based queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);

-- ============================================================================
-- OPTIONAL: RLS POLICIES FOR ADMIN-ONLY FEATURES
-- ============================================================================

-- Example: Allow admins to view all user profiles (optional, enable if needed)
-- DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
-- CREATE POLICY "Admins can view all profiles" ON public.user_profiles
--   FOR SELECT USING (
--     (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'admin'
--     OR auth.uid() = id
--   );

-- ============================================================================
-- HELPER FUNCTION: Check if user is admin
-- ============================================================================

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    SELECT role = 'admin'
    FROM public.user_profiles
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- MIGRATION COMPLETE!
-- ============================================================================
-- To set a user as admin, run this in Supabase SQL Editor:
-- UPDATE public.user_profiles SET role = 'admin' WHERE email = 'your-email@example.com';
-- ============================================================================
