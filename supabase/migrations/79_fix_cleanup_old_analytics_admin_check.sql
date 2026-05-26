-- Add admin role check to cleanup_old_analytics.
-- Previously the function had SECURITY DEFINER but no caller verification,
-- meaning any authenticated user could delete analytics data.
CREATE OR REPLACE FUNCTION cleanup_old_analytics()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: admin access required';
  END IF;

  DELETE FROM analytics_events
  WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$;

GRANT EXECUTE ON FUNCTION cleanup_old_analytics() TO authenticated;
