ALTER TABLE feature_flags ADD COLUMN IF NOT EXISTS is_beta BOOLEAN DEFAULT false;
UPDATE feature_flags SET is_beta = true WHERE key = 'ai_insights';

DROP FUNCTION IF EXISTS admin_get_feature_flags();

CREATE FUNCTION admin_get_feature_flags()
RETURNS TABLE (key TEXT, name TEXT, description TEXT, enabled BOOLEAN, is_beta BOOLEAN, updated_at TIMESTAMPTZ)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  RETURN QUERY
    SELECT f.key, f.name, f.description, f.enabled, f.is_beta, f.updated_at
    FROM feature_flags f ORDER BY f.name;
END; $$;
