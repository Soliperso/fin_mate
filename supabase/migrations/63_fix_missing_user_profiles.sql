-- Backfill user_profiles for auth.users rows that were created during
-- the window when email verification was off and email_confirmed_at was never set.
INSERT INTO public.user_profiles (id, email, full_name)
SELECT
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'full_name', '')
FROM auth.users au
LEFT JOIN public.user_profiles up ON up.id = au.id
WHERE up.id IS NULL
ON CONFLICT (id) DO NOTHING;
