-- Migration 60: Reset all existing users to is_active = true
-- Ensures every signed-up user starts with Active status.
-- Any Inactive state from prior testing is cleared.

UPDATE public.user_profiles
SET is_active = TRUE
WHERE is_active = FALSE;
