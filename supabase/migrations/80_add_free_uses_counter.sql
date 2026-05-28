-- Migration 80: Add lifetime free-uses counter to user_profiles
-- Tracks how many premium features a free user has consumed.
-- Premium users bypass this counter entirely (checked in-app).

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS free_uses_count INTEGER NOT NULL DEFAULT 0;

-- Atomically increment and return the new count.
-- SECURITY DEFINER so it can update the row regardless of RLS.
CREATE OR REPLACE FUNCTION increment_free_uses(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
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

-- Allow authenticated users to call this RPC only for their own id.
REVOKE ALL ON FUNCTION increment_free_uses(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION increment_free_uses(UUID) TO authenticated;
