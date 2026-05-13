-- Public-facing RPC: any authenticated user can read current flag states.
-- Used by the client app to gate features at runtime.
-- Admin-only write access is handled by admin_set_feature_flag().
CREATE OR REPLACE FUNCTION get_feature_flags()
RETURNS TABLE (key TEXT, enabled BOOLEAN)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY SELECT f.key, f.enabled FROM feature_flags f;
END;
$$;
