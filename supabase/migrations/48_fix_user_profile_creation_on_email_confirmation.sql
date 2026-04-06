-- ============================================================================
-- Fix user profile creation to only happen after email confirmation.
--
-- Previously, a trigger on auth.users INSERT would create the user_profiles
-- row immediately at sign-up, before the user confirmed their email.
-- This migration replaces that with two triggers:
--   1. INSERT trigger: creates the profile only when email confirmation is
--      already confirmed (covers setups where email confirmation is disabled).
--   2. UPDATE trigger: creates the profile when email_confirmed_at transitions
--      from NULL → a value (i.e. when the user confirms their email).
-- ============================================================================

-- Function called on new user INSERT
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create profile immediately if email is already confirmed.
  -- When email confirmation is required, the UPDATE trigger below handles it.
  IF NEW.email_confirmed_at IS NOT NULL THEN
    INSERT INTO public.user_profiles (id, email, full_name)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', '')
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate the INSERT trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function called when a user's email is confirmed
CREATE OR REPLACE FUNCTION public.handle_email_confirmed()
RETURNS TRIGGER AS $$
BEGIN
  -- Only fire when email_confirmed_at goes from NULL to a timestamp
  IF OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL THEN
    INSERT INTO public.user_profiles (id, email, full_name)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', '')
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger that fires when auth.users is updated (e.g. email confirmed)
DROP TRIGGER IF EXISTS on_auth_user_email_confirmed ON auth.users;
CREATE TRIGGER on_auth_user_email_confirmed
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_email_confirmed();
