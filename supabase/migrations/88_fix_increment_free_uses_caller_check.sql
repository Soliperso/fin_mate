-- Migration 88: Add caller-owns-ID guard to increment_free_uses
-- Prevents any authenticated user from incrementing another user's counter.

CREATE OR REPLACE FUNCTION increment_free_uses(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Forbidden: cannot modify another user''s counter';
  END IF;

  UPDATE user_profiles
     SET free_uses_count = free_uses_count + 1
   WHERE id = p_user_id
  RETURNING free_uses_count INTO v_count;

  IF v_count IS NULL THEN
    RAISE EXCEPTION 'User profile not found for id %', p_user_id;
  END IF;

  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION increment_free_uses(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION increment_free_uses(UUID) TO authenticated;
