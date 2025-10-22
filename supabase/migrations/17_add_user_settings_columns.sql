-- ============================================================================
-- ADD USER SETTINGS COLUMNS
-- ============================================================================
-- This migration adds user preferences for theme, language, and notifications

-- Add new columns to user_profiles table
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS theme_mode TEXT DEFAULT 'system' CHECK (theme_mode IN ('light', 'dark', 'system')),
ADD COLUMN IF NOT EXISTS language TEXT DEFAULT 'en' CHECK (language IN ('en', 'es', 'fr', 'de')),
ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT jsonb_build_object(
  'push_enabled', true,
  'email_enabled', false,
  'sound_enabled', true,
  'budget_alerts', true,
  'budget_threshold', 80,
  'bill_reminders', true,
  'bill_reminder_days', 1,
  'transaction_alerts', false,
  'transaction_threshold', 1000,
  'money_health_updates', 'weekly',
  'goal_notifications', 'milestones'
);

-- Create index on user_profiles for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_theme_mode ON public.user_profiles(theme_mode);

-- ============================================================================
-- FUNCTION: Update user settings
-- ============================================================================
DROP FUNCTION IF EXISTS update_user_settings CASCADE;
CREATE OR REPLACE FUNCTION update_user_settings(
  p_user_id UUID,
  p_theme_mode TEXT DEFAULT NULL,
  p_language TEXT DEFAULT NULL,
  p_notification_preferences JSONB DEFAULT NULL
)
RETURNS public.user_profiles AS $$
DECLARE
  v_updated RECORD;
BEGIN
  UPDATE public.user_profiles
  SET
    theme_mode = COALESCE(p_theme_mode, theme_mode),
    language = COALESCE(p_language, language),
    notification_preferences = COALESCE(p_notification_preferences, notification_preferences),
    updated_at = NOW()
  WHERE id = p_user_id
  RETURNING * INTO v_updated;

  RETURN v_updated;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================
-- Already covered in 00_create_core_schema.sql - users can view/update own profile
