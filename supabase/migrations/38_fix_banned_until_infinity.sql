-- Migration 38: Fix banned_until — replace 'infinity' with a far-future date.
-- GoTrue (Go) cannot scan Postgres's 'infinity' sentinel into time.Time,
-- causing a 500 "Database error querying schema" instead of a proper 403 "User is banned".

CREATE OR REPLACE FUNCTION admin_set_user_active(p_user_id UUID, p_active BOOLEAN)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin privileges required.';
  END IF;

  UPDATE public.user_profiles
  SET is_active = p_active
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found.';
  END IF;

  UPDATE auth.users
  SET banned_until = CASE
    WHEN p_active THEN NULL
    ELSE '2100-01-01 00:00:00+00'::timestamptz
  END
  WHERE id = p_user_id;
END;
$$;

REVOKE ALL ON FUNCTION admin_set_user_active(UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION admin_set_user_active(UUID, BOOLEAN) TO authenticated;

-- Fix existing rows set to 'infinity' by migration 37
UPDATE auth.users
SET banned_until = '2100-01-01 00:00:00+00'::timestamptz
WHERE banned_until = 'infinity'::timestamptz;
