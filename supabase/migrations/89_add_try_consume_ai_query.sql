-- Migration 89: Atomic AI query gate used by the openai-proxy Edge Function.
-- Checks the caller's subscription tier and free-use count in a single
-- row-locked transaction, then increments on success. The proxy calls this
-- instead of relying on client-side increment, so the limit is enforced
-- server-side even if the mobile client is bypassed.

CREATE OR REPLACE FUNCTION try_consume_ai_query(p_user_id UUID, p_limit INTEGER)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier  TEXT;
  v_count INTEGER;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Forbidden: cannot consume another user''s quota';
  END IF;

  SELECT subscription_tier, free_uses_count
    INTO v_tier, v_count
    FROM user_profiles
   WHERE id = p_user_id
     FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User profile not found for id %', p_user_id;
  END IF;

  -- Premium users are never gated
  IF v_tier = 'premium' THEN
    RETURN TRUE;
  END IF;

  -- Free users: check limit before incrementing
  IF v_count >= p_limit THEN
    RETURN FALSE;
  END IF;

  UPDATE user_profiles
     SET free_uses_count = free_uses_count + 1
   WHERE id = p_user_id;

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION try_consume_ai_query(UUID, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION try_consume_ai_query(UUID, INTEGER) TO authenticated;
