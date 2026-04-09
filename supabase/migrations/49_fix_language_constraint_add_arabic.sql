-- Migration 49: Replace German ('de') with Arabic ('ar') in language check constraint
-- The app dropped German in favour of Arabic, but the DB constraint still blocks 'ar'.

ALTER TABLE user_profiles
  DROP CONSTRAINT IF EXISTS user_profiles_language_check;

ALTER TABLE user_profiles
  ADD CONSTRAINT user_profiles_language_check
    CHECK (language IN ('en', 'es', 'fr', 'ar'));

-- Also update the update_user_settings function to accept 'ar'
CREATE OR REPLACE FUNCTION update_user_settings(
  p_user_id UUID,
  p_theme_mode TEXT DEFAULT NULL,
  p_language TEXT DEFAULT NULL,
  p_notification_preferences JSONB DEFAULT NULL
)
RETURNS user_profiles
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result user_profiles;
BEGIN
  UPDATE user_profiles
  SET
    theme_mode = COALESCE(p_theme_mode, theme_mode),
    language   = COALESCE(p_language, language),
    notification_preferences = COALESCE(p_notification_preferences, notification_preferences),
    updated_at = NOW()
  WHERE id = p_user_id
  RETURNING * INTO result;

  RETURN result;
END;
$$;
